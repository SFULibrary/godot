##
## Copyright (c) 2003, Kristina Long, Simon Fraser University
##

package GODOT::CatalogueHoldings::Circulation;

use GODOT::CatalogueHoldings::Object;
@ISA = qw (GODOT::CatalogueHoldings::Object);

use GODOT::Debug;
use GODOT::String;

use strict;

my $FALSE = 0;
my $TRUE  = 1;

my @FIELDS = qw(item_location call_number status); 
                
sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}

sub item_location {
    my($self, $location) = @_;

    $location = trim_beg_end($location);

    if ($location ne '') { $self->{'item_location'} = $location; }

    return $self->{'item_location'};
}

sub call_number {
    my($self, $callno) = @_;

    unless ($self->{'item_location'}) {
 
        debug("GODOT::CatalogueHoldings::Circulation::call_number:  please set the location before setting the call number");
        return undef;
    } 

    if (defined $callno) { $self->{'call_number'} = $callno; }

    return $self->{'call_number'};
}


sub status {
    my($self, $status) = @_;

    unless ($self->{'item_location'}) {
 
        debug("GODOT::CatalogueHoldings::Circulation::status:  please set the location before setting the status");
        return undef;
    } 

    if (defined $status) { $self->{'status'} = $status; }
    
    return $self->{'status'};
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
