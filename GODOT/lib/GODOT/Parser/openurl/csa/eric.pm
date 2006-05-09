package GODOT::Parser::openurl::csa::eric;

use GODOT::Config;
use GODOT::String;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Parser::openurl::csa;
use CGI qw/unescapeHTML/;

@ISA = "GODOT::Parser::openurl::csa";

my $TRUE  = 1;
my $FALSE = 0;

use strict;



sub parse_citation {
    my ($self, $citation) = @_;
    debug("parse_citation() in GODOT::Parser::openurl::csa::eric") if $GODOT::Config::TRACE_CALLS;

    $self->SUPER::parse_citation($citation);


    ##
    ## Fix for bug (reported to CSA Feb 2003):
    ##
    ## <incoming> title = 17p
    ## <incoming> genre = book
    ## <incoming> atitle = Snatching Defeat from the Jaws of Victory: When Good Projects Go Bad. Girls and Computer Science.
    ##

    if ($citation->parsed('TITLE') =~ m#^\d+p$#) {

        if ($citation->parsed('PGS') eq '') { $citation->parsed('PGS', $citation->parsed('TITLE')); }

        $citation->parsed('TITLE', $citation->parsed('ARTTIT'));
        $citation->parsed('ARTTIT', '');
        
    }

    $citation->parsed('ERIC_NO', $citation->parsed('SYSID'));
    $citation->parsed('SYSID', '');

    ##
    ## (20-may-2003 kl) - ERIC Availability is not currently passed by the Ebscohost interface.
    ##
    ##                  - Only 8.5% of the documents are not available from ERIC, so we make the
    ##                    assumption that all are available (and force the availability level to '1')
    ##                    as this will cause the least errors
    ##
    ## ERIC Availability:
    ##
    ## 1: available in paper copy and microfiche
    ## 2: available in microfiche only
    ## 3: not available from ERIC
    ##

    my $availability_level = 1;

    if ($citation->parsed('ERIC_NO') =~ m#^ed|^ED#) {
         $citation->parsed('ERIC_AV', $availability_level);
    }

    return $citation;
}


1;

__END__

