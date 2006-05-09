##23-aug-2001 yyua: tested with DB at UVic(http://webspirs.uvic.ca/cgi-bin/sw.bat)

package GODOT::Parser::socwork;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;
use GODOT::String;

@ISA = "GODOT::Parser";


use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::socwork") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##
    
    	if ($citation->is_journal()) {	
	    if (! aws($source))  {      
		my $title;
		($title) = split(/\./,$source,2);
		$title =~ s/\(entire-issue\)//;	
		$title =~ s/([^\-])-([^\-])/$1 $2/g;    # Get rid of -s
		$citation->parsed('TITLE', $title);

		my $year = $citation->parsed('YEAR');
		if ($source =~ m#,\s+(.*)\s+$year#)  {
		    $citation->parsed('MONTH', $1);
		}

		if ($source =~ m#([\055\d]+(\([\s\w\055]\)+)*):#)  {            
		    $citation->parsed('VOLISS', $1);
		}

		if ($citation->parsed('VOLISS') =~ m#([\055\d]+)\s*\(([\s\w\055\/]+)\)#)  {
		    $citation->parsed('VOL', $1);
		    $citation->parsed('ISS', $2);
		}
    
		if ($citation->parsed('VOLISS') eq "") {
		    if ($source =~ m#(?:.+)\.\s*([\d]+)\s*\(([\d\/]+)\)#) {
			$citation->parsed('VOL', $1);
			$citation->parsed('ISS', $2);
		    }
		}	

		if ($source =~ m#: (\S+),#)  {
		    $citation->parsed('PGS', $1);
		}
		
		# Hard code some ISSNs for badly matching journal titles
		if ($citation->parsed('TITLE') eq 'Social Work Education') {
		    $citation->parsed('ISSN', '0261-5479');
		}
		
		
	    } else {
		if ($citation->pre('HC') =~ /^\s*(\d+)\((\d+)\)\s*,\s*(\d+),\s*(?:[\w\.]*)\s*([\d\-]+)/) {
		    $citation->parsed('TITLE', "Social Work Research & Abstracts Journal");
		    $citation->parsed('ISSN', "0148-0847");
		    $citation->parsed('ISS', $1);
		    $citation->parsed('VOL', $2);
		    $citation->parsed('YEAR', $3);
		    $citation->parsed('PGS', $4);
		    $citation->parsed('THESIS_TYPE', $citation->pre('DA'));
		}
	    }
    	} elsif ($citation->is_thesis()) {
	    $citation->parsed('PUB', $citation->pre('DA'));
    	    if ($citation->pre('DA') =~ /(\w{3})\.?\s*(\d{4})\./) {
		$citation->parsed('MONTH', $1);
	    	$citation->parsed('YEAR', $2);
    	    }
	}

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::socwork") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

        if (!defined($citation->parsed('PUBTYPE')) || $citation->parsed('PUBTYPE') eq "") {
            if (defined($citation->pre('SO')) && $citation->pre('SO') ne '' ) {
                $reqtype = $GODOT::Constants::JOURNAL_TYPE;
            } else {
                $reqtype = $GODOT::Constants::THESIS_TYPE;
            }
        }

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

