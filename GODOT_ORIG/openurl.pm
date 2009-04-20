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


my $SID_OPENURL_FIELD = 'sid';              ## openurl 0.1 -- ORIGIN-DESCRIPTION
my $REFERRER_ID_OPENURL_FIELD = 'rfr_id';   ## openurl 1.0 -- a "referrer id" to say who made the ContextObject, eg. info:sid/elsevier.com:ScienceDirect

my(@CITN_PRE_OPENURL_ARR) = (

    $SID_OPENURL_FIELD,
    $REFERRER_ID_OPENURL_FIELD,  
    'id',                ## GLOBAL-IDENTIFIER-ZONE
    'pid',               ## LOCAL-IDENTIFIER-ZONE
    'genre',             ## bundles: [ journal | book | conference ]
                         ## individual items:  [ article | preprint | proceeding | bookitem ]
    'aulast',            ## first author's last name
    'aufirst',           ## first author's first name
    'auinit',            ## first author's first and middle initials
    'auinit1',           ## first author's first initial

    'auinitm',           ## first author's middle initials
    'issn',              ## ISSN number
    'eissn',             ## electronic ISSN number
    'coden',             ## CODEN

    'isbn',              ## ISBN number
    'sici',              ## SICI of a journal article, volume or issue 
    'bici',              ## BICI to a section of a book, to which an ISBN has been assigned
    'title',             ## title of a bundle (journal, book or conference)

    'stitle',            ## abbreviated title of a bundle
    'atitle',            ## title of an individual item (article, preprint, proceeding, bookitem)
    'volume',            ## volume of a bundle
    'part',              ## part of a bundle

    'issue',             ## issue of a bundle
    'spage',             ## start page of an individual item in a bundle
    'epage',             ## end page of an individual item in a bundle   
    'pages',             ## pages covered by an individual item in a bundle (spage-epage)

    'artnum',            ## number of an individual item, in cases where there are no pages available
    'date',              ## [ YYYY-MM-DD | YYYY-MM | YYYY ] 
    'ssn',               ## season of publication [ winter | spring | summer | fall ]
    'quarter',           ## quarter of a publication [ 1 | 2 | 3 | 4 ]

    'charset',           ## Used by Refworks in openurl links

    ##
    ## (02-mar-2009 kl) fields added to improve openurl 1.0 support;
    ##
    'ausuffix',          ## author's name suffix, eg. 'Jr' or 'III'
    'au',                ## full name of a single author;  may repeat;
    'aucorp',            ## organization or corporation that is the author or creator of the document;
    'btitle',            ## title of the book
    'pub',               ## publisher name
    'place',             ## place of publication
    'edition',           ## statement of edition of the book;  usually a phrase with or without numbers, but may be a single number.  eg.  "first edition"
    'tpages',            ## total pages;  total pages is the largest recorded number of pages, if this can be determined
    'series',            ## title of a series in which the book or document was issued;  there may also be an ISSN associated with the series;
    'chron',             ## enumeration or chronology in not-normalized form, eg. "1st quarter"
    'co',                ## country of publication for dissertation
    'cc',                ## country of publication code for dissertation
    'inst',              ## institution that issued dissertation
    'advisor',           ## dissertation advisor
    'degree',            ## degree conferred for dissertation
    'rft_id',            ## an identifier for the thing you are describing, eg. info:doi/10.1002/bies.20239, info:oclcnum/148887403, info:pmid/16029089, urn:ISBN:978-0-691-07788-8
    'url_ver',           ## OpenURL version
    'rft_val_fmt',       ## metadata format used by ContextObject; "kev" stands for key-encoded-value;  eg. info:ofi/fmt:kev:mtx:journal, info:ofi/fmt:dev:mtx:book 
    'url_ctx_fmt',       ## format of ContextObject;  fixed value;  eg. info:ofi/fmt:kev:mtx:ctx 
    'rfe_dat'            ## private data (like 'pid' in version 0.1);  eg. <accessionnumber>958948</accessionnumber>
);


##
## Extra point values for fields which are pretty OpenURL specific and warrant extra points,
## plus fields which we are not parsing, but should count as OpenURL fields.
##

my %OPENURL_FUZZY_VALUES = (
	'genre'		=> 5,
        'url_ctx_fmt'   => 5,      ## (02-mar-2009 kl) added for openurl 1.0
        'rft_val_fmt'   => 5,      ## (02-mar-2009 kl) added for openurl 1.

	'sid' 		=> 4,      
        'url_ver'       => 4,      ## (02-mar-2009 kl) added for openurl 1.0      
        'rfr_id',       => 4,      ## (02-mar-2009 kl) added for openurl 1.0      
        'rft_id',       => 4,      ## (02-mar-2009 kl) added for openurl 1.0      
        'rfe_dat'       => 4,      ## (02-mar-2009 kl) added for openurl 1.0      

	'pid'		=> 3,
	'aulast'	=> 3,
	'aufirst'	=> 3,
	'auinit'	=> 3,
	'auinit1'	=> 3,
	'ausuffix'	=> 3,
	'aucorp'	=> 3,

	'charset'	=> 2,
);

##------------------------------------------------------------------------------------------


##
## (02-mar-2009 kl) -- added $REFERRER_ID_OPENURL_FIELD (rfr_id), eg.  info:sid/gale:PPFA, info:sid/ADS
##
sub openurl_dbase_type {

    my $string = &sid;
    my(@arr) = split(/:/, $string);
    return $arr[0]; 
}

sub openurl_dbase_local {

    my $string = &sid;
    my(@arr) = split(/:/, $string, 2);             ## don't want to loose data for sid of form 'www.isinet.com:WoK:WOS'  
    return naws($arr[1]) ? $arr[1] : $arr[0];
}

sub sid {
    my $string = (param($REFERRER_ID_OPENURL_FIELD) =~ m#^info\:sid/(.+)$#) ? $1
               : (param($SID_OPENURL_FIELD)) ? param($SID_OPENURL_FIELD)
               : 'unknown';

    return $string;
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

##-----------------------------------------------------------------------------------

1;







