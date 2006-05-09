##23-aug-2001 yyua: tested with DB at UManitoba (http://www.lib.umanitoba.ca/asp/netdoc/title.asp)
package GODOT::Parser::fsta;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::fsta") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##

	# trim annoying refs bit

	$source =~ s#,\s*\d+\s*refs.*$##;

	if ($citation->is_journal()) {
            ##
	    ## match "Title; Volno (Issno) pp." or "Title; Volno (Issno) pp-pp, pp."
	    ##		
            if ($source =~ m#^\s*([^;]+);\s*(\d+)\s*\(([^)]+)\)\s*([\d\w-, ]+).*$#)  {

                $citation->parsed('TITLE', $1);
	        $citation->parsed('VOL', $2);
                $citation->parsed('ISS', $3);
	        $citation->parsed('PGS', $4);
	    }
            ##
	    ## match "Title; No. voliss, pp...."
            ##
	    elsif ($source =~ m#^\s*([^;]+);\s*No.\s*(\d+)\s*,\s*([\d\w-, ]+).*$#)  {
	        $citation->parsed('TITLE', $1);
		$citation->parsed('VOLISS', $2);
		$citation->parsed('PGS', $3);
	    }
            ##
	    ## match "Statutory Instruments" records
            ##
	    elsif ($source =~ m#^\s*([^;]+);\s*(SI\s*[^/]+)/([^,]+)\s*,\s*(.*)\s*$#)  {
	        $citation->parsed('TITLE', $1);
	        $citation->parsed('VOL', $2);
	        $citation->parsed('ISS', $3);
		$citation->parsed('PGS', $4);
	    }

	    else { ; }
	}
	elsif ($citation->is_book()) {
	    $citation->parsed('PUB', $citation->pre('PB'));
	    if ($source =~ m#^\s*(.+\.)#) {
		$citation->parsed('PGS', $1);
	    }
        }
        elsif ($citation->is_conference())  {

	    if ($source =~ m#^\s*([^;]+);\s*(\d+)\s*\(([^)]+)\)\s*([\d\w-, ]+).*$#)  {
	        $citation->parsed('TITLE', $1);
	        $citation->parsed('VOL', $2);
		$citation->parsed('ISS', $3);
	        $citation->parsed('PGS', $4);
	    }
	    elsif ($source =~ m#^\s*([^;]+);\s*(\d+)\s*,([\d\w-, ]+).*$#) {
		$citation->parsed('TITLE', $1);
	        $citation->parsed('VOLISS', $2);
	        $citation->parsed('PGS', $3);
	    }
        }
	elsif ($citation->is_book_article())  {
            ##
	    ## match patents
            ##
	    if ($source =~ m#^\s*([^\s]+)\s*$#)  {
		$citation->parsed('PUB', $citation->pre('PB'));

	    }
	    elsif ($source =~ m#^\s*([^,]+),\s*p.\s*([\d-]+)\s*ISSN\s*([^.]+)\.\s*$#)  {

		$citation->parsed('TITLE', $1);
		$citation->parsed('PGS', $2);
		$citation->parsed('ISSN', $3);
	    }
	}
	elsif ($citation->is_thesis()) {
            ##
	    ## copy thesis title to correct field
            ##
	    $citation->parsed('ARTTIT', $citation->parsed('TITLE'));
            ##
	    ## match "title; No. nnn, pgs, ...."
            ##
	    if ($source =~ m#\s*([^;]+)\s*;\s*No\.\s*([^,]+)\s*,\s*([^,]+).*#) {
				$citation->parsed('TITLE', $1);
				$citation->parsed('VOLISS', "No. $2");
				$citation->parsed('PGS', $3);
	    }
            ##
	    ## match "Dissertation-Abstracts-International-A;58 (2) 532 Order no. DA9723475, 165pp.. "
            ##
	    elsif ($source =~ m#\s*([^;]+)\s*;\s*([\d-/]+)\s*\(([^)]+)\)\s*([\d-]+)\s*(Order [^,]+)\s*,.*#) {
		$citation->parsed('TITLE', $1);
		$citation->parsed('VOL', $2);
		$citation->parsed('ISS', $3);
		$citation->parsed('PGS', $4);
		$citation->parsed('NOTE', $5);
	    }
	    elsif ($source =~ m#\s*([^;]+)\s*;\s*([\d-/]+)\s*\(([^)]+)\)\s*([\d-]+).*#) {
		$citation->parsed('TITLE', $1);
		$citation->parsed('VOL', $2);
		$citation->parsed('ISS', $3);
		$citation->parsed('PGS', $4);
	    }
	    elsif ($source =~ m#\s*([^;]+)\s*;#) {
		$citation->parsed('TITLE', $1);
	    }
	    else { ; }
        }
	else { ; }

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::fsta") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

	$citation->parsed('PUBTYPE', lc($citation->parsed('PUBTYPE'))); ## way, way faster than /i ! ## JE

	# most FSTA records contain a DT field *or* an NU field.
	# this lets us skip the expensive pattern matches below.
	if ($citation->parsed('PUBTYPE') =~ /^\s*$/)  {

	    if (lc($citation->pre('NU')) =~ /isbn/)  {             ## -change logic to use new $isbn parameter ?
		$reqtype = $GODOT::Constants::BOOK_TYPE;
	    }
	    else {
		$reqtype = $GODOT::Constants::JOURNAL_TYPE;
	    }
	}
	elsif ($citation->parsed('PUBTYPE') =~ /bibliography/ || $citation->parsed('PUBTYPE') =~ /book/ || $citation->parsed('PUBTYPE') =~ /dictionary/)  {
	    $reqtype = $GODOT::Constants::BOOK_TYPE;
	}
	elsif ($citation->parsed('PUBTYPE') =~ /thesis/ || $citation->parsed('PUBTYPE') =~ /dissertation/)  {
	    $reqtype = $GODOT::Constants::THESIS_TYPE;
	}
	elsif ($citation->parsed('PUBTYPE') =~ /conference/ || $citation->parsed('PUBTYPE') =~ /cnference/)  {
	    $reqtype = $GODOT::Constants::CONFERENCE_TYPE;
	}
	elsif ($citation->parsed('PUBTYPE') =~ /patent/ || $citation->parsed('PUBTYPE') =~ /presentation/)  {
	    $reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE;
	}
	else {
	    $reqtype = $GODOT::Constants::JOURNAL_TYPE;
	}

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

