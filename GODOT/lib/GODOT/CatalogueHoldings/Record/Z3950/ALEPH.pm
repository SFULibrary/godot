## GODOT::CatalogueHoldings::Record::Z3950::ALEPH
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##
package GODOT::CatalogueHoldings::Record::Z3950::ALEPH;

use GODOT::CatalogueHoldings::Record::Z3950;
push @ISA, qw(GODOT::CatalogueHoldings::Record::Z3950);

use GODOT::Debug;

use strict;

sub bibliographic {
    my($self) = @_;

    # use Data::Dumper;
    # debug "----------------------------------------------------------------";
    # debug Dumper($self), "\n";
    # debug "----------------------------------------------------------------";

    return $self->record->{'bibliographicRecord'};
}

1;

__END__


