package hold_tab;

use CGI qw(:escape);

use Data::Dumper;
use Time::HiRes qw(gettimeofday);

use GODOTConfig::Configuration;
use GODOTConfig::Cache;

use GODOT::String;
use GODOT::Debug;
use GODOT::Config;
use GODOT::PageElem;
use GODOT::PageElem::Record;
use GODOT::PageElem::Button;
use GODOT::Page;
use GODOT::Template;

require glog;     
require glib;
require gconst;

use CGI qw(-no_xhtml :all); 

use strict;          

##------------------------------------------------------------------------------------
## global defs
##------------------------------------------------------------------------------------
use vars qw($PROG_NAME);
$PROG_NAME = 'GODOT';

use vars qw($TRUE $FALSE);
$TRUE  = 1;
$FALSE = 0;

use vars qw($ZERO $ONE_HUNDRED); 
$ZERO = 0;
$ONE_HUNDRED = 100;

##------------------------------------------------------------------------------------
## fields used to pass info initially to hold_tab.pm 
##
## !!! these fields must all start with 'hold_tab_' as otherwise they will be stripped out !!!
##
## (stripping is required to get rid of many extra fields that Webspirs passes)
## 
##------------------------------------------------------------------------------------
use vars qw($HOLD_TAB_PREFIX);
$HOLD_TAB_PREFIX = $gconst::HOLD_TAB_PREFIX;

##
## -title lists for these db were not included during pre-matching so may not find in pre-matched db
## -if search in pre-matched db fails then try on-the-fly
## -(25-feb-1998 kl) -changed from '@ON_FLY_DB_ARR' to '@PRE_MATCH_DB_ARR' logic as list of pre-matched changes less
##
use vars qw(@PRE_MATCH_DB_ARR);
@PRE_MATCH_DB_ARR = ('arts', 'abii', 'cbca', 'cinahl', 'curcon', 'educ', 'hssi', 'pais', 'rgab', 'scie', 'socio');

use vars qw($BRANCH_FIELD             $DBASE_TYPE_FIELD        $DBASE_LOCAL_FIELD  $DBASE_FIELD 
            $DBASE_TYPE_ABBREV_FIELD  $DBASE_LOCAL_ABBREV_FIELD
            $USERNO_FIELD             $BACK_URL_FIELD          $MSG_ADDR_FIELD     $MSG_FMT_FIELD 
            $MSG_REQ_TYPE_FIELD       $REQNO_FIELD             $SCREEN_FIELD       $COOKIE_FIELD 
            $ACTION_PARAM_FIELD       $REQUEST_ALLOWED_FIELD   $HOLDINGS_FIELD     $HOLDINGS_SITE_FIELD
            $ART_FORM_ONCE_THRU_FIELD $PATR_CHECKED_OK_FIELD   $WARNING_TYPE_FIELD $CALL_NO_SAVE_FIELD
            $PASSWORD_FIELD           $SYNTAX_FIELD            
            $HAS_GET_LINK_FIELD       $HAS_REQUEST_LINK_FIELD  $HAS_CHECK_LINK_FIELD  $HAS_AUTO_REQ_LINK_FIELD
            $HAS_HIDDEN_RECORD_FIELD  $HOLDINGS_HASH_FIELD     $AUTO_REQ_ACTION_FIELD $AUTO_REQ_PARAM_FIELD
            $HIDDEN_COMPLETE_FIELD    $LINK_FROM_CAT_URL_FIELD $TRUSTED_HOST_FIELD    $SEARCH_GROUP_FIELD);

$BRANCH_FIELD             = $gconst::BRANCH_FIELD;

$DBASE_TYPE_FIELD         = 'hold_tab_dbase_type';
$DBASE_TYPE_ABBREV_FIELD  = 'dbt';                             ## -for ebscohost
$DBASE_LOCAL_FIELD        = 'hold_tab_dbase_local';            ## -for ebscohost
$DBASE_LOCAL_ABBREV_FIELD = 'dbl';
$DBASE_FIELD              = $gconst::DBASE_FIELD;

$USERNO_FIELD             = 'hold_tab_userno';
$MSG_ADDR_FIELD           = 'hold_tab_msg_addr'; 
$MSG_REQ_TYPE_FIELD       = 'hold_tab_msg_req_type';
$MSG_FMT_FIELD            = 'hold_tab_msg_fmt';
$REQNO_FIELD              = 'hold_tab_reqno';
$BACK_URL_FIELD           = 'hold_tab_back_url';
$SCREEN_FIELD             = 'hold_tab_screen';
$COOKIE_FIELD             = 'hold_tab_cookie';

$ACTION_PARAM_FIELD       = $gconst::ACTION_PARAM_FIELD;

$REQUEST_ALLOWED_FIELD    = 'hold_tab_request_allowed';
$WARNING_TYPE_FIELD       = 'hold_tab_warning_type';
$HOLDINGS_FIELD           = 'hold_tab_holdings';
$HOLDINGS_SITE_FIELD      = 'hold_tab_holdings_site';           ## -site where holdings exist

$CALL_NO_SAVE_FIELD       = 'hold_tab_call_no_save';            ## -to save call numbers for different sites for use in ILL 
                                                                ##  request formats
$ART_FORM_ONCE_THRU_FIELD  = 'hold_tab_art_form_once_thru';     ## -has user seen article input screen before 
                                                                ## -used to determine whether user should see error msg or not
$PATR_CHECKED_OK_FIELD    = 'patr_checked_ok_field';            ## -patron has been authorized 
$TRUSTED_HOST_FIELD       = 'hold_tab_trusted_host';            ## -patron is coming from a trusted host for current user 
                                                                ##  (aka branch)
$PASSWORD_FIELD           = 'hold_tab_password';
$SYNTAX_FIELD             = 'hold_tab_syntax';

$HAS_GET_LINK_FIELD       = 'hold_tab_has_get_link';
$HAS_REQUEST_LINK_FIELD   = 'hold_tab_has_request_link',
$HAS_CHECK_LINK_FIELD     = 'hold_tab_has_check_link',
$HAS_AUTO_REQ_LINK_FIELD  = 'hold_tab_has_auto_req_link',
$HAS_HIDDEN_RECORD_FIELD  = 'hold_tab_has_hidden_record',

$HOLDINGS_HASH_FIELD      = 'hold_tab_holdings_hash';
$AUTO_REQ_ACTION_FIELD    = 'hold_tab_auto_req_action';
$AUTO_REQ_PARAM_FIELD     = 'hold_tab_auto_req_param';

$SEARCH_GROUP_FIELD       = 'search_group_field';

$HIDDEN_COMPLETE_FIELD    = 'hold_tab_hidden_complete';

$LINK_FROM_CAT_URL_FIELD  = 'link_from_cat_url';


use vars qw(%WARNING_DEFAULT_TEXT_HASH $YOUR_BRANCH_HAS_WARNING_TYPE);

$YOUR_BRANCH_HAS_WARNING_TYPE = 'H';
%WARNING_DEFAULT_TEXT_HASH = ($YOUR_BRANCH_HAS_WARNING_TYPE => 'Are you sure you want to order it from another library?');


use vars qw($ILL_FORM_DESC_TEXT $ILL_FORM_BLANK_DESC_TEXT $AUTO_REQ_DESC_TEXT $FULLTEXT_DESC_TEXT);
use vars qw($CAT_INTER_DESC_TEXT $ILL_REQ_FORM_LIMIT_MSG_DEFAULT_TEXT  
            $ERIC_DOC_PATTERN 
            $PARAM_DELIMITER $PARAM_DELIMITER_PATTERN);

#### $ILL_FORM_DESC_TEXT        = "Interlibrary Loan Request Form.";
$ILL_FORM_DESC_TEXT        = "";
$ILL_FORM_BLANK_DESC_TEXT  = "Continue with Interlibrary Loan Request.";

$AUTO_REQ_DESC_TEXT = "Request this item.";

$FULLTEXT_DESC_TEXT        = "Check for full text,  if available.";
$CAT_INTER_DESC_TEXT       = "Check status and recent holdings.";

$ILL_REQ_FORM_LIMIT_MSG_DEFAULT_TEXT = "You are not eligible for this service. Please see library staff for assistance.";


$ERIC_DOC_PATTERN = '^ed|^ED';     

##
## -use periods as delimeters, not equal signs, as equal signs seem to confuse the browser/CGI.pm (the result is that you
##  get both the url encoded and non-encoded versions of the parameter name in the next screen's params 
##
## -equal signs seem to work OK for 'submit' buttons ...
##

$PARAM_DELIMITER          = '.';      
$PARAM_DELIMITER_PATTERN  = '\.';      


##
## (10-apr-2009 kl) -- no need for a copy in both gconst.pm and here  
##                  -- also likely no need for a copy both in gconst.pm and GODOT::Citation.pm but leave this for another time
##

##
## (04-jul-2001-kl) - added $URL_MSG_FIELD to 'use vars' and '@CITN_ARR'
##

#
#use vars qw(@CITN_ARR
#            $REQTYPE_FIELD     $PUBTYPE_FIELD $ARTTIT_FIELD  $YEAR_FIELD      $ISSN_FIELD
#            $SERIES_FIELD      $MONTH_FIELD   $VOLISS_FIELD  $VOL_FIELD       $ISS_FIELD
#            $PGS_FIELD         $TITLE_FIELD   $PUB_FIELD     $AUT_FIELD       $ARTAUT_FIELD
#            $NOTE_FIELD        $ISBN_FIELD    $REPNO_FIELD   $SYSID_FIELD     $THESIS_TYPE_FIELD
#            $FTREC_FIELD       $URL_FIELD     $ERIC_NO_FIELD $ERIC_AV_FIELD   $MLOG_NO_FIELD
#            $UMI_DISS_NO_FIELD $EDITION_FIELD $CALL_NO_FIELD $YYYYMMDD_FIELD  $ERIC_FT_AV_FIELD
#            $DOI_FIELD         $PMID_FIELD    $BIBCODE_FIELD $OAI_FIELD       $SICI_FIELD
#            $URL_MSG_FIELD     $DAY_FIELD     $GENRE_FIELD   $PATENT_NO_FIELD $PATENTEE_FIELD
#            $PATENT_YEAR_FIELD $NO_HOLDINGS_SEARCH_FIELD);
#

##
## (26-nov-2000) - moved to gconst.pm
##               - please see that file for field descriptions
##
#
# @CITN_ARR = (
#    $REQTYPE_FIELD            = $gconst::REQTYPE_FIELD, 
#    $PUBTYPE_FIELD            = $gconst::PUBTYPE_FIELD,
#    $TITLE_FIELD              = $gconst::TITLE_FIELD,
#    $ARTTIT_FIELD             = $gconst::ARTTIT_FIELD,
#    $SERIES_FIELD             = $gconst::SERIES_FIELD,
#    $AUT_FIELD                = $gconst::AUT_FIELD,
#    $ARTAUT_FIELD             = $gconst::ARTAUT_FIELD,
#    $PUB_FIELD                = $gconst::PUB_FIELD,
#    $ISSN_FIELD               = $gconst::ISSN_FIELD,
#    $ISBN_FIELD               = $gconst::ISBN_FIELD,
#    $SICI_FIELD               = $gconst::SICI_FIELD,  
#    $VOLISS_FIELD             = $gconst::VOLISS_FIELD,
#    $VOL_FIELD                = $gconst::VOL_FIELD,
#    $ISS_FIELD                = $gconst::ISS_FIELD,
#    $PGS_FIELD                = $gconst::PGS_FIELD,
#    $YEAR_FIELD               = $gconst::YEAR_FIELD,
#    $MONTH_FIELD              = $gconst::MONTH_FIELD,
#    $DAY_FIELD                = $gconst::DAY_FIELD,
#    $YYYYMMDD_FIELD           = $gconst::YYYYMMDD_FIELD,                         
#    $EDITION_FIELD            = $gconst::EDITION_FIELD,    
#    $THESIS_TYPE_FIELD        = $gconst::THESIS_TYPE_FIELD,
#    $FTREC_FIELD              = $gconst::FTREC_FIELD,
#    $URL_FIELD                = $gconst::URL_FIELD,
#    $NOTE_FIELD               = $gconst::NOTE_FIELD,
#    $REPNO_FIELD              = $gconst::REPNO_FIELD,
#    $SYSID_FIELD              = $gconst::SYSID_FIELD,                                                                              
#    $ERIC_NO_FIELD            = $gconst::ERIC_NO_FIELD,
#    $ERIC_AV_FIELD            = $gconst::ERIC_AV_FIELD,
#    $ERIC_FT_AV_FIELD         = $gconst::ERIC_FT_AV_FIELD,
#    $MLOG_NO_FIELD            = $gconst::MLOG_NO_FIELD,
#    $UMI_DISS_NO_FIELD        = $gconst::UMI_DISS_NO_FIELD,
#    $CALL_NO_FIELD            = $gconst::CALL_NO_FIELD,
#    $DOI_FIELD                = $gconst::DOI_FIELD, 
#    $PMID_FIELD               = $gconst::PMID_FIELD,
#    $BIBCODE_FIELD            = $gconst::BIBCODE_FIELD,
#    $OAI_FIELD                = $gconst::OAI_FIELD,
#    $URL_MSG_FIELD            = $gconst::URL_MSG_FIELD,
#    $GENRE_FIELD              = $gconst::GENRE_FIELD,
#    $PATENT_NO_FIELD          = $gconst::PATENT_NO_FIELD,
#    $PATENTEE_FIELD           = $gconst::PATENTEE_FIELD,
#    $PATENT_YEAR_FIELD        = $gconst::PATENT_YEAR_FIELD,
#    $NO_HOLDINGS_SEARCH_FIELD = $gconst::NO_HOLDINGS_SEARCH_FIELD
# );
#
##--------------------------------------------------------------------------

use vars qw(@REQTYPE_ARR);
use vars qw($JOURNAL_TYPE $CONFERENCE_TYPE $TECH_TYPE $BOOK_TYPE  $BOOK_ARTICLE_TYPE $THESIS_TYPE $PREPRINT_TYPE);

@REQTYPE_ARR = (
    $JOURNAL_TYPE      = $gconst::JOURNAL_TYPE,
    $CONFERENCE_TYPE   = $gconst::CONFERENCE_TYPE,
    $TECH_TYPE         = $gconst::TECH_TYPE,
    $BOOK_TYPE         = $gconst::BOOK_TYPE,
    $BOOK_ARTICLE_TYPE = $gconst::BOOK_ARTICLE_TYPE,
    $THESIS_TYPE       = $gconst::THESIS_TYPE,
    $PREPRINT_TYPE     = $gconst::PREPRINT_TYPE
);

##
## -for now this list only contains one value 
## -however later it can be added to when we add more full text logic
##
use vars qw(@FULLTEXT_ARR $FULLTEXT_REC);
@FULLTEXT_ARR = ($FULLTEXT_REC = 'fulltext_rec');


##--------------------------------------------------------------------------
use vars qw($HOLD_TABLE_COL);

$HOLD_TABLE_COL = 3;

##---------------------------------------------------------------------

##
## !!!!!!!!!!!!!!!!!!!!!!!!!!!!! must match values used in GODOT::Constants and GODOT::CGI !!!!!!!!!!!!!!!!!!!!!!!!!!!
##

use vars qw(%ACTION_HASH);

use vars qw($START_ACT    $CAT_ACT             $CAT_INTER_ACT     $CHECK_PATR_ACT      $MAIN_HOLD_ACT       
            $ART_FORM_ACT $WARNING_ACT         $PASSWORD_ACT      $REQ_INFO_ACT 
            $REQ_FORM_ACT $REQ_ACCEPT_ACT      $REQ_SEND_ACT      $REQ_RETURN_ACT $REQ_CANCEL_ACT);


%ACTION_HASH = (($START_ACT          = 'start_action')                => '',        
                ($MAIN_HOLD_ACT      = 'main_holdings_action')        => '',
                ($WARNING_ACT        = 'warning_action')              => '',     
                ($ART_FORM_ACT       = 'article_form_action')         => '',
                ($PASSWORD_ACT       = 'password_action')             => '',
                ($CHECK_PATR_ACT     = 'check_patron_db_action')      => '',  
                ($REQ_INFO_ACT       = 'request_info_action')         => '',
                ($CAT_ACT            = 'catalogue_action')            => '',  
                ($CAT_INTER_ACT      = 'catalogue_interface_action')  => '',  

                ($REQ_FORM_ACT       = 'request_form_action')         => '',  
                ($REQ_ACCEPT_ACT     = 'request_accept_action')       => '',  
                ($REQ_SEND_ACT       = 'request_send_action')         => '',  
                ($REQ_RETURN_ACT     = 'request_return_action')       => '',  
                ($REQ_CANCEL_ACT     = 'request_cancel_action')       => '',  
               );
##
## !!!!!!!!!!!!!!!!!!!!!!!!!!!!! must match values used in GODOT::Constants and GODOT::CGI !!!!!!!!!!!!!!!!!!!!!!!!!!!
##

use vars qw($NO_SCR               $MAIN_HOLD_SCR  
            $EXIT_HOLD_SCR        $CAT_SCR             $REQ_FORM_SCR 
            $REQ_INPUT_ERROR_SCR  $REQ_OTHER_ERROR_SCR $REQ_CONFIRM_SCR  $REQ_ACK_SCR
            $CAT_INTER_SCR        $CHECK_PATR_SCR       
            $ART_FORM_SCR         $WARNING_SCR
            $ERROR_SCR            $PASSWORD_SCR        $REQ_INFO_SCR);

$NO_SCR                = 'no_screen_screen';
$MAIN_HOLD_SCR         = 'main_holdings_screen';
$WARNING_SCR           = 'warning_screen';
$ART_FORM_SCR          = 'article_form_screen';
$CAT_SCR               = 'catalogue_screen';
$CAT_INTER_SCR         = 'catalogue_interface_screen';     
$REQ_INFO_SCR          = 'request_info_screen';
$PASSWORD_SCR          = 'password_screen';
$CHECK_PATR_SCR        = 'check_patron_screen';

$REQ_FORM_SCR          = 'request_form_screen';
$REQ_INPUT_ERROR_SCR   = 'request_input_error_screen';
$REQ_CONFIRM_SCR       = 'request_confirmation_screen';
$REQ_OTHER_ERROR_SCR   = 'request_other_error_screen';
$REQ_ACK_SCR           = 'request_acknowledgment_screen';

$ERROR_SCR             = 'error_screen';


use vars qw($MAIN_HOLD_TITLE $CAT_TITLE $ERROR_TITLE $CGI_TITLE $HELP_TITLE $TRIED_MATCH_STATUS);

$CGI_TITLE = "Holdings";

$MAIN_HOLD_TITLE       = "Holdings";
$CAT_TITLE             = "Catalogue Search";   
$HELP_TITLE            = "Holdings/Requesting/Fulltext Help";

$ERROR_TITLE           = "Error";  

$TRIED_MATCH_STATUS  = 'tried_match_status';

my $SEARCH_ALL_SOURCES = 'search_all_sources';
my $SHOW_ALL_HOLDINGS  = 'show_all_holdings';
my $ANOTHER_SCRNO      = 'another_scrno';


my @PATR_ARR = qw(PATR_LAST_NAME_FIELD
		  PATR_FIRST_NAME_FIELD
		  PATR_LIBRARY_ID_FIELD
		  PATR_PATRON_TYPE_FIELD
		  PATR_DEPARTMENT_FIELD
	 	  PATR_PHONE_FIELD
		  PATR_PHONE_WORK_FIELD
                  PATR_BUILDING_FIELD           
                  PATR_PATRON_NOTI_FIELD
		  PATR_PATRON_EMAIL_FIELD
		  PATR_STREET_FIELD
		  PATR_CITY_FIELD
		  PATR_PROV_FIELD
		  PATR_POSTAL_CODE_FIELD
		  PATR_RUSH_REQ_FIELD
		  PATR_NOT_REQ_AFTER_FIELD
		  PATR_PICKUP_FIELD
		  PATR_PAID_FIELD
		  PATR_ACCOUNT_NO_FIELD
                  PATR_NOTE_FIELD);


my %PATR_MAPPING   = ('PATR_LAST_NAME_FIELD'     => 'patr_last_name',
		      'PATR_FIRST_NAME_FIELD'    => 'patr_first_name',
		      'PATR_LIBRARY_ID_FIELD'    => 'patr_library_id',                      
		      'PATR_PATRON_TYPE_FIELD'   => 'patr_patron_type', 
		      'PATR_DEPARTMENT_FIELD'    => 'patr_department',
	 	      'PATR_PHONE_FIELD'         => 'patr_phone',
		      'PATR_PHONE_WORK_FIELD'    => 'patr_phone_work', 
                      'PATR_BUILDING_FIELD'      => 'patr_building',         
                      'PATR_PATRON_NOTI_FIELD'   => 'patr_patron_noti',
		      'PATR_PATRON_EMAIL_FIELD'  => 'patr_patron_email',
		      'PATR_STREET_FIELD'        => 'patr_street',
		      'PATR_CITY_FIELD'          => 'patr_city',
		      'PATR_PROV_FIELD'          => 'patr_prov',
		      'PATR_POSTAL_CODE_FIELD'   => 'patr_postal_code', 
		      'PATR_RUSH_REQ_FIELD'      => 'patr_rush_req',
		      'PATR_NOT_REQ_AFTER_FIELD' => 'patr_not_req_after',
		      'PATR_PICKUP_FIELD'        => 'patr_pickup',
		      'PATR_PAID_FIELD'          => 'patr_paid',
                      'PATR_ACCOUNT_NO_FIELD'    => 'patr_account_no',
                      'PATR_NOTE_FIELD'          => 'patr_note');


my $REQUEST_DEFAULT     = "E";
my $REQUEST_SELF        = "S";
my $REQUEST_NEW         = "W";
my $REQUEST_MEDIATED    = "M"; 
my $REQUEST_DIRECT      = "D";
my $REQUEST_INFO        = "I";
my $REQUEST_NOT_ALLOWED = "N";

my @ILL_LOCAL_TYPE_ARR  = ($REQUEST_NEW, $REQUEST_MEDIATED, $REQUEST_SELF);
my @REQUEST_TYPE_ARR    = ($REQUEST_MEDIATED, $REQUEST_DIRECT, $REQUEST_INFO, $REQUEST_NOT_ALLOWED);

my $TRUE_STR  = 'T';
my $FALSE_STR = 'F';
my $ERIC_COLL_T_IF_FULLTEXT_LINK = 'T_IF_FULLTEXT_LINK';

my $BLOCKING_TRUE                      = $TRUE_STR;
my $BLOCKING_FALSE                     = $FALSE_STR;
my $BLOCKING_FALSE_MEDIATED            = $FALSE_STR . '_MEDIATED';
my $BLOCKING_FALSE_MEDIATED_NO_WARNING = $FALSE_STR . '_MEDIATED_NO_WARNING';
my $BLOCKING_FALSE_WARNING             = $FALSE_STR . '_WARNING';

my $MONO_MODE    = 'mono_mode';
my $JOURNAL_MODE = 'journal_mode';

##
## (13-nov-2007 kl) - these had been set to 'ALL' and 'CAN_BORROW_ONLY' but the config field 'holdings_list' has a form field
##                    of type 'CHECKBOX_BOOL' so the values in the database as set by the 'new' config tool are either '0' or '1'
##
my $HOLDINGS_LIST_ALL               = '0';
my $HOLDINGS_LIST_CAN_BORROW_ONLY   = '1';

my $SAME_NUC_ILL_LOCAL_SYSTEM       = 'L';
my $SAME_NUC_REQUEST_MSG            = 'R';
my $SAME_NUC_IGNORE                 = 'N';


##--------------------------------------------------------------------------------------------
##                        screen-func
##--------------------------------------------------------------------------------------------
##
##  screen functions - all must return success, failure or an action as their first parameter
##
##--------------------------------------------------------------------------------------------

sub main_holdings_screen {
    my($cgi, $page, $config, $citation) = @_;

    my $action = $cgi->action;
    my $new_screen = $cgi->new_screen;
    my $session = $cgi->session;

    my(%citation, %tab_comp_hash, %link_bib_hash);                   ## tab_comp stores table components
    my(@lender_arr, @tmp_arr);
    my($key, $user, $reqtype, $message, $check_citation_result, $lender);

    report_time_location;

    ##--------main_hold_scr may have been called from another screen------
    
    ##
    ## (30-sep-1998 kl) - added fix so that if it is specified but blank it will be ignored as sometimes
    ##                    the http_referer is no good
    ##

    if (! defined(param($BACK_URL_FIELD))) {    
        param(-name=>$BACK_URL_FIELD, '-values'=>[$ENV{'HTTP_REFERER'}]);         
    }
    elsif (aws(param($BACK_URL_FIELD))) {
        param(-name=>$BACK_URL_FIELD, '-values'=>['']);      
    }

    if (! defined $config) {

        $user = param($BRANCH_FIELD);

        $config = GODOTConfig::Cache->configuration_from_cache($user);

        unless (defined $config) {
            &glib::send_admin_email("$0: Unable to get user information ($user).");
            return $FALSE;
        }
    }    
    else {
        $user = $config->site->key;
    }

    ##
    ## -is this user allowed to process blank ILL form requests?
    ##

    if ($citation->get_dbase()->is_blank_dbase() && (! $config->use_blank_citation_form)) {
        $message = "$PROG_NAME is not configured to allow requesting from a blank form for user ($user)."; 
        &glib::sae("$0: $message");       
        $page->messages([$message]);
        $cgi->new_screen('error_screen');       
        return $TRUE;
    }


    ##
    ## -determine with screen number to use for the main screen
    ##

    my $scrno = 1;

    my($arg1, $arg2) = split(/=/, param($hold_tab::ACTION_PARAM_FIELD));

    if (grep {$arg1 eq $_} ($ANOTHER_SCRNO, $SEARCH_ALL_SOURCES, $SHOW_ALL_HOLDINGS)) { $scrno = $arg2; }

    my $search_group = $scrno;  

    $session->var($SEARCH_GROUP_FIELD, $search_group);

    ##------------------------------------------------------------------------
    ##
    ## -put back values in citation hash, until citation object is being used in all the code
    ##

    %citation = $citation->godot_citation();


    $check_citation_result = &process_citation($citation, '', \%citation, \$message, $parse::CITN_CHECK_FOR_SEARCH);

    ##
    ## print out citation after parsing and cleanup
    ##
    if (1) {
        debug "---------------------------------";
        foreach (@gconst::CITN_ARR) { debug "$_ = $citation{$_}"; }
        debug "---------------------------------";
    }

    $reqtype = $citation{$gconst::REQTYPE_FIELD};

    report_time_location;


    ##
    ## -we have enough info to print a holdings table
    ##
    if (($check_citation_result eq $parse::CITN_NEED_ARTICLE_INFO)  || ($check_citation_result eq $parse::CITN_SUCCESS)) {  

        ##
        ## (14-mar-2003 kl) -now that we have decided that there is enough data to do a search,
        ##                   find out if we need more citation data for an ILL request
        ##
  
	$check_citation_result = &process_citation($citation, '', \%citation, \$message, $parse::CITN_CHECK_FOR_REQ);


        ##
        ## -determine which table components you want
        ##
        ## -possibilities are JOURNAL, CONFERENCE, TECH, BOOK, BOOK-ARTICLE, THESIS
        ##

        $tab_comp_hash{$GODOT::Page::INSTRUCTIONS_COMP} = ''; 
        $tab_comp_hash{$GODOT::Page::CITATION_COMP} = ''; 
        $tab_comp_hash{$GODOT::Page::LINK_TEMPLATE_COMP} = '';

        ##
        ## (05-mar-2004 kl) - only search for fulltext on first pass at main screen
        ##
        ## -new linking component - this may include links to fulltext or to other online resources (ex. abstracts, 
        ##  commercial document delivery)
        ##
            
        if (($reqtype eq $JOURNAL_TYPE) && ($scrno == 1)) { 
           

            if ($config->use_fulltext_links) { $tab_comp_hash{$GODOT::Page::LINK_COMP} = ''; }

            ##
            ## -for now just do for journal -- later do for mono as well (if there are any 856 links)
            ## -would want to do in a different fashion as the site's catalogue gets searched anyways with mono
            ##

            if ($config->use_856_links) { 
                $tab_comp_hash{$GODOT::Page::LINK_FROM_CAT_COMP} = ''; 
            }
        }

        ##
        ## -will be set to $PREPRINT_TYPE if an Open Archive Identifier is specified, but no journal title 
        ##  is given (see &openurl::openurl_getreq())
        ##

        ##
        ## -returns a list of hashes with fields:  abbrev_name, full_name, name and group
        ##
        report_time_location;

        if ($reqtype ne $gconst::PREPRINT_TYPE) {

            ##
            ## (31-oct-1998 kl) 
            ##
            ## -determine for which branches you _want_ holdings - will be diff for journal and mono 
            ## -let lower level logic deal with whether their is a source _available_ from which to retrieve
            ##  holdings/circ info
            ##
       
            report_time_location;
            &get_rank_list($config, \@lender_arr, $citation, $search_group) || &glib::send_admin_email("$0: Unable to get rank list ($user).");             
            report_time_location;

            if (! $citation{$gconst::NO_HOLDINGS_SEARCH_FIELD}) { 

                $tab_comp_hash{$GODOT::Page::HOLDINGS_RESULT_COMP} = [@lender_arr]; 
            }

            ##
            ## (30-apr-1998 kl) - added logic for dealing with other collections such as 
            ##                    ERIC and Miroclog fiche
            ##

            &fill_other_coll_comp(\%tab_comp_hash);
        }

        ##
        ## -preprint logic - $reqtype may be $gconst::PREPRINT_TYPE, if there was no item title, or another 
        ##                   type if there was an item title
        ##
         
        if (param($gconst::OAI_FIELD)) { 
            $tab_comp_hash{$GODOT::Page::PREPRINT_COMP} = ''; 
        }

        my $dbase = param($DBASE_FIELD); 

        my $no_ill_form_comp = $FALSE;
        my $no_auto_req_comp = $FALSE;

        my($action_param_1, $action_param_2) = split(/=/, param($hold_tab::ACTION_PARAM_FIELD));

        $page->has_get_link($session->var($HAS_GET_LINK_FIELD));
        $page->has_request_link($session->var($HAS_REQUEST_LINK_FIELD));
        $page->has_check_link($session->var($HAS_CHECK_LINK_FIELD));
        $page->has_auto_req_link($session->var($HAS_AUTO_REQ_LINK_FIELD));
        $page->has_hidden_record($session->var($HAS_HIDDEN_RECORD_FIELD));        
        
        my $holdings_hash_ref = $session->var($HOLDINGS_HASH_FIELD);

        ## 
        ## (02-feb-2006 kl) - for reasons not completely clear to me right now this is required in order for 
        ##                    the $holdings_hash_ref hash to have a value...
        ##
        foreach my $key (keys %{$holdings_hash_ref}) {
            my $junk = ${$holdings_hash_ref}{$key};
        }

        my($main_msg_string,
           $para_server_msg_string,
           $table_string,
           $hold_found,
           $num_cat_link)      = &print_hold_tab($cgi, 
                                                 $action, 
                                                 $new_screen, 
                                                 $citation, 
                                                 $config,
                                                 $page,
                                                 ($action_param_1 eq $SEARCH_ALL_SOURCES),
                                                 ($action_param_1 eq $SHOW_ALL_HOLDINGS),
                                                 $holdings_hash_ref,
                                                 \%tab_comp_hash, 
                                                 $dbase,                                                   
                                                 $check_citation_result, 
                                                 \%link_bib_hash, 
                                                 $no_ill_form_comp,
                                                 $no_auto_req_comp, 
                                                 $search_group,
                                                 $scrno);

        

        $session->var($HOLDINGS_HASH_FIELD, $holdings_hash_ref);

        $page->scrno($scrno);

        ##
        ## (05-mar-2004 kl) - create 'another screen number' record 
        ##

        my $another_scrno_record = new GODOT::PageElem::Record;
        my $another_scrno_button = new GODOT::PageElem::Button;

        $another_scrno_button->action($MAIN_HOLD_ACT);
        $another_scrno_button->param("=$ANOTHER_SCRNO");
        $another_scrno_button->label($ANOTHER_SCRNO);

        $another_scrno_record->type($GODOT::Page::ANOTHER_SCRNO_COMP);
        $another_scrno_record->buttons($another_scrno_button);

        $page->records([ $another_scrno_record ]);

        ##--------------------------------------------------------------------------------------------
        ## (14-mar-2003 kl) - logic to determine title of item based on the results of the holdings search
        ##                  - required when only ISSN or ISBN was passed to godot
        ##
    
        if (! param($gconst::TITLE_FIELD)) {

            my @bib_circ_arr;
            my $title_from_holdings;
            
            foreach my $u (keys %{$holdings_hash_ref}) {

                foreach my $bib_circ_hash_ref (@{${$holdings_hash_ref}{$u}}) {

                    push(@bib_circ_arr, $bib_circ_hash_ref);
                }
            }

            if (@bib_circ_arr) {

                $title_from_holdings = &catalogue::get_title_from_bib_circ(\@bib_circ_arr);                    
            }
      
            param(-name=>$gconst::TITLE_FIELD, '-values'=>[$title_from_holdings]);            
            $citation->parsed('TITLE', $title_from_holdings);
        }

        $page->search_messages($para_server_msg_string . $main_msg_string);

        $session->var($HAS_GET_LINK_FIELD,      $page->has_get_link);
        $session->var($HAS_REQUEST_LINK_FIELD,  $page->has_request_link);
        $session->var($HAS_CHECK_LINK_FIELD,    $page->has_check_link);
        $session->var($HAS_AUTO_REQ_LINK_FIELD, $page->has_auto_req_link);
        $session->var($HAS_HIDDEN_RECORD_FIELD, $page->has_hidden_record);

        ##
        ## -no point displaying the main holdings screen if all that is on it is an [ILL] button
        ##

        ##
        ## (16-jun-2006 kl) 
        ##
        ## Add another condition so that the holdings screen is only skipped if
        ## if we have just searched for the maximum '$search_group'. Otherwise not all
        ## configured sites will get searched.
        ##
        ## $max_search_group may be one greater than any site has been assigned, so check whether we 
        ## have any sites in this group.  If not, assume that there are no more sites to search, for
        ## the purpose of the logic below.
        ## 
        my $max_search_group = ($citation->is_journal) ? $config->max_search_group : $config->max_search_group_non_journal; 

        my @sites_to_search;
        &get_rank_list($config, \@sites_to_search, $citation, $max_search_group) || &glib::send_admin_email("$0: Unable to get rank list ($user).");             
        my $no_more_sites_to_search = ($search_group eq $max_search_group) || 
                                      (($search_group eq ($max_search_group-1)) && (! scalar(@sites_to_search)));                     
        
        if (($config->skip_main_holdings_screen_if_no_holdings) && 
            (defined $tab_comp_hash{$GODOT::Page::ILL_FORM_COMP}) && 
            (! $hold_found) && 
            (! $page->has_get_link) && 
            (! $num_cat_link) &&
            ($no_more_sites_to_search)) {

            ##
            ## -leave third parameter (warning type) null as it currently only gets set
            ##  when holdings are found, which will not be the case if you are here...
            ##
            ## -also leave fifth parameter null as it is the request type for a potential
            ##  lender, of which we will not have any if we are here...
            ##

            my ($action, $next_action) = &get_act_for_req_button($config, $check_citation_result, '', $citation, '');
            my($param_str) = "$user=$REQUEST_NEW";

            if ($next_action ne '')     { $param_str .= "=$next_action";                    }

	    param(-name=>$ACTION_PARAM_FIELD, '-values'=>[$param_str]);
            $cgi->skipped_main_no_holdings($TRUE);
            return $action;
        }
        else {

            $page->records(&citation_manager_comp());           
        }

    }
    else  {

        $page->messages([$message]);
        $cgi->new_screen('error_screen');       
    }


    report_time_location;


    return $TRUE;
}


sub article_form_screen {
    my($cgi, $page, $config, $citation) = @_;

    my $action                = $cgi->action;
    my $new_screen            = $cgi->new_screen;
    my $session               = $cgi->session;
    my $check_citation_result = $cgi->citation_result;
    my $message               = $cgi->citation_message;
 
    #### foreach my $site (param($HOLDINGS_SITE_FIELD)) { debug $site; } 
       
    my $instructions = new GODOT::PageElem::Instructions;
    $instructions->skipped_main_no_holdings($cgi->skipped_main_no_holdings);
    $instructions->skipped_main_auto_req($cgi->skipped_main_auto_req);

    if (param($ART_FORM_ONCE_THRU_FIELD)) {
        if ($check_citation_result eq $parse::CITN_NEED_ARTICLE_INFO) { 
             $page->messages([(naws($message)) ? $message : "Please fill in more information."]); 
        }
    }

    param(-name=>$ART_FORM_ONCE_THRU_FIELD, '-values'=>[$TRUE]);                

    my $button = new GODOT::PageElem::Button;

    $button->label('Continue');
    $button->action(&get_act_for_art_form_button($config, $citation));
    $button->param('=' . param($ACTION_PARAM_FIELD));   
    $page->buttons([$button]);

    $instructions->back_to_dbase(&back_to_database_url(param($BACK_URL_FIELD), $citation));
    $page->instructions($instructions);

    $page->citation_is_complete(($check_citation_result eq $parse::CITN_SUCCESS) ? $TRUE : $FALSE);
    
    return $TRUE;
}


sub catalogue_screen {
    my($cgi, $page, $config, $citation) = @_;

    my $action = $cgi->action;
    my $new_screen = $cgi->new_screen;
    my $session = $cgi->session;

    my(%tab_comp_hash, %citation);
    my($lender, $check_citation_result, $dummy);

    my $user = $config->site->key;

    ## 
    ## -from cat_scr we were not getting article input screen for journals found in 
    ##  item databases (ex. UBC), so added &process_citation(...) logic below
    ##

    foreach (@gconst::CITN_ARR) { $citation{$_} = param($_); }

    $check_citation_result = &process_citation($citation, '', \%citation, \$dummy, $parse::CITN_CHECK_FOR_REQ);  

    $lender = param($hold_tab::ACTION_PARAM_FIELD);

    $tab_comp_hash{$GODOT::Page::INSTRUCTIONS_COMP} = '';
 
    &fill_other_coll_comp(\%tab_comp_hash);

    $tab_comp_hash{$GODOT::Page::CITATION_COMP}   = ''; 

    $tab_comp_hash{$GODOT::Page::HOLDINGS_RESULT_COMP} = [$lender];                                                              
    
    my($dbase) = param($DBASE_FIELD);     
    
    my $no_ill_form_comp = $TRUE;
    my $no_auto_req_comp = $TRUE;

    ##
    ## !!!!!!!!!!!!! temporary dummy values only -- needs to be changed !!!!!!!!!!!!!!!!!!!
    ##

    my $holdings_hash_ref = {};
    my $search_group = $session->var($SEARCH_GROUP_FIELD);
    my $scrno = '';


    my($main_msg_string,
       $para_server_msg_string,
       $table_string,
       $hold_found,
       $num_cat_link)      = &print_hold_tab($cgi, 
                                             $action, 
                                             $new_screen, 
                                             $citation,
                                             $config,
                                             $page, 
                                             $FALSE,
                                             $FALSE,
                                             $holdings_hash_ref, 
                                             \%tab_comp_hash, 
                                             $dbase, 
                                             $check_citation_result,
                                             {},
                                             $no_ill_form_comp,
                                             $no_auto_req_comp, 
                                             $search_group,
                                             $scrno);


    $page->search_messages($para_server_msg_string . $main_msg_string);


    #### debug "------------------catalogue_screen page object-----------------";
    #### debug Dumper($page);
    #### debug "---------------------------------------------------------------";

    return $TRUE;
}

##
## -link to catalogue system web screen - diff for ISSN,  ISBN  ??? also try title ???? book, journal
##
sub catalogue_interface_screen {
    my($cgi, $page, $config, $citation) = @_;

    my $action = $cgi->action;
    my $new_screen = $cgi->new_screen;
    my $session = $cgi->session;

    my(%tab_comp_hash, %queue_hash);

    my $lender  = param($gconst::ACTION_PARAM_FIELD);
    my $reqtype = param($gconst::REQTYPE_FIELD);
    my $dbase   = param($gconst::DBASE_FIELD);

    my $live_source = $TRUE;
    my $res = $FALSE;

    require para;

    my $is_bccampus = (defined $page->local) ? $page->local->is_bccampus : $FALSE;

    use GODOT::CatalogueHoldings::Source;
    #### my %source_info = GODOT::CatalogueHoldings::Source->source_info;

    my @sources_to_try_arr = GODOT::CatalogueHoldings::Source->sources_to_try([$lender], $citation, $live_source); 
    unless (scalar(@sources_to_try_arr) == 1) { 
        debug "one and only one source should be returned for lender ($lender)"
    }

    my $source_to_try = $sources_to_try_arr[0];

    my $source = $source_to_try->source;
    
    my($query, $waitscr_msg, $main_msg) = &para::queue($para::GET_CATALOGUE_URL_CMD,
                                                       $config,
                                                       $source,
                                                       $citation,
                                                       '',
                                                       $dbase,
                                                       '',
                                                       $is_bccampus,
                                                       \%queue_hash, 
                                                       $cgi->config_cache);           
    my @cat_url_arr;

    my($para_server_res, $para_server_msg_string) = &para::run(\%queue_hash,
                                                               [$query],
                                                               $config,
                                                               $GODOT::Config::PARA_SERVER_TIMEOUT,
                                                               $FALSE); 

    if ($para_server_res) {

        my $parallel = &para::from_queue(\%queue_hash, $query);

        if ((defined $parallel) && (ref($parallel->data) eq 'ARRAY')) {
	    @cat_url_arr = @{ $parallel->data };
            $res = $TRUE;
        }
    }

    #### foreach my $u (@cat_url_arr) { debug "cat_url:  $u"; }

    my $cat_url =  shift @cat_url_arr; 

    if (aws($cat_url))  { $res = $FALSE; }

    if ($res) {
        $cgi->redirect($cat_url);
    }
    else {
        $page->messages(["Information on recent holdings is currently not available."]);
        $cgi->new_screen('error_screen');       
    }

    return $TRUE;
}


sub warning_screen {
    my($cgi, $page, $config, $citation) = @_;

    my $action         = $cgi->action;
    my $new_screen     = $cgi->new_screen;
    my $session        = $cgi->session;

    my($button_name, $button_text, $clean_title, $lender, $msg_req_type, $warning_type, $next_action, $warning_msg);

    my $instructions = new GODOT::PageElem::Instructions;
    $instructions->skipped_main_no_holdings($cgi->skipped_main_no_holdings);
    $instructions->skipped_main_auto_req($cgi->skipped_main_auto_req);


    ##
    ## -get warning type
    ##

    ($lender, $msg_req_type, $warning_type, $next_action) = split(/=/, param($hold_tab::ACTION_PARAM_FIELD));

    ##
    ## Do sanity check here. If any of these are blank we have problems....
    ##

    if (aws($lender) || aws($msg_req_type) || aws($warning_type) || aws($next_action))  {

        &glib::send_admin_email("$0: Unexpected warning screen action parameter values ($lender - $msg_req_type - $warning_type");  
        return $FALSE;
    } 

    $page->your_library_has_warning(($warning_type eq $YOUR_BRANCH_HAS_WARNING_TYPE) ? $TRUE : $FALSE);

    ##
    ## -pass ILL request parameters along minus the warning type
    ##

    my $button = new GODOT::PageElem::Button;
    $button->label('Continue');
    $button->action($next_action);
    $button->param("=$lender=$msg_req_type");   
    $page->buttons([$button]);

    $instructions->back_to_dbase(&back_to_database_url(param($BACK_URL_FIELD), $citation));
    $page->instructions($instructions);

    return $TRUE;
}


##
## -displays an information screen to the user (eg. 'please request via some other system') 
## -no 'continue' button is provided
##
sub request_info_screen {
    my($cgi, $page, $config, $citation) = @_;

    my $action         = $cgi->action;
    my $new_screen     = $cgi->new_screen;
    my $session        = $cgi->session;

    my($button_name, $clean_title, $warning_type, $next_action, $msg);

    my $instructions = new GODOT::PageElem::Instructions;
    $instructions->skipped_main_no_holdings($cgi->skipped_main_no_holdings);
    $instructions->skipped_main_auto_req($cgi->skipped_main_auto_req);

    ##
    ## -get request type
    ##

    my ($lender, $msg_req_type) = split(/=/, param($hold_tab::ACTION_PARAM_FIELD));

    ##
    ## Do sanity check here. If any of these are blank we have problems....
    ##

    if (&GODOT::String::aws($lender) || &GODOT::String::aws($msg_req_type))  {

        &glib::send_admin_email("$0: Unexpected request information screen action parameter values ($lender - $msg_req_type");  
        return $FALSE;
    } 

    $instructions->back_to_dbase(&back_to_database_url(param($BACK_URL_FIELD), $citation));
    $page->instructions($instructions);

    return $TRUE;
}

sub password_screen {
    my($cgi, $page, $config, $citation) = @_;

    my $action         = $cgi->action;
    my $new_screen     = $cgi->new_screen;
    my $session        = $cgi->session;

    my $instructions = new GODOT::PageElem::Instructions;
    $instructions->skipped_main_no_holdings($cgi->skipped_main_no_holdings);
    $instructions->skipped_main_auto_req($cgi->skipped_main_auto_req);


    unless ($citation->get_dbase()->is_blank_dbase()) {
        $instructions->back_to_dbase(&back_to_database_url(param($BACK_URL_FIELD), $citation));
    }

    $page->instructions($instructions);
                
    use GODOT::PageElem::FormInput;
    my $elem = new GODOT::PageElem::FormInput;
    $elem->name($PASSWORD_FIELD);
    $elem->type('PASSWORD');
    $page->form_input([$elem]);

    my $button = new GODOT::PageElem::Button;
    $button->label('Continue');
    $button->action(&get_act_for_password_button($config, $citation->is_mono()));
    $button->param('=' . param($ACTION_PARAM_FIELD));   
    $page->buttons([$button]);
    
    return $TRUE;
}


sub check_patron_screen {
    my($cgi, $page, $config, $citation) = @_;

    my $action         = $cgi->action;
    my $new_screen     = $cgi->new_screen;
    my $session        = $cgi->session;

    my($button_name, $title, $clean_title, $error_msg);

    ##
    ## (11-apr-2000 kl) - before going any further, check whether requesting is behind a password 
    ##

    ##
    ## -if there is a password required then check that password that user entered is OK
    ## -set password, otherwise parameters won't be passed right below due to the list context
    ##

    my($password) = param($PASSWORD_FIELD);     

    if (! &ill_check_password($password, $config, $citation, \$error_msg))    {
        
         $page->messages([&GODOT::String::add_trailing_period($error_msg)]);                                     
         $cgi->new_screen('password_error_screen');
         return $TRUE;    
    }

    ##
    ## -need to check that we have all required citation info as this screen could have been called from
    ##  article input screen
    ##

    my $button = new GODOT::PageElem::Button;

    $button->action($REQ_FORM_ACT);
    $button->param('=' . param($ACTION_PARAM_FIELD));                       ## -pass ILL request parameters along
    $button->label($REQ_FORM_ACT);
    $page->buttons([$button]); 

    my $instructions = new GODOT::PageElem::Instructions;
    $instructions->skipped_main_no_holdings($cgi->skipped_main_no_holdings);
    $instructions->skipped_main_auto_req($cgi->skipped_main_auto_req);


    if (! $citation->get_dbase()->is_blank_dbase()) {      
        $instructions->back_to_dbase(&back_to_database_url(param($BACK_URL_FIELD), $citation));
    }

    $page->instructions($instructions);
 
    return $TRUE;
}

sub request_screen {
	my($cgi, $page, $config, $citation) = @_;

	my $action         = $cgi->action;
	my $new_screen     = $cgi->new_screen;
	my $session        = $cgi->session;

        ##
        ## !!! we are now running this with mod_perl so these need to be initialized as they are globals !!!
        ##

	use vars qw(%ill_fields);
	
        %ill_fields      = ();


        ##
	## Copy data to expected fields
        ##    

        my(%patron_hash);
        my($error_msg, $result);
 
	if ( param('ILL_SUBMIT') ) { $ill_fields{'ILL_SUBMIT'}       = param('ILL_SUBMIT'); }
	if ( param($BRANCH_FIELD) ) { $ill_fields{'hold_tab_branch'} = param($BRANCH_FIELD); }

	if ( param($DBASE_FIELD))           { $ill_fields{'hold_tab_dbase'}  = param($DBASE_FIELD); }
	if ( param($USERNO_FIELD))          { $ill_fields{'hold_tab_userno'} = param($USERNO_FIELD); }
	if ( param($SCREEN_FIELD))          { $ill_fields{$SCREEN_FIELD}     = param($SCREEN_FIELD); }
	if ( param($PATR_CHECKED_OK_FIELD)) { $ill_fields{$PATR_CHECKED_OK_FIELD} = param($PATR_CHECKED_OK_FIELD); }

        ##
        ## (01-mar-2001 kl) - added as part of adding OpenURL logic
        ##

	if ( param($SYNTAX_FIELD) )         { $ill_fields{$SYNTAX_FIELD}      = param($SYNTAX_FIELD); }
	if ( param($DBASE_TYPE_FIELD) )     { $ill_fields{$DBASE_TYPE_FIELD}  = param($DBASE_TYPE_FIELD); }
	if ( param($DBASE_LOCAL_FIELD) )    { $ill_fields{$DBASE_LOCAL_FIELD} = param($DBASE_LOCAL_FIELD); }

        ##
        ## -change value from array to scalar as CGI.pm is not used in this part of the code
        ##
        ## !!!! -do not change format with regards to using space as delimiters as RSS 'NextPartners' !!!!
        ## !!!!  comma logic needs the spaces                                                         !!!!
        ##

        if (param($HOLDINGS_SITE_FIELD))  {
            $ill_fields{$HOLDINGS_SITE_FIELD} = join(' ', param($HOLDINGS_SITE_FIELD) );
        }


        #### debug "*** ", location, " - HOLDINGS_SITE_FIELD:  ", $ill_fields{$HOLDINGS_SITE_FIELD};


        # moved HTTP_REFERER logic to main_hold_scr so that it would get URL of database CGI instead this one (kl)

	if (param($BACK_URL_FIELD)) 
	{ 
		$ill_fields{'hold_tab_back_url'} = param($BACK_URL_FIELD); 
	}
	
	$ill_fields{'hold_tab_lender'} = param('hold_tab_lender');

	$ill_fields{'hold_tab_msg_req_type'} = param('hold_tab_msg_req_type');

	if (param($hold_tab::ACTION_PARAM_FIELD) && $ill_fields{'hold_tab_lender'} eq '')
	{
		( $ill_fields{'hold_tab_lender'}, 
                  $ill_fields{'hold_tab_msg_req_type'}) = split(/=/, param($hold_tab::ACTION_PARAM_FIELD));
	}


        if (aws($ill_fields{'hold_tab_msg_req_type'})) { &glib::send_admin_email("$0: blank hold_tab_msg_req_type"); }

        ##
        ## (13-feb-1998 kl) - give up trying to pass all info about lending site in CGI submit 'NAME' string
        ##                    as over time we are going to need more and more lending site info 
        ##                  - makes more sense to simply do call to users database - if this turns out 
        ##                    to be a performance problem we can re-think.
        ## 

        my $lender_config = GODOTConfig::Cache->configuration_from_cache($ill_fields{'hold_tab_lender'});

        unless (defined $lender_config) {

            my $tmp = "Unable to get user information ($ill_fields{'hold_tab_lender'}).";
            &glib::send_admin_email($tmp);
           
            $page->messages([$tmp]);
            $cgi->new_screen('request_other_error_screen');

            return $TRUE;
        }

        ##-----------------------------------------------------------------------------------------------

        debug "1 ****>> $ill_fields{'hold_tab_lender'} -- $ill_fields{'hold_tab_msg_req_type'}\n";

        use GODOT::ILL::Request;
        my $request = GODOT::ILL::Request->dispatch($citation, {'site' => $config->name});

        ##
        ## -use scalar variable $patron_type, as otherwise there are problems with passing values to $request->type below
        ##
        my $patron_type = param('PATR_PATRON_TYPE_FIELD');

        $ill_fields{'hold_tab_msg_req_type'} = $request->type($ill_fields{'hold_tab_msg_req_type'}, 
                                                              $citation,
                                                              $patron_type, 
                                                              $ill_fields{'hold_tab_lender'});
 
        debug "2 ****>> $ill_fields{'hold_tab_lender'} -- $ill_fields{'hold_tab_msg_req_type'}\n";


        ##-----------------------------------------------------------------------------------------------

        ##
        ## -don't put this in @PATR_ARR because we don't want it printed out as a hidden field
        ##
        if ( param('PATR_PIN_FIELD') ) { $ill_fields{'PATR_PIN_FIELD'} = param('PATR_PIN_FIELD'); }          

	foreach (@PATR_ARR)
	{
		if ( defined param($_) && naws(param($_)) ) { $ill_fields{$_} = param($_); }
	}
	
	foreach (@gconst::CITN_ARR)
	{
		if ( defined param($_) && naws(param($_)) ) { $ill_fields{$_} = param($_); }
	}

        ##
        ## -replace call number with that deterimined from holdings for institution from which you are requesting
        ##

        my(%call_no_save_hash) = param($CALL_NO_SAVE_FIELD);

        ##
        ## -save only call number string for lending site
        ##

        if (defined  $call_no_save_hash{$ill_fields{'hold_tab_lender'}}) {      
            $ill_fields{$gconst::CALL_NO_FIELD} = $call_no_save_hash{$ill_fields{'hold_tab_lender'}};
        }

	#####################################################################
	# Begin execution logic
    
        if ($action eq $REQ_CANCEL_ACT)
	{
                $cgi->action($START_ACT);
                $cgi->new_screen('main_holdings_screen');   
                &main_holdings_screen($cgi, $page, $config, $citation);

	}
        elsif ($action eq $REQ_SEND_ACT) 
	{                                     
                $error_msg = &ill_verify_input($config, $citation);

		unless ($error_msg)     
		{
                        # added patron info cache logic (kl)

                        if (&cache_patron_info($config->ill_cache_patron_info, $ill_fields{$USERNO_FIELD}))
                        {
                                &ill_set_patron_cache;
                        }

			if ($config->use_request_confirmation_screen)
			{
				&request_confirmation_screen($cgi, $page, $config, $citation);
			}
			else
			{
				&ill_process_request($cgi, $page, $session, $config, $lender_config, $citation);  
			}
		}
		else
		{
   		        $cgi->error_message($error_msg);
			&request_input_error_screen($cgi, $page, $config, $citation);
		}
	}
        elsif ($action eq $REQ_ACCEPT_ACT) 	
	{
		&ill_process_request($cgi, $page, $session, $config, $lender_config, $citation);
	}
	else
	{
                $result = $FALSE;

                #
                # -added patron cache file logic from spmail (kl)
                #

                if (&cache_patron_info($config->ill_cache_patron_info, $ill_fields{$USERNO_FIELD})) 
                {
                        $result = &ill_get_patron_cache;
                }

                if (! $result) {

                    ##
                    ## -set password, otherwise parameters won't be passed right below
                    ## -reason is that in a list context a non-existent param() will return an empty
                    ##  list instead of ''
                    ##

                    my($password) = param($PASSWORD_FIELD);     

                    if (! &ill_check_password($password, $config, $citation, \$error_msg))    {

                       $page->messages([&GODOT::String::add_trailing_period($error_msg)]);                                     
                       $cgi->new_screen('password_error_screen');
                       goto _end_request_scr;    
                    }

                    ##
                    ## (14-jul-1999) - changed so that modified ID is carried through to next step
                    ##

                    if (naws($config->patr_library_id_def)) {  

                        $ill_fields{'PATR_LIBRARY_ID_FIELD'} = $config->patr_library_id_def . $ill_fields{'PATR_LIBRARY_ID_FIELD'};
                    }

                    if ($ill_fields{$PATR_CHECKED_OK_FIELD}) {		        

                        ##
                        ## (30-may-2004 kl) - will never get here -- see same date below 
                        ##
                    }
                    elsif (&ill_get_patron_record('', 
                                                  $ill_fields{'PATR_LIBRARY_ID_FIELD'}, 
                                                  $ill_fields{'PATR_PIN_FIELD'},
                                                  $config, 
                                                  $citation,
                                                  \$error_msg)) {

                        ##
                        ## (30-may-2004 kl) 
                        ##
                        #### $ill_fields{$PATR_CHECKED_OK_FIELD} = $TRUE;
                    }
                    else {

                        $cgi->new_screen('check_patron_error_screen');
                        $page->messages([&GODOT::String::add_trailing_period($error_msg)]);
                        goto _end_request_scr;                
                    }
                }             

                ##
                ## (31-aug-2000 kl) - is patron allowed to submit an ILL request with no holdings attached?
                ##

                if ($ill_fields{'hold_tab_msg_req_type'} eq $REQUEST_NEW) { 

                    my $irf_msg = $config->ill_req_form_message($ill_fields{'PATR_PATRON_TYPE_FIELD'});

                    if (defined $irf_msg) {             
                    
                        ##
                        ## -screen warning users that they are not allowed to submit an ILL request for which no holdings have
                        ##  been found
                        ##

                        $page->messages([($irf_msg ne '') ? $irf_msg : $ILL_REQ_FORM_LIMIT_MSG_DEFAULT_TEXT]);
                        $cgi->new_screen('permission_denied_screen');

                        goto _end_request_scr;  
                    }
                }

                &request_form_screen($cgi, $page, $config, $citation, $lender_config);

	}
	
_end_request_scr:

        
    return $TRUE;
}

sub request_form_screen {
    my($cgi, $page, $config, $citation, $lender_config) = @_;

    my $action = $cgi->action;
    my $new_screen = $cgi->new_screen;
    my $session = $cgi->session;

    my($label_width) = 40;                                            ## -percentage 
    my($patron_info_from_patron_api, $password_for_mono);

    $cgi->new_screen('request_form_screen');

    ##---------------------------------------------------------------------------------------
    ##
    ## first three param are <patron name>, <patron lib no> and <patron pin no>
    ##

    use GODOT::Patron::API;
    my $patron_api = GODOT::Patron::API->dispatch({'site' => $config->name, 'api'  => $config->patron_api_type},
                                                  $config->use_patron_api, 
                                                  $config->patron_api_host, 
                                                  $config->zhost,
                                                  $config->patron_api_port,
                                                  $config->patron_need_pin,
                                                  $config->patr_fine_limit);

    $patron_info_from_patron_api = $patron_api->available;

    $page->ill_request_type($ill_fields{'hold_tab_msg_req_type'});

    my $instructions = new GODOT::PageElem::Instructions;
         
    foreach my $field (@PATR_ARR) {

        my $map_field = $PATR_MAPPING{$field};

        my $field_status = $config->$map_field;  

        if (grep {$field_status eq $_} qw(R U)) {

            use GODOT::PageElem::FormInput;

            my $elem = new GODOT::PageElem::FormInput;

            if ($field eq 'PATR_LIBRARY_ID_FIELD') {

                ##
                ## (23-feb-2000 kl) - if we are doing patron authentication, then don't give user a 
                ##                    chance to change library card number at this point
                ##

                if ($patron_info_from_patron_api) {
       
                    param(-name=>'PATR_LIBRARY_ID_FIELD', '-values'=>[$ill_fields{'PATR_LIBRARY_ID_FIELD'}]);     
                }
                else {

                    $elem->name($field);
                    $elem->value($ill_fields{$field});
                    $elem->type('PASSWORD');
                }            
            }
            elsif ($field eq 'PATR_PATRON_TYPE_FIELD') {



                ##
                ## -if no patron API is involved, then ignore PATR_PATRON_TYPE_EDIT_ALLOWED_FIELD and
                ##  PATR_PATRON_TYPE_DISP_FIELD settings
                ##

                my $allowed_to_edit     = (! $patron_info_from_patron_api) ? $TRUE : $FALSE;
                my $display_patron_type = (! $patron_info_from_patron_api) ? $TRUE : $FALSE;

                if  ($config->patr_patron_type_edit_allowed)  { 
                    $allowed_to_edit = $TRUE; 
                }

                if ($config->patr_patron_type_disp) {
                        $display_patron_type = $TRUE;  
                }

                if ($display_patron_type) {

		        $elem->name($field);

                        if ($allowed_to_edit) {
		
                                $elem->type('POPUP');
                                
                                my @choices;

		                foreach ($config->patron_types) {

                                    if (trim_beg_end($_) eq trim_beg_end($ill_fields{'PATR_PATRON_TYPE_FIELD'})){
                                        $elem->selected($_);
                                    }
                                    
                                    push @choices, $_;                                        
		                }
                              
                                $elem->choices([@choices]);		
                        }
                        else {
                                if (aws($ill_fields{'PATR_PATRON_TYPE_FIELD'})) {
                                    &glib::send_admin_email("Patron type is blank, but options are set to display and not edit.");
                                } 

                                $elem->type('DISPLAY_ONLY');
                                $elem->value($ill_fields{'PATR_PATRON_TYPE_FIELD'});

                                param(-name=>'PATR_PATRON_TYPE_FIELD', '-values'=>[$ill_fields{'PATR_PATRON_TYPE_FIELD'}]);     

                        }
                }
                else {
                        if ($allowed_to_edit) {
                                &glib::send_admin_email("Does not makes sense to allow editing, but not the display, of patron type.");
                        }

                        param(-name=>'PATR_PATRON_TYPE_FIELD', '-values'=>[$ill_fields{'PATR_PATRON_TYPE_FIELD'}]);     
                }                
            }
	    elsif ($field eq 'PATR_DEPARTMENT_FIELD') {


		$elem->name($field);

                ##
                ## (21-jan-2000 kl) - if a choice list has been configured, then use it otherwise just provide a text field
                ##                    for the patron to fill out
                ##
             
                if (scalar $config->departments) {

                    $elem->type('POPUP');

                    my @choices;
		
		    foreach ($config->departments) {

			$elem->selected($_) if ($_ eq $ill_fields{'PATR_DEPARTMENT_FIELD'});
                        push @choices, $_;
		    }
                    $elem->choices([@choices]);
                }
                else {
		    $elem->type('TEXTFIELD');
                    $elem->value($ill_fields{'PATR_DEPARTMENT_FIELD'});
                }
	    }	
	    elsif ($field eq 'PATR_RUSH_REQ_FIELD') {

		$elem->name($field);
                $elem->type('RADIO');
                $elem->choices({'Yes' => 'Y', 'No' => 'N' });            

		if ($ill_fields{'PATR_RUSH_REQ_FIELD'} eq "Y") { $elem->selected('Yes'); }
                else                                           { $elem->selected('No');  }
	    }
            elsif ($field eq 'PATR_PICKUP_FIELD') {
    
                use GODOT::Patron::Pickup;
                my $pickup = GODOT::Patron::Pickup->dispatch({'site' => $config->name});

                $pickup->lender_site($lender_config->name);

                my $patron = GODOT::Patron::Data->new;
                $patron->converted_2(\%ill_fields);
                $pickup->patron($patron);

                $pickup->citation($citation);
                $pickup->locations([$config->pickup_locations]);;
                $pickup->request_type($ill_fields{'hold_tab_msg_req_type'});

		$elem->name($field);
                $elem->type('POPUP');
                my @choices;
                
	        foreach ($pickup->available_locations) {

                    $elem->selected($_) if ($_ eq $ill_fields{'PATR_PICKUP_FIELD'});
                    push @choices, $_;
	        }

                $elem->choices([@choices]);

            }
    	    elsif ($field eq 'PATR_PAID_FIELD') {

		$elem->name($field);
                $elem->type('RADIO');
                my @choices;

		foreach ($config->payment_methods) {
                    $elem->selected($_) if ($_ eq $ill_fields{'PATR_PAID_FIELD'});
                    push @choices, $_; 
	        }

		$elem->choices([@choices]);
	    }	       
            else {
                $elem->name($field);
                $elem->value($ill_fields{$field});
                $elem->type('TEXTFIELD');
	    }

            $page->form_input([$elem]) if ($elem->name);     
        }
    }

    param(-name=>'hold_tab_lender', '-values'=>[$ill_fields{'hold_tab_lender'}]);
    param(-name=>$MSG_REQ_TYPE_FIELD, '-values'=>[$ill_fields{$MSG_REQ_TYPE_FIELD}]);
    param(-name=>$PATR_CHECKED_OK_FIELD, '-values'=>[$ill_fields{$PATR_CHECKED_OK_FIELD}]);
    param(-name=>$gconst::CALL_NO_FIELD, '-values'=>[$ill_fields{$gconst::CALL_NO_FIELD}]);

    $page->instructions($instructions);
    $instructions->skipped_main_no_holdings($cgi->skipped_main_no_holdings);
    $instructions->skipped_main_auto_req($cgi->skipped_main_auto_req);

    my $button = new GODOT::PageElem::Button;
    $button->action($REQ_SEND_ACT);
    $page->buttons([$button]);

    return $TRUE;

} 

sub request_input_error_screen {
    my($cgi, $page, $config, $citation) = @_;
   
    my $action = $cgi->action;
    my $new_screen = $cgi->new_screen;
    my $session = $cgi->session;

    $cgi->new_screen('request_input_error_screen');

    $page->messages([$cgi->error_message]);

    my $return_button = new GODOT::PageElem::Button;
    $return_button->action($REQ_RETURN_ACT);
    $return_button->label('Return to form');

    my $cancel_button = new GODOT::PageElem::Button;
    $cancel_button->action($REQ_CANCEL_ACT);
    $cancel_button->label('Cancel');

    $page->buttons([$return_button, $cancel_button]);

    return $TRUE;
} 

##################################################
sub request_confirmation_screen
{
    my($cgi, $page, $config, $citation) = @_;

    $cgi->new_screen('request_confirmation_screen');

    my $instructions = new GODOT::PageElem::Instructions;
    $instructions->back_to_dbase(&back_to_database_url($ill_fields{'hold_tab_back_url'}, $citation));

    $page->instructions($instructions);

    $page->ill_request_type($ill_fields{'hold_tab_msg_req_type'});
 
    my $accept_button = new GODOT::PageElem::Button;
    $accept_button->action($REQ_ACCEPT_ACT);
    $accept_button->label('Accept');

    my $cancel_button = new GODOT::PageElem::Button;
    $cancel_button->action($REQ_CANCEL_ACT);
    $cancel_button->label('Cancel');

    $page->buttons([$accept_button, $cancel_button]);

    return $TRUE;
}



sub request_acknowledgment_screen {
    my($cgi, $page, $config, $citation) = @_;

    $cgi->new_screen('request_acknowledgment_screen');

    my $instructions = new GODOT::PageElem::Instructions;
    $instructions->back_to_dbase(&back_to_database_url($ill_fields{'hold_tab_back_url'}, $citation));

    $page->instructions($instructions);

    $page->ill_request_type($ill_fields{'hold_tab_msg_req_type'});

    return $TRUE;
} 

##
## (13-jun-2004 kl) - is this used??
##

sub error_screen {
    my($cgi, $page, $config, $citation) = @_;

    &glib::send_admin_email("$0: " . $cgi->error_message);  

    $page->messages([$cgi->error_message]);

    return $TRUE;
}

##-------------------------------------------------------------------------
##                      end of screen functions
##--------------------------------------------------------------------------
##
## -decide what action should be assigned to button depending on whether: 
##
##      1. a warning message needs to be displayed
##      2. article information is required
##      3. a check of the patron record is required
##      4. ill form to be displayed
##

sub get_act_for_req_button {
    my($config, $check_citation_result, $warning_type, $citation, $request_type) = @_;

    my(%patron_hash);
    my($action, $next_action);


    require password;

    use GODOT::Patron::API;

    my $is_mono = $citation->is_mono;

    my $patron_api = GODOT::Patron::API->dispatch({'site' => $config->name, 'api'  => $config->patron_api_type},
                                                  $config->use_patron_api, 
                                                  $config->patron_api_host, 
                                                  $config->zhost,
                                                  $config->patron_api_port,
                                                  $config->patron_need_pin,
                                                  $config->patr_fine_limit);

    ##
    ## -possibilities for action are:  $ART_FORM_ACT, 
    ##                                 $CHECK_PATR_ACT, 
    ##                                 $PASSWORD_ACT, 
    ##                                 $REQ_FORM_ACT, 
    ##                                 $WARNING_ACT, 
    ##                                 $REQ_INFO_ACT 
    ##
    

    if ($request_type eq $REQUEST_INFO) {
        $action = $REQ_INFO_ACT; 
    }
    ##
    ## -is article information needed?
    ##
    elsif ($check_citation_result eq $parse::CITN_NEED_ARTICLE_INFO) { 
        $action = $ART_FORM_ACT; 
    }
    ##
    ## (20-jul-1999 kl) - don't prompt again for library card number, if we already have a cache for this user 
    ##
    elsif (&ill_get_patron_cache()) {
        $action = $REQ_FORM_ACT;    
    }
    elsif (&password::use_password($config, $citation)) {
        $action = $PASSWORD_ACT;
    }
    ##
    ## first three param are <patron name>, <patron lib no> and <patron pin no>
    ##
    elsif ($patron_api->available) {
        $action = $CHECK_PATR_ACT;
    }
    else {      
        $action = $REQ_FORM_ACT;
    }
    
    ##
    ## -is some sort of warning message required before we continue on with request process?
    ##

    if ($warning_type ne '') { 
        $next_action = $action;                ## -save 'next' action for use with 'continue' button on warning screen
        $action =  $WARNING_ACT; 
    }

    return ($action, $next_action);            ## -remember to not add any more lists to this return statement
}


sub get_act_for_art_form_button {
    my($config, $citation) = @_;

    my %patron_hash;
    my $action;

    my $is_mono = $citation->is_mono;

    require password;

    use GODOT::Patron::API;


    my $patron_api = GODOT::Patron::API->dispatch({'site' => $config->name, 'api'  => $config->patron_api_type},
                                                  $config->use_patron_api, 
                                                  $config->patron_api_host, 
                                                  $config->zhost,
                                                  $config->patron_api_port,
                                                  $config->patron_need_pin,
                                                  $config->patr_fine_limit);

    ##
    ## first three param for get_patron are <patron name>, <patron lib no> and <patron pin no>
    ##

    ##
    ## (20-jul-1999 kl) - don't prompt again for library card number, if we already have a cache for this user 
    ##
    
    if (&ill_get_patron_cache()) {
        $action = $REQ_FORM_ACT;    
    }
    elsif (&password::use_password($config, $citation)) {
        $action = $PASSWORD_ACT;
    }
    elsif ($patron_api->available)  {

        $action = $CHECK_PATR_ACT;
    }
    else {      
        $action = $REQ_FORM_ACT;
    }

    return $action;
}


sub get_act_for_password_button {
    my($config, $is_mono) = @_;

    use GODOT::Patron::API;

    my $patron_api = GODOT::Patron::API->dispatch({'site' => $config->name, 'api'  => $config->patron_api_type},
                                                  $config->use_patron_api, 
                                                  $config->patron_api_host, 
                                                  $config->zhost,
                                                  $config->patron_api_port,
                                                  $config->patron_need_pin,
                                                  $config->patr_fine_limit);

    return ($patron_api->available) ? $CHECK_PATR_ACT : $REQ_FORM_ACT;

}

##--------------------------------------------------------------------------------------
##                          holdings-table
##--------------------------------------------------------------------------------------
##
## (03-nov-1998 kl) - now returns $TRUE/$FALSE for success/failure
##
sub print_hold_tab  {
    my($cgi, 
       $action, 
       $screen, 
       $citation, 
       $config, 
       $page, 
       $search_all_sources, 
       $show_all_holdings, 
       $holdings_hash_ref,
       $tab_comp_hash_ref, 
       $dbase, 
       $check_citation_result, 
       $link_bib_hash_ref, 
       $no_ill_form_comp, 
       $no_auto_req_comp, 
       $search_group, 
       $scrno) = @_;

    my(%table_request_hash, %cat_form_arr_hash, %ill_info_hash, 
       %pre_matched_res_hash, %non_matched_res_hash, %warning_type_hash, %bib_hash, %queue_hash, 
       %link_from_cat_holdings_hash, %link_from_cat_hash, %tab_comp_queue_hash);

    my(@table_jrdb_arr, @union_serials_arr);

    my($lender_arr_ref, $pre_matched_ref, $non_matched_ref);              

    my($user, $hold_found, $link_from_cat_found, $link_found, $res, $docs, $lender, $on_fly_match, $issn, $title, 
       $isbn, $reqtype, $start_time, $lender_arr_len, 
       $non_matched_live_source, $pre_matched_source, $pre_matched_live_source,
       $instructions_row, $link_template_row, 
       $has_get_link, $num_cat_link, $elapsed, $live_source, 
       $link_row_hidden, $link_from_cat_row_hidden, 
       $waitscr_msg, $main_msg, $print_waitscr,
       $para_comp, $time_count, $main_msg_string);
    
    require para;

    $start_time = time;

    $on_fly_match = $FALSE;

    $user = $config->name;

    $reqtype = param($gconst::REQTYPE_FIELD);

    $issn    = param($gconst::ISSN_FIELD);
    $isbn    = param($gconst::ISBN_FIELD);  

    $title   = param($gconst::TITLE_FIELD);

    $live_source = ($screen eq $CAT_SCR);                 ## -set to true/false

    $hold_found = $FALSE;

    my $catalogue_holdings = GODOT::CatalogueHoldings->dispatch({'site' => $user});

    $para_comp = ((defined ${$tab_comp_hash_ref}{$GODOT::Page::LINK_FROM_CAT_COMP}) ||
                  (defined ${$tab_comp_hash_ref}{$GODOT::Page::LINK_COMP})          ||
                  (defined ${$tab_comp_hash_ref}{$GODOT::Page::HOLDINGS_RESULT_COMP}))  ? $TRUE : $FALSE;

    $print_waitscr = $para_comp;

    #### report_time_location;
    #### my @holdings_details = GODOTConfig::DB::Sites->holdings_details;
    #### report_time_location;

    #### my $holdings_details;
    #### foreach my $item (@holdings_details) {
    ####    $holdings_details->{$item->{'name'}} = $item;
    #### }
    
    #### !!!!!!!!!!!!!!!! debug !!!!!!!!!!!!!!!

    unless ($config->use_javascript) { $print_waitscr = $FALSE; } 
    if (grep {remote_host() eq $_} qw(stalefish.lib.sfu.ca godot.lib.sfu.ca)) { $print_waitscr = $TRUE; }
                                    
    ##
    ## -start javascript search progress window
    ##

    if ($print_waitscr) { 
        print STDOUT header; 
        $cgi->header_printed($TRUE);           ## -so we don't print HTTP header twice
    }

    print STDOUT &waitscr($print_waitscr,
                          "\n\n<script language=JavaScript>\n" .
                          "waitscr = window.open(\"\", \"waitscreen\", \"scrollbars=1,width=400,height=600\");\n" .
                          "waitscr.document.writeln('<HTML><HEAD><TITLE> Please Wait...</TITLE></HEAD>');\n" .
                          "waitscr.document.writeln('<BODY BGCOLOR=white><BR><P><CENTER><P><H2>Working...</H2></CENTER>');\n" . 
                          "</script>\n");   
    


    my(%waitscr_hash);

    my $is_bccampus = (defined $page->local) ? $page->local->is_bccampus : $FALSE;

    ##-----------------------------------------------------
    ## -phase 1 - queue up queries to be done in parallel
    ##-----------------------------------------------------

    if (defined ${$tab_comp_hash_ref}{$GODOT::Page::LINK_COMP}) {

        
        my($waitscr_msg, $main_msg);

        ##
        ## -query CUFTS
        ##

        ## 
        ## (28-oct-2003 kl) - removed site restriction so easier to move sites over to CUFTS
        ## (18-sep-2003 kl) - added query CUFTS for SFU
        ##
        my ($cufts_query);

        ($cufts_query, $waitscr_msg, $main_msg) = &para::queue(
                                                         $para::GET_CUFTS_LINKS_CMD,
                                                         $config,
                                                         '',
                                                         $citation,
                                                         $gconst::SEARCH_FULLTEXT_TYPE,  
                                                         '',
                                                         '',
                                                         $is_bccampus,
                                                         \%queue_hash, 
                                                         $cgi->config_cache);           
        $waitscr_hash{$cufts_query} = $waitscr_msg;

        push(@{$tab_comp_queue_hash{$GODOT::Page::LINK_COMP}}, $cufts_query);        

    }


    use GODOT::CatalogueHoldings::Source;
    #### my %source_info = GODOT::CatalogueHoldings::Source->source_info;

    my @user_for_link_from_cat;

    if (defined ${$tab_comp_hash_ref}{$GODOT::Page::LINK_FROM_CAT_COMP}) {

        @user_for_link_from_cat = $catalogue_holdings->link_from_cat_sites($config->link_from_cat_name);

        foreach my $cat_link_user (@user_for_link_from_cat) {

	    report_time_location;

            my @link_sources_to_try_arr = GODOT::CatalogueHoldings::Source->sources_to_try([$cat_link_user], $citation, $TRUE);
            report_time_location;

            #### debug "(1)-------------------------------";
            #### debug Dumper(@link_sources_to_try_arr);
            #### debug "----------------------------------";
            
            foreach my $source_to_try (@link_sources_to_try_arr) { 
                       
                my $live_source = $source_to_try->source;

                if (aws($live_source)) { next; }

                my($query, $waitscr_msg, $main_msg) = &para::queue($para::GET_ON_FLY_HOLDINGS_CMD,
                                                                   $config,
                                                                   $live_source,    
                                                                   $citation,
                                                                   $gconst::SEARCH_LINK_TYPE,
                                                                   $TRUE,
                                                                   \@link_sources_to_try_arr,
                                                                   $is_bccampus,
                                                                   \%queue_hash, 
                                                                   $cgi->config_cache);           

                $waitscr_hash{$query} = $waitscr_msg;
    
                push(@{$tab_comp_queue_hash{$GODOT::Page::LINK_FROM_CAT_COMP}}, $query);
            }
        }        
    }

    ##---------------------------------------------------------------------------
    ##
    ## -$GODOT::Page::HOLDINGS_RESULT_COMP logic
    ##
    ## -get list of sites from which we want holdings....
    ##

    ## 
    ## (30-sep-2004 kl) - make a copy instead of a reference
    ##

    $lender_arr_ref = [];
    if (defined ${$tab_comp_hash_ref}{$GODOT::Page::HOLDINGS_RESULT_COMP}) {
        $lender_arr_ref = [@{${$tab_comp_hash_ref}{$GODOT::Page::HOLDINGS_RESULT_COMP}}];
    }

    if (defined $lender_arr_ref) { $lender_arr_len = scalar @{$lender_arr_ref}; }

    my %holdings_source_sites;
    my %holdings_sources_tried;
    
    report_time_location;

    ##
    ## -do processing required to determine any instructions at top of screen...
    ##
    ## -!!! need to change logic so differentiates better between an error and docs==0....
    ##
    if ($lender_arr_len) {   ## -if there are branches in lender array - ie. we want the HOLDINGS_RESULT_COMP component

        report_time_location;

        my @sources_to_try_arr = GODOT::CatalogueHoldings::Source->sources_to_try([@{$lender_arr_ref}], $citation, $live_source); 
        report_time_location;

        #### debug "(2)-------------------------------";
        #### debug Dumper(@sources_to_try_arr);
        #### debug "----------------------------------";

        foreach my $source_to_try (@sources_to_try_arr) {
            
            ##
            ## -logic for catalogue screen where we want a live source so we can get circ info
            ##

            my $source = $source_to_try->source;
            my $source_user = $source_to_try->site;

            ##
            ## -save <source> => [<site 1>, <site 2>, ...] so we can later determine for which sites
            ##  a holdings search has been done
            ##

            #### debug "adding site ($source_user) to list for source ($source)";

            push(@{$holdings_source_sites{$source}}, $source_user);  

            if (($non_matched_res_hash{$source} ne $TRIED_MATCH_STATUS) && (naws($source))) {


                my($query, $waitscr_msg, $main_msg) = &para::queue($para::GET_ON_FLY_HOLDINGS_CMD,  
                                                                   $config,
                                                                   $source,
                                                                   $citation,
                                                                   $gconst::SEARCH_HOLDINGS_TYPE,
                                                                   $live_source,
                                                                   \@sources_to_try_arr,
                                                                   $is_bccampus,
                                                                   \%queue_hash, 
                                                                   $cgi->config_cache);

                $waitscr_hash{$query} = $waitscr_msg;

                push(@{$tab_comp_queue_hash{$GODOT::Page::HOLDINGS_RESULT_COMP}}, $query);

                ##
                ## -so we do not have to try this source again  
                ##

                $non_matched_res_hash{$source} = $TRIED_MATCH_STATUS;   
            }

        }  ##- for each user in source list
    }


    ##----------------------------------------------------
    ## -phase 2 - do queries in parallel 
    ##---------------------------------------------------- 

    my($para_server_res, $num_holdings_query);

    ##
    ## (14-sep-2001 kl)
    ##

    my $para_server_msg_string;


    $page->user($user);
    $page->user_full_name($config->full_name);

    $page->remote_host(&remote_host());


    my $record_arr_ref;

    if ($para_comp) {

        ##
        ## -figure out which queries we want to run for our first pass
        ##
        
        my(@query_to_run_arr);
        my(@holdings_query_shift_arr);

        if (defined $tab_comp_queue_hash{$GODOT::Page::HOLDINGS_RESULT_COMP}) {
            @holdings_query_shift_arr = @{$tab_comp_queue_hash{$GODOT::Page::HOLDINGS_RESULT_COMP}};
        }

        if (defined $tab_comp_queue_hash{$GODOT::Page::LINK_COMP}) { 
            push(@query_to_run_arr, @{$tab_comp_queue_hash{$GODOT::Page::LINK_COMP}}); 
        }

        if (defined $tab_comp_queue_hash{$GODOT::Page::LINK_FROM_CAT_COMP}) { 
            push(@query_to_run_arr, @{$tab_comp_queue_hash{$GODOT::Page::LINK_FROM_CAT_COMP}}); 
        }

        for (1 .. $GODOT::Config::MAX_QUERY_IN_PARALLEL) {

            my($query) = shift @holdings_query_shift_arr;

            if ($query) { 
                push(@query_to_run_arr, $query); 
                $num_holdings_query++;

                $holdings_sources_tried{$queue_hash{$query}->source} = $TRUE;
            }
            else        { 
                last; 
            }
        }

        report_time_location;
        debug "before parallel....";

        ##
        ## -print out messages related to queries that are going to be run 
        ##

        foreach my $query (@query_to_run_arr) {
 
            print STDOUT &waitscr($print_waitscr, $waitscr_hash{$query}); 
        }

        my($num_para_cmd) = @query_to_run_arr;

        ($waitscr_msg, $main_msg) = &glib::searching_msg('', $gconst::SEARCH_MSG_RUNNING_PARA_TYPE, $config, [$num_para_cmd]);

        print STDOUT &waitscr($print_waitscr, $waitscr_msg);
        
        
	#### use Data::Dumper;
        #### debug "//////////////////////////////////////////////////////////////\n";
        #### debug Dumper(\%queue_hash);
	#### debug "//////////////////////////////////////////////////////////////\n";

        ##
        ## -if the parallel server query fails, then we must skip all steps that depend on the related data structures existing
        ##

        my $tmp_msg;

        ($para_server_res, $tmp_msg) =  &para::run(\%queue_hash, 
                                                   \@query_to_run_arr,
                                                   $config, 
                                                   $GODOT::Config::PARA_SERVER_TIMEOUT, 
                                                   $print_waitscr); 

        $para_server_msg_string .= $tmp_msg;

        #### debug "para_server_msg_string:  $para_server_msg_string";

        debug "after parallel....";
        report_time_location;


        ##----------------------------------------------------
        ## -phase 3 - process results of parallel queries
        ##----------------------------------------------------
        ##
        ## -- !!! need to pass back $res from parallel searching
        ##

        ##
        ## - process results of 'link from catalogue' queries
        ##

        if ($para_server_res && (defined ${$tab_comp_hash_ref}{$GODOT::Page::LINK_FROM_CAT_COMP})) {

   	    my %source_name_hash;

            foreach my $query (@{$tab_comp_queue_hash{$GODOT::Page::LINK_FROM_CAT_COMP}}) {
 
                my $parallel = &para::from_queue(\%queue_hash, $query);

                if ($parallel->reason) {
                    ($waitscr_msg, $main_msg) = &glib::searching_msg('', $parallel->reason, $config, [$parallel->source_name]);

                    print STDOUT &waitscr($print_waitscr, "<FONT COLOR=RED>$waitscr_msg</FONT>");

                    $main_msg_string .= "<FONT COLOR=RED>$main_msg</FONT>";
                }

                if ($parallel->result) {

                    my %data = %{ $parallel->data };

                    foreach (keys %data) {

                        if (defined $link_from_cat_holdings_hash{$_}) { 
                            &glib::send_admin_email("$0: Holdings already exist for $_."); 
                        }

                        $link_from_cat_holdings_hash{$_} = $data{$_};
                        $source_name_hash{$_} = $parallel->source_name;
                    }
                }
            }

            report_time_location;


            my($link_bib_circ_hash_ref);
            my($count);

            ##
            ## (14-nov-2003 kl) - quick fix for UVic -- also see other 14-nov-2003 fix above  
            ##

            foreach my $cat_link_user (@user_for_link_from_cat) {

                next unless defined($link_from_cat_holdings_hash{$cat_link_user});

                foreach $link_bib_circ_hash_ref (@{$link_from_cat_holdings_hash{$cat_link_user}}) {

                    $count++;

                    ##
                    ## -for now, we are just doing journals so 'html_incl_hash' and 'text_incl_hash' parameters 
                    ##  can be for journals only
                    ##

                    my($html_str, $text_str, $call_no_str, $bib_url_str) = &catalogue::fmt_bib_circ($link_bib_circ_hash_ref, 
                                                                                                    $reqtype, 
                                                                                                    $catalogue::SHORT_FMT);

                    foreach (split(/\035/, $bib_url_str)) {

                        my($text, $url) = split(/\036/, $_);

                        $text = trim_beg_end($text);
                        $url  = trim_beg_end($url);

                        if (defined $link_from_cat_hash{$url}) {

                            ##
                            ## -take the longest text, as it is probably the most meaningful
                            ##

                            if (length($text) > length($link_from_cat_hash{$url})) { 
                                $link_from_cat_hash{$url} = $text; 
                            }
                        }
                        else {
                            $link_from_cat_hash{$url} = $text;                        
                        }
                    }
                }
	    
                ($record_arr_ref, $num_cat_link, $link_from_cat_row_hidden) = 
                    &print_link_from_cat_row($screen, $config, $source_name_hash{$cat_link_user}, \%link_from_cat_hash);

                if (ref($record_arr_ref)) { $page->records($record_arr_ref); }

                if ($num_cat_link) { 
                    $link_from_cat_found = $TRUE; 
                    $page->has_get_link($TRUE);
                }                         
	    }            
        }
    
        report_time_location;

        ##
        ## - process results of holdings queries
        ##

        my %skip_msg_hash;
        my $done;

        ##
        ## (09-mar-2004 kl) - initialize num_branch_with_holdings
        ##

        my $num_branch_with_holdings = scalar (keys %{$holdings_hash_ref});


        ##
        ## (01-oct-2001 kl) - added logic to determine if there is a problem with this loop
        ##                    and also to put on the brakes.....
        ##

        
        my $loop_counter;
        my $loop_max = 20;
         
    
        for (1 .. $loop_max) {

            if (! $para_server_res) { 
                #### debug "search loop - left because of para_server_res problem"; 
                last; 
            }

            if ($done) { 
                #### debug "search loop - left because 'done'";
                last; 
            }         

            $loop_counter++;

            if ($loop_counter == $loop_max) {
		&glib::send_admin_email("$0: too many times through search loop");
                last;
            }

            if (defined $tab_comp_queue_hash{$GODOT::Page::HOLDINGS_RESULT_COMP})    {

                foreach my $query (@{$tab_comp_queue_hash{$GODOT::Page::HOLDINGS_RESULT_COMP}}) {

		    my $parallel = &para::from_queue(\%queue_hash, $query);

                    ##
                    ## -Don't print messages more than once
                    ##

                    if ($parallel->reason && (! $skip_msg_hash{$query})) {
                        ($waitscr_msg, $main_msg) = &glib::searching_msg('', $parallel->reason, $config, [$parallel->source_name]);
                        
                        print STDOUT &waitscr($print_waitscr, "<FONT COLOR=RED>$waitscr_msg</FONT>");
                        $main_msg_string .= "<FONT COLOR=RED>$main_msg</FONT>";
                    }

                    $skip_msg_hash{$query} = $TRUE;
                   
                    if ($parallel->result) {

                        $hold_found = $TRUE;  $on_fly_match = $TRUE;

                        my %data = %{ $parallel->data };
       
                        foreach (keys %data) {
                            
                            if (! defined ${$holdings_hash_ref}{$_}) { $num_branch_with_holdings++; }

                            ${$holdings_hash_ref}{$_} = $data{$_};
                        }

                    }  ## -for each user in source list

                } ## -foreach query
            

                #### debug "---------------------------------------------------------------";
                #### debug Dumper($holdings_hash_ref);
                #### debug "---------------------------------------------------------------";
                     
                if ((! $search_all_sources ) && ($num_branch_with_holdings >= $GODOT::Config::MIN_BRANCH_WITH_HOLDINGS)) { 

                    #### debug "search loop - done 1";
                    $done = $TRUE; 
                }
                else { 
            
                    ##
                    ## -if we haven't found enough holdings, do more queries in parallel
                    ##
                    ## -figure out which queries we want to run for the next pass
                    ##

		    @query_to_run_arr = ();       


                    for (1 .. $GODOT::Config::MAX_QUERY_IN_PARALLEL) {

                        my($query) = shift @holdings_query_shift_arr;

                        my $parallel = &para::from_queue(\%queue_hash, $query);

                        if ($query) { 
                            push(@query_to_run_arr, $query); 
                            $num_holdings_query++;

                            $holdings_sources_tried{$parallel->source} = $TRUE;
                        }
                        else { 
                            #### debug "search loop - left because no more query";
                            last; 
                        }
                    }
                           
                    if (@query_to_run_arr)  {

                        if (! $search_all_sources) {

	    		    ($waitscr_msg, $main_msg) = &glib::searching_msg('', 
                                                                       $gconst::SEARCH_MSG_MORE_HOLDINGS_SEARCHES_TYPE, 
                                                                       $config, 
                                                                       [$num_branch_with_holdings,
                                                                        $GODOT::Config::MIN_BRANCH_WITH_HOLDINGS]);
 
                            print STDOUT &waitscr($print_waitscr, $waitscr_msg);

		        }

                        report_time_location;
                        debug "before parallel....";

                        ##
                        ## -print out messages related to queries that are going to be run 
                        ##

                        foreach my $query (@query_to_run_arr) { 

                            print STDOUT &waitscr($print_waitscr, $waitscr_hash{$query}); 
                        }

                        my($num_para_cmd) = @query_to_run_arr;

                        ($waitscr_msg, $main_msg) = &glib::searching_msg('', 
                                                                   $gconst::SEARCH_MSG_RUNNING_PARA_TYPE, 
                                                                   $config,
                                                                   [$num_para_cmd]);

                        print STDOUT &waitscr($print_waitscr, $waitscr_msg);
        
                        ##
                        ## -if the parallel server query fails, then we must skip all steps that depend on 
                        ##  the related data structures existing
                        ##

	                $para_server_res = $FALSE;


                        ($para_server_res, $tmp_msg) = &para::run(\%queue_hash, 
                                                                  \@query_to_run_arr, 
                                                                  $config,
                                                                  $GODOT::Config::PARA_SERVER_TIMEOUT, 
                                                                  $print_waitscr); 

			$para_server_msg_string .= $tmp_msg;

                        if (! $para_server_res) {
                            #### debug "search loop - done 2";
                            $done = $TRUE;
                        }                       
 
                        debug "after parallel....";
                        report_time_location;
		    }
                    else {
                        #### debug "search loop - done 3";
                        $done = $TRUE;
                    }                    
                }
            }
        }
    }



    report_time_location;


    ##----------------------------------------------------
    ##
    ## (30-apr-1998 kl) -other collection (currently ERIC and Microlog fiche) logic
    ##
    if (defined ${$tab_comp_hash_ref}{$GODOT::Page::ERIC_COLL_COMP} || 
        defined ${$tab_comp_hash_ref}{$GODOT::Page::MLOG_COLL_COMP})  {

        $res = &get_other_coll($holdings_hash_ref, $config, $citation, $search_group, $cgi->config_cache);
        if ($res)   { $hold_found = $TRUE; }

    }

    ##
    ## -linking component
    ##

    if ($para_server_res && (defined ${$tab_comp_hash_ref}{$GODOT::Page::LINK_COMP})) {

        foreach my $query (@{$tab_comp_queue_hash{$GODOT::Page::LINK_COMP}}) {

            my $parallel = &para::from_queue(\%queue_hash, $query);
            
            if ($parallel->source_name eq $gconst::CUFTS_NAME) {

                use GODOT::CUFTS;

                my $cufts_search = $parallel->data;

                if ((defined $cufts_search) && ($cufts_search->result)) {

                    my $num_cufts_get_link;

                    ($record_arr_ref, $num_cufts_get_link) = &print_cufts_link_row($screen, $config, $cufts_search, $citation);

		    if (ref($record_arr_ref)) { $page->records($record_arr_ref); }

                    if ($num_cufts_get_link) { $link_found = $TRUE; }
                    
                    ##
                    ## -add/append to GODOTjake link info
                    ##
    
                    $page->has_get_link($num_cufts_get_link);
                }
                else {

                    my $error_message = (defined $cufts_search) ? $cufts_search->error_message : 'Error';
                    ($waitscr_msg, $main_msg) = &glib::searching_msg('', $error_message, $config, [$parallel->source_name]);

                    print STDOUT &waitscr($print_waitscr, "<FONT COLOR=RED>$waitscr_msg</FONT>"); 
                    $main_msg_string .=  "<FONT COLOR=RED>$main_msg</FONT>";             
                }  
	    }
        }        
    }

    if (defined ${$tab_comp_hash_ref}{$GODOT::Page::PREPRINT_COMP}) { 

        $record_arr_ref = &print_preprint_row($screen, $config);

        if (@{$record_arr_ref}) { 
           
            $page->has_get_link($TRUE); 

            if (ref($record_arr_ref)) {  $page->records($record_arr_ref); }
        }
    }

    report_time_location;

    my %auto_req_hash;

    if (defined ${$tab_comp_hash_ref}{$GODOT::Page::HOLDINGS_RESULT_COMP} || 
        defined ${$tab_comp_hash_ref}{$GODOT::Page::ERIC_COLL_COMP}       ||
        defined ${$tab_comp_hash_ref}{$GODOT::Page::MLOG_COLL_COMP})             {

        if ($hold_found) {

            unless (&get_table_info($user, 
                                    $citation, 
                                    $search_all_sources,
                                    $config, 
                                    $lender_arr_ref, 
                                    \%table_request_hash,
                                    \@table_jrdb_arr,
                                    \%ill_info_hash,
                                    $holdings_hash_ref, 
                                    \%warning_type_hash, 
                                    \%auto_req_hash, 
                                    $page->has_get_link,
                                    $search_group, 
                                    $cgi->config_cache))   {
                return $FALSE;
            }

            $elapsed = time - $start_time; 
   
            $start_time = time; 

            ##
            ## -cache this info for later use   
            ##
            param(-name=>$REQUEST_ALLOWED_FIELD, '-values'=>[%table_request_hash]); 
            param(-name=>$WARNING_TYPE_FIELD,    '-values'=>[%warning_type_hash]); 

            ##
            ## -if no contents in @{$lender_arr_ref} then there were no holdings for the branches that we wanted to display
            ##  
            if (! @{$lender_arr_ref}) { $hold_found = $FALSE }
        }
    }

    ##----------------------------------debug----------------------------------    
    # foreach my $key (sort keys %{$holdings_hash_ref}) {
    #    my $message;
    #    foreach my $bibcirc (@{$holdings_hash_ref->{$key}}) {
    #        foreach my $field (keys %{$bibcirc}) {
    #            $message .=  join('', "\n", $field, "\n", Dumper($bibcirc->{$field}));
    #        }
    #        $message .= "--------------------------------------------------------";        
    #    }        
    #    log_message_to_file(join('.', 'bibcirc', $key), $message);   
    # } 
    ##--------------------------------------------------------------------------

    report_time_location;

    ##------------------------------------------------------------------

    my $auto_req_show_all = $search_all_sources || $show_all_holdings;

    ##
    ## -change this to 'if $hold_found' only .... don't worry about contents of components hash ???
    ##
    if (defined ${$tab_comp_hash_ref}{$GODOT::Page::HOLDINGS_RESULT_COMP} || 
        defined ${$tab_comp_hash_ref}{$GODOT::Page::ERIC_COLL_COMP}       ||
        defined ${$tab_comp_hash_ref}{$GODOT::Page::MLOG_COLL_COMP})            {

        #### debug "hold_found:  $hold_found";

        if ($hold_found) {

            #### debug "no_auto_req_comp: $no_auto_req_comp";

            my ($has_auto_req_link, $has_hidden_record, $has_request_link, $has_check_link);

            ($record_arr_ref, 
             $has_request_link, 
             $has_check_link,
             $has_auto_req_link, 
             $has_hidden_record) = &print_result_row($cgi,
                                                     $action, 
                                                     $screen, 
                                                     $citation, 
                                                     \%table_request_hash, 
                                                     \%ill_info_hash, 
                                                     \@table_jrdb_arr,
                                                     $holdings_hash_ref,
                                                     \%warning_type_hash,
                                                     \%auto_req_hash,
                                                     $auto_req_show_all,
                                                     $config,               
                                                     $check_citation_result, 
                                                     $no_auto_req_comp); 

            $page->has_request_link($has_request_link);
            $page->has_check_link($has_check_link);

            $page->has_auto_req_link($has_auto_req_link);
            $page->has_hidden_record($has_hidden_record);

	    if (ref($record_arr_ref)) { $page->records($record_arr_ref); }

            #### debug "........................................."; 
	    #### debug Dumper($record_arr_ref);
            #### debug ".........................................";

            $elapsed = time - $start_time; 

            $start_time = time; 
        }
    }

    report_time_location;

    ##---------------------------------------------------------------
    ##
    ## (17-jun-2002 kl) - need to determine whether there will be any records that are
    ##                    to be displayed on the page for which there is likely 
    ##                    to be a need to know volume/issue information in order to 
    ##                    request or link to the item
    ##

    my $need_citation_info = $FALSE;

    if ($page->records_of_type($GODOT::Page::LINK_COMP, 
                               $GODOT::Page::LINK_FROM_CAT_COMP, 
                               $GODOT::Page::ERIC_COLL_COMP, 
                               $GODOT::Page::MLOG_COLL_COMP, 
                               $GODOT::Page::HOLDINGS_RESULT_COMP)) {
    
        $need_citation_info = $TRUE;
    }


    ##----------------------------------------------------------------------
    ##
    ## (14-oct-1999) 
    ## 
    ## -changed logic so that ${$tab_comp_hash_ref}{$GODOT::Page::ILL_FORM_COMP} gets set here instead of in main_hold_scr
    ## -done because you need to know such things as whether holdings are found or not before you can decide 
    ##
    ## -this logic should come after the logic for other row types (except instructions_row)                    
    ##
    ## -this is require as we will not want to print this row if an auto-requesting row has already been printed 
    ##
    ## -we also don't want to print this row if this screen is the 'catalogue screen' (ie. screen for 
    ##  detailed/more recent holdings for one library)
    ##

    my $fulltext_hold_found = $config->include_fulltext_as_holdings && $page->has_get_link;
                        
    if (($reqtype eq $PREPRINT_TYPE) || $page->has_auto_req_link || $no_ill_form_comp) {
        ##
        ## -don't offer ILL form
        ##
    }
    elsif ($hold_found || $fulltext_hold_found) {

        if ($reqtype eq $JOURNAL_TYPE) {

            if ($config->ill_req_form_always) {
                ${$tab_comp_hash_ref}{$GODOT::Page::ILL_FORM_COMP}   = ''; 
            }
            elsif ((! $page->has_request_link) && $config->ill_req_form_if_nothing_avail_to_request) { 
                ${$tab_comp_hash_ref}{$GODOT::Page::ILL_FORM_COMP}   = ''; 
            }
        }
        else { 

            if ($config->ill_req_form_non_journal_always){ 
                ${$tab_comp_hash_ref}{$GODOT::Page::ILL_FORM_COMP}   = '';   
            }
            elsif ((! $page->has_request_link) && $config->ill_req_form_non_journal_if_nothing_avail_to_request) {         
                 ${$tab_comp_hash_ref}{$GODOT::Page::ILL_FORM_COMP}   = '';
            }  
        }
    }
    else {
        
        if (($reqtype eq $JOURNAL_TYPE) && $config->no_holdings_req) { 
            ${$tab_comp_hash_ref}{$GODOT::Page::ILL_FORM_COMP}   = ''; 
        }
        elsif (($reqtype ne $JOURNAL_TYPE) && $config->no_holdings_req_non_journal) {
            ${$tab_comp_hash_ref}{$GODOT::Page::ILL_FORM_COMP}   = '';
        }
    }

    ##-----------------------------------------------------------------------------

    if (defined(${$tab_comp_hash_ref}{$GODOT::Page::ILL_FORM_COMP})) {

        $record_arr_ref = &print_ill_form_row($screen, $config, $check_citation_result, 
                                              \%warning_type_hash, $hold_found, $citation);

	if (ref($record_arr_ref)) { $page->records($record_arr_ref); }
    }

    ##
    ## -before call instructions, also need to find out if there will be any CHK or REQ buttons 
    ##  so instructions can reflect this 
    ##

    my $more_to_search = $FALSE;

    if (defined ${$tab_comp_hash_ref}{$GODOT::Page::INSTRUCTIONS_COMP}) {
     
        if (defined $tab_comp_queue_hash{$GODOT::Page::HOLDINGS_RESULT_COMP}) {
            $more_to_search = ($num_holdings_query < (scalar @{$tab_comp_queue_hash{$GODOT::Page::HOLDINGS_RESULT_COMP}}));
        }    

        if ($more_to_search) {

	    my $more_to_search_record = new GODOT::PageElem::Record;
	    my $more_to_search_button = new GODOT::PageElem::Button;

	    $more_to_search_button->action($MAIN_HOLD_ACT);
	    $more_to_search_button->param("=$SEARCH_ALL_SOURCES=$scrno");
            $more_to_search_button->label(&generic_search_all_button_text());

	    $more_to_search_record->type($GODOT::Page::SEARCH_ALL_COMP);
	    $more_to_search_record->buttons($more_to_search_button);

	    $page->records([ $more_to_search_record ]);

        }
        elsif ($page->has_auto_req_link && $page->has_hidden_record) {
      
	    my $show_all_record = new GODOT::PageElem::Record;
	    my $show_all_button = new GODOT::PageElem::Button;

	    $show_all_button->action($MAIN_HOLD_ACT);
	    $show_all_button->param("=$SHOW_ALL_HOLDINGS=$scrno");
            $show_all_button->label(&generic_show_all_button_text());

	    $show_all_record->type($GODOT::Page::SHOW_ALL_COMP);
	    $show_all_record->buttons($show_all_button);

	    $page->records([ $show_all_record ]);
        }

        ##
        ## (07-jul-2002 kl) - &instructions now passes back an instructions object instead of a string
        ##

        my $instructions = &instructions($screen, $citation, $hold_found, $num_cat_link, $tab_comp_hash_ref, $config);

        if ($instructions) { $page->instructions($instructions); }
    }

    report_time_location;


    ##--------------------------------------------------------------------------------------------

    ##
    ## (15-sept-2004 kl) - added to make it easier to have different 'no holdings' messages
    ##                     depending on whether it is the local catalogue or a remote catalogue
    ##

    my %site_has_holdings;

    foreach my $record (@{$page->holdings_records}) {
        $site_has_holdings{$record->user} = $TRUE;
    }

    foreach my $source (keys %holdings_source_sites) {

        #### debug "holdings_source_sites:  $source:  ", join(' ', @{$holdings_source_sites{$source}});

        foreach my $site (@{$holdings_source_sites{$source}}) {          

	    unless ($site_has_holdings{$site}) {

   	        my $record = new GODOT::PageElem::Record;
                my $type = ($holdings_sources_tried{$source}) ? $GODOT::Page::TRIED_NO_HOLDINGS : $GODOT::Page::NOT_TRIED;
                $record->type($type);
                $record->user($site);
                $page->records([ $record ]);
            }
        }
    }

    report_time_location;


    ##--------------------------------------------------------------------------------------------
    
    print STDOUT &waitscr($print_waitscr, "<script language=JavaScript>\n" . 
                                          "waitscr.close()\n" . 
                                          "</script>\n");            
    my $table_string;

    report_time_location;

    return ($main_msg_string, 
            $para_server_msg_string,
            $table_string, 
            $hold_found, 
            $num_cat_link);
}


sub waitscr {
    my($use_waitscr, $waitscr_msg) = @_;

    $use_waitscr  ? $waitscr_msg : '';
}

##--------------------------------------------------------------------------------------
##                 holdings-table-component-functions
##--------------------------------------------------------------------------------------
##
## (02-apr-2000 kl)
##
## $has_get_link - the number of [GET] buttons for links to fulltext
## $num_cat_link - the number of links from catalogue 856 field
##
sub instructions {
    my($screen, $citation, $hold_found, $num_cat_link, $tab_comp_hash_ref, $config) = @_;

    my($skip_holdings_text);

    require parse;

    use GODOT::PageElem::Instructions;

    my $instructions = new GODOT::PageElem::Instructions;

    $skip_holdings_text = $FALSE;


    if ($screen eq $CAT_SCR)  {     

        $instructions->no_holdings('No holdings information was found. Please return to previous screen.');

    }
    ##
    ## order with above important  !!!!!!!!!!!!!!!!!!!!!! see original routine !!!!!!!!!!!!!!!!!!!!11
    ##
    elsif ($screen eq $MAIN_HOLD_SCR) {

        $skip_holdings_text = $TRUE;
    }

    ##
    ## -'go back to database'  !!!!!!!! keep - required for new interface !!!!!!!!
    ##

    if (&back_to_database_url(param($BACK_URL_FIELD), $citation)) {      
        $instructions->back_to_dbase(&back_to_database_url(param($BACK_URL_FIELD), $citation));
    }
    
    return $instructions;
}


##-------------------------------------------------------------------------------------------------------------

sub print_cufts_link_row {
    my($screen, $config, $search, $citation) = @_;
    
    my($link_row_hidden);

    require clink;

    my($delimiter) = "\037";

    ##
    ## -loop through list of resources
    ##

    my(@record_arr);

    ##
    ## (14-feb-2004 kl) - code for use with new template system
    ##
   
    foreach my $resource (@{$search->resources_by_rank}) {

        my $record = new GODOT::PageElem::Record;
     
	$record->type($GODOT::Page::LINK_COMP);
        $record->fulltext($resource);

        push(@record_arr, $record);
    }
    
    return (\@record_arr, scalar(@record_arr));
}



##---------------------------------------------------------------------------------------------------

sub print_link_from_cat_row {
    my($screen, $config, $source_name, $link_from_cat_hash_ref) = @_;

    my(@url_arr, @text_arr, @text2_arr, @record_arr);
    my($desc, $num_cat_link, $link_from_cat_row_hidden);

    my $user = $config->name;

    foreach my $url (keys %{$link_from_cat_hash_ref}) { 

        $num_cat_link++;
    } 

    if (! $num_cat_link) { return ''; }            ## -if no links in catalogue, return empty string     

    my($count);

    foreach my $url (keys %{$link_from_cat_hash_ref}) {
 
         my $url_text = ${$link_from_cat_hash_ref}{$url};

         $count++;

         push(@url_arr, $url);

         if ($num_cat_link == 1) { push(@text_arr, "journal page or database");          }
         else                    { push(@text_arr, "journal page or database ($count)"); }

         if (naws($url_text)) { push(@text2_arr, $url_text); }
         else                 { push(@text2_arr, '');        }
    }
      
    if (aws($source_name)) {
        $desc = 'Catalogue';
    }
    else {
        $desc = "$source_name"; 
    }

    $count = 0;                         ## -initialize $count 

    my($url);

    foreach $url (@url_arr) {

        my $record = new GODOT::PageElem::Record;

        $count++;

        my($text) = shift(@text_arr);
        my($text2) = shift(@text2_arr); 

        my($name)  = $LINK_FROM_CAT_URL_FIELD . $PARAM_DELIMITER . $count; 
        param(-name=>$name, '-values'=>[$url]);
        $link_from_cat_row_hidden .= hidden($name) . "\n";  

        $record->type($GODOT::Page::LINK_FROM_CAT_COMP);


        $record->description($desc);
        $record->text("Check $text for " . (($num_cat_link == 1) ? "link " : "links ") . "to article online. " . $text2);
        $record->url($url);
     
        push(@record_arr, $record);
    }

    return (\@record_arr, $num_cat_link, $link_from_cat_row_hidden);
}

##---------------------------------------------------------------------------------------------------

sub print_preprint_row {
    my($screen, $config) = @_;  

    my(@record_arr);
    my($record, $button);
  
    my($archive, $id) = split(/:/, param($gconst::OAI_FIELD), 2);

    if (($archive eq 'arXiv') && naws($id))  {

        my $record = new GODOT::PageElem::Record;

	$record->type($GODOT::Page::PREPRINT_COMP);
	$record->description('arXiv.org e-Print archive');
	$record->text("Check the e-Print archive for a link to article online.\n");
        $record->url("http://arXiv.org/abs/$id");   

        push(@record_arr, $record);
    } 

    return (\@record_arr);
}


sub print_ill_form_row {
    my($screen, 
       $config, 
       $check_citation_result, 
       $warning_type_hash_ref, 
       $hold_found, 
       $citation) = @_;

    my($ill_text, $user, $param_str, $action, $next_action);

    $ill_text = ($citation->get_dbase()->is_blank_dbase() && (! $hold_found)) ? $ILL_FORM_BLANK_DESC_TEXT : $ILL_FORM_DESC_TEXT;

    ##
    ## (31-aug-2000 kl) Text that warns that this function is not available for some users.
    ##


    $ill_text .= (naws($config->ill_req_form_limit_text)) ? ("<P>" . $config->ill_req_form_limit_text) : '';
    
    $user = $config->name;

    ##
    ## -leave fifth parameter null as it is the request type for a potential lender, of which we
    ##  will not have any if we are here...
    ##

    ($action, $next_action) = &get_act_for_req_button($config, 
                                                      $check_citation_result,
                                                      ${$warning_type_hash_ref}{$user}, 
                                                      $citation, 
                                                      '');
    $param_str = "=$user=$REQUEST_NEW";

    if (${$warning_type_hash_ref}{$user} ne '') { $param_str .= "=${$warning_type_hash_ref}{$user}"; } 
    if ($next_action ne '')                     { $param_str .= "=$next_action";                    }

    my $record = new GODOT::PageElem::Record;
    my $button = new GODOT::PageElem::Button;

    $button->label(&generic_ill_button_text());
    $button->action($action);
    $button->param($param_str);

    $record->type($GODOT::Page::ILL_FORM_COMP);
    $record->buttons($button);
    $record->description();
    $record->text($ill_text);
    
    return [$record];
}

sub print_result_row {
    my($cgi, 
       $action, 
       $screen, 
       $citation,
       $table_request_hash_ref, 
       $ill_info_hash_ref, 
       $table_jrdb_arr_ref, 
       $holdings_hash_ref,
       $warning_type_hash_ref,
       $auto_req_hash_ref,
       $auto_req_show_all,
       $config,
       $check_citation_result,
       $no_auto_req_comp) = @_;
    
    my(%holdings_save_hash, %call_no_save_hash);
    my(@hold_branch_arr, @record_arr);
    my($hold_ref, $bib_circ_hash_ref);
    my($recnum, $rowspan, $location, $i, $first_time);
    my($html_str, $text_str, $last_html_str, $last_text_str, $call_no_str, $last_call_no_str, $tmp_str);
    my($next_action, $fmt);
    my($num_request_link, $has_check_link, $has_auto_req_link, $has_hidden_record); 

    my $reqtype = param($gconst::REQTYPE_FIELD);

    my $auto_req = &auto_req($config, $citation);

    my $auto_req_text = $AUTO_REQ_DESC_TEXT;
    my $auto_req_action = undef;
    my $auto_req_param;

    my $session = $cgi->session;      

    report_time_location;

    $fmt = (($reqtype eq $JOURNAL_TYPE)  && ($screen eq $MAIN_HOLD_SCR)) ? $catalogue::SHORT_FMT : $catalogue::LONG_FMT;
  
    #### debug "----------------------------------------------------------------------------------------";
    #### debug Dumper($config);
    #### debug "----------------------------------------------------------------------------------------";

    foreach $hold_ref (@{$table_jrdb_arr_ref})  { 
        
        @hold_branch_arr = @{$hold_ref};  

        ##
        ## get rowspan for holdings cell of table
        ##

        $rowspan = scalar @hold_branch_arr;

        $i = 0;            ## want cells for each branch and one for holdings  

        foreach $location (@hold_branch_arr) { 

            my($record, $button);

            $record = new GODOT::PageElem::Record;
            $record->type($GODOT::Page::HOLDINGS_RESULT_COMP);
            $record->user($location);        

            my $row_holdings_found = $FALSE;
            
            if (${$table_request_hash_ref}{$location}) {


   	        #### debug "<________________> ", $record->user($location);

                my($action, $next_action) = &get_act_for_req_button($config, 
                                                                    $check_citation_result, 
                                                                    ${$warning_type_hash_ref}{$location},
                                                                    $citation, 
                                                                    ${$ill_info_hash_ref}{$location});

                my($param_str) = "=$location=${$ill_info_hash_ref}{$location}";
 
                if (${$warning_type_hash_ref}{$location} ne '') { $param_str .= "=${$warning_type_hash_ref}{$location}"; }
                if ($next_action ne '')                         { $param_str .= "=$next_action";                         }

                my $button_text = &generic_request_button_text(); 

                $button = new GODOT::PageElem::Button;

                if ($auto_req) {

                    if (defined $session->var($AUTO_REQ_ACTION_FIELD)) {
                        $auto_req_action = $session->var($AUTO_REQ_ACTION_FIELD);
                        $auto_req_param  = $session->var($AUTO_REQ_PARAM_FIELD);
                    }
                    elsif (! defined $auto_req_action) {  ## -save the action and parameter information for the auto req button


                        #### debug "_________________ here is where we assign AUTO_REQ_ACTION_FIELD --$action--$param_str";

                        $auto_req_action = $action; 
                        $auto_req_param  = $param_str;
                         
                        $session->var($AUTO_REQ_ACTION_FIELD, $auto_req_action);
                        $session->var($AUTO_REQ_PARAM_FIELD,  $auto_req_param);
                    }
		} 
                else {

                    $button->label($button_text);
                    $button->action($action);
                    $button->param($param_str);
		    $record->buttons($button);

                    $num_request_link++;
	        }
            }

            my $location_config = GODOTConfig::Cache->configuration_from_cache($location);
                             
            my $check_button = &check_button($holdings_hash_ref, $location_config, $cgi, $screen, $citation);

            $record->buttons($check_button) if $check_button;

            my $user_name_text = naws($location_config->abbrev_name) ? $location_config->abbrev_name
                               : naws($location_config->full_name)   ? $location_config->full_name
                               :                                       $location_config->name
	                       ;
   
            $record->description(&GODOT::String::trim_beg_end($user_name_text));

            report_time_location;

            ##
            ## (05-mar-2004 kl) - determine this site's display group 
            ##

            my $display_group = ($citation->is_journal) ? $config->display_group($location) : 
                                                          $config->display_group_non_journal($location);

            my $search_group = ($citation->is_journal) ? $config->search_group($location) :
                                                         $config->search_group_non_journal($location);

            report_time_location;

            $record->display_group($display_group);
            $record->search_group($search_group);

            report_time_location;

            if ($i == 0) {
   
                $first_time = $TRUE;
                $last_html_str = '';
                $last_text_str = '';
                $last_call_no_str = '';

                my $text_string;

                foreach $bib_circ_hash_ref (@{${$holdings_hash_ref}{$location}}) {
                 
                    ($html_str, $text_str, $call_no_str) = &catalogue::fmt_bib_circ($bib_circ_hash_ref, 
                                                                                    $reqtype, 
                                                                                    $fmt);                                    
                    if (($html_str eq '') && ($text_str eq '')) {
                        $tmp_str = sprintf("%s - %s - %s - %s", $location, param($gconst::TITLE_FIELD), param($gconst::ISBN_FIELD), param($gconst::ISSN_FIELD));
                    }

                    if (naws($html_str)) { $row_holdings_found = $TRUE; } 

                    if ($last_text_str ne $text_str) {                 ## -no point repeating text

                        $holdings_save_hash{$location} .= $text_str;

                        $last_text_str = $text_str;
                    }
                
                    if ($last_call_no_str ne $call_no_str) {                 ## -no point repeating text

                        ##
                        ## -dedup later by splitting on '036'
                        ##
                        if (naws($call_no_save_hash{$location})) { $call_no_save_hash{$location} .= "\036"; }
   
                        $call_no_save_hash{$location} .= $call_no_str;

                        $last_call_no_str = $call_no_str;
                    }
                
                    if ($last_html_str ne $html_str) {                 ## -no point repeating html

                        if ($first_time) { 
                            $first_time = $FALSE; 
                        }
                        else {
			    $text_string .= '<P>';
                        }

                        $text_string .= $html_str;    

                        $last_html_str = $html_str;
                    } 
                }

                #### debug "========================================================";
                #### debug $record->user;
                #### debug $text_string; 
                #### debug "========================================================";

                $record->text($text_string); 
            }

            $i++;               

            if ($row_holdings_found) { 

                #### debug "\n//////////////////////";
		#### debug Dumper($auto_req_hash_ref);
    		#### debug "\n//////////////////////";

                ##    
                ## -if auto requesting is on, then only display holdings if so configured or if $auto_req_show_all is true
                ##

                my $show_record = $FALSE;

                #### debug "$auto_req --- $auto_req_show_all";

                if ($auto_req && (! $auto_req_show_all)) {

                    if (${$auto_req_hash_ref}{$location}) { $show_record = $TRUE; }
                }
                else {
                    $show_record = $TRUE;
                } 

                #### debug "show_record:  $show_record";


                if ($show_record) {  

                    push(@record_arr, $record); 
                    if ($check_button) { $has_check_link++;  }
                } 
                else {  

                    $has_hidden_record++;       
                }
            }
        }
    }

    report_time_location;

    ##
    ## (12-nov-2002 kl) - check that there is a defined $auto_req_action
    ##
    ## -if auto requesting is on, then add another result row
    ##

    #### debug "auto_req:  $auto_req -- no_auto_req_comp: $no_auto_req_comp -- auto_req_action:  $auto_req_action";

    if ($auto_req && (! $no_auto_req_comp) && (naws($auto_req_action))) {        

	my $auto_req_record = new GODOT::PageElem::Record;
	my $auto_req_button = new GODOT::PageElem::Button;

	$auto_req_button->label(&generic_auto_req_button_text());

	$auto_req_button->action($auto_req_action);
	$auto_req_button->param($auto_req_param);

	$auto_req_record->type($GODOT::Page::AUTO_REQ_COMP);
	$auto_req_record->buttons($auto_req_button);
	$auto_req_record->description();
	$auto_req_record->text($auto_req_text);

        $has_auto_req_link++;

        push(@record_arr, $auto_req_record);
    }

    report_time_location;

    param(-name=>$HOLDINGS_FIELD, '-values'=>[%holdings_save_hash]);         

    ##
    ## -get rid of poss call no dups here
    ##
    foreach (keys %call_no_save_hash) {

        my(@call_no_arr) = split(/\036/, $call_no_save_hash{$_});

        @call_no_arr = map { trim_beg_end(comp_ws($_)) }  @call_no_arr;

        rm_arr_dup_str(\@call_no_arr);

        $call_no_save_hash{$_} = join('; ', @call_no_arr);
    }


    param(-name=>$CALL_NO_SAVE_FIELD, '-values'=>[%call_no_save_hash]);         

    #### debug "\n*******************************";
    #### debug Dumper(@record_arr); 
    #### debug "\n*******************************";

    report_time_location;

    return (\@record_arr, $num_request_link, $has_check_link, $has_auto_req_link, $has_hidden_record);
}



##
## -returns TRUE/FALSE for success/failure
##
## -add bib_circ_hash containing other collection info
##
sub get_other_coll   {
    my($holdings_hash_ref, $config, $citation, $search_group, $config_cache) = @_;

    my(%bib_circ_hash);
    my(@rank_arr);
    my(@users_arr);
    my($lender, $other_rank_field);

    my $eric_no = $citation->parsed('ERIC_NO');
    my $mlog_no = $citation->parsed('MLOG_NO');

    $other_rank_field = $citation->is_journal ? 'other_rank' : 'other_rank_non_journal';

    ##
    ## (21-jan-2005 kl) - changed to rank logic that considers current $search_group
    ##

    &get_rank_list($config, \@rank_arr, $citation, $search_group); 

    foreach $lender (@rank_arr) {

        my $get_other_coll = $FALSE;
        %bib_circ_hash  = ();           

        my $lender_config = GODOTConfig::Cache->configuration_from_cache($lender);

	unless ($lender_config) {
            return $FALSE;
        }

        &catalogue::fill_bib_circ(\%bib_circ_hash, $catalogue::BIB_CIRC_DB, $lender);
        &catalogue::fill_bib_circ(\%bib_circ_hash, $catalogue::BIB_CIRC_USER, $lender);


        ##
        ## Note that 'eric_coll_avail' can be one of 'T', 'F' or 'T_IF_FULLTEXT_LINK' while
        ## 'mlog_coll_avail' will be either 1 or 0 (ie. boolean)
        ##     

        ##
        ## (18-jan-2001 kl) - added to deal with EDRS E*Subscribe
        ##

        if ((param($gconst::ERIC_FT_AV_FIELD) eq $FULLTEXT_REC) && 
            ($lender_config->eric_coll_avail eq $ERIC_COLL_T_IF_FULLTEXT_LINK)) {
        
            &catalogue::fill_bib_circ(\%bib_circ_hash, $catalogue::BIB_CIRC_ERIC_COLL, $lender_config->eric_coll_text);
        }

        if (($eric_no) && ($lender_config->eric_coll_avail eq $TRUE_STR)) {
       
            &catalogue::fill_bib_circ(\%bib_circ_hash, $catalogue::BIB_CIRC_ERIC_COLL, $lender_config->eric_coll_text);
        }

        if (($mlog_no) && ($lender_config->mlog_coll_avail)) {

            &catalogue::fill_bib_circ(\%bib_circ_hash, $catalogue::BIB_CIRC_MLOG_COLL, $lender_config->mlog_coll_text);
        }

        ##
        ## -put at front of bib_circ list for that $lender
        ##
    
        if (%bib_circ_hash) {
            unshift(@{${$holdings_hash_ref}{$lender_config->name}}, {%bib_circ_hash});
        }
    }

    return $TRUE;
}


sub citation_manager_comp {

    if (aws($GODOT::Config::CITATION_MANAGER_URL)) { return []; }


    my $cm_template = join('', $GODOT::Config::CITATION_MANAGER_URL, 
                               '?site={BRANCH}&state=link_input&cm_import_link=godot_link&DBASE={DBASE}&REQTYPE={REQTYPE}',
                               '&PUBTYPE={PUBTYPE}&TITLE={TITLE}&ARTTIT={ARTTIT}&SERIES={SERIES}&AUT={AUT}&ARTAUT={ARTAUT}',
                               '&PUB={PUB}&ISSN={ISSN}&ISBN={ISBN}&VOLISS={VOLISS}&VOL={VOL}&ISS={ISS}&PGS={PGS}&YEAR={YEAR}',
                               '&MONTH={MONTH}&YYYYMMDD={YYYYMMDD}&EDITION={EDITION}&THESIS_TYPE={THESIS_TYPE}&FTREC={FTREC}',
                               '&URL={URL}&NOTE={NOTE}&REPNO={REPNO}&SYSID={SYSID}&ERIC_NO={ERIC_NO}&ERIC_AV={ERIC_AV}',
                               '&ERIC_FT_AV={ERIC_FT_AV}&MLOG_NO={MLOG_NO}&UMI_DISS_NO={UMI_DISS_NO}&CALL_NO={CALL_NO}',
                               '&DOI={DOI}&PMID={PMID}&BIBCODE={BIBCODE}&OAI={OAI}');
    require link_template;

    my $cm_link = &link_template::link_template_text($cm_template);       

    if ($cm_link) {

        my $record = new GODOT::PageElem::Record;

        $record->type($GODOT::Page::CITATION_MANAGER_COMP);
        $record->url($cm_link);
        return [$record];
    }

    return [];
}


##------------------------------------------------------------
##                 end-component functions
##------------------------------------------------------------
##
## -return 0/1 for failure/success
##
##          holdings_hash_ref             - see catalogue.pm for description of structure
##                                     
##          ordered_branch_arr_ref        - 'IN' value is an ordered array containing all branches 
##                                          (those ranked are first, others in are in alphabetical order)
##
##                                        - 'OUT' value is the same except all those branches for which
##                                          there are no holdings have been deleted
##
##          table_request_hash_ref        - refers to hash{<branch>} = <TRUE|FALSE>
##
##          table_jrdb_arr_ref            - refers to ([<branch1>, <branch2>], 
##                                                     [<branch5>, <branch3>, <branch9>], ...)
##
##          ill_info_hash_ref             - refers to hash{<branch>} = "<fmt>=<addr>"
##
##          holdings_hash_ref             
##
##          warning_type_hash_ref         - messages/warnings associated with requesting from a specified branch
##
##          auto_req_hash_ref             - refers to hash{<branch>} = <TRUE|FALSE> 
## 

sub get_table_info {
    my($branch,
       $citation,
       $search_all_sources, 
       $config,
       $ordered_branch_arr_ref, 
       $table_request_hash_ref,
       $table_jrdb_arr_ref,
       $ill_info_hash_ref, 
       $holdings_hash_ref, 
       $warning_type_hash_ref, 
       $auto_req_hash_ref, 
       $branch_has_fulltext, 
       $search_group, 
       $config_cache) = @_;

    my(%borrower_request_hash, %sort_hash);
    my(@branch_arr, @tmp1_arr, @tmp2_arr, @cur_holdings_group_arr);
    my($first_time, $english_name, $request_type, $branch_has_holdings);
    
    report_time_location;

    $branch_has_holdings = $FALSE;
  
    my $reqtype = $citation->req_type;

    ##
    ## -does your branch have holdings ? 
    ##
    ## (14-oct-1999 kl) - added logic so that you could associate a different branch than your own for blocking logic 
    ##                  - eg. UNKNOWN uses BVAS
    ##
    my($branch_with_your_holdings) = (naws($config->blocking_holdings)) ? $config->blocking_holdings : $branch;

    if (exists (${$holdings_hash_ref}{$branch_with_your_holdings}))   { $branch_has_holdings = $TRUE; }
    
    ##
    ## (11-july-2003 kl) 
    ##
     
    if ($config->include_fulltext_as_holdings) {

        $branch_has_holdings = ($branch_has_holdings || $branch_has_fulltext);    
    } 

    ##
    ## -@branch_arr based on rank info (from borrower info) and english name (from lender info)
    ##
    ## -get rid of sites in list with no holdings....
    ##
    foreach (@{$ordered_branch_arr_ref}) {    

        if (exists ${$holdings_hash_ref}{$_})  { push(@branch_arr, $_); }        ## -have holdings
    } 

    my %request_allowed = param($REQUEST_ALLOWED_FIELD);

    ##
    ## -if empty, then we did not find holdings for any of the branches we care about
    ## -fill sorted branch array ref -- MUST do this now before branch_arr is emptied by logic later in routine...
    ##

    @{$ordered_branch_arr_ref} = @branch_arr; 

    ##--------------------------------------------------------------------------------

    ##
    ## -cache config info for later use in this subroutine
    ##

    report_time_location;

    foreach my $lend_branch (@branch_arr) {                        ## -branches that have holdings and that we want to display

        my $lender_config = GODOTConfig::Cache->configuration_from_cache($lend_branch); 
        return $FALSE unless (defined $lender_config); 

        ##---------------------------------------------------------------------------        
        ## 
        ## -if blocking is turned ON then do not allow borrowing from *other* branches if *your* branch has holdings
        ## -blocking will have no effect on whether or not you can borrow from your own branch
        ## -this is controlled by your REQUEST_FIELD or REQUEST_MONO_FIELD setting (eg. BVAS-BVAS=D would 
        ##  mean that you could request from your own branch)
        ##

        if (($config->blocking eq $BLOCKING_TRUE) && ($branch_has_holdings) && ($config->name ne $lender_config->name)) {
            ${$table_request_hash_ref}{$lend_branch} = $FALSE;     
        }
        ##
        ## - (27-nov-2001 kl) - don't use previously cached values if we are now searching all sources
        ##
        elsif ((defined $request_allowed{$lend_branch}) && (! $search_all_sources)) {
            ${$table_request_hash_ref}{$lend_branch} = $request_allowed{$lend_branch};
        }
        else {
            ${$table_request_hash_ref}{$lend_branch} = &req_allowed($config, $lender_config, $citation); 
        }


        ##-----------------------------------------------------------------------------

        ##
        ## (17-feb-2000 kl) -moved from just after 'get_single_user_info' at start of foreach loop, so would
        ##                   have value of ${$table_request_hash_ref}{$lend_branch}
        ##                  -also added HOLDINGS_LIST_CAN_BORROW_ONLY logic
        ##
        ##
        ## -want save names of *all* sites (not just those that user wants to display) that have holdings 
        ##  so can add info to note field in ILL request msg (12-feb-1998 kl) 
        ##
        ## -see logic after this 'foreach' loop for these other sites
        ##
    
        #### debug "--------------------------------------------------";
        #### debug Dumper($table_request_hash_ref);
        #### debug "--------------------------------------------------";

        use GODOT::ILL::Site;
        my $lender_site = GODOT::ILL::Site->dispatch({'site' => $lender_config->name});
        $lender_site->nuc($lender_config->ill_nuc); 

        unless (($config->holdings_list eq $HOLDINGS_LIST_CAN_BORROW_ONLY) && (! ${$table_request_hash_ref}{$lend_branch})) {

            
            debug $config->holdings_list, " -- $lend_branch -- ${$table_request_hash_ref}{$lend_branch}\n";

            ##
            ## (01-sep-2004 kl) - multiple iterations of main_holdings_screen (due to different scrno or due to 
            ##                    page reloading) will result in sites being added more than once, so need
            ##                    to check whether site is in list of not

	    unless (grep {$lender_site->description eq $_} param($HOLDINGS_SITE_FIELD)) {     
                param(-name=>$HOLDINGS_SITE_FIELD, '-values'=>[param($HOLDINGS_SITE_FIELD), $lender_site->description]);
	    }
        }

        ##-----------fill $ill_info_hash_ref------------------------------------------

        if (${$table_request_hash_ref}{$lend_branch}) {

            $request_type = &get_request_type($config, $lend_branch, $citation);
            
            ##
            ## -if borrower and lender is the same then this is a $REQUEST_SELF (ie. a retrival service)
            ##  
            ## -we ignore whether <user>-<user> relationship is defined as direct or mediated
            ##


            if ($config->name eq $lender_config->name) {
                $request_type = $REQUEST_SELF;                
            }
            elsif (($config->blocking eq $BLOCKING_FALSE_MEDIATED) && 
                   ($branch_has_holdings)                          &&
                   ($config->name ne $lender_config->name)         &&
                   ($request_type eq $REQUEST_DIRECT)) {

                $request_type = $REQUEST_MEDIATED;

                ##
                ## -turn on warning flag for later use
                ##

                ${$warning_type_hash_ref}{$lend_branch} = sprintf("%s", escape($YOUR_BRANCH_HAS_WARNING_TYPE));         
            }             
            ##
            ## (29-jun-2004 kl)
            ##
            elsif (($config->blocking eq $BLOCKING_FALSE_MEDIATED_NO_WARNING) && 
                   ($branch_has_holdings)                                     &&
                   ($config->name ne $lender_config->name)                    &&
                   ($request_type eq $REQUEST_DIRECT)) {


                $request_type = $REQUEST_MEDIATED;
            }             
            ##
            ## (29-mar-2000 kl) - added per request from Sandy Slade at UVic
            ##

            elsif (($config->blocking eq $BLOCKING_FALSE_WARNING) && 
                   ($branch_has_holdings)                         &&
                   ($config->name ne $lender_config->name)) {

                ##
                ## -turn on warning flag for later use
                ##

                ${$warning_type_hash_ref}{$lend_branch} = sprintf("%s", escape($YOUR_BRANCH_HAS_WARNING_TYPE));         
            }             

            elsif (defined(param($WARNING_TYPE_FIELD))) {
                ##
                ## get values from saved info
                ##
                my(%tmp_hash) = param($WARNING_TYPE_FIELD);

                ${$warning_type_hash_ref}{$lend_branch} = $tmp_hash{$lend_branch};
            }

            ${$ill_info_hash_ref}{$lend_branch} = sprintf("%s", escape($request_type));
        }
        
        ##-----------------------------------------------------------------------------           
    }

    report_time_location;
    
    ##
    ## -more $HOLDINGS_SITE_FIELD logic
    ##
    ## (17-feb-2000 kl) - added HOLDINGS_LIST_CAN_BORROW_ONLY logic
    ##
    unless ($config->holdings_list eq $HOLDINGS_LIST_CAN_BORROW_ONLY) {      

        foreach my $lend_branch (keys %{$holdings_hash_ref}) {     ## -sites that have holdings

            if (! (grep {$lend_branch eq $_}  @branch_arr)) {      ## -if not already in @branch_arr and thus dealt with above
                
                my $lender_config = GODOTConfig::Cache->configuration_from_cache($lend_branch); 
                return $FALSE unless (defined $lender_config); 

                my $lender_site = GODOT::ILL::Site->dispatch({'site' => $lender_config->name});
                $lender_site->nuc($lender_config->ill_nuc);

                ##
                ## (01-sep-2004 kl) - avoid duplicates due to multiple main_holdings_screen iterations - see note above 
                ##
	        unless (grep {$lender_site->description eq $_} param($HOLDINGS_SITE_FIELD)) {
                    param(-name=>$HOLDINGS_SITE_FIELD, '-values'=>[param($HOLDINGS_SITE_FIELD), $lender_site->description]);
	        }
            }
        }
    }

    report_time_location;

    ##-------------------------------------------------------------------------------------
    ##
    ## -@table_jrdb_arr is used so that branches with the same holdings, listed one after the other,
    ##  are displayed so that holdings info is not repeated, for example:
    ##
    ##          -----------------------------------------
    ##          |  AEU-main     | AEU holdings 1        |
    ##          |---------------| AEU holdings 2        |
    ##          |  AEU-downtown | AEU holdings 3        |
    ##          -----------------------------------------
    ##

    $first_time = $TRUE;
    @tmp2_arr   = ();

    ##
    ## !!!!!!!!!!!!!!! logic can be simplified as above situation has never yet happened !!!!!!!!!!!!!!!
    ##

    foreach my $lend_branch  (@branch_arr) {

        if ($first_time) {
            push(@tmp2_arr, $lend_branch);
            @cur_holdings_group_arr = ($lend_branch);

            $first_time = $FALSE;
        }
        else {
            if (! grep {$lend_branch eq $_} @cur_holdings_group_arr) { ## -if uses diff holdings than prev user

                push(@{$table_jrdb_arr_ref}, [@tmp2_arr]);
                @tmp2_arr = ();               

                @cur_holdings_group_arr = ($lend_branch); 
            }

            push(@tmp2_arr, $lend_branch);
        }
    }


    push(@{$table_jrdb_arr_ref}, [@tmp2_arr]);    ## add last @tmp2_arr
  

    report_time_location;

    ##
    ## (11-jun-2002 kl) - if we want auto requesting, then fill hash with hide/show information
    ##

    if (&auto_req($config, $citation)) {
    
        ##
        ## -get hide/show information for explicitly ranked branches
        ##

        my %rank_hash;
        if ($reqtype eq $JOURNAL_TYPE) { %rank_hash = $config->auto_req_hash; }
        else                           { %rank_hash = $config->auto_req_non_journal_hash; }
        
        my @rank_arr;

        #### debug location, ', search_group:  ', $search_group;         

        return $FALSE unless (&get_rank_list($config, \@rank_arr, $citation, $search_group));

        my $other_auto_req_show = &other_auto_req_show($config, $citation);

        #### debug "other_auto_req_show:  $other_auto_req_show";
        #### debug Dumper({%rank_hash});

        foreach my $branch (@rank_arr) {

            if (defined $rank_hash{$branch}) { ${$auto_req_hash_ref}{$branch} = $rank_hash{$branch}; } 
            else                             { ${$auto_req_hash_ref}{$branch} = $other_auto_req_show; }                       
        }
    }

    report_time_location;

    return $TRUE;
}

sub req_allowed {
    my($config, $lender_config, $citation) = @_;

    my(%request_hash);
    my($lender_name, $req_allowed, $other_request_method, $request_type_method);

    if ($citation->is_journal) { 
        $other_request_method = 'other_request';  
        $request_type_method = 'request_types'; 
    }
    else { 
        $other_request_method = 'other_request_non_journal'; 
        $request_type_method = 'request_non_journal_types';
    }
    
    $lender_name = $lender_config->name;

    $req_allowed = 0;

    ## -first check lending field from lender record, if not allowed
    ##  to lend then don't bother checking if borrower can borrow

    if ($lender_config->lend) {

        %request_hash = $config->$request_type_method;

        ## -set default first (D:direct or M:mediated)

        if (grep {$config->$other_request_method eq $_} ($REQUEST_MEDIATED, $REQUEST_DIRECT, $REQUEST_INFO)) {
            $req_allowed = 1;
        }

        if (grep {$request_hash{$lender_name}  eq $_} ($REQUEST_MEDIATED, $REQUEST_DIRECT, $REQUEST_INFO)) {
            $req_allowed = 1;
        }

        if ($request_hash{$lender_name} eq $REQUEST_NOT_ALLOWED) {
            $req_allowed = 0;
        }
    }
    return $req_allowed;
}

sub get_request_type {
    my($config, $lender_branch, $citation) = @_;

    my(%request_hash);
    my($request, $other_request_method, $request_type_method);

    if ($citation->is_journal) { 
        $other_request_method = 'other_request';  
        $request_type_method = 'request_types'; 
    }
    else { 
        $other_request_method = 'other_request_non_journal'; 
        $request_type_method = 'request_non_journal_types';
    }

    %request_hash = $config->$request_type_method;

    $request      = $request_hash{$lender_branch};

    if (aws($request) || $request eq $REQUEST_DEFAULT)  {
	$request = $config->$other_request_method;
    }

    return $request;
}

##-----------------------------------------------------------------------------------
## (03-mar-2004 kl) - added search group logic 
##
## -returns TRUE/FALSE for success/failure
##
## -passes back ordered rank array
##
sub get_rank_list {
    my($config, $rank_arr_ref, $citation, $search_group) = @_; 

    #### debug '>>>>>>>>>>>>  ', join("--", $config->name, $search_group);

    report_time_location;

    ##
    ## -will take into account request type 
    ##
        
    my @spec_arr  = ($citation->is_journal) ? $config->rank_for_search_group($search_group) 
                                            : $config->rank_for_search_group_non_journal($search_group);
    report_time_location;

    ##
    ## (04-jul-2004) - added to prevent sites with search groups less than the current one from 
    ##                 being added in by 'other rank' logic below
    ##

    my @lesser_search_group_sites;

    if ($search_group > 1 )  {

        foreach my $sg (1 .. ($search_group - 1)) {

            push(@lesser_search_group_sites, 
                 ($citation->is_journal) ? $config->rank_for_search_group($search_group) 
                                         : $config->rank_for_search_group_non_journal($search_group));
    	}
    }
   
    my $other_rank_field = $citation->is_journal ? 'other_rank' : 'other_rank_non_journal';

    report_time_location;

    use GODOT::SiteGroup;
    my $site_group = GODOT::SiteGroup->new;
    $site_group->group($config->group);

    report_time_location;

    my @group_arr = $site_group->groups;

    ##
    ## -push on branches specified by rank field first
    ##

    foreach (@spec_arr) { push(@{$rank_arr_ref}, $_); } 

    my $default_group;

    if ($citation->is_journal) {
        ##
        ## -based on the current search group, do we want any other sites?
        ##
        $default_group = ($config->other_rank_search_group >= 1) ? 
                         $config->other_rank_search_group : 
                         $config->max_search_group;    
    }
    else {
        $default_group = ($config->other_rank_non_journal_search_group >= 1) ? 
                         $config->other_rank_non_journal_search_group : 
                         $config->max_search_group_non_journal;
    }

    report_time_location;

    #### debug "---------------- here in get_rank_list ------------";
    #### debug Dumper($rank_arr_ref);
    #### debug "---------------------------------------------------";

    if ($search_group ne $default_group) { return $TRUE; }
   
    ##
    ## (10-feb-1999 kl) -check that we have group array info 
    ##                  -if not, then just pass back what we have for rank list so far
    ##
    ## -do we want to use sites that are not ranked ?
    ##
    ## -sort @branch_arr based on rank info (from borrower info) and english name (from lender info)
    ##

    if ((scalar @group_arr) && $config->$other_rank_field)  {

        report_time_location;

        my %sort_hash;

        my @for_rank; 
        my @sites = GODOTConfig::Cache->sites_in_cache;

        report_time_location;

        foreach my $site (@sites) {      ## -we only want ones with potential site holdings
 
            my $config = GODOTConfig::Cache->configuration_from_cache($site); 
            next unless defined($config);
            next unless $config->use_site_holdings;
            my $name = $config->name;
            my $group = $config->group;

            #### debug "-----------$site--$name--$group";

            if ((! (grep {$name eq $_}  @{$rank_arr_ref})) &&            ## -if not already in the rank list
                (! (grep {$name eq $_}  @lesser_search_group_sites))) {  ## -if not part of another (lesser) search group 

                if (grep {$group eq $_} @group_arr) { 
                        push @for_rank, $config;
                }                
	    }
        }

        foreach my $config (sort by_site_name @for_rank) {
            push(@{$rank_arr_ref}, $config->name);
        }

        report_time_location;

    }

    #### debug "---------------- here in get_rank_list ------------";
    #### debug Dumper($rank_arr_ref);
    #### debug "---------------------------------------------------";

    return $TRUE;

}

# sub by_site_name {
#     site_name_sort_key($a) cmp site_name_sort_key($b);
# }

# sub site_name_sort_key {
#     my($ref) = @_;
#     my $key = naws($ref->{'abbrev_name'}) ? $ref->{'abbrev_name'}
#             : naws($ref->{'full_name'})   ? $ref->{'full_name'}
#             :                               $ref->{'name'}
#             ;
#    return lc($key);
# }


sub by_site_name {

    site_name_sort_key($a) cmp site_name_sort_key($b);
}

sub site_name_sort_key {
    my($config) = @_;

    my $key = naws($config->abbrev_name) ? $config->abbrev_name
            : naws($config->full_name)   ? $config->full_name
            :                              $config->name
            ;

    return lc($key);
}




##-----------------------------------------------------------------------------------
##                         misc-func
##-----------------------------------------------------------------------------------


sub process_citation {
    my($citation, $prev_screen, $citation_ref, $message_ref, $check_type) = @_;

    my($check_citation_result, $key);

    my $first_time;
    if (param($ART_FORM_ONCE_THRU_FIELD) != $TRUE) { $first_time = $TRUE; }

    ##
    ## -get all info that has already been parsed and if available, get user entered article info
    ##
        
    foreach (@gconst::CITN_ARR) { 

        if (defined param($_) && (! ${$citation_ref}{$_})) {          ## -get item info from param, but don't overwrite 

            ${$citation_ref}{$_} = param($_);  
       }
    }    

    require parse;

    &parse::second_pass_field_cleanup($citation_ref);                                              

    ##
    ## -save citation to param
    ##
    foreach $key (sort(keys %{$citation_ref})) { 
        param(-name=>$key, '-values'=>[${$citation_ref}{$key}]);     
    }

    ##
    ## -&parse::check_citation(....) returns 'ok', 'need article info', 'not ok' 
    ##

    return &parse::check_citation($citation, $prev_screen, $check_type, $citation_ref, $message_ref, $first_time);
}

##--------------------------------------------------------------------------------------
##
## !!!!!!!!!!!!!!! don't add more param !!!!!!!!!!!!!!!
##
##
## (27-may-2004 kl) - if param($BACK_URL_FIELD) is not defined, then an empty
##                    list is returned.  If param($BACK_URL_FIELD) is in the parameter list 
##                    for &back_to_database, $citation ends up not being passed properly
##

sub back_to_database_url {
    my($hold_tab_back_url, $citation) = @_;

    my($label);

    if (ref($hold_tab_back_url) eq 'GODOT::Citation') { 
        $citation = $hold_tab_back_url; 
        $hold_tab_back_url = '';
    }

    require parse;

    if    ($citation->get_dbase()->no_back_to_database())   { return ''; }
    elsif (aws($hold_tab_back_url))                { return ''; }

    if ($citation->get_dbase()->is_blank_dbase()) { $label = 'To New Request Form';   }
    else                                          { $label = 'Back to Database';      }
   
    return $hold_tab_back_url;
}


sub back_to_database {
    my($hold_tab_back_url, $citation) = @_;

    if (ref($hold_tab_back_url) eq 'GODOT::Citation') { 
        $citation = $hold_tab_back_url; 
        $hold_tab_back_url = '';
    }

    my($label);

    require parse;

    ##
    ## (09-mar-2001 kl)
    ##

    if    ($citation->get_dbase()->no_back_to_database())   { return ''; }
    elsif (aws($hold_tab_back_url))                { return ''; }

    if ($citation->get_dbase()->is_blank_dbase()) { $label = 'To New Request Form';   }
    else                                          { $label = 'Back to Database';      }
   
    return "<FONT SIZE=+1><A HREF=\"$hold_tab_back_url\">$label</A></FONT>";
}



##--------------------------------------------------------------------------------------
sub get_screen { 

    my($screen) = param($SCREEN_FIELD);

    if (! $screen) { return $NO_SCR; }

    unless (defined($GODOT::Constants::SCREENS{$screen})) { 
        &glib::send_admin_email("screen \($screen\) does not exist"); 
        return $NO_SCR;
    }
    return $screen;
}

sub get_action { 
    my($prev_screen) = @_;

    my(@param_arr, @junk_arr);
    my($action, $field, $value, $tmp_str);

    @param_arr = param();


    foreach $action (keys %ACTION_HASH) {           ## -check to see if actions in list are in param
        ##
        ## -assume there is only one that matches, if more ignore rest
        ##
        ($tmp_str, @junk_arr) = grep(/^$action=/, @param_arr);
 
        if ($tmp_str) {  

            ($field, $value) = split(/=/, $tmp_str, 2);    ## -'2' required as value may have '=' signs  
            ##
            ## -set action param field
            ##
            ## ???? do url unencoding of value !!!!
            ##
            param(-name=>$ACTION_PARAM_FIELD, '-values'=>[$value]);

            &CGI::delete($tmp_str);                 ## -delete param now that field, value pair extracted

            return $field;
        }
        else {
           if (param($action)) { return $action; }
        }
    }

    ##
    ## -default action for when form is submitted without a button being pushed (ex.  this is possible when
    ##  there is only one data entry field on a form -- all user has to do is push enter and form gets submitted 
    ##

    if (defined $ACTION_HASH{$GODOT::Constants::SCREENS{$prev_screen}}) { 
        return $GODOT::Constants::SCREENS{$prev_screen}; 
    }
    else { 
        return $START_ACT;            
    }
}




##------------------------------------------------------------------------------------------------------------------------
##
## !!!! -make generic_xxx_button_text routines are in sync with $XXX_BUTTON_TEXT !!!!

sub generic_request_button_text {
    return "REQ";
}


sub generic_ill_button_text {
    return "ILL";
}

sub generic_auto_req_button_text {
    return &generic_request_button_text;
}

sub generic_get_button_text {
    return "GET";
}

sub generic_help_button_text {
    return "HELP";
}

sub generic_search_all_button_text {
    return "ALL";
}

sub generic_show_all_button_text {
    return "ALL";
}




##--------------------------------------------------------------------------
sub session_to_from_param  {
    my($session, $save) = @_;

    ##
    ## (23-feb-2004 kl) - changed from hidden fields to session logic with Apache::Session::File
    ##

    foreach my $field ($BRANCH_FIELD, 
                       $DBASE_FIELD, 
                       $DBASE_TYPE_FIELD, 
                       $DBASE_LOCAL_FIELD,
                       $BACK_URL_FIELD, 
                       $USERNO_FIELD, 
                       $ART_FORM_ONCE_THRU_FIELD, 
                       $TRUSTED_HOST_FIELD, 
                       $SYNTAX_FIELD,                                              
                       'hold_tab_lender',            ## (20-may-2004 kl)
                       $MSG_REQ_TYPE_FIELD,          ## (20-may-2004 kl)
                       $PATR_CHECKED_OK_FIELD,       ## (20-may-2004 kl)
                       $ACTION_PARAM_FIELD,          ## (21-may-2004 kl)
                       @PATR_ARR,                    ## (30-may-2004 kl) 
                       $gconst::ASSOC_SITES_FIELD,   ## (25-oct-2004 kl)
                       'PATR_PIN_FIELD'              ## (03-nov-2005 kl) 
                      ) {
        if ($save) { 
            if (defined(param($field))) { $session->session->{$field} = param($field);  } 
	}
	else { 
            if (defined($session->session->{$field}) && (! defined(param($field)))) { 
                param(-name=>$field,  '-values'=>[$session->session->{$field}]); 
            }
        }
    }
    
    foreach my $field ($HOLDINGS_SITE_FIELD) {

        if ($save) { 
            if (defined(param($field))) { $session->session->{$field} = [ param($field) ];  } 
        }
	else { 
            if (defined($session->session->{$field}) && ! defined(param($field))) { 
                param(-name=>$field,  '-values'=>[@{$session->session->{$field}}]); 
            }           
        }
    }                       
 
    foreach my $field ($REQUEST_ALLOWED_FIELD,   
                       $WARNING_TYPE_FIELD, 
                       $CALL_NO_SAVE_FIELD)     {
        if ($save) { 
             if (defined(param($field))) { $session->session->{$field} = { param($field) };  } 
        }
	else { 
             if (defined($session->session->{$field}) && ! defined(param($field))) { 
                 param(-name=>$field,  '-values'=>[%{$session->session->{$field}}]); 
             }
	    my %hash = param($field);
        }
    }

    ##
    ## save citation info - in url encoded fmt (??)
    ##

    foreach my $field (@gconst::CITN_ARR) { 

        if ($save) {
            if (defined(param($field)) && (param($field) ne '')) {  $session->session->{$field} = param($field); } 
        }
        else {
	    if (defined($session->session->{$field}) && ! defined(param($field))) {
                param(-name=>$field,  '-values'=>[$session->session->{$field}]);
            }
        }                  
    }

    #### if ($save) {
    ####    foreach my $field (sort keys %{$session->session}) { 
    ####        debug ".... save .... $field = ", $session->session->{$field};
    ####    }
    #### }

    ##
    ## -use to check that all hidden fields have been loaded by browser
    ##
    param(-name=>$HIDDEN_COMPLETE_FIELD, '-values'=>[$TRUE]);
    return join("\n", hidden($SCREEN_FIELD), hidden($COOKIE_FIELD), hidden($HIDDEN_COMPLETE_FIELD)), "\n";
}

sub session_from_param {
    my($session) = @_;

    &session_to_from_param($session, $TRUE);
}

sub session_to_param {
    my($session) = @_;

    &session_to_from_param($session, $FALSE);
}

sub fill_other_coll_comp {
    my($tab_comp_hash_ref) = @_;
    ##
    ## ERIC Availability:
    ##
    ## 1: available in paper copy and microfiche
    ## 2: available in microfiche only
    ## 3: not available from ERIC (check the AV field for alternate sources) 
    ##

    if ((param($gconst::ERIC_NO_FIELD) =~ m#$ERIC_DOC_PATTERN#)  && (param($gconst::ERIC_AV_FIELD) =~ m#1|2#)) {

        ${$tab_comp_hash_ref}{$GODOT::Page::ERIC_COLL_COMP}   = '';     
    }

    if (param($gconst::MLOG_NO_FIELD)) { 

        ${$tab_comp_hash_ref}{$GODOT::Page::MLOG_COLL_COMP}   = '';
    }    
}

sub auto_req {
    my($config, $citation) = @_;

    my $field = ($citation->is_journal) ? 'auto_req' : 'auto_req_non_journal';

    my $auto_req = ($config->$field) ? $TRUE : $FALSE;
    
    #### debug "hold_tab::auto_req:  $auto_req";

    return $auto_req;
}

sub other_auto_req_show {
    my($config, $citation) = @_;

    my $field = ($citation->is_journal) ? 'other_auto_req_show' : 'other_auto_req_show_non_journal';
    
    return $config->$field;
}

##
## -returns a button object or undef
##
sub check_button {
    my($holdings_hash_ref, $location_config, $cgi, $screen, $citation) = @_;

    my($source, $live_source);
      
    my $dbase = $citation->dbase;

    my $dummy_ref;
   
    ##
    ## (06-dec-2001 kl) - added for finer control on whether or not 'CHK' button was displayed
    ##
    my $want_details_button = $FALSE;

    if ($citation->is_journal) { 
        unless ($location_config->disable_journal_details) { $want_details_button = $TRUE; }
    }
    else  { 
	unless ($location_config->disable_non_journal_details) { $want_details_button = $TRUE; }
    }

    my $button = undef;        

    if (($want_details_button) && 
        (&catalogue::holdings_in_catalogue($holdings_hash_ref, $location_config->name)) &&
        ($screen ne $CAT_SCR)) {

        use GODOT::CGI::CheckDetailedHoldings;
        my $check_detailed = GODOT::CGI::CheckDetailedHoldings->dispatch({'site'   => $location_config->name,
                                                                          'system' => $location_config->system_type});         
        $button = $check_detailed->button;        
    }

    return $button;
}

##-----------------------------------------------------------------------------------
##
## -do we want to do the patron info caching logic? -- returns TRUE/FALSE
##

sub cache_patron_info {
    my($ill_cache_patron_info, $userno) = @_;

    return ($ill_cache_patron_info) && (! aws($userno));

}

##-----------------------------------------------------------------------------------
##
## -assumes that all param are in URL encoded format
##

sub dev_copy_url {
    my($url) = @_; 
    
    if ($ENV{'PATH_INFO'} eq '/sfx.gif')  {    return $url . $ENV{'PATH_INFO'}; }

    ##
    ## -using url root ($url) and the values from param, construct a URL that includes all the param fields
    ##
    ## (05-mar-2009 kl) - OpenURL 1.0 has repeating fields (eg. 'au', 'rft_id') so change logic below so these are not lost during redirection;
    ##
    my @url_arr;

    foreach my $param_label (param()) { 

        my @param_arr = param($param_label);        
        foreach my $value (@param_arr) {
            push @url_arr, [ $param_label, $value ]; 
        }
    }

    ##
    ## (08-feb-2009 kl) -- add any PATH_INFO we may have;
    ##
    debug "path_info:  $ENV{'PATH_INFO'}";

    return $url . $ENV{'PATH_INFO'}  . '?' . put_query_fields_from_array(\@url_arr); 
}

sub form_url {
    my($target) = @_;

    ##
    ## (03-may-2006 kl) - added so that godot would work with apache ProxyPass and ProxyPassReverse options
    ##                  - logic below assumes that the script name is not changed by proxying

    ##
    ## (06-dec-2006 kl) - bug in apache2 results in CGI.pm not returning proper value;  $ENV{'SCRIPT_NAME'} 
    ##                    appears to work though
    ##

    my $script_name = $ENV{'SCRIPT_NAME'};

    my @path = split('/', $script_name);

    #### debug "script_name:  ", $script_name;

    my $script_no_path = $path[$#path];

    return $script_no_path;
    
}





##-----------------------------------------------------------------------------------
##                         ill-func  
##-----------------------------------------------------------------------------------

#
# -changed logic so can pass back error message (kl)
#
# -(11-apr-2000 kl) - added override for required information if you had to put a password in to do request 
#                     (eg. staff at colleges using SFU Doc Direct)
# 
sub ill_verify_input
{
        my($config, $citation) = @_;       
 
	my ($key);
 
        require password;

        my($skip_required_field_check) = $FALSE;

        if ($config->skip_required_if_password &&
            (&password::use_password($config, $citation)))  
        { 

                $skip_required_field_check = $TRUE; 
        } 

        if (! $skip_required_field_check) 
        {
	        foreach $key (keys %PATR_MAPPING)
	        {
		        my $map_field = $PATR_MAPPING{$key};
		        my $field_status = $config->$map_field;

		        if ($field_status eq "R" && $ill_fields{$key} eq "")                            
		        {                                                        
			        debug "required information was not supplied:  $key\n";
			        return "Some required information was not supplied -- $map_field -- $key.";   # include period
                        }
	        }
	
        }
    
        # check format of patron's email address to make sure that domain is specified (kl)

        if (! aws($ill_fields{'PATR_PATRON_EMAIL_FIELD'}))    
        { 
                if (! valid_email($ill_fields{'PATR_PATRON_EMAIL_FIELD'})) 
                {
                        return "Your email address is not in form jdoe\@nowhere.ca.";  
                }

                if (! aws($config->patron_email_pattern)) 
                {
                        if (! email_pattern_match($ill_fields{'PATR_PATRON_EMAIL_FIELD'}, $config)) 

                        {
                                if (! aws($config->patron_email_no_match_text)) 
                                {
                                        return $config->patron_email_no_match_text;
                                }
                                else 
                                {
                                        return 'Your email address does not match pattern specified by administrator.';  
                                }                       
                        }                                
                }
        }

	return '';     

} 


sub email_pattern_match  {
    my($string, $config) = @_;

    ##
    ## -ignore if all white space
    ##

    if (aws($config->patron_email_pattern)) { return $TRUE; }

    my $pattern = $config->patron_email_pattern;

    return (trim_beg_end($string) =~ m#$pattern#);
}


#
# added routine for caching patron info 
#
sub ill_set_patron_cache 
{

       local(*PATRON_FILE);

       my($patron_file) = &ill_patron_cache_filename;      

       # write out data to temp file so users doesn't have to re-enter info during session

       # ?? what time limit should be put on these files - how often is Webspirs userno recycled...

       if (! open(PATRON_FILE, ">$patron_file")) 
       { 
               &glib::send_admin_email("$0:  failed to open $patron_file for writing"); 
       }

       # strip out any line feeds so they can be used as field terminators

       foreach (@PATR_ARR)
       {
               if (($_ ne 'PATR_NOT_REQ_AFTER_FIELD')  &&  (! aws($ill_fields{$_})))
               {
                       $ill_fields{$_} =~ #\n# #g;

                       printf PATRON_FILE "$_=$ill_fields{$_}\n";  
               }
       }

       close PATRON_FILE;

       chmod(0644, $patron_file);    ## !!!! change later to 0600
}

##
## -returns TRUE/FALSE for success/failure
##
sub ill_get_patron_cache 
{
       local(*PATRON_FILE);

       my($field, $value);

       my($patron_file) = &ill_patron_cache_filename;      

       if (! (-e $patron_file)) { return $FALSE; }       

       if (! open(PATRON_FILE, $patron_file)) 
       {  
               &glib::send_admin_email("$0:  failed to open $patron_file for reading"); 
               return $FALSE;
       }

       # strip out any line feeds so they can be used as field terminators

       while (<PATRON_FILE>) 
       {
               chop $_;

               ($field, $value) = split(/=/, $_, 2); 
               $ill_fields{$field} = $value;
       }

       close PATRON_FILE;

       return $TRUE;
}

sub ill_patron_cache_filename 
{
       ##
       ## (20-jul-1999 kl) -changed from $ill_fields{'hold_tab_userno'} 
       ##

       return  "/tmp/" . param($USERNO_FIELD) . ".patron";      

}


##
## -return TRUE/FALSE for success/failure
##
sub ill_get_patron_record {
    my($patron_name, $patron_lib_no, $patron_pin_no, $config, $citation, $msg_ref) = @_;

    use GODOT::Patron::API;

    #### debug "<<<<< patron_pin_no >>>>>", $patron_pin_no;

    my $patron_api = GODOT::Patron::API->dispatch({'site' => $config->name, 'api'  => $config->patron_api_type},
                                                  $config->use_patron_api,
                                                  $config->patron_api_host,
                                                  $config->zhost,
                                                  $config->patron_api_port,
                                                  $config->patron_need_pin,
                                                  $config->patr_fine_limit);

    ##
    ## -will return TRUE if site is not configured to check patron
    ##

    unless ($patron_api->get_patron($patron_name, $patron_lib_no, $patron_pin_no)) {
        error "GODOT::Patron::API::get_patron failed (", $patron_api->error_message, ")";
        ${$msg_ref} = $patron_api->error_message;
        return $FALSE;
    }
   
    my %patron_hash = (defined $patron_api->patron) ? $patron_api->patron->converted : ();    

    #### debug "<dev patron ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~";
    #### foreach my $key (keys %patron_hash) {
    ####    debug "<dev patron ", $config->name, "  ", $patron_lib_no, "> ", $key, ":  ", $patron_hash{$key};  
    #### }
    #### debug "<dev patron ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n";

    foreach my $key (keys %patron_hash) { 
        $ill_fields{$key} = $patron_hash{$key}; 
    }

    ##
    ## -if email address from patron record does not match pattern specified in site config, don't use it
    ##

    if (! &email_pattern_match($ill_fields{'PATR_PATRON_EMAIL_FIELD'}, $config)) {
        $ill_fields{'PATR_PATRON_EMAIL_FIELD'} = '';
    }
    
    ${$msg_ref} = $patron_api->error_message;

    return $TRUE;        
}



##
## -return TRUE/FALSE for success/failure
##
sub ill_check_password {
    my($password, $config, $citation, $msg_ref) = @_;

    require password;
    
    ##
    ## -if password is *not* required then return true
    ##

    unless (&password::use_password($config, $citation))   { return $TRUE; }

    if (&password::check_password($password, $config)) { 
        return $TRUE; 
    }
    else {
        ${$msg_ref} = 'Password is incorrect.';
        return $FALSE;
    }
}

sub ill_process_request  {
        my ($cgi, $page, $session, $config, $lender_config, $citation) = @_;   

	my $result;
        my $sent_to_local_system = $FALSE;

        my $same_nuc_only_local  = $FALSE;
        my $same_nuc_only_remote = $FALSE;

        if ($config->ill_nuc eq $lender_config->ill_nuc) 
        { 
                if ($config->same_nuc_email eq $SAME_NUC_ILL_LOCAL_SYSTEM) 
                {
                        $same_nuc_only_local  = $TRUE;
                }
                elsif ($config->same_nuc_email eq $SAME_NUC_REQUEST_MSG)  
                {
                        $same_nuc_only_remote  = $TRUE;
                }
        }

	# send the request

        my ($msg_subj, $msg_fmt, $msg_email, $msg_host, $patron_text);      

        use GODOT::ILL::Message::Config;

        ##
        ## $REQUEST_NEW - no holdings found, sending to your own ILL dept so they can find item
        ## $REQUEST_SELF - user has requested an item held at their library
        ## $REQUEST_MEDIATED - request for an item held at another library, sent to your own ILL dept for mediation
        ## $REQUEST_DIRECT - request for an item held at another library, sent directly to remote ILL dept
        ##   

        $result = $TRUE;               ## -initialize result

        if (grep {$ill_fields{'hold_tab_msg_req_type'} eq $_} @ILL_LOCAL_TYPE_ARR)
        {                 
                $patron_text = $ill_fields{'PATR_LAST_NAME_FIELD'};

                $msg_fmt = $config->ill_local_system;

                $msg_host = $config->ill_local_system_host;
                $msg_email = $config->ill_local_system_email;

  
                $sent_to_local_system = $TRUE;        
        }
        elsif ($ill_fields{'hold_tab_msg_req_type'} eq $REQUEST_DIRECT)     
        {       
                ##
                ## -order important !!!
                ##

	        if (grep {$config->ill_local_system eq $_} @GODOT::ILL::Message::Config::SEND_TO_LOCAL) 
                {                        
                        $msg_fmt = $config->ill_local_system;
                        $msg_email = $config->ill_local_system_email;
                        $msg_host = $config->ill_local_system_host;

                        $sent_to_local_system = $TRUE;       
                }
                elsif ($same_nuc_only_local)
                {
                        $patron_text = $ill_fields{'PATR_LAST_NAME_FIELD'};  
   
                        $msg_fmt = $config->ill_local_system;
                        $msg_email = $config->ill_local_system_email;

                        $sent_to_local_system = $TRUE;       
                }
                else 
                {
                        $patron_text = $config->ill_nuc;
                        $msg_fmt = $lender_config->request_msg_fmt;
                        $msg_email = $lender_config->request_msg_email;
                }
        }  
        else 
        {
                &glib::send_admin_email("$0: incorrect hold_tab_msg_req_type ($ill_fields{'hold_tab_msg_req_type'})");
                $result = $FALSE;
        }


        ## 
        ## (15-mar-2000) - temporary fix for problem with patron ids 
        ##               - PATR_LIBRARY_ID_DEF_FIELD is being added multiple times -- we cannot reproduce.....
        ##                 
        
	my $id_def = $config->patr_library_id_def;

        my($prefix_match) = "^($id_def)\\1*" . "(" . strip_white_space($id_def) . ".+)";        

        if ((naws($id_def)) && ($ill_fields{'PATR_LIBRARY_ID_FIELD'} =~ m#$prefix_match#)) {

            &glib::send_admin_email("$0: patron library id field contains multiple PATR_LIBRARY_ID_DEF_FIELD prefixes ($ill_fields{'PATR_LIBRARY_ID_FIELD'}).");

            ##
            ## -set both %ill_fields and param as routines could use either ...
            ##

            $ill_fields{'PATR_LIBRARY_ID_FIELD'} = $2;
            
            param(-name=>'PATR_LIBRARY_ID_FIELD', '-values'=>[$ill_fields{'PATR_LIBRARY_ID_FIELD'}]);  
        }

        ##
        ## -get request number and subject line
        ##

        my $ill_reqno;
	
        if ($result) {

            $ill_reqno = &ill_get_reqno($config->ill_nuc, "G", $GODOT::Config::INSTALLATION_ID);

            if ($ill_reqno eq '')  { $result = $FALSE; }
        }

        use GODOT::ILL::Message;
        ##
        ## -allocate a generic message first so can copy all the fields that stay the same
        ##
        my $message_to_copy = GODOT::ILL::Message->new;

        $message_to_copy->site($config->name);
        $message_to_copy->nuc($config->ill_nuc);        

        $message_to_copy->citation($citation);

        use GODOT::Patron::Data;
        my $patron = GODOT::Patron::Data->new;
        $patron->converted_2(\%ill_fields);
        $message_to_copy->patron($patron);
             
        $message_to_copy->patron_text($patron_text);
        $message_to_copy->sender_name($config->from_name);             
        $message_to_copy->sender_email($config->from_email);             
        $message_to_copy->sender_id($config->ill_id);             

        $message_to_copy->lender_email($lender_config->request_msg_email);             
        $message_to_copy->holdings_site($ill_fields{$HOLDINGS_SITE_FIELD}); 

        my %hold_hash = param($HOLDINGS_FIELD);					 
        $message_to_copy->holdings($hold_hash{$ill_fields{'hold_tab_lender'}});             

        $message_to_copy->fax($config->ill_fax);             

        my $account_number = $config->account_number($ill_fields{'hold_tab_lender'});
        $message_to_copy->account_number($account_number);            

        $message_to_copy->rush_req($ill_fields{'PATR_RUSH_REQ_FIELD'});             
        $message_to_copy->not_req_after($ill_fields{'PATR_NOT_REQ_AFTER_FIELD'});             
        $message_to_copy->max_cost($config->ill_max_cost);

        #### debug "----------------------------------------------";
        #### debug $message_to_copy->dump;
        #### debug "----------------------------------------------";

        my $site = $config->name; 

        my $error_msg;
	my $ill_local_system_request_number;      ## (05-nov-2008 kl) -- added for upei running relais;

        ##
        ## -send main request message 
        ##

        if ($result) {

                $ill_fields{$REQNO_FIELD} = $ill_reqno;         
       
                my $dispatch_site = ($sent_to_local_system) ? $config->name : $lender_config->name;

                my $message = GODOT::ILL::Message->dispatch({'type' => $msg_fmt, 'dispatch_site' => $dispatch_site});

                $message->copy($message_to_copy);

                $message->lender_site($lender_config->name);
                $message->lender_nuc($lender_config->ill_nuc);             
                $message->request_type($ill_fields{'hold_tab_msg_req_type'});             
                $message->email($msg_email) if naws($msg_email);
                $message->host($msg_host) if naws($msg_host);
                
                $result = $message->send($ill_reqno);

                #### debug "result after 'main request' message send:  $result";
                #### debug $message->dump;
                #### debug "----------------------------------------------";
                       
                $error_msg = $message->error_message;
                $ill_local_system_request_number = $message->ill_local_system_request_number;
        }

        ##
        ## send copy to local ill system if request was sent to remote location (don't send twice to local)
        ##

        if ($result && $config->ill_copy_to_local_system && (! $sent_to_local_system) && (! $same_nuc_only_remote ))  
        {
                my $message = GODOT::ILL::Message->dispatch({'type'          => $config->ill_local_system, 
                                                             'dispatch_site' => $site});
                $message->copy($message_to_copy);
                $message->lender_site($lender_config->name);
                $message->lender_nuc($lender_config->ill_nuc);             
                $message->request_type($ill_fields{'hold_tab_msg_req_type'});             
                $message->email($config->ill_local_system_email) if naws($config->ill_local_system_email);
                $message->host($msg_host) if naws($msg_host);
                         
                $result = $message->send($ill_reqno);
                $error_msg = $message->error_message;
                $ill_local_system_request_number = $message->ill_local_system_request_number;

                #### debug "________ result after 'copy to local ill system' message->send:  $result";
        }

	#### debug "ill_local_system_request_number:  $ill_local_system_request_number";
	#### debug join('--', "before patron ack email: ",  $result, $config->ill_email_ack_msg, $ill_fields{'PATR_PATRON_EMAIL_FIELD'});

        ##
        ## send copy to patron
        ##

        if ($result   &&  $config->ill_email_ack_msg && (naws($ill_fields{'PATR_PATRON_EMAIL_FIELD'})))
        {
                my $message = GODOT::ILL::Message->dispatch({'type' => 'PATRON', 'dispatch_site' => $site});
                $message->copy($message_to_copy);
                $message->lender_site($lender_config->name);
                $message->lender_nuc($lender_config->ill_nuc);             
                $message->request_type($ill_fields{'hold_tab_msg_req_type'});             
                $message->email($ill_fields{'PATR_PATRON_EMAIL_FIELD'}) if naws($ill_fields{'PATR_PATRON_EMAIL_FIELD'});
                $message->host($msg_host) if naws($msg_host);
                         
		$message->additional_text($config->ill_email_ack_msg_text);         

                $result = $message->send($ill_reqno);
                $error_msg = $message->error_message;

                #### debug "________ result after 'send copy to patron' message send:  $result";
        }

        ##
        ## log that request(s) was sent
        ##

        if ($result) 
        {
                ##
                ## backward compatibility with ill_log
                ##
                $ill_fields{'hold_tab_msg_addr'} = naws($msg_host) ? $msg_host : $msg_email;     
                &glog::ill_log($GODOT::Config::LOG_FILE, \%ill_fields);
               
                $page->ill_local_system_request_number($ill_local_system_request_number) unless aws($ill_local_system_request_number);
               
		if ($config->use_request_acknowledgment_screen)
		{        
			&request_acknowledgment_screen($cgi, $page, $config, $citation);
		}		
		else 
		{
                        if (! aws($ill_fields{'hold_tab_back_url'}))   
                        {

			        $cgi->redirect($ill_fields{'hold_tab_back_url'});
                        }
                        else 
                        {
                                #
                                # -citation fields required if back URL was HTTP_REFERER - instead of creating
                                #  long URL with hidden fields, changed to call main_hold_scr directly
                                #  
			        $cgi->action($START_ACT);
                                $cgi->new_screen('main_holdings_screen');
                                &main_holdings_screen($cgi, $page, $config, $citation);
                        }
		}
	}
	
	else 
	{ 
	        $page->messages([naws($error_msg) ? $error_msg : "Couldn't format request for output."]);
                $cgi->new_screen('request_other_error_screen');
	}
	
	return;
} 


## 
## -do a request number based on year month
##
## (03-mar-1999 kl) -return null on failure 
##                  -mail to godot admin on error
##
sub ill_get_reqno  {
    my($user, $prefix, $installation_id) = @_;    

    my($reqno_path) = $GODOT::Config::REQNO_DIR;

    my($reqfile)  = "$reqno_path/".$user."_reqno";
    my($lockfile) = "$reqno_path/".$user."_lock";

    use GODOT::Date;
    my($date)  = &GODOT::Date::date_yymmdd(time);
    my($year)  = substr($date, 0, 2);
    my($month) = substr($date, 2, 2);

    my($num)   = 1;

    if (aws($installation_id)) {
        &glib::send_admin_email("$0:  installation id was blank"); 
        return '';    
    }

    if (aws($user)) {
        &glib::send_admin_email("$0:  user was blank"); 
        return '';    
    }

    if (-e $reqfile) {

        my($count) = 0;

        while (-e $lockfile) {
            $count++;
            sleep(1);

            &glib::send_admin_email("$0:  unable to lock request number ($lockfile)");             

            if ($count==20) {  return ''; }       ## -unable to 'lock' request numbers, so return failure  
        }

        if (system("echo '***' > $lockfile")) {  
            &glib::send_admin_email("$0:  unable to write to ($lockfile)");             
            return ''; 
        }

        if (! open(REQFILE, "<$reqfile")) {
            &glib::send_admin_email("$0:  unable to open request number file ($reqfile)");   
            return '';
        }

        my($old_reqno) = <REQFILE>;
        close(REQFILE);

        ##
        ## -check format of $old_reqno in case file has become corrupt
        ## -format should be YYMM999999
        ##
       
        chop $old_reqno;


        if ($old_reqno !~ m#^\d{9,9}$#) {

            &glib::send_admin_email("$0:  request number from $reqfile was in an invalid format ($old_reqno)");                
            return '';
        }

        my($old_month) = substr($old_reqno,2,2);

        ##
        ## -if at some point this logic is changed such that $old_num is assigned as a number with leading zeros
        ##  (ie. $old_num = 000010) then it will be interpretted as hex -- be careful!!!!
        ##   
        ##

        my($old_num)   = substr($old_reqno, 4);             ## -the rest of old reqno

        if ($month == $old_month) {
            $num = $old_num;
            $num++;
        }
    }
    else {
        if (system("echo '***' > $lockfile")) {  
            &glib::send_admin_email("$0:  unable to write to ($lockfile)");             
            return ''; 
        }
    }

    ##
    ## (03-mar-1999 kl) - use leading zeros so number always fixed length
    ##

    my($reqno) = sprintf("$year$month%05d", $num);

    if (! open(REQFILE, ">$reqfile")) {
        &glib::send_admin_email("$0:  unable to open request number file ($reqfile)");   
        return '';
    }
    print REQFILE $reqno, "\n";
    close(REQFILE);

    if (! unlink $lockfile) {
        &glib::send_admin_email("$0:  unable to remove $lockfile");        
        return '';                                                  ## -return failure
    }

    my($ret_str) = "$prefix-$user$reqno-$installation_id";

    return $ret_str;
}







1;


