package GODOT::local::CatalogueHoldings::Search::BVAU;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##
use GODOT::CatalogueHoldings::Search::Z3950::ENDEAVOR;
@ISA = qw(GODOT::CatalogueHoldings::Search::Z3950::ENDEAVOR);

use GODOT::String;
use GODOT::Object;
use GODOT::CatalogueHoldings::Search;
use CGI qw(:escape);

use strict;

sub unique_search_type {
    my($self, $dbase) = @_;
    return ($dbase eq 'ubc') ? $UNIQUE_ONLY_SEARCH : $UNIQUE_INCLUDE_SEARCH;  
}


1;
