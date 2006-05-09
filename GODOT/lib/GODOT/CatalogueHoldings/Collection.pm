##
## Copyright (c) 2003, Kristina Long, Simon Fraser University
##

package GODOT::CatalogueHoldings::Collection;

use GODOT::CatalogueHoldings::Object;
@ISA = qw (GODOT::CatalogueHoldings::Object);

use GODOT::Debug;
use GODOT::String;


use strict;

my $FALSE = 0;
my $TRUE  = 1;


my @COLLECTION_TYPES = qw(ERIC MICROLOG);

my @FIELDS = qw(type text); 
                
sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}


sub type {
    my($self, $type) = @_;

    unless (grep {$type eq $_} (@COLLECTION_TYPES)) {
        debug("GODOT::CatalogueHoldings::Collection was not passed a valid type");        
        return undef;       
    }  
    
    if ($type) { $self->{'type'} = $type; }

    return $self->{'type'};
}

sub text {
    my($self, $text) = @_;

    unless ($self->{'type'}) {
 
        debug("GODOT::CatalogueHoldings::Collection:  please set a collection type before setting text");
        return undef;
    } 

    if ($text) { $self->{'text'} = $text; }

    return $self->{'text'};
}

sub ok_type {
    my($class, $type) = @_;

    my $res = (grep {$type eq $_} @COLLECTION_TYPES) ? $TRUE : $FALSE;  

    return $res;
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
