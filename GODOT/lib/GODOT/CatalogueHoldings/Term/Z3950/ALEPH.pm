package GODOT::CatalogueHoldings::Term::Z3950::ALEPH;
##
## Copyright (c) 2010, Kristina Long, Simon Fraser University
##
use GODOT::Object;
use GODOT::CatalogueHoldings::Term::Z3950;
@ISA = qw(GODOT::CatalogueHoldings::Term::Z3950);

use GODOT::String;
use GODOT::Debug;

use strict;

##
## (16-oct-2010 kl)
##
sub title {
    my($self, $title, $strip_apostrophe_s, $is_journal) = @_;

    $self->SUPER::title($title, $strip_apostrophe_s, $is_journal);
    $title =~ s#;# #g;                                               ## -get rid of semi-colons

    $self->Term($title);
}


1;
