package GODOT::Parser::psy;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::psy") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##
  
        if ($citation->is_journal()) {
            ## Life-Sciences. 1976 Sep; Vol 19(6): 777-786.
            ## Journal-of-Neurology,-Neurosurgery-and-Psychiatry. 1975 Jan; Vol 38(1): 11-17.
	    ## Psychological-Research-Bulletin,-Lund-U..1976; Vol 16(2): 19 pp.. 
	    ## Psychological-Documents.1984 Jul; Vol 14(1) MS. 2635: 16. 
	    if ($source =~ m#(.+)\.\s*(?:\d+)\s*[\w\-]*\s*\;\s*(?:Vol|No|Ser|Mono|\s)\.*\s*([\d\-]+)\(([\w\s\d,\.\-]+)\)\s*\[?([\w\.\d\s]*)\]?\s*:\s*([\d\-\.ipS]+)#) {
                $citation->parsed('ISS', $3);
		my $iss = $citation->parsed('ISS');
		$iss .= "($4)" if $4 ne "";
		$citation->parsed('ISS', $iss);
                $citation->parsed('VOL', $2);
                (my $pgs = $5) =~ tr/a-zA-Z.//;
                $citation->parsed('PGS', $pgs);
                my $title = $1;
                $title =~ s/-/ /g;
                $citation->parsed('TITLE', $title);
            }

	    ## Catalog-of-Selected-Documents-in-Psychology.1976 Nov; Vol 6 1: 28. 
	    ## Law-and-Psychology-Review.1979 Fal; Vol 5: 113-139. 
            elsif ($source =~ m#(.+)\.\s*(?:\d+)\s*[\w\-]*\s*\;\s*(?:Tech\sRpt|Vol|No|Ser|Mono|\s)\.*\s*([\d\-]+)\s*([\w\d\s\.\-,]*):\s*x?,?\s*([\d\-\.ipS]+)#) {
                $citation->parsed('VOL', $2);
		$citation->parsed('ISS', $3) if $3 ne "";
                (my $pgs = $4) =~ tr/a-zA-Z.//;
                $citation->parsed('PGS', $pgs);
                my $title = $1;
                $title =~ s/-/ /g;
                $citation->parsed('TITLE', $title);
		if ( ($citation->parsed('ISS') eq "") && ($citation->parsed('VOL') =~ /(\d+)\-(\d+)/) ) {
		    $citation->parsed('VOL', $1);
		    $citation->parsed('ISS', $2);
		}
            }

	    ## NAVTRAEQUIPCEN.1976 Dec; No. 74-C-0048-1: .
	    elsif ($source =~ m#(.+)\.\s*(\d+)\s*[\w\-]*\s*;\s*(?:Vol|No|Ser|Mono|\s)?\.?\s*([\d\w\-]+)\s*:\s*([\d\-ipS\.]*)#) {
		$citation->parsed('PGS', $4) if $4 ne "";
		$citation->parsed('VOL', $3);
                my $title = $1;   
                $title =~ s/-/ /g;
                $citation->parsed('TITLE', $title);
	    }
	
	    ## National-Institute-on-Drug-Abuse:-Treatment-Research-Notes.1981 Sep; 10-11. 
	    elsif ($source =~ m#(.+)\s*\.\s*(?:\d+)\s*([^;]+)\s*;\s*x?,?\s*([\d\-\.ipS]+)#) {
		$citation->parsed('VOL', $2);
		$citation->parsed('PGS', $3);
                my $title = $1;   
                $title =~ s/-/ /g;
                $citation->parsed('TITLE', $title);
	    }


        } elsif ($citation->is_book_article()) {
		$citation->parsed('ARTTIT', $citation->pre('TI'));
		$citation->parsed('ARTAUT', $citation->pre('AU'));

		#Atkinson, Leslie (Ed); Zucker, Kenneth J. (Ed). (1997). Attachment and psychopathology. (pp. 196-222). New York, NY, US: The Guilfor d Press. viii, 328 pp.
		#Kunzendorf, Robert G.; Wallace, Benjamin. (2000). Individual differences in conscious experience. Advances in consciousness research, Vol. 20. (pp. 17-44). Amsterdam, Netherlands: John Benjamins Publishing Company. xii, 411 pp.

		if ($citation->pre('BK') =~ /^(.+)\.\s+\(\d+\)\.\s+([^.]+)\..*\(pp\.\s+([0-9-]+)\)/){
		    $citation->parsed('TITLE', $2);
		    $citation->parsed('PGS', $3);
		    my $authors = $1; 
		    $authors =~ s/\(Ed\)//g;
		    $citation->parsed('AUT', $authors);
	       }
        } elsif ($citation->is_book() || $citation->is_tech()) {
            $citation->parsed('TITLE', $citation->pre('TI'));
            $citation->parsed('AUT', $citation->pre('AU'));
            $citation->parsed('PUB', $citation->pre('PB'));
	
	}

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::psy") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

    	if ($citation->parsed('PUBTYPE') =~ m#chapter# || $citation->pre('DT') =~ m#chapter#i) {
            $reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE;
	} elsif ($citation->parsed('PUBTYPE') =~ m#conference-proceedings# || $citation->parsed('PUBTYPE') =~ m#empirical-study#) {
	    if ($citation->pre('DT') =~ m#book#i) {
		$reqtype = $GODOT::Constants::BOOK_TYPE;
    	    } elsif ($citation->pre('DT') =~ m#chapter#i) {
		$reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE;
	    } else {
		$reqtype = $GODOT::Constants::JOURNAL_TYPE;
    	    }
    	} elsif ($citation->parsed('PUBTYPE') =~ m#report#) {
	    if ($citation->pre('SO') eq "") {
		$reqtype = $GODOT::Constants::TECH_TYPE;
            } else {
    	        $reqtype = $GODOT::Constants::JOURNAL_TYPE;
	        }
    	} elsif ($citation->parsed('PUBTYPE') =~ m#secondary#) {
	    $reqtype = $GODOT::Constants::JOURNAL_TYPE;  # CHECK THIS!!!!! Todd
        } elsif ($citation->parsed('PUBTYPE') =~ m#dissertation#) {
	    $reqtype = $GODOT::Constants::JOURNAL_TYPE;
    	} elsif ($citation->pre('DT') eq 'Journal-Article') {
	    $reqtype = $GODOT::Constants::JOURNAL_TYPE;
	} elsif ($citation->pre('DT') =~ /Book/) {
	    $reqtype = $GODOT::Constants::BOOK_TYPE;
	}

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

