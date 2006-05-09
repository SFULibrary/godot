package glib;

use CGI qw(-no_xhtml :standard); 

require gconst;

use GODOT::Debug;
use GODOT::String;
use GODOT::Config;

use strict;

use vars qw($TRUE $FALSE);
$TRUE  = 1;
$FALSE = 0;

my $WAITSCR_INDENT = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";


my %MAIN_MSG_BRIEF = ($gconst::SEARCH_MSG_LINK_TYPE                   => $FALSE,
                      $gconst::SEARCH_MSG_FULLTEXT_TYPE               => $FALSE, 
                      $gconst::SEARCH_MSG_HOLDINGS_TYPE               => $FALSE,
                      $gconst::SEARCH_MSG_QUEUE_TYPE                  => $FALSE,
                      $gconst::SEARCH_MSG_RUNNING_PARA_TYPE           => $FALSE,
                      $gconst::SEARCH_MSG_MORE_HOLDINGS_SEARCHES_TYPE => $FALSE,
                      $gconst::SEARCH_MSG_PARA_SERVER_NO_CONNECT_TYPE => $TRUE,
                      $gconst::SEARCH_MSG_PARA_SERVER_TIMEOUT_TYPE    => $TRUE,
                      $gconst::SEARCH_MSG_PARA_SERVER_PROBLEM_TYPE    => $TRUE,
                      $gconst::SEARCH_MSG_PARA_QUERY_TIMEOUT_TYPE     => $TRUE,
                      $gconst::SEARCH_MSG_PARA_QUERY_PROBLEM_TYPE     => $TRUE,
                      $gconst::SEARCH_MSG_SEARCH_TIME_TYPE            => $FALSE,
                      $gconst::SEARCH_MSG_ELAPSED_TIME_TYPE           => $FALSE);


my %WAITSCR_MSG_BRIEF = ($gconst::SEARCH_MSG_LINK_TYPE                   => $FALSE,
                         $gconst::SEARCH_MSG_FULLTEXT_TYPE               => $FALSE,
                         $gconst::SEARCH_MSG_HOLDINGS_TYPE               => $FALSE,
                         $gconst::SEARCH_MSG_QUEUE_TYPE                  => $FALSE,
                         $gconst::SEARCH_MSG_RUNNING_PARA_TYPE           => $FALSE,
                         $gconst::SEARCH_MSG_MORE_HOLDINGS_SEARCHES_TYPE => $FALSE,
                         $gconst::SEARCH_MSG_PARA_SERVER_NO_CONNECT_TYPE => $FALSE, 
                         $gconst::SEARCH_MSG_PARA_SERVER_TIMEOUT_TYPE    => $FALSE,
                         $gconst::SEARCH_MSG_PARA_SERVER_PROBLEM_TYPE    => $FALSE,
                         $gconst::SEARCH_MSG_PARA_QUERY_TIMEOUT_TYPE     => $FALSE,
                         $gconst::SEARCH_MSG_PARA_QUERY_PROBLEM_TYPE     => $FALSE,
                         $gconst::SEARCH_MSG_SEARCH_TIME_TYPE            => $FALSE,
                         $gconst::SEARCH_MSG_ELAPSED_TIME_TYPE           => $FALSE);

sub send_admin_email {
    my($message) = @_; 

    local(*SENDMAIL);
    my($subject, $user);   

    $user = param($gconst::BRANCH_FIELD);

    ##
    ## -strip off program name if included in message
    ##

    ($subject = $message) =~ s#^$0:*\s*##; 

    if (naws($user)) { $subject = "GODOT ($user): " . substr($subject, 0, 110); } 
    else                      { $subject = "GODOT: "         . substr($subject, 0, 110); }

    ##
    ## (04-mar-1999 kl) -added so that would be easier to debug in some circumstances
    ##
   
    my($sendmail) = '/usr/lib/sendmail -t -n';

    $message = "\n\nremote_host: " . &remote_host  . "\n\nreferer: " . &referer . "\n\n" . $message;

    warning $message, "\n";


##
##		open (SENDMAIL, "| $sendmail") || return;
##		print SENDMAIL <<End_of_Message;
## From: 
## To: $GODOT::Config::GODOT_ADMIN_MAILLIST
## Reply-To:
## Subject: $subject
##
## $message
## End_of_Message
##	close(SENDMAIL);
##
}


##
## shortcut name
##

sub sae { &send_admin_email(@_); }   


sub z3950_available {
    my($config) = @_;

    return ($config->use_z3950 && naws($config->zhost) && naws($config->zdbase)) ? $TRUE : $FALSE;
}

sub strip_html {
    my($string) = @_;

    $string =~ s#<[^<>]+>##g;       

    return $string;
}

##
## -returns a list containing a message for the javascript status screen/window ('waitscr') 
##  and for the main holdings table window/screen
##

sub searching_msg {
    my($source, $search_type, $config, $arg_arr_ref) = @_;

    my($source_name);

    ##                              
    ## if a reference to a user hash
    ##

    if (ref $source) { $source_name = &source_name($source); }
    else             { $source_name = $source;               }

    return &_searching_msg_fmt($source_name, $search_type, $config, $arg_arr_ref);
}

sub _searching_msg_fmt {
    my($string, $search_msg_type, $config, $arg_arr_ref) = @_;

    my($waitscr_msg, $main_msg, $tmp);            ## message for main screen


    $string = escapeHTML($string);

    
    if ($search_msg_type eq $gconst::SEARCH_MSG_LINK_TYPE)         {         
        $main_msg = "Searching $string for links...";
    }
    elsif ($search_msg_type eq $gconst::SEARCH_MSG_FULLTEXT_TYPE)  { 
        $main_msg = "Searching $string for fulltext..."; 
    }
    elsif ($search_msg_type eq $gconst::SEARCH_MSG_HOLDINGS_TYPE)  { 
        $main_msg = "Searching $string for holdings..."; 
    }
    elsif ($search_msg_type eq $gconst::SEARCH_MSG_QUEUE_TYPE) {
        my($search_type) = ${$arg_arr_ref}[0]; 
        $main_msg = "Queuing search for $string for $search_type..."; 
    }
    elsif ($search_msg_type eq $gconst::SEARCH_MSG_ELAPSED_TIME_TYPE) {

        my($elapsed_time) = ${$arg_arr_ref}[0]; 

        $tmp = "<B>Elapsed time</B> for parallel searching is " . $elapsed_time . 
               (($elapsed_time == 1) ? " second" : " seconds") . "."; 

        $waitscr_msg = $tmp;
        $main_msg = " $tmp ";
    }
    elsif ($search_msg_type eq $gconst::SEARCH_MSG_RUNNING_PARA_TYPE) { 

        $main_msg = "Sending " . ((${$arg_arr_ref}[0] == 1) ? "search" : "searches") . " to parallel server, please wait...";   
    }
    elsif ($search_msg_type eq $gconst::SEARCH_MSG_MORE_HOLDINGS_SEARCHES_TYPE) {

        my($num_with_holdings) = (${$arg_arr_ref}[0] eq '') ? 0 : ${$arg_arr_ref}[0];
        my($phrase);

        if    ($num_with_holdings == 0) { $phrase = "no libraries";                      }
        elsif ($num_with_holdings == 1) { $phrase = "only 1 library";                    }
        else                            { $phrase = "only $num_with_holdings libraries"; } 

        $main_msg = "<FONT COLOR=RED>Have found $phrase with holdings but<BR>$WAITSCR_INDENT" . 
                    "want at least ${$arg_arr_ref}[1], so continue searching...</FONT>";
    }
    ##
    ## -parallel server messages
    ## 
    elsif ($search_msg_type eq $gconst::SEARCH_MSG_PARA_SERVER_NO_CONNECT_TYPE) { 
        $main_msg = "<FONT COLOR=RED><BR>*** Unable to connect to parallel server ***<BR></FONT>";   
    }
    elsif ($search_msg_type eq $gconst::SEARCH_MSG_PARA_SERVER_TIMEOUT_TYPE) { 
        $main_msg = "<FONT COLOR=RED><BR>*** Parallel server timed out ***<BR></FONT>";   
    }
    elsif ($search_msg_type eq $gconst::SEARCH_MSG_PARA_SERVER_PROBLEM_TYPE) { 
        $main_msg = "<FONT COLOR=RED><BR>*** Parallel server failed ***<BR></FONT>";   
    }
    ##
    ## -parallel query messages
    ##
    elsif ($search_msg_type eq $gconst::SEARCH_MSG_PARA_QUERY_TIMEOUT_TYPE) { 
        $main_msg = "<FONT COLOR=RED>*** " . escapeHTML(${$arg_arr_ref}[0]) . " timed out *** </FONT>";   
    }
    elsif ($search_msg_type eq $gconst::SEARCH_MSG_PARA_QUERY_PROBLEM_TYPE) { 
        $main_msg = "<FONT COLOR=RED>*** " . escapeHTML(${$arg_arr_ref}[0]) . 
                    " failed (" . escapeHTML(${$arg_arr_ref}[1]) . ") *** </FONT>";   
    }
    ##
    ## -elapsed time
    ##
    elsif ($search_msg_type eq $gconst::SEARCH_MSG_SEARCH_TIME_TYPE) {    

        my($search_type, $elapsed_time) = (${$arg_arr_ref}[0], ${$arg_arr_ref}[1]);

        $main_msg = "<B>$string</B> for $search_type - $elapsed_time " . (($elapsed_time == 1) ? "second" : "seconds") .  ".";
    }
    else {

        ##
        ## $search_msg_type has actual message instead of a search type
        ##

        my($source_name_str) = (naws(${$arg_arr_ref}[0])) ? (escapeHTML(${$arg_arr_ref}[0]) . " - ") : '';       

        $main_msg = "<FONT COLOR=RED>*** $source_name_str " . escapeHTML($search_msg_type) . " *** </FONT>";
    }




    if ($waitscr_msg eq '') { $waitscr_msg = $main_msg; }

    ##
    ## -linefeeds cause problems with javascript
    ##

    $waitscr_msg =~ s#\n##g;
    $main_msg    =~ s#\n##g;

    ##
    ## (23-jan-2003 kl) - added brief format for parallel server messages displayed on holdings table
    ##                  - also added logic for brief format for javascript status window in case this 
    ##                    is wanted in the future 
    ##

    my $main_msg_brief    = $config->parallel_server_msg;

    my $waitscr_msg_brief = $FALSE;

    ##
    ## (04-feb-2005 kl) - if $search_msg_type is the message instead of a defined type then we want to display it
    ##   

    if ($main_msg_brief    && ((defined $MAIN_MSG_BRIEF{$search_msg_type}) && (! $MAIN_MSG_BRIEF{$search_msg_type}))) { 
        $main_msg = ''; 
    }
 
    if ($waitscr_msg_brief && ((defined $WAITSCR_MSG_BRIEF{$search_msg_type}) && (! $WAITSCR_MSG_BRIEF{$search_msg_type}))) { 
        $waitscr_msg = ''; 
    } 
   
    if ($waitscr_msg ne '') {

        $waitscr_msg = "<script language=JavaScript>" .
                       "waitscr.document.writeln('<FONT SIZE=-1><I>$waitscr_msg</I></FONT><BR>')" .
                       "</script>";
    }


    if ($main_msg ne '') {

        $main_msg = "<FONT SIZE=-1><I>$main_msg</I></FONT>";
    }
    

    return ($waitscr_msg, $main_msg);   
}

sub source_name {
    my($source_config) = @_;

    my $unknown = 'Unknown';

    return $unknown if (($source_config eq '') || (! defined $source_config));

    use Data::Dumper;
    # debug ".....................................................";
    # debug Dumper($source_config);
    # debug ".....................................................";
  
    my $source_name = naws($source_config->source_name) ? $source_config->source_name
                    : naws($source_config->abbrev_name) ? $source_config->abbrev_name
                    : naws($source_config->full_name)   ? $source_config->full_name
                    :                                     $source_config->name
                    ;

    return $source_name;
}



sub is_single_word {
    my($string) = @_;

    my $tmp = trim_beg_end($string);
    ($tmp !~ m#\s#);
}


1;








