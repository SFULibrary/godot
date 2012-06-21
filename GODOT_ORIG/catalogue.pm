package catalogue;

use CGI qw(-no_xhtml :standard :html3);

require gconst;
require glib;

use GODOT::String;
use GODOT::Debug;
use GODOT::Citation;
use GODOT::Config;
use GODOT::CatalogueHoldings::BibCirc;
use GODOT::CatalogueHoldings::Source;

use GODOTConfig::Configuration;
use GODOTConfig::Cache;

use Data::Dump qw(dump);

use strict;

use vars qw($HOLDINGS_TYPE  $URL_LINK_TYPE);
$HOLDINGS_TYPE = 'catalogue_holdings_type';
$URL_LINK_TYPE = 'catalogue_url_link_type';

my $TRUE  = 1;
my $FALSE = 0;

use vars qw($MARC_TAG_INDENT $INDICATOR_INDENT $MAXIMUM_HITS $NON_MARC_TAG $NUC_BRANCH_DELIM_PATT);
$MARC_TAG_INDENT  = 4;
$INDICATOR_INDENT = 3;

$MAXIMUM_HITS = 350;

$NON_MARC_TAG = 'XXX';       ## -use to hold all non-marc data in OPAC syntax from III and Endeavor

$NUC_BRANCH_DELIM_PATT = '\.';

use vars qw($SHORT_FMT $LONG_FMT);

$SHORT_FMT = 'short_fmt';
$LONG_FMT  = 'long_fmt';

##----------------------------------------------------------------------------------------------------

my $MARC_ISBN_FIELD               = '020';
my $MARC_ISSN_FIELD               = '022';
my $MARC_TITLE_FIELD              = '245';
my $MARC_VARYING_FORM_TITLE_FIELD = '246';

##----------------------------------------------------------------------------------------------------
##
## -fields used to store bib and circ info in hash
##
## -additions/deletions of fields will mean that following need to be updated:
##      1. &fill_bib_circ(...) 
##      2. &fmt_bib_circ(...), 
##      3. %BIB_CIRC_LABEL_HASH 
##      4. @BIB_CIRC_SCALAR_ARR, @BIB_CIRC_LIST_ARR, @BIB_CIRC_LIST_OF_LIST_ARR 
##
## -using hashes of type bib_circ we can create a structure that shows all bib and circ info for mult sites
##  (for a specified citation)
##  
##  $holdings_hash{<user>} = [{%bib_circ_hash}, {%bib_circ_hash}, ....]
## 
##
use vars qw(%BIB_CIRC_LABEL_HASH);
use vars qw(@BIB_CIRC_ARR  @BIB_CIRC_SCALAR_ARR  @BIB_CIRC_LIST_ARR  @BIB_CIRC_LIST_OF_LIST_ARR);      

use vars qw($BIB_CIRC_DB          $BIB_CIRC_DB_SYSTEM $BIB_CIRC_USER       $BIB_CIRC_TITLE        $BIB_CIRC_MARC_TITLE
            $BIB_CIRC_ISSN        
            $BIB_CIRC_ISBN        $BIB_CIRC_CALL_NO   $BIB_CIRC_SEARCH_ONE  
            $BIB_CIRC_SEARCH_LIST $BIB_CIRC_CAT_URL   $BIB_CIRC_BIB_URL    $BIB_CIRC_HOLDINGS     $BIB_CIRC_SIRSI_HOLDINGS  
            $BIB_CIRC_MLOG_COLL   $BIB_CIRC_ERIC_COLL $BIB_CIRC_CIRC       $BIB_CIRC_NOTE);

@BIB_CIRC_ARR = (      
    $BIB_CIRC_DB             = 'bib_circ_db',              ## -single - source of bib/circ info
    $BIB_CIRC_DB_SYSTEM      = 'bib_circ_db_system',       ## -single - system that stores/indexes source of bib/circ info
    $BIB_CIRC_USER           = 'bib_circ_user',            ## -single - user to which holdings belong
                                                           ## -above two fields will be the same if the holdings were 
                                                           ##  retrieved from the users catalogue, but will be different,
                                                           ##  for example, if the holdings were retrieved from a union
                                                           ##  catalogue (ex. union serials list)
    $BIB_CIRC_TITLE          = 'bib_circ_title',           ## -multiple
    $BIB_CIRC_MARC_TITLE     = 'bib_circ_marc_title',      ## -multiple
    $BIB_CIRC_ISSN           = 'bib_circ_issn',            ## -multiple
    $BIB_CIRC_ISBN           = 'bib_circ_isbn',            ## -multiple
    $BIB_CIRC_CALL_NO        = 'bib_circ_call_no',         ## -multiple
                                                           ##
    $BIB_CIRC_ERIC_COLL      = 'bib_circ_eric_coll',       ## -single
    $BIB_CIRC_MLOG_COLL      = 'bib_circ_mlog_coll',       ## -single
                                                           ## 
                                                           ##
    $BIB_CIRC_CAT_URL        = 'bib_circ_cat_url',         ## -multiple - URL(s) to get to this item via web interface
    $BIB_CIRC_BIB_URL        = 'bib_circ_bib_url',         ## -multiple - URL(s) found in bib record (ie. 856 field values)
                                                           ##           - ie. [[<text>, <url>], [...], [...], .....]
                                                           ##
    $BIB_CIRC_HOLDINGS       = 'bib_circ_holdings',        ## -multiple - each item is a ref to a list of list ref
                                                           ##           - ie. [[<nuc>, <holdings summ stmts>], [...], [...]]
                                                           ##
    $BIB_CIRC_SIRSI_HOLDINGS = 'bib_circ_sirsi_holdings',  ## -multiple - each item is a ref to a list of list ref
                                                           ##           - ie. [[<nuc>, <holdings summ stmts>], [...], [...]] 
                                                           ##           - holdings summary statements are in SIRSI display format, 
                                                           ##             including HTML tags
                                                           ##
    $BIB_CIRC_CIRC           = 'bib_circ_circ',            ## -multiple - each item is a ref to a list of list ref
                                                           ##           - ie. for III [[<location>, <call no>, <status>], [...]] 
                                                           ##           - the fields in the lists may change depending on 
                                                           ##             what system is being used (ex. III, DRA)
    $BIB_CIRC_NOTE           = 'bib_circ_note',            ## -multiple - notes - temporarily using for DRA circ info....
);     


@BIB_CIRC_SCALAR_ARR        = ($BIB_CIRC_DB,
                               $BIB_CIRC_DB_SYSTEM,
                               $BIB_CIRC_USER,
                               $BIB_CIRC_ERIC_COLL,
                               $BIB_CIRC_MLOG_COLL); 

@BIB_CIRC_LIST_ARR          = ($BIB_CIRC_TITLE,
                               $BIB_CIRC_MARC_TITLE, 
                               $BIB_CIRC_ISSN, 
                               $BIB_CIRC_ISBN, 
                               $BIB_CIRC_CALL_NO, 
                               $BIB_CIRC_SEARCH_ONE,
                               $BIB_CIRC_CAT_URL,
                               $BIB_CIRC_NOTE); 

@BIB_CIRC_LIST_OF_LIST_ARR =  ($BIB_CIRC_SEARCH_LIST, 
                               $BIB_CIRC_BIB_URL,
                               $BIB_CIRC_HOLDINGS,
                               $BIB_CIRC_SIRSI_HOLDINGS, 
                               $BIB_CIRC_CIRC);   


%BIB_CIRC_LABEL_HASH = (
    $BIB_CIRC_TITLE => 'Title',
    $BIB_CIRC_ISSN  => 'ISSN',
    $BIB_CIRC_ISBN  => 'ISBN',
    $BIB_CIRC_CALL_NO => 'Call Number'
);


use vars qw(%BIB_CIRC_JOURNAL_HTML_HASH
            %BIB_CIRC_JOURNAL_NOTE_HASH 
            %BIB_CIRC_MONO_HTML_HASH 
            %BIB_CIRC_MONO_NOTE_HASH);



%BIB_CIRC_JOURNAL_HTML_HASH = ($BIB_CIRC_ERIC_COLL => '',
                               $BIB_CIRC_MLOG_COLL => '', 
                               $BIB_CIRC_HOLDINGS  => '',               
                               $BIB_CIRC_CIRC      => '',
                               $BIB_CIRC_NOTE      => '');    ## -temporarily use for DRA circ info


%BIB_CIRC_MONO_HTML_HASH    = ($BIB_CIRC_TITLE     => '',
                               $BIB_CIRC_ISSN      => '',  
                               $BIB_CIRC_ISBN      => '',  
                               $BIB_CIRC_CALL_NO   => '',
                               $BIB_CIRC_ERIC_COLL => '',
                               $BIB_CIRC_MLOG_COLL => '', 
                               $BIB_CIRC_HOLDINGS  => '',
                               $BIB_CIRC_CIRC      => '',
                               $BIB_CIRC_NOTE      => '');    ## -temporarily use for DRA circ info  

%BIB_CIRC_MONO_NOTE_HASH    = ($BIB_CIRC_CALL_NO   => '', 
                               $BIB_CIRC_ERIC_COLL => '',
                               $BIB_CIRC_MLOG_COLL => '',                                
                               $BIB_CIRC_HOLDINGS  => '',
                               $BIB_CIRC_CIRC      => '');    ## -but only use if no $BIB_CIRC_HOLDINGS info

%BIB_CIRC_JOURNAL_NOTE_HASH = ($BIB_CIRC_CALL_NO   => '',
                               $BIB_CIRC_ERIC_COLL => '',
                               $BIB_CIRC_MLOG_COLL => '',
                               $BIB_CIRC_HOLDINGS  => '',
                               $BIB_CIRC_CIRC      => '');    ## -but only use if no $BIB_CIRC_HOLDINGS info

##
##  - returns (<result>, <reason>, <db source name>)
##
##  -if a success, then $holdings_hash_ref is filled and $reason is not
##
##  -holdings_hash_ref is a pointer to a structure with the following format:
##
##   $holdings_hash{$user} = [{%bib_circ_hash_1},
##                            {%bib_circ_hash_2},
##                                  .
##                                  .
##                                  .
##                            {%bib_circ_hash_N}]
##
##  -get holdings from: 1. unmatched union serials database   *OR*
##                      2. regular ILS catalogue 
##
sub get_on_fly_holdings {
    my($holdings_hash_ref, 
       $config, 
       $db_config, 
       $citation, 
       $live_source, 
       $sources_to_try_arr_ref, 
       $search_type) = @_;

    my(%div_hash, %bib_circ_hash);
    my(@bib_circ_arr, @location_arr);
    my($bib_circ_hash_ref, $holdings_arr_ref, $dummy_ref);
    my($elapsed, $start_time);
    my($res, $docs, $circ_res, $db_user_source_name);
    
    $start_time = time;

    ##
    ## -get information about holdings source
    ##

    $db_user_source_name = &glib::source_name($db_config);

    my($reason);

    use GODOT::CatalogueHoldings::Search;    

    ($res, $docs, $reason) = &cat_search($db_config, 
                                         $config, 
                                         \@bib_circ_arr,
                                         $catalogue::HOLDINGS_TYPE, 
                                         $ALL_AVAIL,                                             
                                         $search_type,
                                         $citation);

    if (! $res)  { return($FALSE, $reason, $db_user_source_name); }

    if (! $docs) { return($FALSE, '', $db_user_source_name);      }     

    $elapsed = time - $start_time;

    @location_arr = &get_locations_for_source($db_config->name, $live_source, $citation, $sources_to_try_arr_ref);

    #### debug ">>> location_arr: ", join("--", @location_arr);

    $start_time = time;


    ## 
    ## -now need to go from @bib_circ_arr to a properly adjusted $holdings_hash_ref:
    ##
    ##  1. -makes sense to get circ info first before original bib records 
    ##      are split apart by any adjustments  done on basis of their contents 
    ##      For example, BVAS GODOT::CatalogueHoldings::BibCirc objects get split into 
    ##      BVAS and BVASB (Bennett and Belzberg) based on location codes in holdings statement.
    ##     
    ##     -will need to make sure that any info required (ex. unique keys) to get
    ##      circ info is put into GODOT::CatalogueHoldings::BibCirc objects by &catalgue::cat_search(...)
    ##
    ##  2. -after getting circ info fill @holdings_hash_ref
    ##  
    ##     -depending on site, circ info may cause a GODOT::CatalogueHoldings::BibCirc objects to be split up
    ##      (ex. Belzberg and Bennett logic for BVAS)
    ##
    
    my $reqtype = $citation->req_type;

    foreach my $bib_circ (@bib_circ_arr) {

        %div_hash = ();        

        $bib_circ->divide(\%div_hash);

        my($nuc_branch, $nuc, $branch);

        foreach $nuc_branch (keys %div_hash) {

            #### debug "... nuc_branch:  $nuc_branch";

            ##
            ## (30-apr-2000 kl) - $nuc_branch may be of the form <nuc> or <nuc>.<branch> (eg. MWU or BVAS.BENNETT LIBRARY)
            ##                  - see GODOT::CatalogueHoldings::BibCirc::union_holdings_from_cat_rec <nuc>.<branch> logic
            ##                  - have added logic to handle second form as @location_arr only contains <nuc>
            ##
            ##

            ($nuc, $branch) = split(/$catalogue::NUC_BRANCH_DELIM_PATT/, $nuc_branch);

            ##
            ## -only add to @{holdings_hash_ref} if this is the source ($db_user) to be used for the current location ($nuc_branch) 
            ##

            if (grep {$nuc_branch eq $_} @location_arr) { 

                push(@{${$holdings_hash_ref}{$nuc_branch}}, { $div_hash{$nuc_branch}->converted });  
            }
            elsif (($nuc_branch ne $nuc) && (grep {$nuc eq $_} @location_arr)) {
               
                push(@{${$holdings_hash_ref}{$nuc}}, { $div_hash{$nuc_branch}->converted });     

            }

        }

        $elapsed = time - $start_time;

        $start_time = time;
    }

    #### debug "++++++++++++++++++++++ holdings_hash_ref +++++++++++++++++++++++++++";
    #### debug Data::Dump::dump($holdings_hash_ref);
    #### debug "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++";

    return($TRUE, '', $db_user_source_name);
}

##
## -returns array (<result>, <docs>, <reason>)
##
## -fills @{$bib_circ_arr_ref}
##
## <result>            $TRUE/$FALSE for success/failure
## <docs>              number of records
## <reason>            reason for failure
##

sub cat_search  {
    my($db_config, 
       $config, 
       $bib_circ_arr_ref, 
       $fmt_type, 
       $condition,  
       $search_type,
       $citation) = @_;

    my $site               = $db_config->name;
    my $system_type        = $db_config->system_type;

    my $lender_name = $db_config->name;

    my(@rec_arr, @succ_arr);

    ##
    ## -if z39.50 use attributes are not specified in user profile, then use default values
    ##  

    use GODOT::CatalogueHoldings::Search::Z3950;          ## for some constants

    my $search          = GODOT::CatalogueHoldings::Search->dispatch({'site' => $site, 'system' => $system_type});
    my $search_no_title = GODOT::CatalogueHoldings::Search->dispatch({'site' => $site, 'system' => $system_type});

    ##
    ## (15-oct-2010 kl) -- added strip_apostrophe_s and title_index_includes_non_ascii
    ##
    $search->strip_apostrophe_s($db_config->strip_apostrophe_s);
    $search_no_title->strip_apostrophe_s($db_config->strip_apostrophe_s);

    $search->title_index_includes_non_ascii($db_config->title_index_includes_non_ascii);
    $search_no_title->title_index_includes_non_ascii($db_config->title_index_includes_non_ascii);
     
    ##
    ## -do we want to do a unique search based on a system id or use a combination of ISSN, ISBN and title
    ##
    my $unique_search_type = $search->unique_search_type($citation->dbase);

    unless ((grep {$unique_search_type eq $_} ($UNIQUE_ONLY_SEARCH, $UNIQUE_INCLUDE_SEARCH, $NO_UNIQUE_SEARCH)))      {
        return($FALSE, 0, "Invalid unique search type ($unique_search_type).");   
    }

    if ($unique_search_type eq $UNIQUE_ONLY_SEARCH) {

        if (! $db_config->zsysid_search_avail) {

            return($FALSE, 0, "Search type is $UNIQUE_ONLY_SEARCH but Z3950_SYSID_SEARCH_AVAIL_FIELD is not true ($lender_name).");
        }
    }

    if (grep {$unique_search_type eq $_} ($UNIQUE_ONLY_SEARCH, $UNIQUE_INCLUDE_SEARCH)) {

        if ($db_config->zsysid_search_avail) {

            ##
            ## -check that 1) we have a 'SYSID' and 
            ##             2) that we have a reasonable value for $db_config->zuse_att_sysid
            ##
         
            if (naws($citation->parsed('SYSID'))) {
                $search->sysid_terms($citation);
                $search_no_title->sysid_terms($citation);
            }        
        }
    }

    ##
    ## -include regular issn/isbn/title unless this is supposed to be a unique *only* search
    ##
    ##            $unique_search_type
    ##            -------------------           
    ## logic is:  $GODOT::CatalogueHoldings::BibCirc::UNIQUE_ONLY_SEARCH    - searches:  <unique search>
    ##            $GODOT::CatalogueHoldings::BibCirc::UNIQUE_INCLUDE_SEARCH - searches:  <unique search>, <issn>, <isbn>, <title>
    ##            $GODOT::CatalogueHoldings::BibCirc::NO_UNIQUE_SEARCH      - searches:  <issn>, <isbn>, <title>
    ##

    if (grep {$unique_search_type eq $_} ($UNIQUE_INCLUDE_SEARCH, $NO_UNIQUE_SEARCH)) { 

        if ($citation->parsed('ISSN')) {
            $search->issn_terms($citation);            
            $search_no_title->issn_terms($citation);            
        }


        if ($citation->parsed('ISBN')) {
            $search->isbn_terms($citation);                                                                     
            $search_no_title->isbn_terms($citation);                                                                      
        }

        ##-----------------------------------------------------------------------------
        ## 
        ## (30-jan-1999 kl) - add series logic so that search also gets done on series title when this is available
        ##  

        ##
        ## - also look at 'good enough' logic......ask when series search would not be a good idea....
        ##

        if ($citation->parsed('TITLE')) {
            $search->title_terms($citation);
        }
    }

    ##
    ## -is Z39.50 access available for this database?
    ## 
    ## -(01-dec-2000 kl) - changed so that it returns $FALSE
    ##

    if (! &glib::z3950_available($db_config)) { 

        return($FALSE, 0, "Z39.50 searching is not configured for $lender_name."); 
    }

    ##-----------------------------------------------------------------------------
    ##                     do the search.....
    ##-----------------------------------------------------------------------------    

    unless ($search->terms) {
        return($FALSE, 0, "Search term filter has left no search terms."); 
    }    
   
    my($res, $docs, $reason) = &get_record($db_config,
                                           'F',
                                           $condition,
                                           $MAXIMUM_HITS,
                                           $citation->req_type, 
                                           $search,
                                           \@rec_arr,                    ## -function fills
                                           \@succ_arr);                  ## -function fills with successful search strings
                    


    ##
    ## (16-feb-1998 kl) -try again without search terms based on title 
    ##
    
    if (($search_no_title->terms) && (! $res) && ($docs > $MAXIMUM_HITS)) {   

        @rec_arr = ();                      ## initialize @rec_arr, @succ_arr
        @succ_arr = ();                     

        ($res, $docs, $reason) = &get_record($db_config,
                                             'F',
                                             $condition,
                                             $MAXIMUM_HITS,
                                             $citation->req_type,
                                             $search_no_title,                ## -pass to function (NB. no title terms)
                                             \@rec_arr,                       ## -function fills
                                             \@succ_arr);                     ## -function fills with successful search strings 
                                                                               
    }
        
    debug location_plus, "($search_type) after catalogue::get_record --" . $db_config->name . "--res--$res--docs--$docs\n";

    my $succ_search_str;

    if ($res) {
        ##
        ## -value given to $succ_search_str depends on number of docs found *before* filtering is done 
        ##  (&good_match(...)) so set $succ_search_str before $docs is altered
        ##

        $succ_search_str = '';
         
        if (($docs == 1) && (@succ_arr == 1)) {           ## -a search term exists that returns *exactly one* record
            $succ_search_str = $succ_arr[0];
        }

        foreach my $record (@rec_arr)   {   ## each record is a GODOT::CatalogueHoldings::Record or a subclass       

            ##
            ## (08-oct-2010 kl) 
            ## Read MARC record into an object of a suitable classs.  Currently only MARC::Record is being used but other classes could be used.
            ## Object gets used in:  GODOT::CatalogueHoldings::Record::Z3950::good_match
            ##                       GODOT::CatalogueHoldings::BibCirc::url_link_format 
            ##                       GODOT::CatalogueHoldings::BibCirc::holdings_format          
            ##

            next unless ($record->bib_record_read_correct_decode);  
               
            ##
            ## -is match good enough? 
            ##
            ## -This second pass is necessary because one may not have much control over the way 
            ##  the way searching or indexing is done on remote databases with the result that 
            ##  the result sets may contain bad matches (ex. title search for 'the-financial-post' 
            ##  brings up 245=Careers and the job market.)
            ##            
            my($match_res, $match_reason) = $record->good_match($db_config, $citation);
                
            if ($match_res)  {         
                            
                debug location_plus, "after successful good match ($site)";

                my $bib_circ = GODOT::CatalogueHoldings::BibCirc->dispatch({'site' => $site, 'system' => $system_type});           
                $bib_circ->user_site($config->name);
                $bib_circ->citation($citation);
                $bib_circ->search_type($search_type);
 
                ##
                ## (15-oct-2010 kl) -- added strip_apostrophe_s and title_index_includes_non_ascii
                ##
                $bib_circ->strip_apostrophe_s($db_config->strip_apostrophe_s);
                $bib_circ->title_index_includes_non_ascii($db_config->title_index_includes_non_ascii);
 
                if ($fmt_type eq $URL_LINK_TYPE) { $bib_circ->url_link_format($db_config, $record); }
                else                             { $bib_circ->holdings_format($db_config, $record); }
                
                #### debug location;
                #### debug "================= ($site) =============================================";
                #### debug Data::Dump::dump($bib_circ);
                #### debug "==============================================================";

                if (! $bib_circ->is_empty) { push(@{$bib_circ_arr_ref}, $bib_circ);  }
                else                       { $docs--;                                }  

            }
            else {
                $docs--;       ## -toss out 'bad' matches
            }
        }
    }

    #### debug "//////////////////////////////////////////////////////////////";
    #### debug Data::Dump::dump($bib_circ_arr_ref);
    #### debug "\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\";

    return($res, $docs, $reason);      
}
##------------------------------------------------------------------------------------
##
## (10-sep-2003 kl) - added this routine to handle the transition between the original search code
##                    and the redesigned search code
##
sub get_record {
    my($db_config, $elemname, $condition, $max_hits, $reqtype, $search, $rec_arr_ref, $succ_arr_ref) = @_;

    my($res, $docs, $reason);

    my $site = $db_config->name;
    my $system_type = $db_config->system_type;
      
    use GODOT::Constants;

    use GODOT::CatalogueHoldings::System;
    my $system = GODOT::CatalogueHoldings::System->dispatch({'site' => $site, 'system' => $system_type});

    $system->Site($site);
    $system->Type($system_type);
        
    $system->Use($db_config->use_z3950);
    $system->Host($db_config->zhost);
    $system->Port($db_config->zport);
   
    $system->Database($db_config->zdbase);
    $system->Timeout($GODOT::Config::Z3950_TIMEOUT);

    use GODOT::CatalogueHoldings::Term;

    ##
    ## -fill in system fields related to Z39.50 attributes based on user config 
    ##

    &redesign_attrib($db_config, $system);

    $search->search($system, $condition, $max_hits);

    if ($search->result) {
        push(@{$rec_arr_ref}, $search->records) if ($search->docs);                
        $res = $TRUE;
    }
    else {
        $res = $FALSE;
    }

    ##
    ##     1) no docs
    ##     2) search failure 
    ##

    $docs = $search->docs;
    $reason = $search->error_message;
    $succ_arr_ref = $search->successful_search_terms;

    #### debug "-----------------------------------------------------";
    #### debug "   res:  $res";
    #### debug "  docs:  $docs";
    #### debug "reason:  $reason";
    #### debug "-----------------------------------------------------";

    return ($res, $docs, $reason);
}


##-----------------------------------------------------------------------------------------------
##
## $lc is 'lender config'
##
sub redesign_attrib {
    my($lc, $system) = @_;

    $system->SysID->UseAttribute($lc->zuse_att_sysid) if ($lc->zsysid_search_avail && naws($lc->zuse_att_sysid));

    $system->ISBN->UseAttribute($lc->zuse_att_isbn) if naws($lc->zuse_att_isbn);
    $system->ISSN->UseAttribute($lc->zuse_att_issn) if naws($lc->zuse_att_issn);
    $system->Title->UseAttribute($lc->zuse_att_title) if naws($lc->zuse_att_title);
    $system->JournalTitle->UseAttribute($lc->zuse_att_journal_title) if naws($lc->zuse_att_journal_title);

    ##
    ## -single word title attributes
    ##
    $system->Title->PositionAttribute($lc->zpos_att_sw_title, 'SingleWord') if naws($lc->zpos_att_sw_title);
    $system->Title->StructureAttribute($lc->zstruct_att_sw_title, 'SingleWord') if naws($lc->zstruct_att_sw_title);       
    $system->Title->TruncationAttribute($lc->ztrunc_att_sw_title, 'SingleWord') if naws($lc->ztrunc_att_sw_title); 
    $system->Title->CompletenessAttribute($lc->zcompl_att_sw_title, 'SingleWord') if naws($lc->zcompl_att_sw_title);

    ##
    ## -title attributes
    ##
    $system->Title->PositionAttribute($lc->zpos_att_title) if naws($lc->zpos_att_title);
    $system->Title->StructureAttribute($lc->zstruct_att_title) if naws($lc->zstruct_att_title);
    $system->Title->TruncationAttribute($lc->ztrunc_att_title) if naws($lc->ztrunc_att_title);
    $system->Title->CompletenessAttribute($lc->zcompl_att_title) if naws($lc->zcompl_att_title);       

    ##
    ## -single word journal title attributes
    ##
    $system->JournalTitle->PositionAttribute($lc->zpos_att_sw_journal_title, 'SingleWord') if naws($lc->zpos_att_sw_journal_title);
    $system->JournalTitle->StructureAttribute($lc->zstruct_att_sw_journal_title, 'SingleWord') if naws($lc->zstruct_att_sw_journal_title);
    $system->JournalTitle->TruncationAttribute($lc->ztrunc_att_sw_journal_title, 'SingleWord') if naws($lc->ztrunc_att_sw_journal_title);      
    $system->JournalTitle->CompletenessAttribute($lc->zcompl_att_sw_journal_title, 'SingleWord') if naws($lc->zcompl_att_sw_journal_title);

    ##
    ## -journal title attributes
    ##
    $system->JournalTitle->PositionAttribute($lc->zpos_att_journal_title) if naws($lc->zpos_att_journal_title); 
    $system->JournalTitle->StructureAttribute($lc->zstruct_att_journal_title) if naws($lc->zstruct_att_journal_title);  
    $system->JournalTitle->TruncationAttribute($lc->ztrunc_att_journal_title) if naws($lc->ztrunc_att_journal_title);
    $system->JournalTitle->CompletenessAttribute($lc->zcompl_att_journal_title) if naws($lc->zcompl_att_journal_title);

    #### print "\n--------------< in redesign_attrib >-----------------\n",
    ####      $system->tagged,
    ####      "\n-----------------------------------------------------\n";
}


##------------------------------------------------------------------------------------
sub get_title_from_bib_circ {
    my($bib_circ_arr_ref) = @_;            

    my %title_hash;
    my %title_count_hash;
    my %source_hash;

    foreach my $bib_circ_hash_ref (@{$bib_circ_arr_ref}) {
    
        my $source = ${$bib_circ_hash_ref}{$catalogue::BIB_CIRC_DB};

        foreach my $marc_title (@{${$bib_circ_hash_ref}{$catalogue::BIB_CIRC_MARC_TITLE}}) {
       
            ##
            ## $marc_title is a MARC::Field
            ##
            my @string;
	        foreach my $subfield ($marc_title->subfields) {
		        my($code, $data) = @{$subfield};
		        if (grep {$code eq $_} qw(a b)) {
		            push @string, $data;
		        }
	        }
            
	        my $title = join(' ', @string);

            ##
            ## (11-apr-2010 kl) -- changed from normalize_marc8 to normalize as $marc_title (and therefore $title) is now utf8
            ##                  -- related to similarly dated changes in GODOT::CatalogueHoldings::BibCirc  
            ##
            my $clean_title = &GODOT::String::normalize($title); 

            if (&GODOT::String::aws($clean_title)) { next; }

            my $source_key  = $source . '.' . $clean_title;

            ##
            ## -don't count same title from same source more than once
            ##
            if (! defined($source_hash{$source_key})) {

                $title_count_hash{$clean_title}++;

                push(@{$title_hash{$clean_title}}, $title);
	    }
                    
            $source_hash{$source_key}++;
        }
    }
     
    ##
    ## -now that we have collected all the titles, determine which is the most frequently used
    ## -need to add logic to strip non-char-num at beg and end
    ##

    my $most_common_title;
    my $most_common_title_count;

    while (my ($title, $count) = each %title_count_hash) {
  
       if ($count > $most_common_title_count) {

           $most_common_title = $title;
           $most_common_title_count = $count;
       }
    } 

    ##
    ## -return first example in list of non-normalized version of title
    ## -remove leading/trailing characters that are not alphanumeric

    $most_common_title = ${$title_hash{$most_common_title}}[0];

    $most_common_title =~ s#^[^a-zA-Z0-9]+##;
    $most_common_title =~ s#[^a-zA-Z0-9]+$##;

    return $most_common_title;
}

##------------------------------------------------------------------------------
##
## !!!! @values is an array so don't put any parameters after !!!!
##
## 
sub fill_bib_circ {
    my($bib_circ_hash_ref, $field, @values) = @_;

    my($item, $non_aws);

    if (grep {$field eq $_} @BIB_CIRC_SCALAR_ARR) {                     

        if (! aws($values[0])) { ${$bib_circ_hash_ref}{$field} = $values[0];  }                          
    }
    elsif (grep {$field eq $_} @BIB_CIRC_LIST_ARR) {

        foreach $item (@values) {
            if (! aws($item)) { push(@{${$bib_circ_hash_ref}{$field}}, $item); }
        }

    }
    elsif (grep {$field eq $_} @BIB_CIRC_LIST_OF_LIST_ARR)  {

        $non_aws = $FALSE;
        foreach $item (@values) {
            if (! aws($item)) { $non_aws = $TRUE; }
        }

        if ($non_aws) { push(@{${$bib_circ_hash_ref}{$field}}, [@values]); }

    }
}

##------------------------------------------------------------------------------
##
## -returns list containing holdings in two different formats: 1) html formatted
##                                                             2) plain text for use in ILL messages
## -on failure returns ('', '')
##
## -a hash value may be a scalar, a list ref, or a ref to a list of list ref (ie. [[], [], [], ...])
##

sub fmt_bib_circ {
    my($bib_circ_hash_ref, $reqtype, $fmt) = @_;

    my(@tmp_arr_1);
    my($html_incl_hash_ref, $text_incl_hash_ref);
    my($field, $html_str, $text_str, $call_no_str, $bib_url_str, $item, $list_ref);
    my($html_incl, $text_incl, $len, $tmp_str, $no_call_number_text);

    #### debug "+++---------------------++++ bib_circ_hash_ref +++-------------------------+++\n"; 
    #### debug Data::Dump::dump($bib_circ_hash_ref);
    #### debug "+++------------------------------------------------------------------------+++\n";

    report_time_location;        

    my $db_config = GODOTConfig::Cache->configuration_from_cache(${$bib_circ_hash_ref}{$BIB_CIRC_DB});
    my $holdings_site_config = GODOTConfig::Cache->configuration_from_cache(${$bib_circ_hash_ref}{$BIB_CIRC_USER});

    ##
    ## (12-may-2005 kl) - TEMPORARY FIX -- create a GODOT::CatalogueHoldings::BibCirc object to take care of
    ##                    some site/system specific logic below 
    ##
    my $bib_circ = GODOT::CatalogueHoldings::BibCirc->dispatch({'site'   => $db_config->name,
                                                                'system' => $db_config->system_type});

    ##
    ## (15-oct-2010 kl) -- added strip_apostrophe_s and title_index_includes_non_ascii
    ##
    $bib_circ->strip_apostrophe_s($db_config->strip_apostrophe_s);
    $bib_circ->title_index_includes_non_ascii($db_config->title_index_includes_non_ascii);

    my $num_holdings = (scalar @{${$bib_circ_hash_ref}{$BIB_CIRC_HOLDINGS}}) if defined ${$bib_circ_hash_ref}{$BIB_CIRC_HOLDINGS};
    my $num_circ     = (scalar @{${$bib_circ_hash_ref}{$BIB_CIRC_CIRC}}) if defined ${$bib_circ_hash_ref}{$BIB_CIRC_CIRC};

    my $only_circ_in_short_journal_rec;
                                     
    $no_call_number_text = $bib_circ->call_number_text;     
  
    if ($reqtype eq $gconst::JOURNAL_TYPE) {
        $html_incl_hash_ref = { %catalogue::BIB_CIRC_JOURNAL_HTML_HASH };
        $text_incl_hash_ref = { %catalogue::BIB_CIRC_JOURNAL_NOTE_HASH }; 
    }
    else {
        $html_incl_hash_ref = { %catalogue::BIB_CIRC_MONO_HTML_HASH };
        $text_incl_hash_ref = { %catalogue::BIB_CIRC_MONO_NOTE_HASH };        
    }
       
   if ($fmt eq $SHORT_FMT) {
        
	if ($reqtype eq $gconst::JOURNAL_TYPE) {

            my $no_holdings_statement = $holdings_site_config->disable_holdings_statement_display;

            $only_circ_in_short_journal_rec = ($no_holdings_statement) ? $TRUE
                                            : (! $num_circ)            ? $FALSE 
                                            :                            (! $num_holdings)
                                            ;

            delete ${$html_incl_hash_ref}{$BIB_CIRC_HOLDINGS} if $no_holdings_statement;
            delete ${$html_incl_hash_ref}{$BIB_CIRC_CIRC} if $holdings_site_config->disable_item_and_circulation_display;
        }
    }

    if ($fmt eq $LONG_FMT) {

        ${$html_incl_hash_ref}{$BIB_CIRC_TITLE} = '';         
        ${$html_incl_hash_ref}{$BIB_CIRC_ISBN} = '';         
        ${$html_incl_hash_ref}{$BIB_CIRC_ISSN} = '';         
      
        $bib_circ->adjust_html_incl_long($html_incl_hash_ref);
    }

    $bib_circ->adjust_html_incl($reqtype, $html_incl_hash_ref);


    #### debug "/////////////// ", join('--', keys %{$html_incl_hash_ref}), "\n"; 

    foreach $field (@BIB_CIRC_ARR) {    ## for each field in bib/circ hash
    
        if (! defined(${$bib_circ_hash_ref}{$field})) {  next;  }

        ##
        ## (07-oct-1999 kl) - call number string logic added so call number for holdings that user selects can 
        ##                    be included in call number field of ILL request (eg. requests for UBC will appear in call number 
        ##                    field of RSS email format (aka ISO email format)
        ##

        if (naws($call_no_str))   { $call_no_str .= "\036";   }

        if ($field eq $BIB_CIRC_CALL_NO)   { 
            $call_no_str .=  join("\036", @{${$bib_circ_hash_ref}{$field}}); 
        }

        if ($field eq $BIB_CIRC_BIB_URL)   {
             
            foreach (@{${$bib_circ_hash_ref}{$field}}) {           

                $bib_url_str .= join("\036", @{$_}) . "\035";                
            }
        }

        $html_incl = defined(${$html_incl_hash_ref}{$field});
        $text_incl = defined(${$text_incl_hash_ref}{$field});
      
        if ($html_incl || $text_incl) {   ## -do we want to include field for either format          

            if (! aws($BIB_CIRC_LABEL_HASH{$field})) {    ## -add label
  
                if (defined($BIB_CIRC_LABEL_HASH{$field})) {
                    if ($html_incl) { $html_str .= b("$BIB_CIRC_LABEL_HASH{$field}: "); }
                    if ($text_incl) { $text_str .= "$BIB_CIRC_LABEL_HASH{$field}: ";    }
                }
            }

            if (grep {$field eq $_} @BIB_CIRC_SCALAR_ARR) {          

                if ($html_incl) { $html_str .= ${$bib_circ_hash_ref}{$field}; }

                if ($text_incl) { 

                    if (grep {$field eq $_} ($BIB_CIRC_ERIC_COLL, $BIB_CIRC_MLOG_COLL)) {
                        $tmp_str = &glib::strip_html(${$bib_circ_hash_ref}{$field});
                    }
                    else {
                        $tmp_str = ${$bib_circ_hash_ref}{$field};
                    }
                    
                    $text_str .= $tmp_str;
                }
            }
            elsif ( grep {$field eq $_} @BIB_CIRC_LIST_ARR) {        

                @tmp_arr_1 = map {strip_trailing_punc_ws($_)} @{${$bib_circ_hash_ref}{$field}};

                ##
                ## (26-apr-2003 kl) - added logic to dedup these fields as seeing a problem when displaying titles from ELN_AG_MONO
                ##
                rm_arr_dup_str(\@tmp_arr_1);

                
                if ($html_incl) { $html_str .= join('; ', @tmp_arr_1); }
                if ($text_incl) { $text_str .= join('; ', @tmp_arr_1); }
            }
            elsif ( grep {$field eq $_} @BIB_CIRC_LIST_OF_LIST_ARR) {      

                my(@tmp_arr_text, @tmp_arr_html);  

		my($source_db) = ${$bib_circ_hash_ref}{$BIB_CIRC_DB};

                if ($html_incl || $text_incl) {

                    if ($html_incl &&  $html_str) { $html_str .= '<P>'; }
                    
                    foreach $list_ref (@{${$bib_circ_hash_ref}{$field}}) {  

                        my(@tmp_arr_1) = @{$list_ref};

                        ##
                        ## (02-mar-2005 kl) - Sirsi holdings have HTML added by this point, so do escaping then instead of here
                        ## (23-feb-2005 kl) - holdings statements with '<' and '>' were not displaying correctly
                        ##
                        unless ($field eq $BIB_CIRC_SIRSI_HOLDINGS) {
                             foreach my $tmp (@tmp_arr_1) { $tmp = escapeHTML($tmp); }
		        }

                        ##
                        ## -shift off NUC code as we don't need this to be printed out
                        ##
 
                        if (($field eq $BIB_CIRC_HOLDINGS) || ($field eq $BIB_CIRC_SIRSI_HOLDINGS) ) { shift(@tmp_arr_1); }    
                                           
                        $tmp_str = strip_trailing_punc_ws(join(' - ', @tmp_arr_1));                      
                        if (naws($tmp_str)) { push(@tmp_arr_text, $tmp_str); }

                        if ($field eq $BIB_CIRC_CIRC) { 

                            my(@tmp_arr) = @tmp_arr_1;
                          
                            if ($bib_circ->skip_circ_location($tmp_arr[0])) { next; };
                            
                            ##
                            ## -add some html for a clearer display  
                            ##

                            $tmp_str = "$tmp_arr_1[0]" . ((trim_beg_end($tmp_arr_1[1]) ne $no_call_number_text) ? 
                                                         " -- $tmp_arr_1[1]" : "")  .  
                                                         ((naws($tmp_arr_1[2])) ? "; $tmp_arr_1[2]" : "");
		        }

                        if (naws($tmp_str)) { push(@tmp_arr_html, $tmp_str); }
                    }
                }   
             
                if ($html_incl) {

                    if    ($field eq $BIB_CIRC_CIRC)   { 

			$html_str .= join('<P>', @tmp_arr_html);

                    }
                    elsif ($field eq $BIB_CIRC_HOLDINGS) { 

                        $html_str .= join('<P>', @tmp_arr_html);     
                    }
                    else  { 

                        $html_str .= join('<BR>', @tmp_arr_html);    
                    } 
                }

                if ($text_incl) { 

                    if (($field eq $BIB_CIRC_CIRC) && (defined(${$bib_circ_hash_ref}{$BIB_CIRC_HOLDINGS}))) { 
                        ##
                        ## skip as holdings statement will get too long
                        ##
                    }
                    else  {  
                        $text_str .= join(';', @tmp_arr_text);     
                    } 
                }

            }

            if ($html_incl && $html_str) { 

                $html_str .= '<BR>' unless ($html_str =~ m#</[uo]l>\s*$#i);
            }  


            if ($text_incl && $text_str) { $text_str .= '. ';   }        
        }        
    }

    #### report_time_location;

    return ($html_str, $text_str, $call_no_str, $bib_url_str);
}

##
## -are there holdings that can be found in the site's catalogue or are there only holdings from collections like ERIC or Microlog fiche?
##
sub holdings_in_catalogue {
    my($holdings_hash_ref, $location) = @_;

    my($bib_circ_hash_ref);
    my($catalogued_holdings_found);

    foreach $bib_circ_hash_ref (@{${$holdings_hash_ref}{$location}}) {

        my($num_holdings) = @{${$bib_circ_hash_ref}{$BIB_CIRC_HOLDINGS}} if (defined ${$bib_circ_hash_ref}{$BIB_CIRC_HOLDINGS});
        my($num_circ)     = @{${$bib_circ_hash_ref}{$BIB_CIRC_CIRC}}     if (defined ${$bib_circ_hash_ref}{$BIB_CIRC_CIRC});

        ##
        ## (20-jun-2012 kl) 
        ## -display link to catalogue if there is a url in the catalogue to the item 
        ## -was added to fix problem where title and isbn for a book were being displayed on the main screen but a 'Check Detailed Holdings' link was not 
        ##
        my($num_bib_url) = @{${$bib_circ_hash_ref}{$BIB_CIRC_BIB_URL}}     if (defined ${$bib_circ_hash_ref}{$BIB_CIRC_BIB_URL});

        if ($num_holdings || $num_circ || $num_bib_url) {
            return $TRUE;
        }
    }
}

##
## (22-jan-2005 kl) - $live_source parameter no longer being used 
##

sub get_locations_for_source {
    my($source, $live_source, $citation, $source_arr_ref) = @_;

    #### debug location;
    #### debug Data::Dump::dump($source_arr_ref);
    #### debug "---------------------------------------------";

    my @location_arr;
    my $source_user;

    my $dbase = $citation->dbase;

    ##
    ## -logic for when the database (from which we link to godot) is the same as $source
    ## 

    if (($source eq $citation->get_dbase->source) && (scalar $citation->get_dbase->source_sites))  {

        @location_arr = $citation->get_dbase->source_sites;
    }
    else {

        foreach my $source_to_try (@{$source_arr_ref}) {

            if ($source eq $source_to_try->source) {
                push(@location_arr, $source_to_try->site);
            }
        }
    }
 
    return @location_arr;
}

1;


