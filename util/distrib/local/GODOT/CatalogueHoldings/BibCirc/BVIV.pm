package GODOT::local::CatalogueHoldings::BibCirc::BVIV;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##
use GODOT::CatalogueHoldings::BibCirc::Z3950::ENDEAVOR;
@ISA = qw(GODOT::CatalogueHoldings::BibCirc::Z3950::ENDEAVOR);

use GODOT::String;
use GODOT::Object;
use GODOT::CatalogueHoldings::BibCirc;
use CGI qw(:escape);

use strict;


sub _holdings_found_if_holdings {
    ## do nothing
}

sub _skip_hacd_enum_and_chron  { return $TRUE; }

sub _call_number_for_statement { 
    my($self, $call) = @_;

    return (naws($call) ? "Call Number:  $call, " : '');
}

sub adjust_html_incl {
    my($self, $reqtype, $html_incl_hash_ref) = @_;

    ##
    ## (24-mar-2005 kl) UVic doesn't want the holdings record displayed for books, as it only gives the 
    ## location and the circ record does that anyways.
    ##
    unless ($reqtype eq 'JOURNAL') {
        delete ${$html_incl_hash_ref}{'bib_circ_holdings'};
    }
        
    delete ${$html_incl_hash_ref}{'bib_circ_issn'};
    delete ${$html_incl_hash_ref}{'bbi_circ_isbn'};        
}


1;
