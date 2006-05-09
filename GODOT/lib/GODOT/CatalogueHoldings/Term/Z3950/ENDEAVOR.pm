package GODOT::CatalogueHoldings::Term::Z3950::ENDEAVOR;

##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use GODOT::CatalogueHoldings::Term::Z3950;
@ISA = qw(GODOT::CatalogueHoldings::Term::Z3950);

use strict;

use GODOT::String;


sub title {
    my($self, $title, $strip_apostrophe_s, $is_journal) = @_;

    ##
    ## -only use first part of title -- presumably 245-a   
    ##
    ## (05-apr-2000 kl) - added as temporary fix for UVic and U of Regina (problem is that 245-b does not appear 
    ##                    to be indexed for use attribute '4')
    ##

    my $junk;
    ($title, $junk) = split(':', $self->SUPER::title($title, $strip_apostrophe_s, $is_journal), 2);    

    $self->Term($title);
}

1;
