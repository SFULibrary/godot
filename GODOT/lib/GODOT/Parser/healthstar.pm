##23-aug-2001 yyua: tested with DB at UVic (http://webspirs.uvic.ca/cgi-bin/hp.bat)

package GODOT::Parser::healthstar;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;
use GODOT::String;

@ISA = "GODOT::Parser";


use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::healthstar") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##

        if (! aws($source))  {      
            my $title;
            ($title) = split(/\./,$source,2);	
            $citation->parsed('TITLE', $title);

	    my $year = $citation->parsed('YEAR');
            if ($source =~ m#$year\s+(\S+);#)  {
	        $citation->parsed('MONTH', $1);
            }

            if ($source =~ m#;(.*):#)  {
                $citation->parsed('VOLISS', $1);
            }

            if ($citation->parsed('VOLISS') =~ m#([\055\d]+)\s*\(([\s\w\055]+)\)#)  {

                $citation->parsed('VOL', $1);
                $citation->parsed('ISS', $2);
            }

            if ($source =~ m#: (\S+)$#)  {
                $citation->parsed('PGS', $1);
            }
        }

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::healthstar") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

	if ($citation->parsed('PUBTYPE') =~ m#serial#)  { 
            $reqtype = $GODOT::Constants::BOOK_TYPE; 
        }
	if ($reqtype eq $GODOT::Constants::UNKNOWN_TYPE){
	    $reqtype = $GODOT::Constants::JOURNAL_TYPE;
	}

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

