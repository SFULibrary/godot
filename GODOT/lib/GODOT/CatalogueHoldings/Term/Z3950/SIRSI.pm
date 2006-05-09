package GODOT::CatalogueHoldings::Term::Z3950::SIRSI;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use GODOT::CatalogueHoldings::Term::Z3950;
@ISA = qw(GODOT::CatalogueHoldings::Term::Z3950);

use GODOT::String;

use strict;

sub title {
    my($self, $title, $strip_apostrophe_s, $is_journal) = @_;

    $self->SUPER::title($title, $strip_apostrophe_s, $is_journal);

    ## 
    ## (28-nov-2003 kl) - brackets in a search term result in errors for Net::Z3950 searching a Sirsi catalogue
    ##

    $title =~ s#\(# #g;                                       ## -get rid of brackets
    $title =~ s#\)# #g;

    $self->Term($title);
}


1;
