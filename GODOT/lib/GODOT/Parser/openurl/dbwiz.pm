package GODOT::Parser::openurl::dbwiz;

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
    debug("parse_citation() in GODOT::Parser::openurl::dbwiz") if $GODOT::Config::TRACE_CALLS;

    $self->SUPER::parse_citation($citation); 

        ## 
        ## <repno>10692851S</repno>
        ## <publisher>My Fave Publisher</publisher>
        ##

        if ($citation->pre('pid') =~ m#<repno>(.+)</repno>#) {
            $citation->parsed('REPNO', $1);
        }

        if ($citation->pre('pid') =~ m#<publisher>(.+)</publisher>#) {
            $citation->parsed('PUB', $1);
        }

}

1;

__END__

