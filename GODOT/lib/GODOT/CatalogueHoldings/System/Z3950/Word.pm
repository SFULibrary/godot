##
## Copyright (c) 2003, Kristina Long, Simon Fraser University
##

package GODOT::CatalogueHoldings::System::Z3950::Word;

use GODOT::CatalogueHoldings::Object;
@ISA = qw( GODOT::CatalogueHoldings::Object );


use GODOT::Debug;

use strict;

my $FALSE = 0;
my $TRUE  = 1;

my @FIELDS = ('SingleWord',  
              'AnyNumberWord');


sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}


1;

__END__

-----------------------------------------------------------------------------------------

=head1 NAME

GODOT::XXX - 

=head1 METHODS

=head2 Constructor

=over 4

=item new([$dbase])

=back

Returns a reference to XXX object. 


=head2 ACCESSOR METHODS

=over 4

=item mysubroutine([$value])

=back

=head1 AUTHORS / ACKNOWLEDGMENTS

Kristina Long


=cut
