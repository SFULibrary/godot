# Class::DBI::Details
#
# Base class for implementing a details style interface to a 
# table.
#
# Copyright Todd Holbrook, Simon Fraser University (2003)
#

package Class::DBI::Details;

use base qw(Class::Accessor Class::Data::Inheritable);

use strict;

__PACKAGE__->mk_classdata('_columns');
__PACKAGE__->mk_classdata('_field');
__PACKAGE__->mk_classdata('_value');
__PACKAGE__->mk_classdata('_DB');

__PACKAGE__->_field('field');
__PACKAGE__->_value('value');

sub new {
	my ($class, $key, $id) = @_;
	my $self = bless {}, $class;
	$self->{_has_been_initialized} = 0;  # Cheat here to avoid get _init trigger loop
	$self->{_key} = $key;
	$self->{_id} = $id;
	_require_class($class->_DB);

	return $self;
}

sub _require_class {
	my $class = shift;

	# return quickly if class already exists
	no strict 'refs';
	return if exists ${"$class\::"}{ISA};
	return if eval "require $class";

	# Only ignore "Can't locate" errors from our eval require.
	# Other fatal errors (syntax etc) must be reported (as per base.pm).
	return if $@ =~ /^Can't locate .*? at \(eval /;
	chomp $@;
	Carp::croak($@);
}



sub _mk_column_accessors {
	my ($class, @columns) = @_;

	foreach my $col (@columns) {
		my $accessor = $class->make_accessor($col);
		$class->_make_method($class->accessor_name($col), $accessor);

		$accessor = $class->make_delete_accessor($col);
		$class->_make_method($class->deletor_name($col), $accessor);
	}
}

sub _make_method {
	my ($class, $name, $method) = @_;
	return if defined &{"$class\::$name"};
	$class->_carp("Column '$name' in $class clashes with built-in method")
		if defined &{"Class::DBI::Details::$name"};
	no strict 'refs';
	*{"$class\::$name"} = $method;
	return;
}

sub make_delete_accessor {
	my ($class, $col) = @_;

	return sub {
		my $self = shift;
		$self->_init() unless $self->{_has_been_initialized};
		delete $self->{$col};
		$self->{__deleted_cols}->{$col} = 1;
		return undef;
	};
}

sub set {
	my $self = shift;
	my $key = shift;

	$self->_init() unless $self->{_has_been_initialized} or $self->{_initializing};

	$self->{__dirty_cols}->{$key} = 1 unless $self->{_initializing};
	delete($self->{__deleted_cols}->{$key}) if $self->{__deleted_cols}->{$key};

	return $self->SUPER::set($key, @_);
}

sub get {
	my $self = shift;
	my $key = shift;

	$self->_init() unless $self->{_has_been_initialized} or $self->{_initializing};
	
	return undef if $self->{__deleted_cols}->{$key};
	return $self->SUPER::get($key, @_);
}

sub columns {
	my $proto = shift;
	my $class = ref $proto || $proto;
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
	
	my @rows = $self->_DB->search($self->{_key} => $self->{_id});

	$self->{_initializing} = 1;

	foreach my $row (@rows) {
		my $method = $row->field;
		if (defined($self->$method())) {
			$self->_croak('Multiple detail fields found in ' . $self->_DB . ' for id '.  $self->{_id} . ' - field ' . $method);
		}
		$self->$method($row->value);
	}

	$self->{_initializing} = 0;
	$self->{_has_been_initialized} = 1;  # Cheat here to avoid get _init trigger loop
}


sub _update {
	my ($self) = @_;

	no strict 'refs';
	foreach my $col (keys %{$self->{__dirty_cols}}) {
		my @rows = $self->_DB->search($self->{_key} => $self->{_id}, $self->_field => $col);
		if (scalar(@rows) == 1) {
			my $method = $self->_value;
			$rows[0]->$method($self->$col);
			$rows[0]->update();
		} elsif (scalar(@rows) > 0) {
			$self->_croak('Multiple detail fields found in ' . $self->_DB . ' for id ' . $self->{_id} . ' - field ' . $col);
		} else {
			$self->_DB->create({$self->_field => $col, $self->_value => $self->$col, $self->{_key} => $self->{_id}});
		}
	}
	
	foreach my $col (keys %{$self->{__deleted_cols}}) {
		$self->_DB->delete($self->{_key} => $self->{_id}, $self->_field => $col);
	}
	
	delete $self->{__dirty_cols};
	delete $self->{__deleted_cols};

	return 1;
}


sub _delete {
	my ($self) = @_;
#	$self->_DB->delete($self->{_key} => $self->{_id});

## WORK AROUND THE delete() using LIKE

	my $it = $self->_DB->search($self->{_key} => $self->{_id});
	while (my $obj = $it->next) { $obj->delete }

	return 1;
}



sub DESTROY {
	my ($self) = shift;
	my @dirty;
	foreach my $col (keys %{$self->{__dirty_cols}}) {
		push @dirty, $col;
	}
	foreach my $col (keys %{$self->{__deleted_cols}}) {
		push @dirty, $col;
	}
	if (scalar(@dirty) > 0) {
		my($class, $id, $key) = (ref($self), $self->{_id}, $self->{_key});
		$self->_carp("$class for key $key id $id destroyed without saving changes to " . join (', ', @dirty));
	}
}

sub ignore_changes {
	delete $_[0]->{__dirty_cols};
	delete $_[0]->{__deleted_cols};
	return $_[0];
}


#-------------------------------------------------------------------------
# EXCEPTIONS
#-------------------------------------------------------------------------

sub _carp {
	my ($self, $msg) = @_;
	Carp::carp($msg || $self);
	return;
}

sub _croak {
	my ($self, $msg) = @_;
	Carp::croak($msg || $self);
	return;
}
                                                



1;
