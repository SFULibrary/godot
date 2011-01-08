package GODOT::CatalogueHoldings::Term::Z3950::SIRSI;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use GODOT::CatalogueHoldings::Term::Z3950;
@ISA = qw(GODOT::CatalogueHoldings::Term::Z3950);

use GODOT::String;
use GODOT::Debug;

use strict;

sub title {
    my($self, $title, $strip_apostrophe_s, $is_journal) = @_;

    ## 
    ## (28-nov-2003 kl) - brackets in a search term result in errors for Net::Z3950 searching a Sirsi catalogue
    ##
    $title =~ s#\(# #g;                                     
    $title =~ s#\)# #g;

    $title = $self->SUPER::title($title, $strip_apostrophe_s, $is_journal);

    return $self->Term($title);
}


1;
