package GODOT::Patron::API::DEFAULT;

##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use GODOT::Patron::API;
@ISA = qw(GODOT::Patron::API);

use GODOT::String;
use GODOT::Object;
use GODOT::Debug;

use GODOT::Patron::Config;

use strict;


my %INCOMING_TO_OBJ_MAPPING = ('VALID'                   => 'authorized',
                               'VALID_REASON'            => 'authorized_reason',
 
                               'PATR_FIRST_NAME_FIELD'   => 'first_name',
	                       'PATR_LAST_NAME_FIELD'    => 'last_name',
		               'PATR_LIBRARY_ID_FIELD'   => 'library_id',

		               'PATR_PATRON_TYPE_FIELD'  => 'type',
		               'PATR_DEPARTMENT_FIELD'   => 'department',
		               'PATR_PATRON_EMAIL_FIELD' => 'email',

		               'PATR_PICKUP_FIELD'       => 'pickup',
		               'PATR_PHONE_FIELD'        => 'phone',
		               'PATR_PHONE_WORK_FIELD'   => 'pnone_work',

		               'PATR_BUILDING_FIELD'     => 'building',
		               'PATR_PATRON_NOTI_FIELD'  => 'notification',
		               'PATR_STREET_FIELD'       => 'street',

		               'PATR_CITY_FIELD'         => 'city',
		               'PATR_PROV_FIELD'         => 'province',
		               'PATR_POSTAL_CODE_FIELD'  => 'postal_code',

		               'PATR_PAID_FIELD'         => 'payment_method',
		               'PATR_ACCOUNT_NO_FIELD'   => 'account_number',
                               'PATR_NOTE_FIELD'         => 'note');

sub get_patron {
    my($self, $patron_name, $patron_lib_no, $patron_pin_no) = @_;

    ##
    ## -return TRUE because no error has occurred, all that this means is that site is not configured to get patron info
    ##
    return $TRUE unless $self->available;
    
    my $patron_server_info  = $self->host . ' ' . $self->port;

    my $reply = $self->ask_server_until_match($PATRON_API_TIMEOUT, "AUTH $patron_lib_no $patron_pin_no\n", '^>\r\n$');

    debug "<<------------------------------------->>", $reply, "<<------------------------------------->>";

    if ($reply eq '') {
        $self->error_message("Unable to check patron record.  Please try again later.");
        error "failed to connect to patron server ($patron_server_info)";
        return $FALSE;
    }

    ##
    ## -read reply to determine if we have an error case
    ##

    my %rec_hash = ();    

    foreach my $line (split(/\r\n/, $reply)) {

        if ($line =~ /(.+)\>(.+)/) { $rec_hash{$1} = $2; }
        else                       { error "unexpected format for default patron api ($line)"; }

        if (defined($rec_hash{'ERROR'})) {
            $self->error_message($rec_hash{'ERROR'});
            error "$0: $rec_hash{'ERROR'} ($patron_server_info)";
            return $FALSE;
        } 
    }

    use GODOT::Patron::Data;
    my $patron = GODOT::Patron::Data->dispatch({'site' => $self->site, 'api' => $self->api});
    $self->patron($patron);

    if ($rec_hash{'VALID'} eq 'Y') {                  ## -patron is authorized 

        $self->_process_patron_data({%rec_hash});

        debug "--------------------------------------\n", $patron->dump, "--------------------------------------\n";

        return $TRUE; 
    } 
    else {
        $self->error_message($rec_hash{'VALID_REASON'});
        error "$0: $rec_hash{'VALID_REASON'} ($patron_server_info)";
        return $FALSE;
    }

    return $FALSE;      ## -should never get here
}


sub ask_server_until_match {
    my($self, $timeout, $cmd, $pattern) = @_;

    local(*SOCK);
    my($socket, $network, $flow);
    my($hostname);
    my($prtknt);
    my($reply);

    my $server = $self->host;
    my $port   = $self->port;

    ##
    ## (11-feb-2000 kl) -trailing whitespace can cause problems
    ##

    $server = trim_beg_end($server);

    use Socket;

    my $proto = getprotobyname('tcp');

    socket(SOCK, PF_INET, SOCK_STREAM, $proto);

    my $sin = sockaddr_in($port, inet_aton($server));

    if (! connect(SOCK, $sin)) { 
	error "$0: connecting to server '$server': $!";
	return '';
    }

    select (SOCK);  $| = 1;  select (STDOUT); $| = 1;

    print SOCK $cmd, "\r\n";

    ##
    ## ??? will $SIG{'x'} cause problems with 'use strict'
    ## 
    ##

    $SIG{'ALRM'} = sub { die "timeout" };
     
    eval {
	alarm ($timeout);
	$prtknt = 0;

	while (<SOCK>) {

             if (($pattern ne '')  && (m#$pattern#)) { last; } 

	     $reply .= $_;     ## -append server output to $reply 
	     $prtknt++;
	}

        alarm(0);
    };

    ##
    ## -look at return of eval statement - return failure for anything except null
    ##

    if ($@) { return ''; }                

    return $reply;
}


sub _process_patron_data {
    my($self, $incoming) = @_;

    my %mapping = $self->_incoming_to_obj_mapping;

    foreach my $field (keys %{$incoming}) {             

        if ($field eq 'VALID') { next;  }

        my $obj_field = $mapping{$field} if (defined $mapping{$field});
        my $value = ${$incoming}{$field};
  
        if (naws($obj_field) && naws($value)) { 
            no strict 'refs';
            $self->patron->$obj_field($value);        
            use strict;    
        }
    }
}

sub _incoming_to_obj_mapping {
    my($self) = @_;

    return %INCOMING_TO_OBJ_MAPPING;
}



1;
