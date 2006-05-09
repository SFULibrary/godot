##23-aug-2001 yyua: tested with DB at UVic (http://webspirs.uvic.ca/cgi-bin/nu.bat)
package GODOT::Parser::cinahl;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::cinahl") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##

        if ($citation->is_journal()) {        

            $citation->parsed('TITLE', $source);   ## default
        }
        elsif (($citation->is_book()) || ($citation->is_book_article())) {     

            if ($citation->is_book()) {

                $citation->parsed('TITLE', $citation->pre('TI'));  

                $citation->parsed('AUT', $citation->pre('AU'));

            }
            elsif ($citation->is_book_article()) {
                ##
                ## Treating families of chronic pain patients IN: 
                ## Psychological approaches to pain management: a practitioner's handbook (Gatchel RJ et al)
                ##
                if ($citation->pre('TI') =~ m#(.+)\s+IN:\s+(.+)#) {

                    $citation->parsed('ARTTIT', $1);
                    $citation->parsed('TITLE', $2);

                    if ($citation->parsed('TITLE') =~ m#^(.+)\s*\((.+)\)\s*$#) {
                        $citation->parsed('TITLE', $1);
                        $citation->parsed('AUT', $2);  
                    }
                }

                $citation->parsed('ARTAUT', $citation->pre('AU')); 
            }
        }
        elsif ($citation->is_conference())  {  

            if ($citation->pre('TI') =~ m#(.+)\s+IN:\s+(.+)#) {
                $citation->parsed('ARTTIT', $1);
                $citation->parsed('TITLE', $2);
                $citation->parsed('AUT', '');
                $citation->parsed('ARTAUT', $citation->pre('AU'));  

                if ($citation->parsed('TITLE') =~ m#^(.+)\s*\((.+)\)\s*$#) {
                    $citation->parsed('TITLE', $1);
                    $citation->parsed('AUT', $2);  
                }
            }
            else {
                $citation->parsed('TITLE', $citation->pre('TI'));
                $citation->parsed('ARTTIT', '');
                $citation->parsed('AUT', $citation->pre('AU'));
                $citation->parsed('ARTAUT', '');  

            }          
        }
        elsif ($citation->is_tech()) {
            $citation->parsed('TITLE', $citation->pre('TI'));        
            $citation->parsed('ARTTIT', '');        
            $citation->parsed('AUT', $citation->pre('AU'));        
            $citation->parsed('ARTAUT', '');        
        }
        ##
        ## TEXAS WOMAN'S UNIVERSITY 1993 PH.D. (146 p) 
        ## Uniformed Services University of the Health Sciences (USUHS) 1997 MSN (pages unknown)
        ##
        elsif ($citation->is_thesis())  {  

            $citation->parsed('TITLE', $citation->pre('TI'));

            if    ($citation->parsed('PUBTYPE') =~ m#masters-thesis#) { 
               $citation->parsed('THESIS_TYPE', 'Masters');
            }
            elsif ($citation->parsed('PUBTYPE') =~ m#doctoral-dissertation#) { 
                $citation->parsed('THESIS_TYPE', 'Doctoral');
            }

            $citation->parsed('UMI_DISS_NO', $citation->pre('ON'));
            my $no = $citation->parsed('UMI_DISS_NO');
            $no =~ s/UMI Order #//i;
            $citation->parsed('UMI_DISS_NO', $no);
        
        }
        
        ##
        ## -source logic 
        ##
 
        if ($citation->is_journal()) {
            ## 
            ## Nursing-Times (NURS-TIMES) 1997 Oct 29-Nov 4; 93(44): 70-1 
            ## Wyoming-Nurse (WYO-NURSE) 1997 Sep-Nov; 9(4): 23 
            ##
            if ($source =~  
                m#([^\s]+)\s*\(([^\s]+)\)\s+(\d\d\d\d)\s+([\s\w\055]+)\s*;\s*([\w\055]+)\s*\(([\w\055]+)\)\s*:\s*(.*)#) {

                $citation->parsed('TITLE', $1);
                $citation->parsed('MONTH', $4);
                $citation->parsed('VOL', $5);
                $citation->parsed('ISS', $6);      
                $citation->parsed('PGS', $7);
            }
        } 
        elsif ($citation->is_thesis()) {

            $citation->parsed('PUB', $source);
  
            if ($source =~ m#^(.+) \d\d\d\d .+ (\(.+\))\s*$#) {
                $citation->parsed('PUB', $1);
                $citation->parsed('PGS', $2);  
            }
        }
        else {

            $citation->parsed('PUB', $source);

            ##
            ## Guilford Press (New York, NY) 1996 (519 p) 
            ## 1995 (347 p) (201 bib)        
            ## Med Libr Assoc (Chicago, IL) 1996(various paging) (84 bib) 
            ## 
            ## -PY may not be in every record so extract from source if availble
            ##       
            if ($source =~ m#^(.*)\s+(\d\d\d\d)\s*(\(.+\).*)$#) {      
                $citation->parsed('PUB', $1);
                $citation->parsed('YEAR', $2);    
                $citation->parsed('PGS', $3);    
            }
            elsif ($source =~ m#^(\d\d\d\d)\s*(\(.+\).*)$#) {
                $citation->parsed('YEAR', $1);    
                $citation->parsed('PGS', $2);    
            }
            ##
            ## F A Davis (Philadelphia, PA) 1998 ed 2 (233 p)
            ##
            elsif ($source =~ m#^(.*)\s+(\d\d\d\d)\s+ed\s+(\d+)\s+(\(.+\).*)$#) {      
                $citation->parsed('PUB', $1);
                $citation->parsed('YEAR', $2);   
                $citation->parsed('EDITION', $3);    
                $citation->parsed('PGS', $4);    
            }
            ##
            ## Am-Assoc-Coll-Nurs 1996: (67 p) 
            ##
            elsif ($source =~ m#^(.+)\s+\d\d\d\d\s*:\s*(.+)$#) {
                $citation->parsed('PUB', $1);
                $citation->parsed('PGS', $2);
            }
            ##
            ## NLN-PUBL 1993 #14-2541: 1-16 (21 ref)   
            ## (\043 is the hash sign)
            ##
            elsif ($source =~ m/^(.+)\s+\d\d\d\d\s+\043(.+)\s*:\s*(.+)$/) {
                $citation->parsed('PUB', $1);
                $citation->parsed('REPNO', $2);
                $citation->parsed('PGS', $3);
            }
            ##
            ## ANA-PUBL 1995 Jun #G-187: (72 p) 
            ## (\043 is the hash sign)
            ##
            elsif ($source =~ m/^(.+)\s+\d\d\d\d\s+(.+\s+)\043(.+)\s*:\s*(.+)$/) {
                $citation->parsed('PUB', $1);
                $citation->parsed('MONTH', $2); 
                $citation->parsed('REPNO', $3); 
                $citation->parsed('PGS', $4); 
            }
            ##
            ## State of Wisconsin. Laws, Statutes, and Regulations 1996 Sep (84 p) 
            ## 
            elsif ($source =~ m#^(.*)\s+(\d\d\d\d)\s+(.+)\s+(\(.+\).*)$#) {             
                $citation->parsed('PUB', $1);
                $citation->parsed('YEAR', $2);   
                $citation->parsed('MONTH', $3);    
                $citation->parsed('PGS', $4);    
            }
        }

        my $pgs = $citation->parsed('PGS');
        $pgs =~ s#\)\s*\(#, #g;           
        $pgs =~ s#[()]# #g;           
        $citation->parsed('PGS', $pgs);
  
        ##
        ## corporate author 
        ##
        if ($citation->pre('CA')) {

            if ($citation->parsed('AUT')) { 
		my $aut = $citation->parsed('AUT');
		$aut .= '; ' . $citation->pre('CA');  
		$citation->parsed('AUT', $aut);
	    }
            else {
		$citation->parsed('AUT', $citation->pre('CA'));  
	    }
        }

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::cinahl") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

        my @tmp_arr = split(/;\s*/, $citation->parsed('PUBTYPE'));           ## -seperate so can do exact matching on each type
                                                            ## -otherwise would have to worry about substrings
        ##
        ## -order important
        ##
        if (grep 
            {$_ eq 'journal-article' || $_ eq 'editorial' || $_ eq 'letter' || $_ eq 'review' } 
            @tmp_arr) {      

            $reqtype = $GODOT::Constants::JOURNAL_TYPE; 
        }
        elsif (grep {$_ eq 'book'} @tmp_arr) {
            $reqtype = $GODOT::Constants::BOOK_TYPE; 
        }
        elsif (grep {$_ eq 'book-chapter'} @tmp_arr) {
            $reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE; 
        }
        elsif ((grep {$_ eq 'masters-thesis'} @tmp_arr) || (grep {$_ eq 'doctoral-dissertation'} @tmp_arr)) {
            $reqtype = $GODOT::Constants::THESIS_TYPE; 
        }
        elsif (grep {$_ eq 'proceedings'} @tmp_arr) {
            $reqtype = $GODOT::Constants::CONFERENCE_TYPE; 
        }
        else {
            $reqtype = $GODOT::Constants::TECH_TYPE;      
        }

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

