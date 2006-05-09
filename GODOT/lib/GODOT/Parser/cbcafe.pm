package GODOT::Parser::cbcafe;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::cbcafe") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	##---------------Customized code goes here-------------------##

	my $source = $citation->parsed('SOURCE');

        if (($citation->is_tech()) || ($citation->is_thesis()) || ($citation->is_book())) {
            $citation->parsed('TITLE', $citation->pre('TI'));
            $citation->parsed('ARTTIT', "");
    	    if ($source =~ /^\s*(.*),\s*\d{2,4}\s*\.\s*([\d\-\+pgPG ]+\.)/) {
    		$citation->parsed('PUB', $1);
    		$citation->parsed('PGS', $2);

	    # Dalhousie University, 1999.viii, 392 p. Illustrations; Bibliography; Tables.
    	    } elsif ($source =~ /^\s*(.+)\s*,\s*\d{2,4}\s*\.\s*([^\s,]+)\s*,\s*([\d\-\/]+\s*[pgPG]+)\./) {
    	        $citation->parsed('PUB', $1);
    	        $citation->parsed('VOL', $2);
    	        $citation->parsed('PGS', $3);
    	    } else {
    	        $citation->parsed('PUB', $source);
    	    }
    	    $citation->parsed('AUT', $citation->pre('AU'));
   	    $citation->parsed('ARTAUT', "");
        } else {
	    my ($title, $arttit);
            ($title) = split(/,/,$source,2);
            $citation->parsed('TITLE', $title);
	    $arttit = $citation->parsed('ARTTIT');
	    $arttit =~ s/^\s*\[(.+)\]\s*$/$1/;
	    $citation->parsed('ARTTIT', $arttit);

    	    my $yearIn2digits = substr($citation->parsed('YEAR'),2,2);

	    my $year = $citation->parsed('YEAR');
    	    if ($source =~ m#\s+(\S*)(\s+\d+){0,1},\s+$year#)  {
    	        $citation->parsed('MONTH', $1);
            } elsif ($source =~ m#\s+(\S+)(\s[\d\/]+)?\'$yearIn2digits#)  {
    	        $citation->parsed('MONTH', $1);
            	##
                ## CBCA Fulltext reference uses these acronyms for month names ###

		my $month = $citation->parsed('MONTH');

                $month =~ s#D#December#; 
                $month =~ s#N#November#;
                $month =~ s#O#October#;
                $month =~ s#S(?!pr|um)#September#;
                $month =~ s#Ag#August#;
           	$month =~ s#Jl#July#;
                $month =~ s#Je#June#;
                $month =~ s#My#May#;
           	$month =~ s#Ap#April#;
                $month =~ s#Mr#March#;
                $month =~ s#F(?!al)#February#;
                $month =~ s#Ja#January#;
                $month =~ s#Spr(?!ing)#Spring#;
                $month =~ s#Summ?(?!er)#Summer#;
                $month =~ s#Fal(?!l)#Fall#;
                $month =~ s#Wint?(?!er)#Winter#;

                $citation->parsed('MONTH', $month);
            }
              
            if ($source =~ m#,\s*[Vv]\.?([\-\/\d]+)\s*[nN][oO]\.?\s*([\d\w\-\/]+)\s*:#) {
            	$citation->parsed('VOL', $1);						        
            	$citation->parsed('ISS', $2); 
            } elsif ($source =~ m#,\s*[Vv]\.([\055\d]+(\([\/\s\w\055]+\))*)#)  {
            	$citation->parsed('VOLISS', $1);						        
	    } elsif ($source =~ /^.+,\s*[vV]\s*\.\s*(\d+)\s*[no]*\.?\s*([\w\/\d]*)\s*:\s*([\w\/\-]*)\s*\d{4}\s*\./) {
	    	$citation->parsed('VOL', $1);
	    	$citation->parsed('ISS', $2);
	    	$citation->parsed('MONTH', $3);
	    } elsif ($source =~/^.+\,\s*\(([^)]+)\)/) {
	    	$citation->parsed('VOLISS', $1);
	    } else {
		$source =~ /^.+\,(.+)$/;
	        $citation->parsed('PUB', $1);
	    }
    
    	    if ($source =~ m#pg\s*(\S+)\.#)  {
     	       	$citation->parsed('PGS', $1);
            }
		
#    	    } elsif ($source =~ m#([\dpgPG ]+\.)#)  {
#     	       	$citation->parsed('PGS', $1);
#    	    }
         	
            if ($citation->parsed('VOLISS') =~ m#([\055\d]+)\s*\(([\s\w\055\/]+)\)#)  {
                $citation->parsed('VOL', $1);
                $citation->parsed('ISS', $2);
            }	
        }
	$citation->parsed('SYSID', $citation->pre('AN'));
        if ($citation->pre('FA') =~ /fulltext:\s*\d+\s*words/) {
           $citation->fulltext_available(1);
 	}          

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::cbcafe") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); ##yyua

	##---------------Customized code goes here-------------------##

        if ($citation->parsed('PUBTYPE') =~ /(?:journal|period|review|article)/i) {
	    $reqtype = $GODOT::Constants::JOURNAL_TYPE;
	} elsif ($citation->parsed('PUBTYPE') =~ /(?:book-announcement)/i) {
            $reqtype = $GODOT::Constants::BOOK_TYPE;
	} elsif ($citation->parsed('PUBTYPE') =~ /(?:monograph|document)/i) {
            $reqtype = $GODOT::Constants::TECH_TYPE;
	} elsif ($citation->parsed('PUBTYPE') =~ /(?:thesis|\bthese\b)/i) {
	    $reqtype = $GODOT::Constants::THESIS_TYPE;
	} else {
		if ($citation->parsed('ISSN') =~ /\S/) {
		    $reqtype = $GODOT::Constants::JOURNAL_TYPE;
		} else {
	            $reqtype = $GODOT::Constants::BOOK_TYPE;
	        }
	}

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

