##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##
package GODOT::local::CatalogueHoldings::Term::AEU;

use GODOT::CatalogueHoldings::Term::Z3950;

@ISA = qw(GODOT::CatalogueHoldings::Term::Z3950);

use GODOT::Debug;

use strict;

sub Term {
    my $self = shift;

    ##
    ## (23-mar-2005 kl) - the apostrophe for an apostrophe-s must be stripped out for title searching 
    ## with the current Z3950 attributes 
    ##

    if (@_) {

         (my $term = shift @_) =~ s#'s#s#g;;

         return $self->SUPER::Term($term);
    }
    else {
	return $self->SUPER::Term;
    }

   

}
