package GODOT::local::CatalogueHoldings::Search::BVAS;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##
use GODOT::CatalogueHoldings::Search::Z3950::III;
@ISA = qw(GODOT::CatalogueHoldings::Search::Z3950::III);

use GODOT::String;
use GODOT::Object;
use GODOT::CatalogueHoldings::Search;
use CGI qw(:escape);

use strict;

sub unique_search_type {
    my($self, $dbase) = @_;

    return ($dbase eq 'sfu_iii') ? $UNIQUE_ONLY_SEARCH : $UNIQUE_INCLUDE_SEARCH;  
}

1;
