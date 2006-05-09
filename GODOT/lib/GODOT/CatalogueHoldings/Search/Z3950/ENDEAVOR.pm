package GODOT::CatalogueHoldings::Search::Z3950::ENDEAVOR;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use GODOT::CatalogueHoldings::Search::Z3950;
push @ISA, qw(GODOT::CatalogueHoldings::Search::Z3950);

use GODOT::Debug;
use GODOT::String;

use strict;

sub syntax {
    return 'OPAC';
}
