
unless (exists $ENV{'MOD_PERL'}) {
    use CGI qw(:header :end_html);
    print header, start_html(-dtd=>$gconst::DTD), "Please run using apache with mod_perl.", end_html;
    goto _end;  
}

##
## (02-mar-1999 kl)
##
## -Seed the random number generator now, not in library files,
##  because this is being run mod_perl and the library files are being pre-loaded.
##
## -If you only do it at apache startup (either explicitly or by letting perl do it the first time
##  that the rand function is called (not sure about second case), then you will have a problem with 
##  different httpd processes producing the same numbers. 
##
## (03-mar-1999 kl) -add BEGIN block so this only happens once per httpd child, instead of each time 
##                   hold_tab.cgi is run
##

BEGIN {
    srand(time|$$);  
}

use strict;

use sigtrap qw(PIPE);               ## Enable stack backtrace on unexpected signals

use File::Basename;
use CGI qw(-no_xhtml :standard :unescape :escape);
use Time::HiRes qw(gettimeofday);

use Data::Dumper;

use GODOT::String;
use GODOT::Debug;
use GODOT::Page;
use GODOT::Date;
use GODOT::Config;
use GODOTConfig::Configuration;
use GODOTConfig::Cache;

require hold_tab;

##
## -used to try to detect where an httpd is stuck
## -to use, issue the following on the command line: kill -USR1 `cat logs/httpd.pid`
## (from perl.apache.org/src/mod_perl.html)
##
use Carp ();
#### $SIG{'USR1'} = sub { Carp::confess('caught SIGUSR1!'); };

##-----------------------------------------------------------------
##                     global 'constants'
##-----------------------------------------------------------------
use vars qw($TRUE $FALSE);
$TRUE = 1;
$FALSE = 0;


my($OPENURL_COOKIE_PUSHER_IMAGE) = 'http://godot.lib.sfu.ca/godot/images/cookie_pusher_godot.gif';

main();

sub main {

    my @dev_machine_arr;       
    my $prev_screen;
    my $action;

    GODOTConfig::Cache->init_cache;

    ##
    ## apache 1.3.3 (quick fix)
    ##

    if (aws($ENV{'REMOTE_HOST'}))  { $ENV{'REMOTE_HOST'} = $ENV{'REMOTE_ADDR'}; }

    debug; 
    debug sprintf("<------ $hold_tab::PROG_NAME %s %s %s %s --------------------->", &GODOT::Date::date_yymmdd(time), &GODOT::Date::date_hh_mm_ss(time), remote_host(), param($hold_tab::SYNTAX_FIELD));
    foreach (param()) {   debug "<incoming> $_ = ", param($_);   }
    debug "<--------------------------------------------------------------------------------->";
    debug;

    ##
    ## (16-may-2002 kl) - fix required because almost all URL encoding is removed
    ##                    when the javascript 'window.open' function is run by Internet Explorer
    ##                  - if any of the values of the parameters contain a semicolon, then CGI.pm 
    ##                    assumes that this is a delimeter between a field=value pair (using a semicolon
    ##                    instead of an ampersand as a delimeter is the new style)
    ##

    if (param('sid') =~ m#^IOP:#) {

        &CGI::delete_all();

	my @qs = split(/&/, $ENV{'QUERY_STRING'});

	foreach my $i (0 .. $#qs)  {
	    $qs[$i] = unescape($qs[$i]);
	    my ($name,$value) = split(/=/, $qs[$i], 2);
	    param(-name=>$name,  '-values'=>[$value]);
	}

        ##
        ## -'pid' contains patent info but this gets split because it is in the form 
        ##  <patent>PN=$PN&PA=$PA&PY=$PY</patent> (Patent number, patentee and patent year) 
        ##

        if (param('pid')) {
            my $pat_string = param('pid') . '&PA=' . param('PA') . '&PY=' . param('PY');
            param(-name=>'pid',  '-values'=>[$pat_string]);
            &CGI::delete('PA');
            &CGI::delete('PY');            
        }
    }
    elsif (param('sid') =~ m#^AMS:#) {

        &CGI::delete_all();

	my @qs = split(/&/, $ENV{'QUERY_STRING'});

	foreach my $i (0 .. $#qs)  {
	    $qs[$i] = unescape($qs[$i]);
	    my ($name,$value) = split(/=/, $qs[$i], 2);
	    param(-name=>$name,  '-values'=>[$value]);
	}
    }
    elsif (param('sid') =~ m#^ukoln:#) {

        param(-name=>'sid',  '-values'=>['ukoln:ukoln']);
    }

    ##--------------------------------------------------------------------------------------------------
    ##
    ## -redirect to development/test copy of godot - this means we don't, when 
    ##  doing development work, need to add links to the database interfaces from which 
    ##  we link to godot
    ## 

    use GODOT::Redirect;
    
    debug 'redirect....  ', GODOT::Redirect::redirect_url;

    if (my $redirect_url = GODOT::Redirect::redirect_url) {
        print redirect(-location=>&hold_tab::dev_copy_url($redirect_url), -nph=>0, -method=>'GET');
        return;
    }

    select(STDERR); $| = 1;
    select(STDOUT); $| = 1;                        ## ?? is this necessary ??

    use GODOT::Authentication;
    my $authentication = GODOT::Authentication->new;


    ##
    ## -(09-mar-2001) - initially set up for Insitute of Physics journal links in 'References' and 'Abstracts'
    ## -image for OpenURL link invoked by cookie pusher script
    ##

    if ($ENV{'PATH_INFO'} eq '/sfx.gif')  {
   
        ##
        ## -get user based on client-side cookie or trusted hosts file
        ## -does not look for user in 'hold_tab_branch' field as is done in the main godot logic
        ##

        my $user = $authentication->get_site();

        my $config = GODOTConfig::Cache->configuration_from_cache($user);

	unless (defined $config) {
	    &glib::send_admin_email("$0: Failed to get configuration information for OpenURL cookie pusher image.");
            print redirect($OPENURL_COOKIE_PUSHER_IMAGE);
	}

        if (naws($config->openurl_cookie_pusher_image)) {
            print redirect($config->openurl_cookie_pusher_image);
        }
        else {
            print redirect($OPENURL_COOKIE_PUSHER_IMAGE); 
        }
    
        return;
    }


    ##----------------------------new session logic----------------------------------------------

    $prev_screen = &hold_tab::get_screen();
    $action      = &hold_tab::get_action($prev_screen);

    debug "prev_screen:  $prev_screen, action:  $action"; 

    use GODOT::Session;

    my $session;

    if ($prev_screen eq $hold_tab::NO_SCR) {
        $session = new GODOT::Session ('', 'new_session' => $TRUE, 'session' => undef);
    }
    else {
        $session = new GODOT::Session (param($hold_tab::COOKIE_FIELD));

        ##
        ## -temporary fix -- copy session values to CGI.pm param
        ##
        &hold_tab::session_to_param($session);        
    } 

    ##--------------------------------------------------------------------------------------------
    ##
    ## -have we linked from a godot page or a non-godot page?
    ##

    my $syntax             = param($hold_tab::SYNTAX_FIELD);
    my $dbase_type         = param($hold_tab::DBASE_TYPE_FIELD);
    my $dbase_local        = param($hold_tab::DBASE_LOCAL_FIELD);
    my $dbase_type_abbrev  = param($hold_tab::DBASE_TYPE_ABBREV_FIELD);
    my $dbase_local_abbrev = param($hold_tab::DBASE_LOCAL_ABBREV_FIELD);
   
    ##
    ## (01-dec-2003 kl) - added for Ebscohost for VCC
    ##

    my $branch_abbrev      = param($GODOT::Constants::BRANCH_ABBREV_FIELD);  

    #### debug "<dbase_type dbase_local> $dbase_type $dbase_local";

    use GODOT::Database;
    my($database) = new GODOT::Database;

    unless ($database->init_dbase([param()], $syntax, $dbase_type, $dbase_local, $dbase_type_abbrev, $dbase_local_abbrev) > 0 ){

         print header, start_html(-dtd=>$gconst::DTD), "Link to script failed.", p, "Unable to initialize database information.", end_html;
         goto _end;
    }

    ##
    ## !!!!!!!!!! - set this after GODOT::Database::init_dbase is run as otherwise creation of param('hold_tab_cookie')
    ## !!!!!!!!!!   interferes with syntax determination 

    param(-name=>$hold_tab::COOKIE_FIELD,  '-values'=>[$session->session_id]);

    #### debug "cookie: ", param($hold_tab::COOKIE_FIELD);

    ##
    ## *kl* move this to hidden field logic later
    ##

    param(-name=>$hold_tab::SYNTAX_FIELD, '-values'=>[$database->dbase_syntax()]);     

    ##
    ## (06-feb-2002 kl) 
    ##

    param(-name=>$hold_tab::DBASE_TYPE_FIELD,  '-values'=>[$database->dbase_type()]);     
    param(-name=>$hold_tab::DBASE_LOCAL_FIELD, '-values'=>[$database->dbase_local()]);     
    
    ##-------------------------------------------------------------------------------------------------

    ## -delete action from param so doesn't get saved later
    
    ##
    ## -check that essential fields have been passed -- problem may be MS Internet Explorer bug 
    ##

    if (aws(param($hold_tab::DBASE_FIELD)) && aws($database->dbase_local()) ) {
 
	&glib::send_admin_email("$0: Both $hold_tab::DBASE_FIELD and $hold_tab::DBASE_LOCAL_FIELD were empty (". &user_agent() . ")");
 
        print header, 
              start_html(-dtd=>$gconst::DTD),
              "Link to script failed.",
	      end_html;

        foreach (param()) { debug "<*> param($_): ", param($_); }
	goto _end;
    }

    ##
    ## -translate URL incoded citation fields if they exist  
    ##
    if ($action ne $hold_tab::START_ACT) {

        foreach my $field (@hold_tab::CITN_ARR) { 
            if (param($field)) {
  	        param(-name=>$field, '-values'=>[unescape(param($field))]);   
            }
        }
    }

    ##
    ## -get user info from parameters or from path info
    ## 
    (my $path_info = $ENV{'PATH_INFO'}) =~ s#^/##;      

    my $site_param = (naws(param($hold_tab::BRANCH_FIELD))) ? param($hold_tab::BRANCH_FIELD) 
                   : (naws(param($GODOT::Constants::BRANCH_ABBREV_FIELD))) ?  param($GODOT::Constants::BRANCH_ABBREV_FIELD)
                   : $path_info;

    my $user = $authentication->get_site($site_param);

    my $assoc_sites = ($authentication->valid_field('assoc_sites') && (defined $authentication->assoc_sites)) ? 
                      [ $authentication->assoc_sites ] : [];

    my $page_local  = ($authentication->valid_field('page_local')) ? $authentication->page_local : undef;

    ##
    ## (25-oct-2004 kl) - save assoc_sites as scalar due to a problem with passing param values 
    ##                    other than scalars to parallel server
    ##

    if (scalar @{$assoc_sites}) { param(-name=>$gconst::ASSOC_SITES_FIELD, '-values'=>[join(' ', @{$assoc_sites})]) ; }

    if ($authentication->valid_field('trusted_host') && $authentication->trusted_host) { 
        param(-name=>$hold_tab::TRUSTED_HOST_FIELD, '-values'=>[$TRUE]); 
    }

    param(-name=>$hold_tab::BRANCH_FIELD, '-values'=>[$user]);
    debug "user >>>> $user";

    ##
    ## -don't read in if ILL module is going to be called as it has other user info logic.
    ##
    ## (8-mar-1998 kl) - over time more config options are being added - given this it appears 
    ##                   not to make sense to continue to add fields to ill_def method of getting 
    ##                   user info - thus for now we will use both methods for ILL forms processing logic 
    ## 
    ##                 - obviously using both methods is not ideal -- will look at fix when
    ##                   do work on packaging up for install at other sites and dealing with user info 
    ##                   sync issues
    ##


    my $config = GODOTConfig::Cache->configuration_from_cache($user);
  
    unless (defined $config) {

        &glib::send_admin_email("$0: Unable to get user information for user ($user).");

        print header, 
              start_html(-dtd=>$gconst::DTD),
              "<h3>Sorry, I could not identify the address from which you are coming.\n",
              "You must access this function from an approved Internet address.\n",
              "If you believe you are receiving this message in error, please send\n",
              "email to klong\@sfu.ca.<\/H3>\n", 
              end_html;

	goto _end;
    }


    ##--------------------------------------------------------------------------------------------------
    ##
    ## -will find a value for param($hold_tab::DBASE_FIELD) if it currently does not have a valid value 
    ##

    my $message; 
    my $dbase = param($hold_tab::DBASE_FIELD);

    my $res = $database->check_dbase($dbase, \$message, \$database);

    #### debug "\n-- GODOT::Database after check_dbase --\n", Dumper($database), "\n--------\n\n";
    #### debug "2 - after check_dbase in hold_tab.cgi:  ", ref($database), "\n";

    unless ($res) { ## mod_yyua

	debug "message -> $message";

        if ($message =~ m#does not currently work with database#) {

	    &glib::send_admin_email("$0: $message");

            unless (aws($config->error_not_parseable)) {
                ##
                ## changed from add to replace custom message 
                ##
                $message = " " . $config->error_not_parseable;       
            }
        } 
        else {
	    &glib::send_admin_email("$0: $message");
        } 
  
        ##
        ## -all the custom start html, page header and start form stuff
        ##

        print header, start_html(-dtd=>$gconst::DTD), $message, end_html;
        goto _end;

    }


    ##
    ## -save as a param so will be available to subsequent invocations
    ##
    param(-name=>$hold_tab::DBASE_FIELD, '-values'=>[$database->dbase()]);

    require GODOT::Citation;
    my($citation) = new GODOT::Citation($database);

    ##
    ## -has citation data already been parsed or not?
    ## -(13-mar-2003) - change from 'title' to 'title or issn or isbn'
    ##

    ##
    ## *kl* move this to citation or parser modules??????
    ##

    if (naws(param($gconst::TITLE_FIELD)) || 
        naws(param($gconst::ISSN_FIELD))  || 
        naws(param($gconst::ISBN_FIELD)))       {

        $citation->init_from_godot_parsed_params();

        use Data::Dumper;
        #### debug "\n-- GODOT::Citation --\n", Dumper($citation), "\n--------\n\n";
    }
    else {
	require GODOT::Parser;

	# Set some information on the citation before initializing the param fields

        #
	# Check for BRS/III flags - taken out of parse.pm
        # 

	if (defined $database->source) { 
        
            my $source = $database->source;

            my $tmp_config = GODOTConfig::Cache->configuration_from_cache($source); 

            unless (defined $tmp_config) {
	        &glib::sae("$0: Unable to get user information for $source.");
	        goto _end;
            }

            if ($tmp_config->system_type eq 'III') { $citation->is_iii_database(1); }
	}


	$citation->init_from_params();

        ##
        ## (06-feb-2002 kl) - !!!!! added Database object as another parameter -- can probably be changed
        ##                    later so that all that gets passed is the Database object !!!!
        ##

	my $parser = GODOT::Parser->dispatch($citation->dbase(), $database, $user);

        unless ($parser) { ##yyua_mod
            my $usr_msg = 'Not enough information available for searching. Administrator has been informed.';
            my $admin_msg = 'Dispatching parser for database '. $database->dbase() . ' failed!';
            &glib::send_admin_email("$0: $admin_msg");

            print header, start_html(-dtd=>$gconst::DTD), $usr_msg, end_html;
            goto _end;
        }

	$parser->parse($citation);
    }
    
    #### use Data::Dumper;
    #### debug "\n-- GODOT::Citation --\n", Dumper($citation), "\n--------\n\n";


    use GODOT::CGI; 
    my $cgi = new GODOT::CGI;

    $cgi->prev_screen($prev_screen);
    $cgi->session($session);
    $cgi->action($action);
    $cgi->result($action);                       ## -initialize

    my $brake;


    my $page = new GODOT::Page;

    $page->form_url(&hold_tab::form_url());

    $page->local($page_local);

    ##
    ## -loop in case we need to call another screen.....
    ##

    while (grep {$cgi->result eq $_} (keys %hold_tab::ACTION_HASH))   {    

        $brake++;
        if ($brake > 2) { last; }                ## -!!! put on the brakes during debugging !!!

        my(%citation);   
        my($process_citation_msg);     

        if ($cgi->prev_screen ne $hold_tab::NO_SCR) {
            $cgi->citation_result(&hold_tab::process_citation($citation, $cgi->prev_screen, \%citation, \$process_citation_msg, $parse::CITN_CHECK_FOR_REQ));
            $cgi->citation_message($process_citation_msg);
        }

        ##
        ## -determine which function to call 
        ##

        $cgi->get_state($config, $citation);

        debug "from state table: (", $cgi->prev_screen, " ",  $cgi->action, ") ->  ", $cgi->subroutine_name;

        unless ($cgi->result) {
	    &glib::send_admin_email("$0: state (" .  $cgi->prev_screen . " " .  $cgi->action . ") not in state table");

            print header, 
                  start_html, 
                  h2("Please use button to submit form"),
                  "If you did use a button to submit the previous screen and are still getting this message, then please notify $GODOT::Config::ADMIN_ID_TEXT.", 
                  end_html;

            goto _end;
        }
       
	no strict;
	$cgi->subroutine(\&{'hold_tab::' . $cgi->subroutine_name});
	use strict;

        ##----------------------------------------------------------------------------------

        $page->session_id($cgi->session->session_id);    

        $cgi->new_screen($cgi->subroutine_name);

        ##
        ## -run screen function to fill GODOT::Page object and modify GODOT::CGI object
        ##

	$cgi->screen($page, $config, $citation);

        param(-name=>$hold_tab::SCREEN_FIELD, '-values'=>[$cgi->new_screen]);     

        ##
        ## -if an action, then loop 
        ##

        if (grep {$cgi->result eq $_} (keys %hold_tab::ACTION_HASH))  { 

            my $saved_cgi = $cgi;
            
            $cgi = new GODOT::CGI;
            $cgi->session($session);
            $cgi->result($saved_cgi->result);
            $cgi->action($saved_cgi->result);
            $cgi->prev_screen($saved_cgi->new_screen);
            $cgi->skipped_main_no_holdings($saved_cgi->skipped_main_no_holdings);
            $cgi->skipped_main_auto_req($saved_cgi->skipped_main_auto_req);

            next;
        }
        elsif ($cgi->result) {                

            $page->hidden_fields(&hold_tab::session_from_param($cgi->session));

            if ($cgi->redirect) { 

                print redirect($cgi->redirect); 
                return;
            }
            else { 
                ##
                ## !!!!!!!!!!!! CGI::header changes state of CGI object so don't run just for string value !!!!!!!!!
                ##
                print header unless ($cgi->header_printed);
                print $page->format($cgi->new_screen, $citation, $config); 
            }
        }
        ##----------------------------------------------------------------------------------
    }

    unless ($cgi->result) {
        error "Function for (", $cgi->prev_screen, " ",  $cgi->action, ") failed.\n";

        &glib::sae("function failed for state change (prev_screen=" . $cgi->prev_screen . " action=" . $cgi->action .  " user_agent=" . &user_agent . ")"); 

        my $email = $GODOT::Config::ADMIN_ID_TEXT;

        $cgi->new_screen('error_screen');       
        $page->messages(["Sorry, an error has occurred.  Webmaster is being notified by email. If problems continue, please notify $email."]);     

        print header, $page->format($cgi->new_screen, $citation, $config);
        goto _end;          
    }    

_end:
  
    &CGI::delete_all();

    &CGI::_reset_globals();  

    report_time_location;
}






