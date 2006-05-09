require 5.003;

use FindBin qw($Bin);
use lib ("$Bin/../local",  $Bin,  "$Bin/../GODOT/lib",  "$Bin/../GODOTConfig/lib");

use strict;
use Socket;
use Carp;
use CGI qw(-no_debug -no_xhtml :unescape :escape);
use Getopt::Std;
use FileHandle;
use Storable qw(retrieve store retrieve_fd store_fd);

use POSIX "sys_wait_h";
use Time::HiRes qw(gettimeofday);
use Parallel::ForkManager;

use para;   

use GODOT::Config;
use GODOT::Debug;
use GODOT::Parallel;

use GODOTConfig::Configuration;
use GODOTConfig::Cache;

use vars qw($TRUE $FALSE);
$TRUE  = 1;
$FALSE = 0;

use vars qw(%ALLOWED_HOSTS);

%ALLOWED_HOSTS = ("localhost" => 1);

my %servers_hash;  

my $MAX_PROCESSES = 15; 

sub spawn;    # forward declaration

sub logmsg { print STDOUT "$0 $$: @_ at ", scalar localtime, "\n" } 

my $port = $GODOT::Config::PARALLEL_SERVER_PORT;

my $proto = getprotobyname('tcp');
socket(Server, PF_INET, SOCK_STREAM, $proto) or die "socket: $!";

setsockopt(Server, SOL_SOCKET, SO_REUSEADDR, pack("l", 1)) or die "setsockopt: $!";

bind(Server, sockaddr_in($port, INADDR_ANY)) or die "bind: $!";

listen(Server,SOMAXCONN) or die "listen: $!";

##
## -save PID to file for use by start/stop script
##
my %option;
getopts("p:", \%option);

my $pid_file = $option{'p'};
if ($pid_file) {
    my $fh = new FileHandle "> $pid_file";
    defined $fh || die "unable to open PID file '$pid_file' for writing";
    print $fh "$$";
    $fh->close;
}

logmsg "PID file is $pid_file" if ($pid_file); 
logmsg "server started on port $port";
logmsg "(\$GODOT::Config::Z3950_TIMEOUT is $GODOT::Config::Z3950_TIMEOUT)";
logmsg "(\$GODOT::Config::PARA_SERVER_QUERY_TIMEOUT is $GODOT::Config::PARA_SERVER_QUERY_TIMEOUT)";
logmsg "(\$GODOT::Config::PARA_SERVER_TIMEOUT is $GODOT::Config::PARA_SERVER_TIMEOUT)";

my $waitedpid = 0;
my $paddr;

##
## -request loop
##

my($counter);

select(STDOUT);
$| = 1;

my (%kid_input);
my (%kid_timer);

my $run_on_finish_subroutine = 

               sub {

                   my ($pid, $exit_code, $ident) = @_;

                   warn "__________ child $pid just finished with exit code $exit_code\n";

                   delete $kid_timer{$pid};           ## -remove from list of outstanding child processes
    
                   my $filename = &get_query_filename($$, $pid); 

                   print Client "$filename\n";
               };
    
##-------------------end of run_on_finish callback routine-------------------------------


##
## For now, easiest way to set up virtual methods for detail fields....  
## Otherwise will get error message along lines of:
##
## Can't locate object method "use_fulltext_links" via package 
## "Class::DBI::Relationship::HasDetails::Details::GODOTConfig::DB::Site_Config
## 
my $config = new GODOTConfig::Configuration($GODOT::Config::DEFAULT_SITE);
my $junk = $config->abbrev_name;



for ( ; $paddr = accept(Client,Server); close Client) 
{
    my($port,$iaddr) = sockaddr_in($paddr);
    my $name = gethostbyaddr($iaddr,AF_INET);

    $counter++;

    if (inet_ntoa($iaddr) eq '127.0.0.1') { $name = 'localhost'; }

    logmsg "($counter) connection from $name [", inet_ntoa($iaddr), "] at port $port";

    select(Client);
    $| = 1;

    if (&is_host_allowed($name))
    {

       spawn sub 
       { 
           GODOTConfig::Cache->init_cache;

           my $writing = 1;
           %kid_timer = ();
           %kid_input = ();

	   $| = 1; 

           my $from_client = retrieve_fd(\*Client) || &glib::send_admin_email("$0: unable to read from Client file handle");;
          
           use Data::Dumper;
                     
           #### foreach my $parallel (@{$from_client}) { debug Dumper($parallel); }

	   my $pm = new Parallel::ForkManager($MAX_PROCESSES);

           ##
           ## Setup up a callback for when the child finishes up
           ##

           $pm->run_on_finish($run_on_finish_subroutine);

           my $start_time = gettimeofday;

           ##
           ## Create the child processes
           ##

	   foreach my $parallel (@{$from_client}) {

	       ##
               ## Forks and returns the pid for the child:
               ##

	       if (my $pid = $pm->start) { 


                   #### debug "__________ child $pid just started\n";
                   #### debug "in parent after fork:  ", gettimeofday - $start_time;                  

	           $kid_input{$pid} = $parallel;

	           $kid_timer{$pid} = gettimeofday;

                   next;              
	       }

               ## ----------------child-start--------------------
               
               #### debug "in child after fork:  ", gettimeofday - $start_time;                  

               my ($ppid) = getppid();

               &para_query($parallel, &get_query_filename($ppid, $$), $GODOT::Config::PARA_SERVER_QUERY_TIMEOUT);

	       $pm->finish; # Terminates the child process

               ## ----------------child-end----------------------
               

               ##
               ## -!!!! neither parent or child ever get to end of 'for loop' !!!!
               ##
	   }
           
           ##
           ## -handle senario where not all queries have returned
           ## -want to make sure that parallel server does not timeout as a result
           ## 

           ##-------------------------------------------------------


           
           $SIG{ALRM} = sub { die "timeout" };

           eval
           {
               alarm($GODOT::Config::PARA_SERVER_QUERY_TIMEOUT);
           
               warn "Waiting for children...\n";
           
	       $pm->wait_all_children;
           
               alarm(0);
           };
                      
           my $eval_res = $@;
           
           if ($eval_res)   {
           
              if ($eval_res =~ /timeout/) {
           
                   alarm(0);

                   warn "We have timed out on wait_all_children.\n";

                   ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

                    foreach my $kid (keys %kid_timer)
                    {                     
                        my $parallel = $kid_input{$kid};
                        $parallel->message_type($gconst::SEARCH_MSG_PARA_QUERY_TIMEOUT_TYPE);
                        $parallel->message_args([$parallel->source_name]);

			my $filename = &get_query_filename($$, $kid);
                        Storable::store($parallel, $filename) || &glib::send_admin_email("$0: unable to write to $filename");;

                        print Client "$filename\n";

                        warn "Killing child process ($kid) that has not finished....\n";
			kill 9, $kid;                                 
                    }

                    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	       }
           }
           else {

               warn "Children all done.\n";
           }
           
           ##---------------------------------------------------------------------------------------

           my($e_time) = int(gettimeofday - $start_time);
           logmsg "--------- BYE BYE ($e_time secs)------------";

           print Client $para::BYE_OUTPUT_TYPE, "\n";
       };


       ##
       ## !!!!!!!!!!! will not need this if we switch to Parallel::ForkManager for servers as well  ??????
       ##
       
       ## -check current server list to see if any are terminated, but have not yet had 
       ##  their 'death certificate' (ie. exit status) collected with a wait/waitpid call      
       ##

       my($server, $waited_server);
       my(@servers) = keys(%servers_hash);

       foreach $server (@servers) {
       
          $waited_server = waitpid($server, &WNOHANG);
          if ($waited_server) { delete $servers_hash{$waited_server}; }
       }

    }
    else
    {
       logmsg "connection from $name at port $port - denied";
    }
}


sub spawn 
{
   my $coderef = shift;

   unless (@_ == 0 && $coderef && ref($coderef) eq 'CODE')
   { 
      confess "usage: spawn CODEREF";
   }

   my $pid;

   if (! defined($pid = fork))
   {
      logmsg "cannot fork: $!";
      return;
   } 
   elsif ($pid)
   {
      logmsg "begat $pid"; 

      $servers_hash{$pid} = 1;         

      return;                        # i'm the parent
   }

   # else i'm the child -- go spawn

   exit &$coderef();
} 


sub is_host_allowed
{
   my ($host) = @_;

   if (defined $ALLOWED_HOSTS{$host})
   {
      return 1;
   }
   else
   {
      return 0;
   }
}


##
## -returns a status message
##
sub para_query {
   my($parallel, $filename, $timeout) = @_;

   my ($elapsed_time, $before_time);
   my ($timed_out) = 0;
   my $eval_res;

   $before_time = time;

   #### debug '1 ', location, ':  ', ref($parallel), "\n", Dumper($parallel);

   $SIG{ALRM} = sub { die "timeout" };

   eval
   {
      alarm($timeout);

      &para::query($parallel);

      alarm(0);
   };

   $eval_res = $@;

   ##
   ## -$message is for logging or emailing administrator
   ## -$reason is for displaying to the user
   ##

   my($result, $message, $reason, $search_msg_type, $output);

   #### debug '2 ', location, ':  ', ref($parallel), "\n", Dumper($parallel);

   my $source_name = $parallel->source_name if (defined $parallel);
   
   if ($eval_res)   {

       if (open(OUTPUT, ">$filename")) {

           if ($eval_res =~ /timeout/) {

               alarm(0);

               my $waitpid = waitpid(-1, &WNOHANG);

               $timed_out = 1;
               $elapsed_time = time - $before_time;

               $message = "timed out ($source_name)";
               $reason  = "$source_name timed out";
               $search_msg_type = $gconst::SEARCH_MSG_PARA_QUERY_TIMEOUT_TYPE;
           }
           else {

               alarm(0);

               $message = "bombed - returned error is $eval_res ($source_name)";
               $reason  = $eval_res;
           }

           if (! close(OUTPUT)) {
               $message = "unable to close $filename after writing";  
               $reason = $message;
           }
       }
       else {       
           $message = "unable to open $filename for writing";         
           $reason = $message;
       }

       if ($reason eq '') { $reason = $message; }

       $parallel->result($FALSE);
       $parallel->reason($reason);
       $parallel->data(undef);       
   }
   else {
       $result = $TRUE;
   }

   $elapsed_time = time - $before_time;

   select(STDOUT);
   $| = 1;

   ##
   ## -status message processing
   ##
    
   if ($result) {

       $parallel->message_type($gconst::SEARCH_MSG_SEARCH_TIME_TYPE);
       $parallel->message_args([$parallel->search_type, $elapsed_time]);
   }
   else {

       logmsg $message;
       &glib::send_admin_email("$0: $message");

       if ($reason eq '') { $reason = $message; }    

       if ($search_msg_type eq $gconst::SEARCH_MSG_PARA_QUERY_TIMEOUT_TYPE) {

           $parallel->message_type($gconst::SEARCH_MSG_PARA_QUERY_TIMEOUT_TYPE);
           $parallel->message_args([$source_name]);
       }
       else {

           $parallel->message_type($gconst::SEARCH_MSG_PARA_QUERY_PROBLEM_TYPE);
           $parallel->message_args([$source_name, $reason]);
       }
   }

   $parallel->filename($filename);
   $parallel->end_time(gettimeofday);

   store($parallel, $filename) || &glib::send_admin_email("$0: unable to write to $filename");

   wait;     
}

sub get_query_filename  {
    my($parent, $kid) = @_;

    return "/tmp/" . $parent . '.' . $kid . '.output'; 
}

















