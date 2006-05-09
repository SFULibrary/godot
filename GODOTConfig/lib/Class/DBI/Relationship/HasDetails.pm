package Class::DBI::Relationship::HasDetails;

=head1 NAME

Class::DBI::Relationship::HasDetails

=head1 DESCRIPTION

Relationship module for Class::DBI that adds extra fields to a table object
based on field/value pairs in another table.  This can be handy if you have
some base information that belongs to most records and extra information
that belong to very few but you want to treat them the same when using the
object. It is also handy if you are working with data where new fields show
up regularly that belong to a subset of the data and you don't want to have
to make regular schema changes.  It's not as useful when it's data you want
to search on often, use as a foreign key, etc.  I call these bits of
information "details".

These fields work pretty much the same as a native table field if you use
the generated accessor on them.  It does not override set() or get() to
allow for accessing them that way.  I haven't tried setting triggers or
validation or anything like that either, though it may work.

Here's an example based on the included test file.

You have a basic Movie table with the title and release year of the movie.
You don't know what extra information someone might want to store - genre,
tagline, price, etc.

So you create the basic Movie table:

  movie
  -------------------------
  id    INTEGER PRIMARY KEY
  title VARCHAR(1024)
  year  INTEGER

and a details table:

  movie_details
  -------------------------
  id       INTEGER PRIMARY KEY
  movie    INTEGER
  field    VARCHAR(1024)
  value    VARCHAR(1024)

and use CDBI::R::HasDetails to link them:

  package My::Movie;

  use base 'My::DBI';

  use Class::DBI::Relationship::HasDetails;
  __PACKAGE__->table('Movies');
  __PACKAGE__->columns(All => qw/id title year/);

  __PACKAGE__->has_details('details', 'My::MovieDetails' => 'movie');
  __PACKAGE__->details_columns(qw(tagline genre price));
	
You can now do:

  my $movie = My::Movie->create( { title => 'Trainspotting', year => 1996 } );
  $movie->genre('Drama');
  $movie->update;


=cut





use strict;
use warnings;

use Data::Dumper;

use base 'Class::DBI::Relationship';

sub import {
	my $self = shift;
	my $caller = caller();
	$caller->mk_classdata('__has_details_list');
	$caller->add_relationship_type(
		has_details => 'Class::DBI::Relationship::HasDetails'
	);
}

sub remap_arguments {
	my ($proto, $class, $accessor, $f_class, $f_key, $args) = @_;

	return $class->_croak("has_details needs an accessor name") unless $accessor;
	return $class->_croak("has_details needs a foreign class")  unless $f_class;
	return $class->_croak("has_details needs a foreign key") unless $f_key;

	$class->can($accessor)
		and return $class->_carp("$accessor method already exists in $class\n");

	$class->_require_class($f_class);

	if (ref $f_key eq "HASH") {    # didn't supply f_key, this is really $args
		return $class->_croak("has_details needs a foreign key");
	}

	if (ref $f_key eq "ARRAY") {
		return $class->_croak("Multi-column foreign keys not supported")
			if @$f_key > 1;
		$f_key = $f_key->[0];
	}

	$args ||= {};
	$args->{foreign_key} = $f_key;

	no strict 'refs';
	*{"$class\::__details_objects"} = sub { 
			my ($self, $value) = @_;
			defined($value) and
				$self->{'__details_objects'} = $value;
			return $self->{'__details_objects'};
		};

	return ($class, $accessor, $f_class, $args);
}

sub _set_up_class_data {
	my $self = shift;
	my $accessor = $self->accessor;

	$self->SUPER::_set_up_class_data;
}

sub triggers {
	my $details_self = shift;
	my $accessor = $details_self->accessor;

	return (
		before_update => sub {
			my $self = shift;
			return $self->$accessor->_update;
		},
		before_delete => sub {
			my $self = shift;
			return $self->$accessor->_delete;
		}
	);
}

sub methods {
	my $self = shift;
	my $accessor = $self->accessor;

	return (
		$accessor		=> $self->_has_details_method,
		"${accessor}_columns"	=> $self->_details_columns,
	);
}

sub _has_details_method {
	my $details_self = shift;
	my $accessor = $details_self->accessor;
	
	return sub {
		my $self = shift;

		defined($self->__details_objects) or
			$self->__details_objects({});
		unless (ref($self->__details_objects->{$accessor})) {
			my $virtual_class_name = 'Class::DBI::Relationship::HasDetails::Details::' . $details_self->foreign_class;
			my $virtual_class = "package ${virtual_class_name};\n";
			$virtual_class .= "use base 'Class::DBI::Relationship::HasDetails::Details';\n";
			$virtual_class .= "1;\n";

			eval($virtual_class);
			if ($@) {
				$self->_croak("Unable to eval dynamic class: $@");
			}
			$self->__details_objects->{$accessor} = $virtual_class_name->new($details_self->foreign_class, $details_self->args->{foreign_key}, $self->id(), $details_self->args->{columns});
		}
		return $self->__details_objects->{$accessor};
	}
}

sub _details_columns {
	my $self = shift;
	my $accessor = $self->accessor;
	
	return sub {
		my $class = shift;
		if (scalar(@_) > 0) {
			defined($self->args->{columns}) and
				$self->_carp("Detail columns have already been set for accessor '$accessor'.  Results may be... unexpected.");

			$self->args->{columns} = [@_];

			no strict 'refs';
			foreach my $method (@{$self->args->{columns}}) {
				if ($class->can($method)) {
					$self->_carp("method '$method' already exists in base object while mapping details methods");
					next;
				}
				my $accessor_name = Class::DBI::Relationship::HasDetails::Details->accessor_name($method);
				my $deletor_name = Class::DBI::Relationship::HasDetails::Details->deletor_name($method);

				*{"$class\::$accessor_name"} = sub {return shift->$accessor->$accessor_name(@_);};
				*{"$class\::$deletor_name"} = sub {return shift->$accessor->$deletor_name(@_);};
				
			}

		} else {
			return defined($self->args->{columns}) ? @{$self->args->{columns}} : ();
		}
	}
}

##
## Remap set() and get() and provide our own.  We keep the original set() and get() around
## so we can call them.  Hopefully this will be a little more upgrade proof.
##




package Class::DBI::Relationship::HasDetails::Details;

use base qw(Class::Accessor Class::Data::Inheritable);

use Data::Dumper;

__PACKAGE__->mk_classdata('_columns');
__PACKAGE__->mk_classdata('_f_class');
__PACKAGE__->mk_classdata('_key');
__PACKAGE__->mk_classdata('_field');
__PACKAGE__->mk_classdata('_value');

sub _initializing 		{ shift->_local_accessor('_initializing',	@_) }
sub _initialized		{ shift->_local_accessor('_initialized', 	@_) }
sub _id				{ shift->_local_accessor('_id',			@_) }
sub _dirty_cols			{ shift->_local_accessor('_dirty_cols',		@_) }
sub _deleted_cols		{ shift->_local_accessor('_deleted_cols',	@_) }

__PACKAGE__->_field('field');
__PACKAGE__->_value('value');

sub _local_accessor {
	my ($self, $field, $value) = @_;
	defined($self) or
		$self->_croak('Undefined $self in _local_accessor() called from: ' . caller());
	defined($field) or
		$self->_croak('Undefined $field in _local_accessor() called from: ' . caller());

	if (defined($value)) {
		$self->{$field} = $value;
	}
	return $self->{$field};
}


sub new {
	my ($class, $f_class, $key, $id, $columns) = @_;
	my $self = bless {}, $class;

	$self->_initialized(0);
	$self->_initializing(0);

	$self->_f_class($f_class);
	$self->_key($key);
	$self->_id($id);

	$self->_dirty_cols({});
	$self->_deleted_cols({});

	$self->columns(@$columns);

	return $self;
}

sub _mk_column_accessors {
	my ($self, @columns) = @_;

	foreach my $col (@columns) {
		$self->_make_method($self->accessor_name($col), $self->my_make_accessor($col));
		$self->_make_method($self->deletor_name($col), $self->make_delete_accessor($col));
	}
}

##
## Don't use make_accessor from Class::Accessor because we want to check for
## undef in order to delete
##

sub my_make_accessor {
	my ($class, $field) = @_;
	
	# Build a closure around $field.

	my $deletor_name = $class->deletor_name($field);
	
	return sub {
		my $self = shift;
		
		if (scalar(@_)) {
			if (defined($_[0])) {
				return $self->set($field, @_);
			} else {
				return $self->$deletor_name;
			}
		} else {
			return $self->get($field);
		}
	};
}

##
## *** check if _make_method is being called a lot more than it should be.
##

sub _make_method {
	my ($self, $name, $method) = @_;
	no strict 'refs';

	my $class = ref($self);
	return if defined &{"$class\::$name"};

	$self->_carp("Column '$name' in $self clashes with built-in method")
		if defined &{"Class::DBI::Details::$name"};

	*{"$class\::$name"} = $method;	

	return;
}

sub make_delete_accessor {
	my ($class, $col) = @_;

	return sub {
		my $self = shift;
		$self->_init() unless $self->_initialized || $self->_initializing;
		if (defined($self->{$col})) {
			delete $self->{$col};
			$self->_deleted_cols->{$col} = 1;
		}
		return undef;
	};
}

sub set {
	my $self = shift;
	my $key = shift;

	$self->_init() unless $self->_initialized || $self->_initializing;

	$self->_dirty_cols->{$key} = 1 unless $self->_initializing;
	delete($self->_deleted_cols->{$key}) if $self->_deleted_cols->{$key};

	return $self->SUPER::set($key, @_);
}

sub get {
	my $self = shift;
	my $key = shift;

	$self->_init() unless $self->_initialized || $self->_initializing;
	
	return undef if $self->_deleted_cols->{$key};
	return $self->SUPER::get($key, @_);
}

sub columns {
	my $class = shift;

	return $class->_set_columns(@_) if @_;
	return @{$class->_columns};
}

sub _set_columns {
	my ($class, @columns) = @_;

	$class->_columns([@columns]);
	$class->_mk_column_accessors(@columns);

	return @columns;
}

sub accessor_name {
	my ($class, $column) = @_;
	return $column;
}

sub deletor_name {
	my ($class, $column) = @_;
	return "delete_$column";
}

sub _init {
	my ($self) = @_;
	
	my @rows = $self->_f_class->search($self->_key => $self->_id);

	$self->_initializing(1);

	foreach my $row (@rows) {
		my $method = $row->field;
		if (defined($self->$method())) {
			$self->_f_class->_croak('Multiple detail fields found in ' . $self->_f_class . ' for id '.  $self->{_id} . ' - field ' . $method);
		}
		$self->$method($row->value);
	}

	$self->_initializing(0);
	$self->_initialized(1);  # Cheat here to avoid get _init trigger loop
}


sub _update {
	my ($self) = @_;

	no strict 'refs';
	foreach my $col (keys %{$self->_dirty_cols}) {
		my @rows = $self->_f_class->search($self->_key => $self->_id, $self->_field => $col);
		if (scalar(@rows) == 1) {
			my $method = $self->_value;
			$rows[0]->$method($self->$col);
			$rows[0]->update();
		} elsif (scalar(@rows) > 0) {
			$self->_croak('Multiple detail fields found in ' . $self->_f_class . ' for id ' . $self->_id . ' - field ' . $col);
		} else {
			$self->_f_class->create({$self->_field => $col, $self->_value => $self->$col, $self->_key => $self->_id});
		}
	}
	
	foreach my $col (keys %{$self->_deleted_cols}) {
		$self->_f_class->search($self->_key => $self->_id, $self->_field => $col)->delete_all;
	}
	
	$self->_dirty_cols({});
	$self->_deleted_cols({});

	return 1;
}


sub _delete {
	my ($self) = @_;
	$self->_f_class->search($self->_key => $self->_id)->delete_all;
	return 1;
}



sub DESTROY {
	my ($self) = shift;
	my @dirty;
	foreach my $col (keys %{$self->_dirty_cols}) {
		push @dirty, $col;
	}
	foreach my $col (keys %{$self->_deleted_cols}) {
		push @dirty, $col;
	}
	if (scalar(@dirty) > 0) {
		my($class, $id, $key) = (ref($self), $self->_id, $self->_key);
		$self->_f_class->_carp("$class for key $key id $id destroyed without saving changes to " . join (', ', @dirty));
	}
}

sub ignore_changes {
	$_[0]->_dirty_cols({});
	$_[0]->_deleted_cols({});
	return $_[0];
}



	
1;
