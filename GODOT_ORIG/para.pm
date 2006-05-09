package para;

##
## -driver for searching routines that we want run in parallel
##
## *** -try to avoid requiring too many packages, especially large ones such as hold_tab.pm ***
## *** -this package is used by the parallel search server which may fork many processes    ***
##

use CGI qw(-no_xhtml :standard :escape :unescape);

use strict;

require glib;
require catalogue;

use Data::Dumper;
use Storable qw(retrieve store retrieve_fd store_fd);
use Time::HiRes qw(gettimeofday);

use GODOT::Debug;
use GODOT::String;
use GODOT::Config;
use GODOT::Parallel;
use GODOTConfig::Configuration;
use GODOTConfig::Cache;


##----------------------------------------------------------------------------
##                 'constants'
##----------------------------------------------------------------------------

use vars qw($TRUE $FALSE);
$TRUE  = 1;
$FALSE = 0;

use vars qw($QUEUE_HASH_OUTPUT_TYPE
            $STATUS_MSG_OUTPUT_TYPE
            $BYE_OUTPUT_TYPE);

$QUEUE_HASH_OUTPUT_TYPE = 'queue_hash_output_type';
$STATUS_MSG_OUTPUT_TYPE = 'status_msg_output_type';
$BYE_OUTPUT_TYPE        = 'bye_output_type';

use vars qw(@CMD_PARAM_ARR $GET_ON_FLY_HOLDINGS_CMD $GET_CATALOGUE_URL_CMD $GET_CUFTS_LINKS_CMD);

@CMD_PARAM_ARR = ($GET_ON_FLY_HOLDINGS_CMD = 'get_on_fly_holdings_cmd',
                  $GET_CATALOGUE_URL_CMD   = 'get_catalogue_url_cmd',
                  $GET_CUFTS_LINKS_CMD     = 'get_cufts_links_cmd');              


use vars qw($PARA_DELIM);
$PARA_DELIM = "\036";

##
## -global to this package
##

my(@OUTPUT_ARR, $RESULT_OUTPUT, $REASON_OUTPUT, $DATA_OUTPUT); 

@OUTPUT_ARR = ($RESULT_OUTPUT           = 'result_output',
               $REASON_OUTPUT           = 'reason_output',
               $DATA_OUTPUT             = 'data_output');

sub logmsg { 
    print "\n\n$0 $$: @_ at ", scalar localtime, "\n"; 
}        


sub test {
    my($zhost) = @_;

    my($i);

    foreach ($i=0; $i<=30; $i++) {
        print "$$ - $i\n";
        sleep 1;
    }
}

sub queue {
    my($cmd, 
       $config, 
       $source, 
       $citation,
       $search_type,
       $live_source, 
       $sources_to_try_arr_ref, 
       $is_bccampus,
       $queue_hash_ref, 
       $config_cache) = @_;

    my(%cgi_param_hash);
    my($user, $waitscr_msg, $main_msg, $source_name);

    ##
    ## -determine source name
    ## -if applicable, check that source profile exists
    ##
    my $total_start = gettimeofday;

    my $source_config;

    if ($cmd eq $GET_ON_FLY_HOLDINGS_CMD) {

        $source_config = GODOTConfig::Cache->configuration_from_cache($source);

        unless (defined $source_config) {
            &glib::send_admin_email("$0: Unable to get source information for para::queue subroutine ($source).");
            return ('', '', '');
        }

        $source_name = &glib::source_name($source_config); 
    }
    elsif ($cmd eq $GET_CATALOGUE_URL_CMD) {
       ##
       ## do nothing for now
       ##
    }
    elsif ($cmd eq $GET_CUFTS_LINKS_CMD) {

        $source_name = $gconst::CUFTS_NAME;
    }
    else {
        &glib::send_admin_email("$0: (para::queue) unexpected command ($cmd).");
    }

    foreach (param()) {  

        if (defined param($_)) { 

            ##
            ## -logic to force values to be of type SCALAR and not LVALUE (which dump logic doesn't like)
            ## -it is a mystery to me at the moment why this is necessary ?????!!!! ... kl 
            ##
            my $tmp = param($_);
            $cgi_param_hash{$_} = "$tmp"; 
        }      
    }
    my $parallel = new GODOT::Parallel;

    $parallel->command($cmd);
    $parallel->cgi_param(\%cgi_param_hash);
    $parallel->site($config->name);

    $parallel->source($source);
    $parallel->source_name($source_name);
    $parallel->search_type($search_type);

    $parallel->live_source($live_source);
    $parallel->sources_to_try($sources_to_try_arr_ref);
    $parallel->is_bccampus($is_bccampus);

    $parallel->citation($citation);

    $parallel->query_name(join(':', $cmd, $source, $search_type));

    ${$queue_hash_ref}{$parallel->query_name} = $parallel;                           ## -fill queue hash


    if ($cmd eq $GET_ON_FLY_HOLDINGS_CMD) {

        if (&glib::z3950_available($source_config)) { 

            ($waitscr_msg, $main_msg) = &glib::searching_msg($source_config, 
                                                             $gconst::SEARCH_MSG_QUEUE_TYPE, 
                                                             $config,
                                                             [$search_type]);
        }
    }
    elsif ($cmd eq $GET_CUFTS_LINKS_CMD) {

        ($waitscr_msg, $main_msg) = &glib::searching_msg($source_name, 
                                                         $gconst::SEARCH_MSG_QUEUE_TYPE, 
                                                         $config,
                                                         [$search_type]);
    }

    #### debug "total for queuing $source for $cmd: ", gettimeofday - $total_start;  

    return ($parallel->query_name, $waitscr_msg, $main_msg);
}

##
## -called by parallel server
##
sub query {
    my($parallel) = @_;

    my(%holdings_hash, %output_hash);
    my(@resource_arr);
    my($dump_ref);

    my $start = gettimeofday;

    #### debug '6a ___ ', gettimeofday - $start, "\n";
    $start = gettimeofday;

    my $site = $parallel->site;

    my $config = GODOTConfig::Cache->configuration_from_cache($site);

    unless (defined $config) {
        $parallel->result($FALSE);
        $parallel->reason("Unable to get configuration information ($site).");
        return;
    }

    my %cgi_param = %{ $parallel->cgi_param };
    foreach (keys %cgi_param) {
        param(-name=>$_, '-values'=>[$cgi_param{$_}]);   
    }

    my $source_config;
    if (grep {$parallel->command eq $_} ($GET_ON_FLY_HOLDINGS_CMD, $GET_CATALOGUE_URL_CMD)) {

        $source_config = GODOTConfig::Cache->configuration_from_cache($parallel->source);
        unless (defined $source_config) {
            $parallel->result($FALSE);
            $parallel->reason("Unable to get configuration information (" . $parallel->source  . ").");
            return;
        }
    }

    my($result, $reason, $source_name);

    if ($parallel->command eq $GET_ON_FLY_HOLDINGS_CMD)   {

        ($result, $reason, $source_name) = &catalogue::get_on_fly_holdings(\%holdings_hash,
                                                                           $config,
                                                                           $source_config,
                                                                           $parallel->citation,
                                                                           $parallel->live_source,
                                                                           $parallel->sources_to_try,
                                                                           $parallel->search_type);   
        $dump_ref = \%holdings_hash;
    }
    elsif  ($parallel->command eq $GET_CATALOGUE_URL_CMD) {

        my @bib_circ_arr;
        my $dummy;

        require catalogue;
 
        my $search_res;
        my $docs;

        use GODOT::CatalogueHoldings::Search;   

        ($search_res, $docs, $reason) = &catalogue::cat_search($source_config, 
                                                               $config, 
                                                               \@bib_circ_arr, 
                                                               $catalogue::URL_LINK_TYPE, 
                                                               $AT_LEAST_ONE, 
                                                               $dummy,
                                                               $parallel->citation);    
        if ($search_res) {
            ##
            ## -assume for now first one (ie. first url in first bib record) will be URL we want...!!!!!
            ##
            my @cat_url = $bib_circ_arr[0]->cat_url;
            my $url = $cat_url[0]->url;

            $result = $TRUE;
                               
            my @cat_url_arr;
            push(@cat_url_arr, $url);
            $dump_ref = \@cat_url_arr;                
        }
        else {
            $result = $FALSE;
            $reason = (naws($reason)) ?  $reason : "Search for $GET_CATALOGUE_URL_CMD command failed.";
        }
    }
    elsif ($parallel->command eq $GET_CUFTS_LINKS_CMD) {
    
        use GODOT::CUFTS;

        require clink;

        my(%dummy_hash);
        my($msg);

        $source_name = $gconst::CUFTS_NAME; 
        $result = $TRUE;
 
        my $cufts_search = &clink::cufts_server_query($config, param($gconst::ASSOC_SITES_FIELD), $parallel->is_bccampus);

        if (! $cufts_search->result) {

            my $msg = $cufts_search->error_message;

            &glib::send_admin_email("$0: $source_name fulltext server query failed (" . $msg . ")");  

            $result = $FALSE;
            $reason = "$source_name fulltext server query failed (" . $msg . ")";
        }
       
        $dump_ref = $cufts_search;
    }
    else {
        my $command = $parallel->command;
        &glib::send_admin_email("$0: (para::query) unexpected command (cmd = $command, site = $site)");
    }

    if ($reason) {  debug location, ":  $reason (site = $site)";  }
 
    $parallel->source_name($source_name);
    $parallel->result($result);
    $parallel->reason($reason);
    $parallel->data($dump_ref);

    #### debug location, ':  ', Dumper($parallel);

    return; 
}

sub run {
   my ($queue_hash_ref, $query_to_run_arr_ref, $config, $timeout, $print_waitscr) = @_;

   my (@from_server, $timed_out, $failed_to_connect, $before_time, $waitscr_msg, $main_msg, $main_msg_string);

   $before_time = time;

   if (! $timeout) { $timeout = 10; }

   ##
   ## -each comand consists of a 'dumped' hash that has been 'escaped'
   ## -concatenate all the commands then pass to parallel server
   ##

   my @to_send;   

   ##
   ## send an array of GODOT::Parallel objects
   ##
   foreach my $query (@{$query_to_run_arr_ref}) {

       my $parallel = $queue_hash_ref->{$query};
       $parallel->start_time(gettimeofday);
       push @to_send, $parallel; 
   }

   $SIG{ALRM} = sub { 
                        warn "...........para::run....timed out.............\n"; 
                        die "timeout" 
                    };
   eval
   {
      alarm($timeout);

      use Socket;

      my($connected);

      local(*SOCK);

      ##
      ## -decide which parallel server we are going to use
      ##

      my $num_servers = scalar(@GODOT::Config::PARALLEL_SERVERS);

      use Time::HiRes;

      my $number = (Time::HiRes::time * 100000) + $$;

      my ($server, $port);
     
      foreach my $tmp ( 1 .. $num_servers ) {

          my $choice = ($number % $num_servers);

	  ($server, $port) = @{$GODOT::Config::PARALLEL_SERVERS[$choice]};

	  $server = trim_beg_end($server);                      ## --trailing whitespace can cause problems
	  $port   = trim_beg_end($port);                        ## --trailing whitespace can cause problems

	  my $proto = getprotobyname('tcp');

	  socket(SOCK, PF_INET, SOCK_STREAM, $proto);

	  my $sin = sockaddr_in($port, inet_aton($server));

	  if (connect(SOCK, $sin)) { 
              $connected = $TRUE; 
              last; 
          }
          else {
              $number++;                       
          }
      }  
   
      select (SOCK);   $| = 1;   
      select (STDOUT); $| = 1;     

      if ($connected) { 
          Storable::store_fd(\@to_send, \*SOCK) || &glib::send_admin_email("$0: unable to write to SOCK file handle");;

          my $line;
   
          ##
          ## -read return from para_server.pl
          ##

          while (defined($line = <SOCK>)) {    

             chop $line;                                 ## -strip off linefeed
             next if aws($line);
             last if ($line eq $BYE_OUTPUT_TYPE);         

             debug location, ':  ', $line;

             my $filename = $line;           

             my $parallel = retrieve($filename) || &glib::send_admin_email("$0: unable to read from $filename");;        
             if (-e $filename) { unlink($filename); }

             if (naws($parallel->message_type)) {

                 my($waitscr_msg, $main_msg) = &glib::searching_msg($parallel->source_name, 
                                                                    $parallel->message_type, 
                                                                    $config, 
                                                                    $parallel->message_args);

                 if ($print_waitscr) { print $waitscr_msg; }

                 $main_msg_string .= "$main_msg "; 
             }

             push @from_server, $parallel;
          }

          close SOCK;
      }
      else {

          my($waitscr_msg, $main_msg) = &glib::searching_msg('', $gconst::SEARCH_MSG_PARA_SERVER_NO_CONNECT_TYPE, $config); 
          if ($print_waitscr) { print $waitscr_msg; }

          $main_msg_string .= "$main_msg ";

          $failed_to_connect = $TRUE;
          &glib::send_admin_email("$0: (para::run) $gconst::SEARCH_MSG_PARA_SERVER_NO_CONNECT_TYPE.");
      }

      alarm(0);
   };

   my($eval_res) = $@;

   if ($eval_res)   
   {
      if ($eval_res =~ /timeout/)
      {  
         alarm(0);         
                  
         ($waitscr_msg, $main_msg) = &glib::searching_msg('', $gconst::SEARCH_MSG_PARA_SERVER_TIMEOUT_TYPE, $config);

         if ($print_waitscr) { 
             print "<FONT COLOR=RED>$waitscr_msg</FONT>";
         }

         $main_msg_string .= "<FONT COLOR=RED>$main_msg</FONT>";

         &glib::send_admin_email("$0: (para::run) $gconst::SEARCH_MSG_PARA_SERVER_TIMEOUT_TYPE.");

         $timed_out = $TRUE;         
      }
      else
      {        
         alarm(0);

         ($waitscr_msg, $main_msg) = &glib::searching_msg('', $gconst::SEARCH_MSG_PARA_SERVER_PROBLEM_TYPE, $config);

         if ($print_waitscr) {
             print "<FONT COLOR=RED>$waitscr_msg</FONT>";
         }
          
         $main_msg_string .= "<FONT COLOR=RED>$main_msg</FONT>";

         &glib::send_admin_email("$0: (para::run) $gconst::SEARCH_MSG_PARA_SERVER_PROBLEM_TYPE ($eval_res).");
      }

      return ($FALSE, $main_msg_string);                           ## -return failure..... 
   }

   ##
   ## -put results in queue
   ##

   foreach my $parallel (@from_server) {
       ${$queue_hash_ref}{$parallel->query_name} = $parallel; 

       debug "* parallel search time for ", $parallel->source, " (", $parallel->command, ") ", 
             $parallel->end_time - $parallel->start_time; 

   }

   ##
   ## -only print 'elapsed messages' if we successfully connected to the parallel server and got results back
   ##
   if ($failed_to_connect || $timed_out) {

       return ($FALSE, $main_msg_string);
   }
   else {

       my($elapsed_time) = time - $before_time;
       ($waitscr_msg, $main_msg) = &glib::searching_msg('', 
                                                        $gconst::SEARCH_MSG_ELAPSED_TIME_TYPE, 
                                                        $config, 
                                                        [$elapsed_time]);

       if ($print_waitscr) { print $waitscr_msg; }

       $main_msg_string .= $main_msg;
   
   }

   return ($TRUE, $main_msg_string);
}


##
## -returns undef if query not in queue hash
##
sub from_queue {
    my($queue_hash_ref, $query) = @_;

    return undef unless (defined $queue_hash_ref->{$query});

    return undef unless (ref($queue_hash_ref->{$query}) eq 'GODOT::Parallel');

    return $queue_hash_ref->{$query};
}


1;














