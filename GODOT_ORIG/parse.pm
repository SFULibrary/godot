package parse;

##
## !!!!! remember this gets run mod_perl and not CGI !!!!
##

use GODOT::String;
use GODOT::Date;
use GODOT::Debug;

require hold_tab;       ## -chg circular requires....
require openurl;

use CGI qw(-no_xhtml :standard);
 
use Text::Striphigh 'striphigh';

use strict;

use vars qw($TRUE $FALSE);
$TRUE  = 1;
$FALSE = 0;

##
## !!!!!!!!!!!!!!!! values must be the same as those used in GODOT::Page object !!!!!!!!!!!!!
##

use vars qw($CITN_SUCCESS $CITN_NEED_ARTICLE_INFO $CITN_FAILURE);

$CITN_SUCCESS           = 'citn_success';
$CITN_NEED_ARTICLE_INFO = 'citn_need_article_info';
$CITN_FAILURE           = 'citn_failure';

## 
## (14-mar-2003 kl) - new citation requirement logic only requires title, ISSN or ISBN for searching
##                  - more details, however, are needed for an ILL request
##
use vars qw($CITN_CHECK_FOR_SEARCH $CITN_CHECK_FOR_REQ);

$CITN_CHECK_FOR_SEARCH  = 'citn_check_for_search';
$CITN_CHECK_FOR_REQ     = 'citn_check_for_requesting';


##-----------------------------------------------------------------------
##  -fields used to pass data to holdings table CGI via hidden fields
##  -'PRE' refers to this is data BEFORE any parsing is done, ie. it is
##   the data direct from the database interface.
##-----------------------------------------------------------------------
use vars qw(%CITN_PRE_ABBREV_HASH);

use vars qw(@CITN_PRE_ARR);

use vars qw($PT_PRE_FIELD   $DT_PRE_FIELD   $TI_PRE_FIELD   $AU_PRE_FIELD
            $PY_PRE_FIELD   $IS_PRE_FIELD   $ISSN_PRE_FIELD $SO_PRE_FIELD
            $SE_PRE_FIELD   $JN_PRE_FIELD   $AS_PRE_FIELD   $PB_PRE_FIELD
            $SN_PRE_FIELD   $RT_PRE_FIELD   $IB_PRE_FIELD   $PG_PRE_FIELD
            $VOL_PRE_FIELD  $ISS_PRE_FIELD  $MON_PRE_FIELD  $BN_PRE_FIELD
            $PUB_PRE_FIELD  $NU_PRE_FIELD   $CA_PRE_FIELD   $AV_PRE_FIELD
            $ISBN_PRE_FIELD $AD_PRE_FIELD   $CT_PRE_FIELD   $AN_PRE_FIELD 
            $LV_PRE_FIELD   $NT_PRE_FIELD   $CP_PRE_FIELD   $CS_PRE_FIELD
            $ON_PRE_FIELD   $MN_PRE_FIELD   $SID_PRE_FIELD  $UR_PRE_FIELD
            $ED_PRE_FIELD   $FT_PRE_FIELD   $BK_PRE_FIELD   $BA_PRE_FIELD
            $BL_PRE_FIELD   $CN_PRE_FIELD   $DI_PRE_FIELD   $DG_PRE_FIELD
            $NN_PRE_FIELD   $RN_PRE_FIELD   $HC_PRE_FIELD   $DA_PRE_FIELD
            $JT_PRE_FIELD   $FA_PRE_FIELD   $DL_PRE_FIELD   $PN_PRE_FIELD
            $ST_PRE_FIELD   $PD_PRE_FIELD   $CY_PRE_FIELD   $PU_PRE_FIELD
);

##
## -T000 refers to the leader  
##

use vars qw($T000_PRE_FIELD 
            $T001_PRE_FIELD 
            $T008_PRE_FIELD 
            $T020_PRE_FIELD
            $T022_PRE_FIELD 
            $T027_PRE_FIELD 
            $T035_PRE_FIELD 
            $T090_PRE_FIELD 
            $T099_PRE_FIELD
            $T100_PRE_FIELD 
            $T110_PRE_FIELD
            $T111_PRE_FIELD 
            $T245_PRE_FIELD 
            $T250_PRE_FIELD 
            $T260_PRE_FIELD
            $T440_PRE_FIELD 
            $T700_PRE_FIELD 
            $T773_PRE_FIELD 
            $T775_PRE_FIELD 
            $T800_PRE_FIELD 
            $T852_PRE_FIELD 
            $T856_PRE_FIELD
            $T907_PRE_FIELD
            $T920_PRE_FIELD 
            $T926_PRE_FIELD
            $T979_PRE_FIELD
            $T984_PRE_FIELD
            $T988_PRE_FIELD
            $T992_PRE_FIELD);

##
## !!!! if fields get added to this array that are not for Webspirs to godot link !!!!
## !!!! (eg. SLRI to godot link) then one may have to change link_info.cgi        !!!!
##

@CITN_PRE_ARR = (

    $PN_PRE_FIELD   = 'hold_tab_pn',    # ICL - Journal name
    $PD_PRE_FIELD   = 'hold_tab_pd',    # ICL - Publish date
    $PU_PRE_FIELD   = 'hold_tab_pu',    # ICL - Publisher name
    $CY_PRE_FIELD   = 'hold_tab_cy',    # ICL - Publisher city

    $PT_PRE_FIELD   = 'hold_tab_pt',
    $DT_PRE_FIELD   = 'hold_tab_dt',
    $TI_PRE_FIELD   = 'hold_tab_ti',
    $PB_PRE_FIELD   = 'hold_tab_pb',
    $CT_PRE_FIELD   = 'hold_tab_ct',

    $CA_PRE_FIELD   = 'hold_tab_ca',
    $AU_PRE_FIELD   = 'hold_tab_au',
    $PY_PRE_FIELD   = 'hold_tab_py',
    $AD_PRE_FIELD   = 'hold_tab_ad',

    $IS_PRE_FIELD   = 'hold_tab_is',
    $SN_PRE_FIELD   = 'hold_tab_sn',
    $ISSN_PRE_FIELD = 'hold_tab_issn',
    $ISBN_PRE_FIELD = 'hold_tab_isbn',
    $NU_PRE_FIELD   = 'hold_tab_nu',	

    $IB_PRE_FIELD   = 'hold_tab_ib',
    $BN_PRE_FIELD   = 'hold_tab_bn',

    $SO_PRE_FIELD   = 'hold_tab_so',
    $SE_PRE_FIELD   = 'hold_tab_se',

    $JN_PRE_FIELD   = 'hold_tab_jn',
    $AS_PRE_FIELD   = 'hold_tab_as',
  
    $RT_PRE_FIELD   = 'hold_tab_rt',
    $PG_PRE_FIELD   = 'hold_tab_pg',
    $AV_PRE_FIELD   = 'hold_tab_av',

    $VOL_PRE_FIELD  = 'hold_tab_vol',      ## for HW Wilson databases via SLRI and for blankform
    $ISS_PRE_FIELD  = 'hold_tab_iss',      ## for HW Wilson databases via SLRI and for blankform
    $MON_PRE_FIELD  = 'hold_tab_mon',      ## for HW Wilson databases via SLRI and for blankform
    $PUB_PRE_FIELD  = 'hold_tab_pub',      ## for HW Wilson databases via SLRI and for blankform

    $AN_PRE_FIELD   = 'hold_tab_an',
    $LV_PRE_FIELD   = 'hold_tab_lv',

    $NT_PRE_FIELD   = 'hold_tab_nt',
    $CP_PRE_FIELD   = 'hold_tab_cp',
    $CS_PRE_FIELD   = 'hold_tab_cs',

    $ON_PRE_FIELD   = 'hold_tab_on',
    $MN_PRE_FIELD   = 'hold_tab_mn',       ## Microlog number (ex. 96-04469) - CRI database
    $SID_PRE_FIELD  = 'hold_tab_sid',      ## System ID (DRA database ctrl num) - Graeme Clark
    $UR_PRE_FIELD   = 'hold_tab_ur',       ## URL in record - may be to fulltext
    $ED_PRE_FIELD   = 'hold_tab_ed',       ## edition field
    $FT_PRE_FIELD   = 'hold_tab_ft',       ## fulltext available - !!!! not required for ERL db so have 
                                           ##                      added logic to http://delos.lib.sfu.ca/perl/link_info.cgi
                                           ##                      to strip out !!!! - problem is that FT is used for fulltext 
    $BK_PRE_FIELD   = 'hold_tab_bk',       ## originally added as book title field for Georef
    $BA_PRE_FIELD   = 'hold_tab_ba',       ## originally added as book author field for Georef
    $BL_PRE_FIELD   = 'hold_tab_bl',       ## originally added as bib level for Georef - required to determine request type 
                                           ## - !!! did this get used ???
    $CN_PRE_FIELD   = 'hold_tab_cn',       ## originally added as conference information for Georef 
    $DI_PRE_FIELD   = 'hold_tab_di', 
    $DG_PRE_FIELD   = 'hold_tab_dg', 

    $NN_PRE_FIELD   = 'hold_tab_nn',       ## originally added as annotation field for Georef
    $RN_PRE_FIELD   = 'hold_tab_rn',       ## originally added as report number field for Georef              

    $HC_PRE_FIELD   = 'hold_tab_hc',       ## For SocWork
    $DA_PRE_FIELD   = 'hold_tab_da',       ## For SocWork
    
    $FA_PRE_FIELD   = 'hold_tab_fa', 	   ## CBCA FT Education
    $JT_PRE_FIELD   = 'hold_tab_jt',       ## CWI
    $DL_PRE_FIELD   = 'hold_tab_dl',       ## ERIC document link field

    $T000_PRE_FIELD = 'hold_tab_t000',     ## MARC leader
    $T001_PRE_FIELD = 'hold_tab_t001',     ## MARC 001
    $T008_PRE_FIELD = 'hold_tab_t008',     ## MARC 008 (Fixed Length Data Elements)   
    $T020_PRE_FIELD = 'hold_tab_t020',
    $T022_PRE_FIELD = 'hold_tab_t022',     
    $T027_PRE_FIELD = 'hold_tab_t027',     
    $T035_PRE_FIELD = 'hold_tab_t035',
    $T090_PRE_FIELD = 'hold_tab_t090',     
    $T099_PRE_FIELD = 'hold_tab_t099',     
    $T100_PRE_FIELD = 'hold_tab_t100', 
    $T110_PRE_FIELD = 'hold_tab_t110', 
    $T111_PRE_FIELD = 'hold_tab_t111', 
    $T245_PRE_FIELD = 'hold_tab_t245', 
    $T250_PRE_FIELD = 'hold_tab_t250', 
    $T260_PRE_FIELD = 'hold_tab_t260', 
    $T440_PRE_FIELD = 'hold_tab_t440', 
    $T700_PRE_FIELD = 'hold_tab_t700', 
    $T773_PRE_FIELD = 'hold_tab_t773', 
    $T775_PRE_FIELD = 'hold_tab_t775', 
    $T800_PRE_FIELD = 'hold_tab_t800',
    $T852_PRE_FIELD = 'hold_tab_t852',
    $T856_PRE_FIELD = 'hold_tab_t856', 
    $T907_PRE_FIELD = 'hold_tab_t907', 
    $T920_PRE_FIELD = 'hold_tab_t920',
    $T926_PRE_FIELD = 'hold_tab_t926',
    $T979_PRE_FIELD = 'hold_tab_t979',
    $T984_PRE_FIELD = 'hold_tab_t984',
    $T988_PRE_FIELD = 'hold_tab_t988',
    $T992_PRE_FIELD = 'hold_tab_t992',
);

##
## (08-oct-1999 kl) - used for ebscohost as they needed shortnames due to size restrictions at their end
##

use vars qw($OPENURL_SYNTAX);
$OPENURL_SYNTAX = 'openurl_syntax';

use vars qw(@ISSN_FIELD_ARR @ISBN_FIELD_ARR);

@ISSN_FIELD_ARR = ($IS_PRE_FIELD, $ISSN_PRE_FIELD, $SN_PRE_FIELD, $NU_PRE_FIELD, $T022_PRE_FIELD);

@ISBN_FIELD_ARR = ($IB_PRE_FIELD, $BN_PRE_FIELD, $SN_PRE_FIELD, $IS_PRE_FIELD, $NU_PRE_FIELD, $ISBN_PRE_FIELD, $T020_PRE_FIELD);;

##---------------------------------------------------------------------
use vars qw(@ITEM_ART_INP_ARR 
            @ALLOW_NO_ARTICLE_TITLE_DB_ARR 
            @DBASE_DOS_EXTENDED %DOS_TO_UNIX_EXTENDED);


@ITEM_ART_INP_ARR = ($hold_tab::JOURNAL_TYPE, $hold_tab::CONFERENCE_TYPE);


## -if a journal article citation comes from one of these databases/e-journals and does not 
##  include an article title, but does include an article author or page information, process it anyways
##
## -this lack of an article title can be a problem with science citations
##

@ALLOW_NO_ARTICLE_TITLE_DB_ARR = ('unknown',
                                  'iopp');


#
# Databases that may have extended characters in them which follow the
# standard DOS extended character set.  UNIX seems to use a different 
# character set.
#
@DBASE_DOS_EXTENDED = ('cbcafe', 'icl');

# Conversion table from DOS extended to UNIX extended character sets.
# In DECIMAL.
%DOS_TO_UNIX_EXTENDED = (
	'128' => 199,  # C
	'129' => 252,  # u-umlat
	'130' => 233,  # e-acute
	'131' => 226,  # a-hat
	'132' => 228,  # a-umlat
	'133' => 224,  # a-grave
	'134' => 229,  # a-o
	'135' => 231,  # c
	'136' => 234,  # e-hat
	'137' => 235,  # e-umlat
	'138' => 232,  # e-grave
	'139' => 239,  # i-umlat
	'140' => 238,  # i-hat
	'141' => 236,  # i-grave
	'142' => 196,  # A-umlat
	'143' => 197,  # A-o
	'144' => 201,  # E-acute
	'145' => 230,  # ae
	'146' => 198,  # AE
	'147' => 244,  # o-hat
	'148' => 246,  # o-umlat
	'149' => 242,  # o-grave
	'150' => 251,  # u-hat
	'151' => 249,  # u-grave
	'153' => 214,  # O-umlat
	'154' => 220,  # U-umlat
	'156' => 158,  # Pound sign
	'157' => 165   # Yen??
);



##----------------------------------------------------------------------------------
##
## -cleanup that we want to apply seperately from the &parse() logic 
##
## -(article data from user does not currently go through &parse(), however
##   we still want some cleanup done)
##
sub second_pass_field_cleanup {
    my($citation_ref) = @_;

    my($year);

    ##
    ## -strip year out of month field
    ##
    if (${$citation_ref}{$hold_tab::MONTH_FIELD} =~ m#(\d\d\d\d)#) {
        $year = $1;

        if ($year eq ${$citation_ref}{$hold_tab::YEAR_FIELD})   {    ## -if same then strip off as it is dup info

            ${$citation_ref}{$hold_tab::MONTH_FIELD} =~ s#\d\d\d\d##;
        }
    }

    ##
    ## -fill voliss, if possible, so voliss logic does not have to be repeated in different request formats (16-feb-1998 kl)
    ##
    if (! (aws(${$citation_ref}{$hold_tab::VOL_FIELD}) || aws(${$citation_ref}{$hold_tab::ISS_FIELD}))) {

        ${$citation_ref}{$hold_tab::VOLISS_FIELD} = 
            "${$citation_ref}{$hold_tab::VOL_FIELD} \(${$citation_ref}{$hold_tab::ISS_FIELD}\)";
    }
    elsif ((aws(${$citation_ref}{$hold_tab::VOLISS_FIELD})) && (! aws(${$citation_ref}{$hold_tab::VOL_FIELD}))) {

        ${$citation_ref}{$hold_tab::VOLISS_FIELD} = ${$citation_ref}{$hold_tab::VOL_FIELD}; 
    }
    elsif ((aws(${$citation_ref}{$hold_tab::VOLISS_FIELD})) && (! aws(${$citation_ref}{$hold_tab::ISS_FIELD}))) {

        ${$citation_ref}{$hold_tab::VOLISS_FIELD} = "\(${$citation_ref}{$hold_tab::ISS_FIELD}\)";  
    }

    ##
    ## -clean up so don't have to do whitespace check later - can just check for NULL
    ##    
    foreach (@hold_tab::CITN_ARR) { 

        if (aws(${$citation_ref}{$_})) { ${$citation_ref}{$_} = ''; }

        ##
        ## -see GODOT::Parser for similar change
        ##

        ${$citation_ref}{$_} =~ s#\000##g;
        ${$citation_ref}{$_} =~ s#\226#-#g;                 
    } 
}



##
## -returns $CITN_SUCCESS, $CITN_NEED_ARTICLE_INFO OR $CITN_FAILURE
##
sub check_citation {
    my($citation, $prev_screen, $check_type, $citation_ref, $message_ref, $first_time) = @_;
   
    my(@missing_arr); 
    my($admin_msg, $missing_field_text, $reqtype);

    $reqtype = ${$citation_ref}{$hold_tab::REQTYPE_FIELD};

    ##
    ## (27-feb-2004 kl) - added $MAIN_HOLD_SCR to list so that would work when SKIP_MAIN_HOLD_SCR_IF_NO_HOLD is true
    ##
    ##
    ## -check that the browser has loaded all the hidden fields
    ##

    if (! grep {$prev_screen eq $_} ($hold_tab::MAIN_HOLD_SCR, $hold_tab::NO_SCR, ''))  {

        if (! param($hold_tab::HIDDEN_COMPLETE_FIELD)) {

            $admin_msg = 'Previous page did not load completely.  Please go back and reload.';
            &glib::send_admin_email($admin_msg);
            ${$message_ref} = $admin_msg;

            return $CITN_FAILURE;
        }
    }



    if ($citation->get_dbase()->is_blank_dbase()) {
        $missing_field_text = "More citation information is required. Please fill in as much information as possible.";
    }
    else {
        ##
        ## (29-aug-2007 kl) - changed as per pg/ns request;
        ##
        #### $missing_field_text = "Not enough information was extracted from citation to continue." . "<P>Please consult your library catalogue for holdings.";
        $missing_field_text =  "Sorry, we can't tell whether we have this item based on the information provided. Please look up the title in your library's catalogue."; 
    }

    ##
    ## -do we have a request type?
    ##

    if ($citation->is_unknown()) {    

	push(@missing_arr, $gconst::REQTYPE_FIELD);

        $admin_msg .= &missing_field_msg(\@missing_arr, $citation_ref);
        $admin_msg = sprintf("%s is %s\n\n%s", $hold_tab::DBASE_FIELD, param($hold_tab::DBASE_FIELD), $admin_msg);
        &glib::send_admin_email($admin_msg);
        ${$message_ref} = $missing_field_text;
        return $CITN_FAILURE;
    }

    ##
    ## (12-mar-2003 kl) - allow user to fill in information for any type of citation so that
    ##                    godot will work with minimal OpenURL (and other linking) implementations
    ##                    (eg. those that only pass ISSN)


    ##
    ## -check whether we have enough citation data to do a search
    ##
    ##    
    ## -preprint and item level checking 
    ##

    if (($reqtype eq $gconst::PREPRINT_TYPE) && (! ${$citation_ref}{$gconst::OAI_FIELD})) {  

        push(@missing_arr, $gconst::OAI_FIELD);
    }
    ##
    ## (12-mar-2003 kl) - make godot work with minimal linking implementations (eg. issn only)
    ##                  - you now need only one of title, issn or isbn
    ##
    elsif ($reqtype ne $gconst::PREPRINT_TYPE) {

        if (! (${$citation_ref}{$hold_tab::TITLE_FIELD}  || 
               ${$citation_ref}{$hold_tab::ISBN_FIELD}   || 
               ${$citation_ref}{$hold_tab::ISSN_FIELD}))      { 
    
            $admin_msg .= "*** do not have sufficient title/ISBN/ISSN info ***\n";
              
            foreach my $field (${$citation_ref}{$hold_tab::TITLE_FIELD}, 
                               ${$citation_ref}{$hold_tab::ISBN_FIELD},
                               ${$citation_ref}{$hold_tab::ISSN_FIELD})    {          
             
                if (! ${$citation_ref}{$field}) { push(@missing_arr, ${$citation_ref}{$field}); }
            }            
        }
    }


    if (@missing_arr) {

        $admin_msg .= &missing_field_msg(\@missing_arr, $citation_ref); 
                
        $admin_msg = sprintf("%s is %s\n\n%s", $hold_tab::DBASE_FIELD, param($hold_tab::DBASE_FIELD), $admin_msg);

        &glib::send_admin_email($admin_msg);
        ${$message_ref} = $missing_field_text;
        return $CITN_FAILURE; 
    }

    ##
    ## -if preprint has an Open Archive identifier (checked above) then we have enough info, so return success 
    ##    

    if ($reqtype eq $gconst::PREPRINT_TYPE) { return $CITN_SUCCESS; }

    ##
    ## -for data entered in a blank form, check format of year, ISSN and ISBN
    ##

    if ($citation->get_dbase()->is_blank_dbase()) {

        my($year) = trim_beg_end(${$citation_ref}{$hold_tab::YEAR_FIELD});
        my($issn) = trim_beg_end(${$citation_ref}{$hold_tab::ISSN_FIELD});

        my($continue_msg) = p . "Please correct before continuing.";

        if (naws($year)) {

            if (naws($year !~ m#^\d\d\d\d$#)) {

                ${$message_ref} = "Year should contain four digits, i.e. 1979.";

                if ($prev_screen eq $hold_tab::ART_INP_SCR) { 
                    return $CITN_NEED_ARTICLE_INFO; 
                }
                else  {
                     ${$message_ref} .= " $continue_msg"; 
                     return $CITN_FAILURE;           
                } 

            }

            my($max_date) = &GODOT::Date::date_yyyy(time) + 1;
            my($min_date) = 1000;

            if (($min_date > $year) || ($max_date < $year)) {

                ${$message_ref} = "Year should be between $min_date and $max_date.";
                
                if ($prev_screen eq $hold_tab::ART_INP_SCR) {
                    return $CITN_NEED_ARTICLE_INFO;
                }
                else  {
                     ${$message_ref} .= " $continue_msg";
                     return $CITN_FAILURE;
                } 
            }
        }

        ##
        ## -new ISBN parsing logic extracts ISBN only if it is valid so to look for input errors we 
        ##  need the ISBN before parsing
        ##
        my($isbn) = trim_beg_end($citation->pre('ISBN'));

        if (naws($isbn)) {

            my $valid_isbn = valid_ISBN($isbn);

            unless ($valid_isbn) {

                 ${$message_ref} = join(' ', '<b>You have entered an invalid ISBN.</b>  The ISBN should consist of ten or thirteen',
                                             'digits with the exception of the last character, which may be a digit or an X.',  
                                             'If you have entered a correct number of characters, then the problem may be',
				             'that the final character (a check digit) is not correct.',
                                             'Example ISBNs are 1-56619-909-3 and 979-1-56619-909-3.',
                                             $continue_msg);

                 return $CITN_FAILURE; 
             }                  
        }

        if (naws($issn)) {

            if (! (valid_ISSN_s_ok($issn) || valid_ISSN_no_hyphen_s_ok($issn)))   {

                ${$message_ref} = 
                   "Invalid ISSN. ISSN format is '9999-9999' or '9999-999X', " . 
                   "where '9' is a digit from '0' to '9', i.e. 0234-7854. " . 
                   $continue_msg;

                return $CITN_FAILURE; 
            }
        }
    }

    ## 
    ## -check whether we have enough information to do an ILL request
    ##   

    #### warn "******** <$check_type> <$reqtype> <${$citation_ref}{$hold_tab::TITLE_FIELD}>\n";

    ##
    ## (15-may-2002 kl) - added '$citation->need_article_info()' logic to deal with openurl genre=journal
    ##

    if ($check_type eq $CITN_CHECK_FOR_REQ) {

        if (! ${$citation_ref}{$hold_tab::TITLE_FIELD}) {

            return $CITN_NEED_ARTICLE_INFO;
        }
        ##
        ## -when coming from the blank input form, give user the opportunity to add journal article 
        ##  and conference paper details
        ##
        ## -in the case of conference paper details, they are not mandatory so only display 
        ##  the citation info screen once
        ##
        elsif ($first_time && ($citation->get_dbase()->is_item_dbase()) && (grep {$reqtype eq $_} @ITEM_ART_INP_ARR))  {

            return $CITN_NEED_ARTICLE_INFO;
        }        
        elsif ($reqtype eq $hold_tab::BOOK_ARTICLE_TYPE) {    
   
            if (! ${$citation_ref}{$hold_tab::ARTTIT_FIELD}) { push(@missing_arr, $hold_tab::ARTTIT_FIELD); }
        }
        elsif ($reqtype eq $hold_tab::JOURNAL_TYPE) {   

            if (&no_article_title_ok($citation->dbase())) {

                ## do nothing
            }
            elsif (! ${$citation_ref}{$hold_tab::ARTTIT_FIELD}) { 

                push(@missing_arr, $hold_tab::ARTTIT_FIELD);
            }

            ##
            ## (23-jan-2003) -minimum article information
            ##
    
            if ((${$citation_ref}{$hold_tab::YEAR_FIELD} && ${$citation_ref}{$hold_tab::PGS_FIELD}) ||
                (${$citation_ref}{$hold_tab::VOLISS_FIELD})                                         ||
                (${$citation_ref}{$hold_tab::VOL_FIELD} && ${$citation_ref}{$hold_tab::PGS_FIELD})  ||
                (${$citation_ref}{$hold_tab::VOL_FIELD} && ${$citation_ref}{$hold_tab::ISS_FIELD})  ||
                (${$citation_ref}{$hold_tab::YEAR_FIELD} && ${$citation_ref}{$hold_tab::MON_FIELD}))      {

                ##
                ## -we have enough info  
                ## 
            }
            else {

                   $admin_msg .= "*** do not have sufficient year/volume/issue/month/page info ***\n";
              
                   foreach my $field (${$citation_ref}{$hold_tab::YEAR_FIELD}, 
                                      ${$citation_ref}{$hold_tab::VOL_FIELD},
                                      ${$citation_ref}{$hold_tab::MONTH_FIELD}, 
                                      ${$citation_ref}{$hold_tab::ISS_FIELD},
                                      ${$citation_ref}{$hold_tab::VOLISS_FIELD}) {          

                       if (! ${$citation_ref}{$field}) { push(@missing_arr, ${$citation_ref}{$field}); }
                   }
              }  
        }


        if (@missing_arr) { return $CITN_NEED_ARTICLE_INFO; }

    }

    return $CITN_SUCCESS;
}


##-----------------------------------------------------------------------------------

sub missing_field_msg {
    my($missing_arr_ref, $citation_ref) = @_;

    my($string);

    if (@{$missing_arr_ref}) { $string .= "*** missing fields ***\n"; }

    foreach (@{$missing_arr_ref}) { $string .= "    $_\n"; }  
         
    if (@{$missing_arr_ref}) {

        $string .= "\n-------parsed-citation-info---------\n";    
        foreach (keys %{$citation_ref}) { $string .= "$_ = ${$citation_ref}{$_}\n"; } 
        $string .= "------------------------------------\n\n";  

        $string .= "--citation-info-from-db-interface---\n";    
        foreach (@CITN_PRE_ARR) { $string .= "$_ = " . param($_) . "\n"; } 
        $string .= "------------------------------------\n\n";  
    }

    return $string;
}


sub no_article_title_ok {
    my($dbase) = @_;

    if ((grep {$dbase eq $_} @ALLOW_NO_ARTICLE_TITLE_DB_ARR)  && 
        (naws(param($gconst::ARTAUT_FIELD)) || naws(param($gconst::PGS_FIELD))))  {

        return $TRUE;
    }

    return $FALSE;
}


1;

