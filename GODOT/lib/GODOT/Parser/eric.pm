package GODOT::Parser::eric;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;
use GODOT::String;
use CGI ':standard';

@ISA = "GODOT::Parser";

my $TRUE  = 1;
my $FALSE = 0;

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::eric") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##

        ##
        ## -fields used to determine if available on ERIC Microfiche 
        ##
        $citation->parsed('ERIC_NO', $citation->pre('AN'));   ## accession number 
        $citation->parsed('ERIC_AV', $citation->pre('LV'));   ## level of availability

        ##
        ## -fulltext available within citation database
        ##
        if ($citation->parsed('PUBTYPE') =~ m#073#) {
           $citation->fulltext_available(1);
        }

        ##
        ## (16-apr-2002-kl) - fulltext only available online if level of availability is '1',
        ##                    otherwise you just are linked to a citation with an abstract
        ##                  - email from Perce 15-apr-2002
        ##
        ## (11-jan-2001 kl) - added for new EDRS E*Subscribe Eric document service
        ##
        if (naws($citation->pre('DL')) && ($citation->parsed('ERIC_AV') eq '1')) {

           $citation->fulltext_available(1);
           $citation->parsed('URL', $citation->pre('DL'));

           my($tmp) = a({href=>$citation->parsed('URL')}, 'here');
           $citation->parsed('URL_MSG', "Click $tmp for the full text of the document.");

           $citation->eric_fulltext_available(1);

           ##
           ## (22-may-2002 kl) - emailed Perce checking that this is what we want 
           ##                  - do we need similar logic for LINK_COMP and LINK_FROM_CAT_COMP ????
           ##
           #### $citation->parsed('NO_HOLDINGS_SEARCH', $TRUE);
           ##

        }

	$citation->parsed('PGS', $citation->pre('PG'));  
        
        if ($citation->is_journal()) {
            ##
    	    ## Development-Review;v17 n1 p101-09 Mar 1997;
	    ## Child-Development;v67 n5 p2417-33 Oct 1996;
            ## Advances-in-Education-Research;v2 Spr 1997; 
            ## Writing-Notebook:-Visions-for-Learning;v10 n1 p10-11 Sep-Oct 1992; 
            ##           
	    my ($title, $restv);
            ($title, $restv) = split(/;/,$source,2);
            $citation->parsed('TITLE', $title);
             
	    my $year = $citation->parsed('YEAR');
            if ($restv =~ m#\s+(\S*)(\s+\d+){0,1}\s+$year#)  {
                $citation->parsed('MONTH', $1);
            }

            if ($restv =~ m#[\s;]+v(\S+)\s+#)  { $citation->parsed('VOL', $1); }
            if ($restv =~ m#\s+n(\S+)\s+#)     { $citation->parsed('ISS', $1); }	
            if ($source =~ m#\s+p(\S+)\s+#)    { $citation->parsed('PGS', $1); }
        }
        elsif ($citation->is_thesis()) {
            
            if ($citation->pre('NT') =~ m#\d+\s+p\.;([^\.]+)#) { 
                $citation->parsed('PUB', $1); 
            }
            else { 
                $citation->parsed('PUB', $citation->pre('NT')); 
            }

            if    ($citation->parsed('PUBTYPE') =~ m#040#) { $citation->parsed('THESIS_TYPE', 'Undetermined'); }
            elsif ($citation->parsed('PUBTYPE') =~ m#041#) { $citation->parsed('THESIS_TYPE', 'Doctoral');     }    
            elsif ($citation->parsed('PUBTYPE') =~ m#042#) { $citation->parsed('THESIS_TYPE', 'Masters');      }    
            elsif ($citation->parsed('PUBTYPE') =~ m#043#) { $citation->parsed('THESIS_TYPE', 'Practicum Paper'); }    
        }
        elsif ($citation->is_book()) {

           ## do nothing
        }     
        elsif ($citation->is_conference()) {

            if (! aws($citation->pre('TI')))  {
                $citation->parsed('TITLE', $citation->pre('TI'));
                $citation->parsed('ARTTIT', '');
            }
	    $citation->parsed('AUT', $citation->pre('AU'));
	    $citation->parsed('ARTAUT', '');
        }        
        elsif ($citation->is_tech()) {

            ##
            ## -added logic to deal with document type 'Information Analyses - ERIC IAP's (071)'
            ##
            if  (($citation->parsed('PUBTYPE') =~ m#071#) && 
                 ($citation->pre('TI') =~ m#(.+)\.\s*ERIC/CUE\s+Digest,\s*Number\s+(\d+)#))  {

                $citation->parsed('ARTTIT', $1);     ## set pattern matches first
                $citation->parsed('VOLISS', $2);

                $citation->parsed('ARTAUT', $citation->pre('AU'));
                $citation->parsed('TITLE', 'ERIC/CUE Digest');
                $citation->parsed('AUT', '');    
            }
            else {
                if (! aws($citation->pre('TI')))  {
                    $citation->parsed('TITLE', $citation->pre('TI'));
                    $citation->parsed('ARTTIT', '');
                }

	        $citation->parsed('ARTAUT', '');
	        $citation->parsed('AUT', $citation->pre('AU'));
            }
        }
     
        ##
        ## -publisher and note logic
        ##
        if (! $citation->is_thesis()) {
            $citation->parsed('PUB', $citation->pre('CS'));
            $citation->parsed('NOTE', $citation->pre('NT'));
        }  

        if (! aws($citation->pre('AV'))) {
            my $note = $citation->parsed('NOTE');
            $note .= ' ' . $citation->pre('AV');    
            $citation->parsed('NOTE', $note);
        }        

	my $pub = $citation->parsed('PUB');
        if (! aws($pub)) {
            $pub .= '. ' 
        }
        $pub .= $citation->pre('CP');  
	$citation->parsed('PUB', $pub);

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::eric") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

        if ($citation->parsed('PUBTYPE') =~ m#books#) {
 
            $reqtype = $GODOT::Constants::BOOK_TYPE; 
        }
        elsif ($citation->parsed('PUBTYPE') =~ m#dissertations#) {        

            $reqtype = $GODOT::Constants::THESIS_TYPE;
        }
        elsif (($citation->parsed('PUBTYPE') =~ m#journal[\s\-]+articles#)    ||
               ($citation->parsed('PUBTYPE') =~ m#serials#)             ||
               (! aws($citation->pre('JN')))) {    ## (19-may-1998 kl)  

            $reqtype = $GODOT::Constants::JOURNAL_TYPE;    
        }
        elsif (($citation->parsed('PUBTYPE') =~ m#proceedings#) ||
               ($citation->parsed('PUBTYPE') =~ m#meeting#))    {

            $reqtype = $GODOT::Constants::CONFERENCE_TYPE;
        }
        elsif (($citation->parsed('PUBTYPE') =~ m#information analyses - eric#)              ||
               ($citation->parsed('PUBTYPE') =~ m#legal /legislative /regulatory materials#) ||
               ($citation->parsed('PUBTYPE') =~ m#non-print media#)                          ||
               ($citation->parsed('PUBTYPE') =~ m#computer programs#)                        ||
               ($citation->parsed('PUBTYPE') =~ m#data files#)                               ||
               ($citation->parsed('PUBTYPE') =~ m#numeric#)                                  ||
               ($citation->parsed('PUBTYPE') =~ m#questionnaires#))  {

            $reqtype = $GODOT::Constants::TECH_TYPE;  
        }
        ##
        ## -logic for the rest of them ?? - if it has an ISBN then call it a book
        ##                                - otherwise call it tech type
        ##
        elsif ($citation->parsed('ISBN')) {
            $reqtype = $GODOT::Constants::BOOK_TYPE;       
        }
        # Last ditch attempt... "Journal" in name is probably a journal...
        # This fixes some stupid records with missing document types. 
	elsif ($citation->pre('SO') =~ /journal/i) {
	    $reqtype = $GODOT::Constants::JOURNAL_TYPE;
        } else {
            $reqtype = $GODOT::Constants::TECH_TYPE;      
        }

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

