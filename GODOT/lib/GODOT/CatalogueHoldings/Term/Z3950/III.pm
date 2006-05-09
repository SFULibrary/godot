package GODOT::CatalogueHoldings::Term::Z3950::III;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##


use GODOT::Object;
use GODOT::CatalogueHoldings::Term::Z3950;
@ISA = qw(GODOT::CatalogueHoldings::Term::Z3950);

use GODOT::String;

use strict;

sub title {
    my($self, $title, $strip_apostrophe_s, $is_journal) = @_;

    $self->SUPER::title($title, $strip_apostrophe_s, $is_journal);
    $title =~ s#:# #g;                                       ## -get rid of colons
    $title = "\"$title\"";                                   ## -add quotes

    $self->Term($title);
}

sub strip_trailing_year_title {
    my($self, $title, $strip_apostrophe_s, $is_journal) = @_;

    $self->SUPER::strip_trailing_year_title($title, $strip_apostrophe_s, $is_journal);

    $title = $self->Term;
    $title = "\"$title\"";                                   ## -add quotes
    return $self->Term($title);
}



1;
