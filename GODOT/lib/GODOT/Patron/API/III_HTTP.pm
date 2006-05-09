package GODOT::Patron::API::III_HTTP;

##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use GODOT::Patron::API;
@ISA = qw(Exporter GODOT::Patron::API);

@EXPORT = qw($DD_MM_YY_DATE_TYPE $MM_DD_YY_DATE_TYPE $YY_MM_DD_DATE_TYPE);

use GODOT::String;
use GODOT::Object;
use GODOT::Debug;
use GODOT::Date;
use CGI qw(:escape);

use strict;

##
## -these are used to indicate the two DD/MM formats, the year may be YY or YYYY
##
use vars qw($DD_MM_YY_DATE_TYPE $MM_DD_YY_DATE_TYPE $YY_MM_DD_DATE_TYPE);
$DD_MM_YY_DATE_TYPE = 'dd_mm_yy';
$MM_DD_YY_DATE_TYPE = 'mm_dd_yy';
$YY_MM_DD_DATE_TYPE = 'yy_mm_dd';


sub get_patron {
    my($self, $patron_name, $patron_lib_no, $patron_pin_no) = @_;
  
    ##
    ## -return TRUE because no error has occurred, all that this means is that site is not configured to get patron info
    ##
    return $TRUE unless $self->available;

    my %patron_field_hash = $self->_incoming_to_obj_mapping;

    my($url, $web_page);

    use LWP::UserAgent;

    ##---------------------------------------------
    ##
    ## -PIN logic
    ##
    if ($self->need_pin)  {

        $url = $self->_pintest_url($self->host, $self->port, $patron_lib_no, $patron_pin_no);  

        my $ua = new LWP::UserAgent;
        my $request = new HTTP::Request GET => $url;
        $request->header('Accept' => 'text/html');
        my $res = $ua->request($request);

        unless ($res->is_success) {
            error "$0: failed GET request - $url - " . $res->message . "(" . $res->message . ") - ";
            $self->error_message('Unable to reach patron authentication server.'); 
            return $FALSE;
        }

        $web_page = $res->content;
        $web_page =~ s#</?HTML>##gi;
        $web_page =~ s#</?BODY>##gi;
        $web_page = trim_beg_end($web_page);    

        my($pin_retcode, $pin_errnum);

        foreach my $line (split(/<BR>/i, $web_page)) {

            $line = trim_beg_end($line);


            if  ($line =~ m#^RETCODE=(.+)#) {              ## -incorrect for III_HTTP but need to double check,
                $pin_retcode = $1;                             also need to check re U of W III_HTTP implementation
            }
            elsif ($line =~ m#^RETCOD=(.+)#) { 
                $pin_retcode = $1; 
            }
            elsif ($line =~ m#^ERRNUM=(.+)#)  { 
                $pin_errnum = $1;   
            }
            elsif ($line =~ m#^ERRMSG=(.+)#)  { 
		my $msg = $1;
                $self->error_message($msg);  
                return $FALSE;                               ## -error - return message
            }
            else {
                error "$0: get_iii_patron - incorrectly formatted line for PIN test";
            }
        }

        return $FALSE unless (($pin_retcode eq '0') && ($pin_errnum eq '') && (aws($self->error_message)));
    }
    ##---------------------------------------------

    $url = $self->_data_url($patron_lib_no, $patron_pin_no);

    debug "...url... $url";

    my $ua = new LWP::UserAgent;
    my $request = new HTTP::Request GET => $url;
    $request->header('Accept' => 'text/html');
    my $res = $ua->request($request);

    if (! $res->is_success) {
        error "$0: failed GET request - $url - " . $res->message . "(" . $res->message . ") - ";
        $self->error_message('Unable to reach patron authentication server.'); 
        return $FALSE;
    }

    $web_page = $res->content;

    $web_page =~ s#</?HTML>##gi;
    $web_page =~ s#</?BODY>##gi;

    $web_page = trim_beg_end($web_page);    

    my %rec_hash;

    use GODOT::Patron::Data;
    my $patron = GODOT::Patron::Data->dispatch({'site' => $self->site, 'api' => $self->api});
    $self->patron($patron);

    foreach my $line (split(/<BR>/i, $web_page)) {

        my $value;

        $line = trim_beg_end($line);

        debug "...data line...", $line;

        if ($line =~ m#^ERRNUM=(.+)#) {
            $value = $1;                                 ## -ignore for now
        }
        elsif ($line =~ m#^ERRMSG=(.+)#) {
            ##
            ## ?????????? why didn't $self->error_message($1) work ???????????
            ##
	    my $msg = $1;
            $self->error_message($msg);  
            return $FALSE;                               ## -error - return message
        }
        elsif ($line =~ m#(.+)\[p[a-zA-Z0-9]+\]=(.*)#) {

	     no strict 'refs';

             my $field = $1;
             $value = trim_beg_end($2);

             $rec_hash{$field} = $value;                 ## -save fields and values exactly as they are from patron record

             if (defined $patron_field_hash{$field}) {

                 my $patron_field = $patron_field_hash{$field};

                 if ($patron_field eq 'last_name') {

                     my $first;
                     ($value, $first) = split(/,/, $value);

                     $patron->first_name(trim_beg_end($first));              
                 }
                 elsif ($patron_field eq 'street') {

                     $value =~ s#\$#, #g;                                   ## '$' divides address parts                     
                 }

                 if (naws($patron->$patron_field)) { $patron->$patron_field($patron->$patron_field . '; '); }

                 $patron->$patron_field($patron->$patron_field . $value);
             }
     
             use strict;             
        }
        else {
            #### error "$0: get_iii_patron - incorrectly formatted line ($line)";
        }
    }

    #### debug $self->patron->dump;


    ##
    ## !!!!!!!!!!!!!!!!!!!! testing only !!!!!!!!!!!!!!!!!!!!!!
    ##
    #### $self->patron->expiry_date('01-01-01');
    #### $self->patron->expiry_date('01-30-01');
    #### $self->patron->mblock('zz');
    #### $self->patron->money_owed('$10.00');
    #### $self->patron->block_until('06-01-01');
    #### $self->patron->type('z');
    #### $self->patron->hlodues('9');

    ## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


    return $self->good_patron;            ## -is the patron in good standing
}


sub iii_expiry_date_ok {
    my($self, $date_type) = @_;

    my($exp_yyyymmdd);

    ##
    ## -assume that the only valid contents of this field is dd-mm-yy, mm-dd-yy or yy-mm-dd
    ##

    if (! $self->_yyyymmdd($self->patron->expiry_date, $date_type, \$exp_yyyymmdd)) {
    
        $self->error_message("The expiry date in your patron record is in an invalid format.");
        error "$0: expiry date is not in a valid format (", $self->patron->expiry_date, ")";
        return $FALSE;
    }

    if ($exp_yyyymmdd < &GODOT::Date::date_yyyymmdd(time)) {

        $self->error_message("Your library record expired on " . $self->patron->expiry_date . ".");
        return $FALSE;
    }
  
    return $TRUE;
}

##
## -MBLOCK means manual block
##
sub iii_mblock_ok {
    my($self) = @_;

    if ($self->patron->mblock ne '-') {
        $self->error_message("There is a manual block on your account.");  
        return $FALSE;
    } 

    return $TRUE;
}

sub iii_money_owed_ok {
    my($self) = @_;

    my $money_owed = $self->patron->money_owed; 
    my $fine_limit = $self->fine_limit;

    if ($money_owed !~ m#^\$\d+\.\d\d$#) {

        $self->error_message("The money owed field in your patron record is in an invalid format.");
        error "$0: money owed is in an invalid format (", $money_owed, ")";
        return $FALSE;
    }

    ##
    ## -strip off leading dollar sign        
    ##

    $money_owed =~ s#^\$##g;      
    $fine_limit =~ s#^\$##g;            ## -this should not be necessary as this should be stripped by user profile config tool    

    if (aws($fine_limit)) { $fine_limit = 0.00; }

    if ($money_owed > $fine_limit) {
        $self->error_message("You owe \$$money_owed.  The fine limit is \$$fine_limit."); 
        return $FALSE;
    }

    return $TRUE;
}

sub iii_hlodues_ok {
    my($self) = @_;

    my $hlodues = $self->patron->hlodues;

    if ($hlodues eq '') { return $TRUE; }

    if ($hlodues !~ m#^\d+$#) {
        $self->error_message("The overdues field in your patron record is in an invalid format.");
        error "$0: overfue field in an invalid format ($hlodues)";
        return $FALSE;
    }

    if ($hlodues > 0) {
        $self->error_message("You have overdue items."); 
        return $FALSE;
    }

    return $TRUE;
}

##
## -go through subroutines adding $self and then add $self logic to calls 
##

sub iii_blk_until_ok {
    my($self, $date_type) = @_;

    return $FALSE if (aws($date_type)); 

    my $blk_until = $self->patron->block_until;

    my($blk_yyyymmdd);

    if ($blk_until eq '-  -') {  return $TRUE; }                 ## -there is no 'block until' date

    unless ($self->_yyyymmdd($blk_until, $date_type, \$blk_yyyymmdd)) {    

        $self->error_message("The \'block until\' date in your patron record is in an invalid format.");
        error "$0: \'block until\' date is not in a valid format ($blk_until)";
        return $FALSE;
    }

    if (&GODOT::Date::date_yyyymmdd(time) <= $blk_yyyymmdd) {

        $self->error_message("Your library record is blocked until $blk_until.");
        return $FALSE;
    }
 
    return $TRUE;
}

sub iii_patron_type_ok {
    my($self) = @_;

    ##
    ## -if doesn't exist return success, but notify admin in case it should be defined for this user....
    ##

    my @patron_types = $self->_incoming_patron_types;   
    my $patron_type = $self->patron->type;

    unless (scalar @patron_types) {
        error "No valid patron types are given for ", $self->site, ".";    
        return $TRUE;
    }

    unless (grep {$patron_type eq $_} @patron_types)  {
        $self->error_message("Your patron type ($patron_type) is not allowed to request.");
        return $FALSE;
    }

    return $TRUE;
}

##
## -return TRUE/FALSE for good/bad patron
##
sub good_patron {

    return $TRUE;
}

sub available {
    my($self) = @_;

    return ($self->api_enabled && (defined $self->host)) ? $TRUE : $FALSE; 
}


##
## -returns TRUE/FALSE for success/failure
## -fills ${$yyyymmdd_ref}
##
sub _yyyymmdd {
    my($self, $date, $date_type, $yyyymmdd_ref) = @_;

    my($dd, $mm, $yy);

    if ($date =~ m#^(\d\d)\055(\d\d)\055(\d\d)$#)  {

        ## !!!! if add matching logic here change $1, $2, $3 logic below !!!!

        if    ($date_type eq $DD_MM_YY_DATE_TYPE) { $dd = $1;  $mm = $2;  $yy = $3; }
        elsif ($date_type eq $YY_MM_DD_DATE_TYPE) { $yy = $1;  $mm = $2;  $dd = $3; }
        else                                      { $mm = $1;  $dd = $2;  $yy = $3; }  ## -silly American format.....

        ${$yyyymmdd_ref} = &GODOT::Date::add_cent($yy) . $mm . $dd;
     
        return $TRUE;
    }
    elsif ($date =~ m#^(\d\d)\055(\d\d)\055(\d\d\d\d)$#) {

        my($yyyy);

        ## !!!! if add matching logic here change $1, $2, $3 logic below !!!!

        if ($date_type eq $DD_MM_YY_DATE_TYPE) { $dd = $1;  $mm = $2;  $yyyy = $3; }
        else                                   { $mm = $1;  $dd = $2;  $yyyy = $3; }  ## -silly American format.....

        ${$yyyymmdd_ref} = $yyyy . $mm . $dd;
     
        return $TRUE;
    }
    else {
        return $FALSE;
    }
}


sub _data_url {
    my($self, $patron_lib_no, $patron_pin_no) = @_;

    return $self->_root_patron_url . escape($patron_lib_no) . "/dump";  
}

sub _pintest_url {
    my($self, $host, $port, $patron_lib_no, $patron_pin_no) = @_;

    return $self->_root_patron_url . escape($patron_lib_no) . '/' . escape($patron_pin_no) . "/pintest";  
}

sub _root_patron_url {
    my($self) = @_;

    (aws($self->port)) ? "http://" . $self->host . "/PATRONAPI/" : 
                         "http://" . $self->host . ":" . $self->port . "/PATRONAPI/";
}

sub _incoming_to_obj_mapping {
    my($self) = @_;

    error location, ":  should not be being called.  Only site specific classes are available";

    return ();
}

sub _incoming_patron_types {
    return ();
}



1;

