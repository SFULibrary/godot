package GODOT::Parser::ageline;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;
use GODOT::String;

@ISA = "GODOT::Parser";


use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::ageline") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation); 

	#-----------------------------------------------------------------#

	my $source = $citation->parsed('SOURCE');

	#Clinical-Psychology. Fall 2000; Vol. 7 (No. 3): p. 337-344 (8p.)
	#Gerontologist-. Aug 1998; Vol. 38 (No. 4): p. 481-489 (9p.)
	#Journal-of-Aging-and-Social-Policy. 1995; Vol. 7 (No. 1): p. 85-102 (18p.)
	#Journals-of-Gerontology. Nov 1991; Vol. 46 (No. 6): p. P378-P385 (8p.)
	#Public-Health-Reports. Sep-Oct 1984; Vol. 99 (No. 5): p. 446-449 (4p.)
	
        if ($citation->is_journal())  {
	    if ($source =~ /^([^.]+)\.\s/) {
		my $title = $1;
		$title =~ s/-/ /g;
		$citation->parsed('TITLE', $title);
	    }
	    if ($source =~ /([\w-]+)\s+\d{4};/) {
		$citation->parsed('MONTH', $1);
	    }
	    if ($source =~ /Vol\.\s+([\d-]+)/) {
		$citation->parsed('VOL', $1);
	    }
	    if ($source =~ /No\.\s+([\d-]+)/) {
		$citation->parsed('ISS', $1);
	    }
	    if ($source =~ /p\.\s+([\dPp-]+)/) {
		$citation->parsed('PGS', $1);
	    }
	    $citation->parsed('YEAR', $citation->pre('PY'));
        }
        elsif ($citation->is_book_article()) {
            ##
            ## In: Formosa-Saviour Ed). Age vault: an INIA collaborating network anthology. 
            ## International Institute on Ageing, United Nations--Malta, Malta, 1995: p. 121-127 (7p.). 
            ##
            if ($source =~ m#^In: (.+)\.\s*(.+)\.(.+)\s+(\d\d\d\d):\s+p\.\s+([\d\055]+)#) {

                $citation->parsed('AUT', $1);
                $citation->parsed('TITLE', $2);
                $citation->parsed('PUB', $3);
                $citation->parsed('YEAR', $4);
                $citation->parsed('PGS', $5);
            }
            ##
            ## Insider's guide to HMOs: how to navigate the managed-care system and get the health care you 
            ## deserve. Plume, New York, NY, 1997: p. 91-116 (26p.). 
            ##            
            elsif ($source =~ m#^(.+)\.(.+)\s+(\d\d\d\d):\s+p\.\s+([\d\055]+)#) {

                $citation->parsed('TITLE', $1);
                $citation->parsed('PUB', $2);
                $citation->parsed('YEAR', $3);
                $citation->parsed('PGS', $4);
            }
            $citation->parsed('ARTAUT', $citation->pre('AU'));

            $citation->parsed('NOTE', $citation->pre('AV'));
        }
        elsif ($citation->is_book()) {

            $citation->parsed('PUB', trim_beg_end($source));
            ##
            ## Friends and Relatives of Institutionalized Aged, New York, NY, 1987: 160p. 
            ##

            if ($citation->parsed('PUB') =~ m#(.+ \d\d\d\d):\s+(\d+)p\.#) {
                $citation->parsed('PUB', $1);
                $citation->parsed('PGS', $2);
            }


            if ($citation->pre('CA')) {
		my $aut = $citation->parsed('AUT'); 
                if ($citation->parsed('AUT')) { 
		    $aut .= '; '; 
	        }
                $aut .= $citation->pre('CA');
                $citation->parsed('AUT', $aut);
            }            

            $citation->parsed('NOTE', $citation->pre('AV'));

        }
        elsif ($citation->is_thesis())  {
          $citation->parsed('NOTE', trim_beg_end($source));
        }

	my $pub = $citation->parsed('PUB');
        $pub  =~ s#,\s*$##g;
        $citation->parsed('PUB', $pub);

	#----------------------------------------------------------------------#

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::ageline") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation);


        if ($citation->parsed('PUBTYPE') =~ m#report#)     { return $GODOT::Constants::BOOK_TYPE;         }
        elsif ($citation->parsed('PUBTYPE') =~ m#chapter#) { return $GODOT::Constants::BOOK_ARTICLE_TYPE; }

	return $reqtype;
}


1;

__END__

