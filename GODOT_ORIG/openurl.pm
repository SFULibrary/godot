package openurl;

##
## !!!!! remember this gets run mod_perl and not CGI !!!!
##

use CGI qw(-no_xhtml :standard); 

use GODOT::String;
use Text::Striphigh 'striphigh';

use strict;

require gconst;

use vars qw($TRUE $FALSE);
$TRUE  = 1;
$FALSE = 0;

## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
## !!!!! -these variables are only GLOBAL to this package !!!!!
## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


my(@CITN_PRE_OPENURL_ARR) = (

    my($SID_OPENURL_FIELD)     = 'sid',        ## ORIGIN-DESCRIPTION
    my($ID_OPENURL_FIELD)      = 'id',         ## GLOBAL-IDENTIFIER-ZONE
    my($PID_OPENURL_FIELD)     = 'pid',        ## LOCAL-IDENTIFIER-ZONE
    my($GENRE_OPENURL_FIELD)   = 'genre',      ## bundles: [ journal | book | conference ]
                                               ## individual items:  [ article | preprint | proceeding | bookitem ]
    my($AULAST_OPENURL_FIELD)  = 'aulast',     ## first author's last name
    my($AUFIRST_OPENURL_FIELD) = 'aufirst',    ## first author's first name
    my($AUINIT_OPENURL_FIELD)  = 'auinit',     ## first author's first and middle initials
    my($AUINIT1_OPENURL_FIELD) = 'auinit1',    ## first author's first initial

    my($AUINITM_OPENURL_FIELD) = 'auinitm',    ## first author's middle initials
    my($ISSN_OPENURL_FIELD)    = 'issn',       ## ISSN number
    my($EISSN_OPENURL_FIELD)   = 'eissn',      ## electronic ISSN number
    my($CODEN_OPENURL_FIELD)   = 'coden',      ## CODEN

    my($ISBN_OPENURL_FIELD)    = 'isbn',       ## ISBN number
    my($SICI_OPENURL_FIELD)    = 'sici',       ## SICI of a journal article, volume or issue 
    my($BICI_OPENURL_FIELD)    = 'bici',       ## BICI to a section of a book, to which an ISBN has been assigned
    my($TITLE_OPENURL_FIELD)   = 'title',      ## title of a bundle (journal, book or conference)

    my($STITLE_OPENURL_FIELD)  = 'stitle',     ## abbreviated title of a bundle
    my($ATITLE_OPENURL_FIELD)  = 'atitle',     ## title of an individual item (article, preprint, proceeding, bookitem)
    my($VOLUME_OPENURL_FIELD)  = 'volume',     ## volume of a bundle
    my($PART_OPENURL_FIELD)    = 'part',       ## part of a bundle

    my($ISSUE_OPENURL_FIELD)   = 'issue',      ## issue of a bundle
    my($SPAGE_OPENURL_FIELD)   = 'spage',      ## start page of an individual item in a bundle
    my($EPAGE_OPENURL_FIELD)   = 'epage',      ## end page of an individual item in a bundle   
    my($PAGES_OPENURL_FIELD)   = 'pages',      ## pages covered by an individual item in a bundle (spage-epage)

    my($ARTNUM_OPENURL_FIELD)  = 'artnum',     ## number of an individual item, in cases where there are no pages available
    my($DATE_OPENURL_FIELD)    = 'date',       ## [ YYYY-MM-DD | YYYY-MM | YYYY ] 
    my($SSN_OPENURL_FIELD)     = 'ssn',        ## season of publication [ winter | spring | summer | fall ]
    my($QUARTER_OPENURL_FIELD) = 'quarter',     ## quarter of a publication [ 1 | 2 | 3 | 4 ]

    my($CHARSET_OPENURL_FIELD)         = 'charset',     ## Used by Refworks in openurl links
);


my(@BUNDLE_GENRE_ARR) = ( 
   my($JOURNAL_GENRE)    = 'journal', 
   my($BOOK_GENRE)       = 'book',
   my($CONFERENCE_GENRE) = 'conference'
); 
          

my(@INDIVIDUAL_ITEM_GENRE_ARR) = (
   my($ARTICLE_GENRE)    = 'article',
   my($PREPRINT_GENRE)   = 'preprint',
   my($PROCEEDING_GENRE) = 'proceeding',
   my($BOOKITEM_GENRE)   = 'bookitem'
);


my(%GENRE_TO_REQTYPE_HASH) = (
    $JOURNAL_GENRE    => '',                             ## journal, volume of a journal, issue of a journal
    $BOOK_GENRE       => $gconst::BOOK_TYPE,
    $CONFERENCE_GENRE => $gconst::CONFERENCE_TYPE,
    $ARTICLE_GENRE    => $gconst::JOURNAL_TYPE,
    $PREPRINT_GENRE   => $gconst::PREPRINT_TYPE,         ## a preprint
    $PROCEEDING_GENRE => $gconst::CONFERENCE_TYPE,
    $BOOKITEM_GENRE   => $gconst::BOOK_ARTICLE_TYPE,     
);

my(%ID_NAMESPACE_TO_LOCAL_FIELDS_HASH) = (
    'doi'     => $gconst::DOI_FIELD,
    'pmid'    => $gconst::PMID_FIELD,
    'bibcode' => $gconst::BIBCODE_FIELD,
    'oai'     => $gconst::OAI_FIELD,
);


##
## Extra point values for fields which are pretty OpenURL specific and warrant extra points,
## plus fields which we are not parsing, but should count as OpenURL fields.
##

my %OPENURL_FUZZY_VALUES = (
	'sid' 		=> 4,
	'pid'		=> 3,
	'genre'		=> 5,
	'aulast'	=> 3,
	'aufirst'	=> 3,
	'auinit'	=> 3,
	'auinit1'	=> 3,
	'charset'	=> 2,
);

##------------------------------------------------------------------------------------------

sub openurl_parse {
    my($citation_ref) = @_;

    ##
    ## -keep any incoming values
    ##

    my(%citation) = %{$citation_ref};
    my(%param_hash);
    my($reqtype) = $citation{$gconst::REQTYPE_FIELD};

    ##
    ## -in case we haven't already, get rid of any leading and trailing whitespace
    ##

    foreach (param()) {
        $param_hash{$_} = trim_beg_end(param($_));
    }

    $citation{$gconst::TITLE_FIELD} = ($param_hash{$TITLE_OPENURL_FIELD} ne '') ? 
                                      $param_hash{$TITLE_OPENURL_FIELD} :
                                      $param_hash{$STITLE_OPENURL_FIELD};

    $citation{$gconst::ARTTIT_FIELD} = $param_hash{$ATITLE_OPENURL_FIELD};

    ##
    ## -put together the first author's name, starting with the 'better' or 'more informative' components
    ##

    my($author) = $param_hash{$AULAST_OPENURL_FIELD};
        
    if ($param_hash{$AUFIRST_OPENURL_FIELD} ne '')   {
                
        if ($author ne '') { $author .= ", "; }
        $author .= $param_hash{$AUFIRST_OPENURL_FIELD};

        if ($param_hash{$AUINITM_OPENURL_FIELD} ne '' ) { $author .= " $param_hash{$AUINITM_OPENURL_FIELD}"; }

    }
    elsif ($param_hash{$AUINIT_OPENURL_FIELD})   {

        if ($author ne '') { $author .= ", "; }
        $author .= $param_hash{$AUINIT_OPENURL_FIELD};
    }
    elsif ($param_hash{$AUINIT1_OPENURL_FIELD})   {

        if ($author ne '') { $author .= ", "; }
        $author .= $param_hash{$AUINIT1_OPENURL_FIELD};
    }

    ##
    ## -is the author for a 'bundle' or an 'individual item' (ie. an article, book chaper, etc)
    ##

    if (grep {$param_hash{$GENRE_OPENURL_FIELD} eq $_} @INDIVIDUAL_ITEM_GENRE_ARR)  { $citation{$gconst::ARTAUT_FIELD} = $author; }
    else                                                                            { $citation{$gconst::AUT_FIELD}    = $author; }  

    ##
    ## -standard numbers 
    ##

    $citation{$gconst::ISSN_FIELD} = ($param_hash{$ISSN_OPENURL_FIELD} ne '') ? 
                                     $param_hash{$ISSN_OPENURL_FIELD} :
                                     $param_hash{$EISSN_OPENURL_FIELD};

    $citation{$gconst::ISBN_FIELD} = $param_hash{$ISBN_OPENURL_FIELD};

    ##
    ## -volume and issue
    ##

    $citation{$gconst::VOL_FIELD} = ($param_hash{$VOLUME_OPENURL_FIELD} ne '') ?
                                    $param_hash{$VOLUME_OPENURL_FIELD} :
                                    $param_hash{$PART_OPENURL_FIELD} ;                    ## ???? or should this mapt to issue ????

    $citation{$gconst::ISS_FIELD} = $param_hash{$ISSUE_OPENURL_FIELD};

    ##
    ## -figure out pages
    ##

    my($pages)  = $param_hash{$PAGES_OPENURL_FIELD};
    my($spage)  = $param_hash{$SPAGE_OPENURL_FIELD};  
    my($epage)  = $param_hash{$EPAGE_OPENURL_FIELD};  
    my($artnum) = $param_hash{$ARTNUM_OPENURL_FIELD};    

    if ($pages eq '') {
        if ($spage && $epage) { $pages = "$spage-$epage"; }
        elsif ($spage)        { $pages = $spage;          } 
        elsif ($artnum)       { $pages = $artnum;         }       
    }
   
    $citation{$gconst::PGS_FIELD} = $pages;

    ##
    ## -what date format do we have?
    ##   
    my($date) = $param_hash{$DATE_OPENURL_FIELD};
    my($mm);

    if ($date ne '') {

        if ($date =~ m#(\d\d\d\d)\055(\d\d)\055(\d\d)#) {                ## YYYY-MM-DD
      
            $citation{$gconst::YEAR_FIELD}     = $1;   
            $citation{$gconst::YYYYMMDD_FIELD} = "$1$2$3";
            $mm                                = $2;
        }
        elsif ($date =~ m#(\d\d\d\d)\055(\d\d)#) {                       ## YYYY-MM    

            $citation{$gconst::YEAR_FIELD} = $1; 
            $mm                            = $2; 
        }
        elsif ($date =~ m#(\d\d\d\d)#) {                                 ## YYYY  
 
            $citation{$gconst::YEAR_FIELD} = $1; 
        }
    }

    ##
    ## -don't pass blank to &GODOT::Date::date_mm_to_mon or will get 'DEC' -- need to fix date_mm_to_mon !!!!!
    ##

    use GODOT::Date;

    if ($mm) { $citation{$gconst::MONTH_FIELD} = &GODOT::Date::date_mm_to_mon($mm); }

    if (! $citation{$gconst::MONTH_FIELD}) { $citation{$gconst::MONTH_FIELD} = $param_hash{$SSN_OPENURL_FIELD}; }

    ##
    ## -do we want to put numeric quarter in month field???? 
    ## -possible confusion????
    ## -add new quarter field ????
    ##

    if ((! $citation{$gconst::MONTH_FIELD}) && $param_hash{$QUARTER_OPENURL_FIELD}) { 

        my(%quarter_hash) = ('1' => '1st', '2' => '2nd', '3' => '3rd', '4' => '4th');

        $citation{$gconst::MONTH_FIELD} = "$quarter_hash{$param_hash{$QUARTER_OPENURL_FIELD}} quarter"; 
    }
    
    ##
    ## !!!!! -still need to map OpenURL 'id', 'pid', 'coden', 'sici' and 'bici' !!!!!!
    ##    

    if ($param_hash{$ID_OPENURL_FIELD})  {   

        my($namespace, $identifier) = split(/:/, $param_hash{$ID_OPENURL_FIELD}, 2);

        $citation{$ID_NAMESPACE_TO_LOCAL_FIELDS_HASH{$namespace}} = $identifier;
    }

    %{$citation_ref} = %citation;
}


##
## !!!!! -need to add 'journal' and 'preprint' genre logic to godot !!!!!
##

sub openurl_getreq {
    
    my($reqtype, $no_title);
    my($genre) = param($GENRE_OPENURL_FIELD);

    ##
    ## -'oai' specifies identifier used in Open Archives Initiative  
    ##
    ## -deal with case seen in 'iopp' where the genre was 'article' but no journal title was given and 
    ##  article was only available through the preprint archive
    ##
   
    $no_title = (aws(param($TITLE_OPENURL_FIELD)) && aws(param($STITLE_OPENURL_FIELD))) ? $TRUE : $FALSE;
 
    if ($no_title && (param($ID_OPENURL_FIELD) =~ m#^oai:#)) { return $gconst::PREPRINT_TYPE; } 

    return $GENRE_TO_REQTYPE_HASH{$genre};
}


sub openurl_dbase_type {

    if (! param($SID_OPENURL_FIELD)) { return 'unknown'; }

    my(@arr) = split(/:/, param($SID_OPENURL_FIELD));
    return $arr[0]; 
}

sub openurl_dbase_local {


    if (! param($SID_OPENURL_FIELD)) { return 'unknown'; }

    my(@arr) = split(/:/, param($SID_OPENURL_FIELD));
    if    (naws($arr[1]))  { return $arr[1];   }
    elsif (naws($arr[0]))  { return $arr[0];   }
    else                   { return 'unknown'; }              
}

##
## Updated by Todd to handle fuzzy OpenURL matching.  This now returns a positive value
## for fields which are OpenURL related, or a negative value for non-OpenURL fields.
##

sub openurl_is_field {
	my ($string) = @_;
	
	my $value;
	
	$value = $OPENURL_FUZZY_VALUES{$string};

	!defined($value) && grep {$string eq $_} @CITN_PRE_OPENURL_ARR and
		$value = 2;
	
	defined($value) or
		$value = -1;
	
	return $value;
}

sub genre {

    return param($GENRE_OPENURL_FIELD);
}

##-----------------------------------------------------------------------------------
1;







