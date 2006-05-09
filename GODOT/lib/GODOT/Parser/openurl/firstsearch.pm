package GODOT::Parser::openurl::firstsearch;

use GODOT::Config;
use GODOT::String;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Parser::openurl;
use CGI qw/unescapeHTML/;

@ISA = "GODOT::Parser::openurl";

use strict;


sub pre_parse {
    my ($self, $citation) = @_;
    debug("pre_parse() in GODOT::Parser::openurl::firstsearch") if $GODOT::Config::TRACE_CALLS;

    if ($citation->pre('genre') eq $GODOT::Config::JOURNAL_GENRE) {

        ##
        ## -date makes no sense for genre=journal in the context of godot
        ##

        $citation->pre('date', '');
    }
}

sub parse_citation {

	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::openurl::firstsearch") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation); 


        if ($citation->pre('genre') eq $GODOT::Config::JOURNAL_GENRE) {

            ##
            ## -temporary fix -- see email to Jennifer Faure 14-may-2002
            ##

            if (&GODOT::String::aws($citation->parsed('TITLE'))) {

	        $citation->parsed('TITLE', $citation->pre('atitle'));
	        $citation->parsed('ARTTIT', '');
	    }
        }

        ## 
        ## <accession number>10692851SEP012000v9n9251129210249</accession number>
        ##

        if ($citation->pre('pid') =~ m#<accession number>(.+)</accession number>#) {

	    $citation->parsed('SYSID', $1);
        }

        ##
        ## -multiple ISBNs appear to be sent with a delimiting semicolon 
        ## -assume the same may be true of ISSNs  
        ## -currently godot logic can only handle one ISSN and/or one ISBN so only take the first one(s)...
        ##

        my @issn_arr = split(';', $citation->pre('ISSN'));
        $citation->parsed('ISSN', GODOT::String::clean_ISSN($issn_arr[0]));

        my @isbn_arr = split(';', $citation->pre('ISBN'));
        $citation->parsed('ISBN', GODOT::String::clean_ISBN($isbn_arr[0]));

        ##### warn "pid:  ", $citation->pre('pid'), "\n";
}

1;

__END__

