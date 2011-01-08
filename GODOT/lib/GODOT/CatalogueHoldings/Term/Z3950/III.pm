package GODOT::CatalogueHoldings::Term::Z3950::III;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##


use GODOT::Object;
use GODOT::CatalogueHoldings::Term::Z3950;
@ISA = qw(GODOT::CatalogueHoldings::Term::Z3950);

use GODOT::String;
use GODOT::Debug;

use strict;

sub title {
    my($self, $title, $strip_apostrophe_s, $is_journal) = @_;

    $self->SUPER::title($title, $strip_apostrophe_s, $is_journal);
    $title =~ s#:# #g;                                       ## -get rid of colons
    $title = "\"$title\"";                                   ## -add quotes

    $self->Term($title);
}

##
## (11-oct-2010 kl) vendor specific title method now called in GODOT::CatalogueHolding::Term::strip_trailing_year_title 
##                  so no need to have vendor specific strip_trailing_year_method below
##
#### sub strip_trailing_year_title {
####    my($self, $title, $strip_apostrophe_s, $is_journal) = @_;
####
####    $self->SUPER::strip_trailing_year_title($title, $strip_apostrophe_s, $is_journal);
####
####    $title = $self->Term;
####    $title = "\"$title\"";                                   ## -add quotes
####
####    report_location;
####    debug '>>>> Term:  ', $title;
####    return $self->Term($title);
#### }
####

1;
