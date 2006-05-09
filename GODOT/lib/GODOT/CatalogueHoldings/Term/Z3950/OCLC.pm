package GODOT::CatalogueHoldings::Term::Z3950::OCLC;
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

    $title =~ s#\'s#s#gi;                                ## maclean's ===> macleans
    
    ##
    ## -strip non-searchable characters (based on BRS standard language table)
    ##
    ## (\046 is a ampersand, \047 is an apostrophe, and \054 is a comma)
    ## (\055 is a hyphen, \056 is a period, \100 is an 'at' sign)
    ##
    $title =~ s#[\046\047\054]##g;                      ## remove  
    $title =~ s#[^a-zA-Z0-9\-055\056\100\s]# #g;        ## replace with space
    $title =~ s#\s+# #g;                                ## compress

    ##
    ## - remove period followed by whitepace or period at the end of the string
    ## -we want to keep periods in the middle of initials - ex. 'u.s'
    ##
    $title =~ s#\.\s+# #g;    
    $title =~ s#\.$##g;

    $self->Term($title);
}

1;
