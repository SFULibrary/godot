
#
# Copyright Todd Holbrook - Simon Fraser University (2003)
#

package GODOTConfig::DB::DBI;

use base 'Class::DBI';
use Exception::Class::DBI;
use GODOTConfig::Exceptions;
use GODOTConfig::Config;
use SQL::Abstract;
use Class::DBI::Query;
use Class::DBI::AbstractSearch;
use Class::DBI::Iterator;

use strict;

#
# Override the Class::DBI _croak() method to throw an exception instead of croaking
#

sub _croak {
	my ($self, $message, %info) = @_;

	GODOTConfig::Exception::DB->throw(message => $message, info => \%info);

	return; 
}

__PACKAGE__->set_db('Main', @GODOTConfig::Config::GODOT_DB_CONNECT);

__PACKAGE__->set_sql('count_where' =>
	qq{
		SELECT COUNT(%s)
		FROM %s
		WHERE %s
	});
	
sub count_where_abstract {
	my ($class, %where) = @_;
	
	my $sql = SQL::Abstract->new;
	my ($where, @bind) = $sql->where(\%where);
	$where =~ s/^\s*WHERE\s*//i;
		
	my $sth;
	my $val = eval {
		$sth = $class->sql_count_where('*', $class->table, $where);
		$sth->execute(@bind);
		my @row = $sth->fetchrow_array;
		$sth->finish;
		$row[0];
	};
	if ($@) {
		_croak("Error in count_where: '$sth->{Statement}': $@");
	}

	return $val;
}

sub count_where { shift->_count_where('=', @_) };
sub count_where_like { shift->_count_where('LIKE', @_) };

sub _count_where {
	my ($proto, $search_type, @args) = @_;
	my $class = ref $proto || $proto;
	
        @args = %{ $args[0] } if ref $args[0] eq "HASH";
        my (@cols, @vals);
        my $search_opts = @args % 2 ? pop @args : {};
        while (my ($col, $val) = splice @args, 0, 2) {
		my $column = $class->find_column($col) || (first { $_->accessor eq $col } $class->columns) or
			$class->_croak("$col is not a column of $class");

                push @cols, $col;
                push @vals, $class->_deflated_column($col, $val);
        }

        my $query = Class::DBI::Query->new({ owner => $class, sqlname => 'count_where', essential => '*' });
        $query->add_restriction("$_ $search_type ?") foreach @cols;
	$query->add_restriction("1 = 1") unless $query->restrictions;  # There must be one WHERE clause (Simon Wilcox)
	
        my $sth = $query->run(\@vals);

	my $val = $sth->fetchrow_arrayref->[0];

	$sth->finish;
	return $val;

}

##
## Experimental and untested
##

sub retrieve_all_limit {
	my ($class, $limit, $offset) = @_;
	
	my $sql = '';
	$sql .= 'LIMIT $limit' if defined($limit);
	$sql .= 'OFFSET $offset' if defined($offset);
	
	return $class->retrieve_from_sql($sql); 
}


1;













