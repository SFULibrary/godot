package GODOT::Parser::openurl::cas;
##
## SciFinder Scholar 
##

use GODOT::Config;
use GODOT::String;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Parser::openurl;
use CGI qw/unescapeHTML/;

@ISA = "GODOT::Parser::openurl";

use strict;

sub parse_citation {

    my ($self, $citation) = @_;
    debug("parse_citation() in GODOT::Parser::openurl::cas") if $GODOT::Config::TRACE_CALLS;

    $self->SUPER::parse_citation($citation); 

    ## 
    ## pid=<authfull>Abel, Edward W.</authfull><source>Journal of ... CODEN:JORCAI ISSN:0022-328X.</source>
    ##

    if ($citation->pre('pid') =~ m#<authfull>(.+)</authfull>#) {
        my $author = $1;

        if (grep {$citation->pre('genre') eq $_} @GODOT::Config::INDIVIDUAL_ITEM_GENRE_ARR)  {
            $citation->parsed('ARTAUT', $author);
        }
        else {
            $citation->parsed('AUT', $author);
        }
    }
}

1;

__END__

