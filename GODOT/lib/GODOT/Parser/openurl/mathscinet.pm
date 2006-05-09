package GODOT::Parser::openurl::mathscinet;

use GODOT::Config;
use GODOT::String;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Parser::openurl;
use CGI qw/unescapeHTML/;

@ISA = "GODOT::Parser::openurl";

my $TRUE  = 1;
my $FALSE = 0;

use strict;

sub parse_citation {

	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::openurl::mathscinet") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation); 

        ##
        ## -there may be multiple ISBNs separated by a semicolon        
        ## -assume this may be true for ISSNs as well
        ## -save the first ISSN/ISBN that is in the correct format
        ## 

        my @isbn_arr = split(';', $citation->parsed('ISBN'));

        foreach my $isbn (@isbn_arr) {            

            warn "<<< isbn:  $isbn >>>";

            if ($isbn = GODOT::String::clean_ISBN($isbn)) {
                $citation->parsed('ISBN', $isbn);
                last;
            }
        }

        my @issn_arr = split(';', $citation->parsed('ISSN'));

        foreach my $issn (@issn_arr) {

            if ($issn = GODOT::String::clean_ISSN($issn, $TRUE)) {
                $citation->parsed('ISSN', $issn);
                last;
            }
        }

        ##
        ## -for genre=conference, title is showing up in 'atitle'
        ## -should be showing up in 'title' according to OpenURL draft standard
        ##  and the documentation on SFX site
        ## -for now (01-oct-2002 kl) email Drew and until this is fixed, handle 
        ##  as an exception case 
        ##

        if ($citation->pre('genre') eq $GODOT::Config::CONFERENCE_GENRE) {

            if (! $citation->parsed('TITLE')) {
                $citation->parsed('TITLE', $citation->pre('atitle'));                
                $citation->parsed('ARTTIT', '');
            }
        }


        ##
        ## -for genre=bookitem, conference place and year are showing up in brackets following the 
        ##  contents of 'title' field 
        ## -for now put 'conference place' in 'PUB' field although maybe this is not the best place
        ## -'title' field also has a trailing comma
        ##

        if ($citation->pre('genre') eq $GODOT::Config::BOOKITEM_GENRE) {

            ##
            ## -trim off trailing comma
            ##
            my $title = $citation->parsed('TITLE');
            $title =~ s#,\s*$##g;

            ##
            ## (eg. Cryptography and coding (Cirencester, 1999))
            ##
            if ($title =~ m#^\s*(.+)\s+\((.+),\s+(\d\d\d\d)\)\s*$#) {

                $title = $1;
                $citation->parsed('PUB', $2);                
                ##
                ## -ignore date ($3) for now as not clear what date this is
                ##
            }

            $citation->parsed('TITLE', $title);
        }


}

1;

__END__

