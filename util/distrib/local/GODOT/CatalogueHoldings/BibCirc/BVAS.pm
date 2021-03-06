package GODOT::local::CatalogueHoldings::BibCirc::BVAS;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##
use GODOT::CatalogueHoldings::BibCirc::Z3950::III;
@ISA = qw(GODOT::CatalogueHoldings::BibCirc::Z3950::III);

use GODOT::String;
use GODOT::Object;
use GODOT::CatalogueHoldings::BibCirc;
use CGI qw(:escape);

use strict;

##
## !!!!!!!!!!!!! for temporary fix only !!!!!!!!!!!!!
##
sub call_number_text {
    return 'No Call Number';
}


##
## -as this point in processing, a title alone is not enough to assume SFU holdings (of print)
## -catalogue has separate records for print and electronic copies
##
sub _holdings_found_if_title {
    my($self) = @_;
    ## do nothing
}


sub circ_location_to_site {
    my($self, $location) = @_;
 
    my $site = $self->site;

    $location = lc($location);

    if    ($location =~ m#belzberg#)             { $site = 'BVASB'; }
    elsif ($location =~ m#surrey|portal|techbc#) { $site = 'BVASS'; }
  
    return $site;
}

	   
1;
