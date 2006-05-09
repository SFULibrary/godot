## GODOT::CatalogueHoldings::Record::Z3950::III
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##
package GODOT::CatalogueHoldings::Record::Z3950::III;

use GODOT::CatalogueHoldings::Record::Z3950;
push @ISA, qw(GODOT::CatalogueHoldings::Record::Z3950);

use GODOT::Debug;

use strict;

sub bibliographic {
    my($self) = @_;

    return $self->record->{'bibliographicRecord'};
}


1;

__END__


