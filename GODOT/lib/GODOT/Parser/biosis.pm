package GODOT::Parser::biosis;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::biosis") if $GODOT::Config::TRACE_CALLS;

	warn('PY: ' . $citation->pre('PY'));
	warn('SO: ' . $citation->pre('SO'));

	$self->SUPER::parse_citation($citation);

	##---------------Customized code goes here-------------------##

	my $source = $citation->parsed('SOURCE');

	if  ($citation->dbase_type() eq 'slri') {
	    if ($citation->parsed('ISBN') && $citation->parsed('ISSN')) {
		if ($citation->pre('DT') =~ /review/i) {
		     $citation->parsed('ISBN', '');
		}
		elsif ($citation->pre('DT') =~ /chapter/i || $citation->pre('DT') eq 'Book') {
		     $citation->parsed('ISSN', '');
		}
		else {
		    $citation->parsed('ISBN', '');
		}	
	    }
	    if ($citation->is_journal()) {
		$citation->parsed('ARTTIT', $citation->pre('TI'));
		$citation->parsed('VOL', $citation->pre('VOL'));
		$citation->parsed('ISS', $citation->pre('ISS'));
		$citation->parsed('PGS', $citation->pre('PG'));

		if ($citation->pre('PY') !~ /^\d{4}\.?$/) {
			$citation->parsed('MONTH', $citation->pre('PY'));

			if ($citation->parsed('MONTH') =~ /^(\d{1,2})\s+(\w+)$/) {
				$citation->parsed('DAY', $1);
				$citation->parsed('MONTH', $2);
			} elsif ($citation->parsed('MONTH') =~ /^(\w+)\s+(\d{1,2})$/) {
				$citation->parsed('DAY', $2);
				$citation->parsed('MONTH', $1);
			}

		}

		$citation->parsed('ARTAUT', $citation->pre('AU'));  

		if ($source =~ /^(.+)\s{3,}(\d{4})\s{3,}(.+)$/) {
		    $citation->parsed('TITLE', $1);
		    $citation->parsed('YEAR', $2);
		    $citation->parsed('URL', $3);
		} elsif ($source =~ /^(.+)\s{3,}(\d{4})\.?\s*$/) {
		    $citation->parsed('TITLE', $1);
		    $citation->parsed('YEAR', $2);
		}


	    }
	    elsif ($citation->is_book_article()) {
		$citation->parsed('TITLE', $citation->pre('BK'));
		$citation->parsed('ARTAUT', $citation->pre('AU'));
		$citation->parsed('AUT', $citation->pre('ED'));
	    }
	} elsif ($citation->dbase_type() eq 'erl') {
	    if ($citation->is_journal()) {

		#Brain-Pathology. April, 2000; 10 (2): 260-272.
		#Mammalian-Species. [print] 5 June, 2001; (668): 1-3.
		#Research-and-Practice-in-Forensic-Medicine. 1999; (42): 129-133.
		#Water-Research. Sept., 1998; 32 (9) 2728-2734.
		#Journal-of-Chromatography-A. 1997; 758 (1) 75-83.

		if ($source =~ /^(.*?)\.\s+/) {
		    my $title = $1;
		    $title =~ s/-/ /g;
		    $citation->parsed('TITLE', $title);
		}
		if ($source =~ /;\s+(\d+)*\s*\((.*)\)/) {
		    $citation->parsed('VOL', $1);
		    $citation->parsed('ISS', $2);
		}
		if ($source =~ /([\d+-]+)\.$/) {
		    $citation->parsed('PGS', $1);
		}
		if ($source =~ /\s+([^,\s]+)\,\s+\d{4};/) {
		    $citation->parsed('MONTH', $1);
		}

		##
		## ex. JOURNAL OF NEUROSCIENCE RESEARCH 36(2): 209-218
		## 
		if ($source =~ m#^(.+)\s+([\055\d]+)\(([\055\d]+)\)\s*:\s*(.+)$#) {

		    $citation->parsed('TITLE', $1);
		    $citation->parsed('VOL', $2);
		    $citation->parsed('ISS', $3);
		    $citation->parsed('PGS', $4);
		}
		##
		## ex. Journal of Hydrology (Amsterdam) 155(1-2): 73-91. 
		##         
		if ($citation->parsed('TITLE') =~ m#(.+)\s+\((.+)\)#) {
		    $citation->parsed('TITLE', $1);
		    $citation->parsed('PUB', $2);
		}
	    }
	}

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::biosis") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

	my $type = $citation->dbase_type();
	debug ("dbase_type = $type");

	if ($citation->dbase_type() eq 'slri') {
	    if ($citation->parsed('ISSN') && !$citation->parsed('ISBN')) {
	       $reqtype = $GODOT::Constants::JOURNAL_TYPE;
	    } elsif ($citation->pre('DT') =~ m#chapter#i) {
		$reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE;
	    } elsif ($citation->pre('BK')) {
		if ( $citation->pre('PG') =~ /[xvi]+\s*\d+/ ) {
		    $reqtype = $GODOT::Constants::BOOK_TYPE;
		} else {
		    $reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE;
		}
	    }
	}
	elsif ($citation->dbase_type() eq 'erl') {
	    ## Don't have enough info. Assume journal type temporarily. ##
	    $reqtype = $GODOT::Constants::JOURNAL_TYPE; 
	}
	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

