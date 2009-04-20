package gconst;

use strict;

use vars qw($TRUE $FALSE);
$TRUE  = 1;
$FALSE = 0;

##
## (04-jul-2001-kl) - added $URL_MSG_FIELD to 'use vars' and '@CITN_ARR'
##
use vars qw(@CITN_ARR $CITN_PREFIX
            $REQTYPE_FIELD     $PUBTYPE_FIELD $ARTTIT_FIELD  $YEAR_FIELD      $ISSN_FIELD
            $SERIES_FIELD      $MONTH_FIELD   $VOLISS_FIELD  $VOL_FIELD       $ISS_FIELD
            $PGS_FIELD         $TITLE_FIELD   $PUB_FIELD     $AUT_FIELD       $ARTAUT_FIELD
            $NOTE_FIELD        $ISBN_FIELD    $REPNO_FIELD   $SYSID_FIELD     $THESIS_TYPE_FIELD
            $FTREC_FIELD       $URL_FIELD     $ERIC_NO_FIELD $ERIC_AV_FIELD   $MLOG_NO_FIELD
            $UMI_DISS_NO_FIELD $EDITION_FIELD $CALL_NO_FIELD $YYYYMMDD_FIELD  $ERIC_FT_AV_FIELD
            $DOI_FIELD         $PMID_FIELD    $BIBCODE_FIELD $OAI_FIELD       $OCLCNUM_FIELD
            $URL_MSG_FIELD
            $SICI_FIELD        $DAY_FIELD     $GENRE_FIELD   $PATENT_NO_FIELD $PATENTEE_FIELD
            $PATENT_YEAR_FIELD $NO_HOLDINGS_SEARCH_FIELD     $PUB_PLACE_FIELD $CODEN_FIELD
            $BICI_FIELD        $WARNING_FIELD);


$CITN_PREFIX = '_ht_';

##
## (19-mar-2009 kl) -- fields should match those in @GODOT::Citation::CITATION_MAPPINGS
##

@CITN_ARR = (

    $REQTYPE_FIELD     = '_ht_reqtype',       ## should only contain values from @REQTYPE_ARR 
    $PUBTYPE_FIELD     = '_ht_pubtype',       ## type of publication - used to determine $REQTYPE_FIELD  

    $TITLE_FIELD       = '_ht_title',         ## title of book, journal, etc (for article title use $ARTTIT_FIELD)
    $ARTTIT_FIELD      = '_ht_arttit',        ## article title
    $SERIES_FIELD      = '_ht_series',        ## series

    $AUT_FIELD         = '_ht_aut',           ## author/editor  
    $ARTAUT_FIELD      = '_ht_artaut',        ## article author

    $PUB_FIELD         = '_ht_pub',           ## publishing info
    $PUB_PLACE_FIELD   = '_ht_pub_place',     ## publisher place

    $ISSN_FIELD        = '_ht_issn',          ## ISSN
    $ISBN_FIELD        = '_ht_isbn',          ## ISBN

    $VOLISS_FIELD      = '_ht_voliss',        ## volume and issue (use if volume and issue cannot be parsed out)
    $VOL_FIELD         = '_ht_vol',           ## volume 
    $ISS_FIELD         = '_ht_iss',           ## issue
    $PGS_FIELD         = '_ht_pgs',           ## pages
    $YEAR_FIELD        = '_ht_year',          ## year (YYYY)
    $MONTH_FIELD       = '_ht_month',         ## month - any format
    $DAY_FIELD         = '_ht_day',           ## day of the month 

    $YYYYMMDD_FIELD    = '_ht_yyyymmdd',      ## numeric date 
                                              ## (30-mar-2000 kl) - added for fulltext linking 

    $EDITION_FIELD     = '_ht_edition',       ## edition
    
    $THESIS_TYPE_FIELD = '_ht_thesis_type',   ## thesis type (eg. Master's, Ph.D)

    $FTREC_FIELD       = '_ht_ftrec',         ## fulltext included in record  ... so don't need to go any further ...
    $URL_FIELD         = '_ht_url',           ## URL field found in citations for web pages
    $NOTE_FIELD        = '_ht_note',          ## note

    $REPNO_FIELD       = '_ht_repno',         ## report number 
    $SYSID_FIELD       = '_ht_sysid',         ## system ID  - ex. if citation is from DRA catalogue then
                                              ##              001 field could be stored here
                                              ##            - this string should be unique and be able to be used
                                              ##              to retrieve the record in question (preferably via Z39.50)
    
    $ERIC_NO_FIELD     = '_ht_eric_no',       ## ERIC document number  - used to access microfiche
    $ERIC_AV_FIELD     = '_ht_eric_av',       ## ERIC Level of Availability field 
    $ERIC_FT_AV_FIELD  = '_ht_eric_ft_av',    ## ERIC document is available online; 
                                              ## Link is specified in the ERIC citation record

    $MLOG_NO_FIELD     = '_ht_mlog_no',       ## Microlog number - used to access microfiche
    $UMI_DISS_NO_FIELD = '_ht_umi_diss_no',   ## UMI Dissertation Number - in future use as link to UMI...

    $CALL_NO_FIELD     = '_ht_call_no',       ## call number - for item databases such as 'ubc'

    $DOI_FIELD         = '_ht_doi',           ## digital object identifier
    $PMID_FIELD        = '_ht_pmid',          ## PubMed identifier
    $BIBCODE_FIELD     = '_ht_bibcode',       ## identifier used in Astrophysics Data System
    $OAI_FIELD         = '_ht_oai',           ## identifier used in the Open Archives initiative
    $OCLCNUM_FIELD     = '_ht_oclcnum',           
    $CODEN_FIELD       = '_ht_coden',         
    $BICI_FIELD        = '_ht_bici',

    $URL_MSG_FIELD     = '_ht_url_msg',       ## message indicating that there is a url given in the database record (may include link)
    $WARNING_FIELD     = '_ht_warning',       

    $SICI_FIELD        = '_ht_sici',      
    $GENRE_FIELD       = '_ht_genre',         ## for OpenURL links

    $PATENT_NO_FIELD          = '_ht_patent_no',          ## Patent number
    $PATENTEE_FIELD           = '_ht_patentee',           ## Patentee
    $PATENT_YEAR_FIELD        = '_ht_patent_year',        ## Patent Year
    $NO_HOLDINGS_SEARCH_FIELD = '_ht_no_holdings_search'  ## Do not bother doing a search for regular holdings, eg. for patents
);


use vars qw(@REQTYPE_ARR);
use vars qw($JOURNAL_TYPE $CONFERENCE_TYPE $TECH_TYPE $BOOK_TYPE  $BOOK_ARTICLE_TYPE $THESIS_TYPE $PREPRINT_TYPE);

@REQTYPE_ARR = (
    $JOURNAL_TYPE      = 'JOURNAL',
    $CONFERENCE_TYPE   = 'CONFERENCE',
    $TECH_TYPE         = 'TECH',
    $BOOK_TYPE         = 'BOOK',
    $BOOK_ARTICLE_TYPE = 'BOOK-ARTICLE',
    $THESIS_TYPE       = 'THESIS',
    $PREPRINT_TYPE     = 'PREPRINT'               ## (10-mar-2001) - added for OpenURL links
);



use vars qw($HOLD_TAB_PREFIX $BRANCH_FIELD $DBASE_FIELD $ACTION_PARAM_FIELD $ASSOC_SITES_FIELD); 

$HOLD_TAB_PREFIX    = 'hold_tab_';
$BRANCH_FIELD       = 'hold_tab_branch';
$DBASE_FIELD        = 'hold_tab_dbase';
$ACTION_PARAM_FIELD = 'hold_tab_action_param';
$ASSOC_SITES_FIELD  = 'hold_tab_assoc_sites';


use vars qw($SEARCH_MSG_LINK_TYPE 
            $SEARCH_MSG_FULLTEXT_TYPE 
            $SEARCH_MSG_HOLDINGS_TYPE 
            $SEARCH_MSG_QUEUE_TYPE 
            $SEARCH_MSG_RUNNING_PARA_TYPE
            $SEARCH_MSG_MORE_HOLDINGS_SEARCHES_TYPE
            $SEARCH_MSG_PARA_SERVER_NO_CONNECT_TYPE  
            $SEARCH_MSG_PARA_SERVER_TIMEOUT_TYPE
            $SEARCH_MSG_PARA_SERVER_PROBLEM_TYPE
            $SEARCH_MSG_PARA_QUERY_TIMEOUT_TYPE
            $SEARCH_MSG_PARA_QUERY_PROBLEM_TYPE
            $SEARCH_MSG_SEARCH_TIME_TYPE
            $SEARCH_MSG_ELAPSED_TIME_TYPE);

$SEARCH_MSG_LINK_TYPE                    = 'search_msg_link_type';
$SEARCH_MSG_FULLTEXT_TYPE                = 'search_msg_fulltext_type';
$SEARCH_MSG_HOLDINGS_TYPE                = 'search_msg_holdings_type';
$SEARCH_MSG_QUEUE_TYPE                   = 'search_msg_queue_type';
$SEARCH_MSG_RUNNING_PARA_TYPE            = 'search_msg_running_para_type';
$SEARCH_MSG_MORE_HOLDINGS_SEARCHES_TYPE  = 'search_msg_more_holdings_searches_type';

$SEARCH_MSG_PARA_SERVER_NO_CONNECT_TYPE  = 'search_msg_para_server_no_connect_type';  
$SEARCH_MSG_PARA_SERVER_TIMEOUT_TYPE     = 'search_msg_para_server_timeout_type';
$SEARCH_MSG_PARA_SERVER_PROBLEM_TYPE     = 'search_msg_para_server_problem_type';

$SEARCH_MSG_PARA_QUERY_TIMEOUT_TYPE      = 'search_msg_para_query_timeout_type';
$SEARCH_MSG_PARA_QUERY_PROBLEM_TYPE      = 'search_msg_para_query_problem_type';

$SEARCH_MSG_SEARCH_TIME_TYPE             = 'search_msg_search_time_type';
$SEARCH_MSG_ELAPSED_TIME_TYPE            = 'search_msg_elapsed_time_type';

use vars qw($SEARCH_HOLDINGS_TYPE $SEARCH_LINK_TYPE $SEARCH_FULLTEXT_TYPE);

$SEARCH_HOLDINGS_TYPE  = 'holdings';
$SEARCH_LINK_TYPE      = 'links';
$SEARCH_FULLTEXT_TYPE  = 'fulltext';


##
## -constants for fulltext server
##
use vars qw($FT_SERVER_BEST_LINK $FT_SERVER_ERRORS $FT_SERVER_DATABASE_NAME 
            $FT_SERVER_RESOURCE_ID $FT_SERVER_TITLE $FT_SERVER_PROVIDER_NAME
            $FT_SERVER_START_TIME $FT_SERVER_END_TIME $FT_SERVER_START_STRING $FT_SERVER_END_STRING
            $FT_SERVER_DATABASE_VIEW $FT_SERVER_ISSUE_LIST_VIEW $FT_SERVER_LASTEST_ISSUE_VIEW 
            $FT_SERVER_YEAR_VIEW $FT_SERVER_ARTICLE_LIST_VIEW 
            $FT_SERVER_ARTICLE_VIEW $FT_SERVER_AUTH_METHOD $FT_SERVER_AUTH_IP_TEXT 
            $FT_SERVER_AUTH_METHOD_IP $FT_SERVER_AUTH_METHOD_ID_PW $FT_SERVER_AUTH_METHOD_ID_PW_UE
            $FT_SERVER_SUBSCRIP_TYPE  $FT_SERVER_SUBSCRIP_EIHP 
            $FT_SERVER_SUBSCRIP_IF_856_THEN_ELEC $FT_SERVER_SUBSCRIP_IF_HOLD_THEN_ELEC           
            $FT_SERVER_SUBSCRIP_ALL $FT_SERVER_NOTES 
            $JAKE_NAME $CUFTS_NAME);

$FT_SERVER_BEST_LINK     = 'best_link';
$FT_SERVER_ERRORS        = 'errors';  
$FT_SERVER_DATABASE_NAME = 'database_name';
$FT_SERVER_PROVIDER_NAME = 'provider_name';
$FT_SERVER_TITLE         = 'journal_name';
$FT_SERVER_RESOURCE_ID   = 'jake_id';
$FT_SERVER_NOTES         = 'notes';

$FT_SERVER_START_TIME    = 'fulltext_start_time';
$FT_SERVER_END_TIME      = 'fulltext_end_time';
$FT_SERVER_START_STRING  = 'fulltext_start_string';
$FT_SERVER_END_STRING    = 'fulltext_end_string';

$FT_SERVER_DATABASE_VIEW       = 'syntax_for_database';
$FT_SERVER_ISSUE_LIST_VIEW     = 'syntax_for_issue_list';
$FT_SERVER_LASTEST_ISSUE_VIEW  = 'syntax_for_latest_issue';
$FT_SERVER_YEAR_VIEW           = 'syntax_for_year';
$FT_SERVER_ARTICLE_LIST_VIEW   = 'syntax_for_article_list';
$FT_SERVER_ARTICLE_VIEW        = 'syntax_for_article';

$FT_SERVER_AUTH_METHOD   = 'auth_method'; 
$FT_SERVER_AUTH_IP_TEXT  = 'auth_ip_text';

$FT_SERVER_AUTH_METHOD_IP       = 'ip';
$FT_SERVER_AUTH_METHOD_ID_PW    = 'id_pw';
$FT_SERVER_AUTH_METHOD_ID_PW_UE = 'id_pw_user_entered';

$FT_SERVER_SUBSCRIP_TYPE = 'subscrip_type';
$FT_SERVER_SUBSCRIP_EIHP = 'electronic_if_have_print';

$FT_SERVER_SUBSCRIP_IF_856_THEN_ELEC  = 'if_856_then_electronic';
$FT_SERVER_SUBSCRIP_IF_HOLD_THEN_ELEC = 'if_holdings_then_electronic';

$FT_SERVER_SUBSCRIP_ALL  = 'all';  


$JAKE_NAME  = 'JAKE';

$CUFTS_NAME = 'CUFTS';


use vars qw($DTD);
$DTD = '-//IETF//DTD HTML//EN';




##-----------------------------------------------------------------------------
1;














