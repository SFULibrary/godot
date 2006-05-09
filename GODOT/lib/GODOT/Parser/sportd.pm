package GODOT::Parser::sportd;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;
use GODOT::String;

@ISA = "GODOT::Parser";


use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::sportd") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##

        # trim annoying refs bit
        $source =~ s#\s*[Rr]efs.*$##;

        # trim annoying "Total pages:"
        $source =~ s#\s*,\s*Total\s*Pages:.*$##i;

        if ($citation->is_journal()) {

            # match "Title; Volno (Issno), date, pages"

#	    $source = $citation->pre('JN');

            if ($source =~ m#^\s*([^;]+);\s*(\d+)\s*\(([^)]+)\)\s*,\s*([^,]+)\s*,\s*(.+)\s*$#)  {
                $citation->parsed('TITLE', $1);
                $citation->parsed('VOL', $2);  
                $citation->parsed('ISS', $3);  
                $citation->parsed('MONTH', $4);
                $citation->parsed('PGS', $5);  

                # remove year from month
                my $month = $citation->parsed('MONTH');
                $month =~ s#\s*\d{4}\s*##;
                $citation->parsed('MONTH', $month);
            }
             
            # match broken records
            # match "Title;Issno), date, pages"

            elsif ($source =~ m#^\s*([^;]+);([^)]+)\)\s*,\s*([^,]+)\s*,\s*(.+)\s*$#) {
                $citation->parsed('TITLE', $1);
                $citation->parsed('ISS', $2);  
                $citation->parsed('MONTH', $3);
                $citation->parsed('PGS', $4);  

                # remove year from month
                my $month = $citation->parsed('MONTH');
                $month =~ s#\s*\d{4}\s*##;
                $citation->parsed('MONTH', $month);
            }
            # match "Title; voliss, year, pages"
            elsif ($source =~ m#^\s*([^;]+);\s*([^,]+)\s*,[^,]+,\s*(.+)\s*$#) {
                $citation->parsed('TITLE', $1);
                $citation->parsed('VOLISS', $2);
                $citation->parsed('PGS', $3);   
            }

            # match "Title; date, pages"

            elsif ($source =~ m#^\s*([^;]+);\s*([^,]+)\s*,\s*(.+)\s*$#)  {
                $citation->parsed('TITLE', $1); 
                $citation->parsed('VOLISS', $2);
                $citation->parsed('PGS', $3);
            }

	        # Maclean's-(Toronto) 111(37), 14 Sept 1998, 47-47, Total Pages: 1; 
  	        # European-journal-of-applied-physiology-and-occupational-physiology -(Berlin) 80(6), Nov/Dec 1999, 575-581 Refs:40, Total Pages: 17; 
	        # - Todd Holbrook - Lots of failed parsing in SportD, try to fix it here if JE's stuff above fails.

	    elsif ($source =~ /^(.+)\s*-?\s*\(?[^)]*\)?\s+(\d+)\(?([^)]*)\)?\s*,\s*(\d*\s*[\w\/]*)\s+\d{2,4}\s*,\s*([\d;\-]+)/) {
		$citation->parsed('TITLE', $1);
    	    	$citation->parsed('VOL', $2);
    	    	$citation->parsed('ISS', $3);
    	    	$citation->parsed('MONTH', $4);
    	    	$citation->parsed('PGS', $5);
		my $title = $citation->parsed('TITLE');
		$title =~ s/([^\-])-([^\-])/$1 $2/g;    # Get rid of -s
		$citation->parsed('TITLE', $title);
    	    }	    	

            # Remove French title added on to Canadian-journal-of-sport-sciences/Revue-canadienne-des-sciences-du-sport 
            my $title = $citation->parsed('TITLE');
            $title =~ s#Canadian\sjournal\sof\ssport\ssciences/Revue\scanadienne\sdes\ssciences\sdu\ssport#Canadian journal of sport sciences#i;
            $citation->parsed('TITLE', $title);

        } elsif ($citation->is_book()) {
            $citation->parsed('PUB', $source);
        } elsif ($citation->is_book_article()) {
            $source = $citation->pre('PB');
        
            # In, Stein, M.and Hollwitz, J. (eds.), Psyche and sports, Wilmette, Ill., Chiron Publications, 1994, p. 89- 109 Refs:1
            if ($source =~ m#^In,?\s*(.+)\s*\(eds?\.\)[\.,]\s*(.+)[\.,]\s*[cC]?\d{4},\s*[pP]+\.?\s*(\d+\s*\-?\s*\d*)#) {
                $citation->parsed('AUT', $1);
                $citation->parsed('TITLE', $2);  # Not good, but it's not going to get any better
                $citation->parsed('PGS', $3);
                $citation->parsed('ARTAUT', $citation->pre('AU'));
                my $aut = $citation->parsed('AUT');
                $aut =~ s/(.+)\s*\(/$1/;
                $citation->parsed('AUT', $aut);
            }   
            #In, Risk management in sport : proceedings of the 4th annual ANZSLA Conference, Brisbane, 14-17 July 1994, Parkville,
            elsif ($source =~ m#^In,?\s*(.+)[\.,]\s*[cC]?\d{4},\s*[pP]+\.?\s*(\d+\s*\-?\s*\d*)#) {
                $citation->parsed('AUT', "");
                $citation->parsed('TITLE', $1);  # Not good, but it's not going to get any better
                $citation->parsed('PGS', $2);
                $citation->parsed('ARTAUT', $citation->pre('AU'));
            } else {
		# Sport Discus data sucks, so fall back to dumping the title.  Argh.            
            
            	$citation->parsed('TITLE', $source);
            }
        }


        if (naws($citation->pre('UR'))) { $citation->fulltext_available(1);}

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::sportd") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

        $citation->parsed('PUBTYPE', lc($citation->parsed('PUBTYPE'))); # so we don't need /i in matches. ## JE

	# all of these have completely unparseable source fields,
	# so we'll handle them all the same way.

	if ($citation->parsed('PUBTYPE') =~ /monograph/ || 
	    $citation->parsed('PUBTYPE') =~ /microform/ || 
	    $citation->parsed('PUBTYPE') =~ /thesis/ || 
	    $citation->parsed('PUBTYPE') =~ /video/  
	    # || $citation->parsed('PUBTYPE') =~ /analytic/
	    ) {

	    $reqtype = $GODOT::Constants::BOOK_TYPE;
	} elsif ($citation->parsed('PUBTYPE') =~ m#book-analytic#) {   
		$reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE;
	} elsif ($reqtype eq $GODOT::Constants::UNKNOWN_TYPE || !defined($reqtype) || $reqtype eq '') { 
	    $reqtype = $GODOT::Constants::JOURNAL_TYPE; ##Best guess 
	}

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

