##
## Copyright (c) 2003, Kristina Long, Simon Fraser University
##

package GODOT::CatalogueHoldings::Holdings;

use GODOT::CatalogueHoldings::Object;
@ISA = qw (GODOT::CatalogueHoldings::Object);

use GODOT::Debug;
use GODOT::String;


use strict;

my $FALSE = 0;
my $TRUE  = 1;

my @FIELDS = qw(site holdings); 
                
sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}


sub site {
    my($self, $site) = @_;
    
    $self->{'site'} = $site unless aws($site);
    return $self->{'site'};
}

sub holdings {
    my($self, $holdings) = @_;

    unless ($self->{'site'}) {
        debug(location, ":  please set the site before setting the holdings statement");
        return undef;
    } 

    $self->{'holdings'} = $holdings unless aws($holdings);

    return $self->{'holdings'};
}




1;

__END__

-----------------------------------------------------------------------------------------

=head1 NAME

GODOT::CatalogueHoldings::Terms - 

=head1 METHODS

=head2 Constructor

=over 4

=item new()

=back

=head2 ACCESSOR METHODS

=over 4

=item mysubroutine([$value])

=back

=head1 AUTHORS / ACKNOWLEDGMENTS

Kristina Long


=cut
