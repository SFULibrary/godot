package GODOT::ILL::Message;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##
use GODOT::Config;
use GODOT::Debug;
use GODOT::String;
use GODOT::Object;
use GODOT::ILL::Site;

use base qw(GODOT::Object);

use strict;

my @FIELDS = ('dispatch_site',
              'site', 
              'nuc',
              'lender_site',
              'lender_nuc',
              'type', 
              'request_type',             ## ie. 'D' (direct), 'M' (mediated)
              'citation',                 ## GODOT::Citation             
              'patron',                   ## GODOT::Patron::Data
              'email',            
              'lender_email',
              'host',
              'sender_name',
              'sender_email',
              'sender_id',
              'patron_text',
              'holdings_site',
              'holdings',
              'fax',
              'account_number',
              'max_cost',
              'rush_req',
              'not_req_after',
              'additional_text',     
              'error_message');


my @INCLUDE_PATH = ([qw(local  type dispatch_site)],
                    [qw(local  type)],
                    [qw(global type)]);

my $DELIM = ':';
my $WRAP_INDENT = 20;
my $WRAP_LEN    = 59;


##
## -called using class not object, so appears to need to have 'dispatch' defined explicitly for the class 
##

sub dispatch {
    my ($class, $param)= @_;

    my $dispatch_site = ${$param}{'dispatch_site'};    
    
    ##
    ## -for ELN-AG, ELN-AG-MONO, NEOS-OTHER, BNM-COW, BNM-NAN and BNM-POW
    ##    
    ${$param}{'dispatch_site'} =~ s#\055#_#g if (defined ${$param}{'dispatch_site'});

    my $obj = $class->SUPER::dispatch([@INCLUDE_PATH], $param);
    $obj->{'dispatch_site'} = $dispatch_site;
    $obj->{'type'} = ${$param}{'type'};

    return $obj;
}


sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}


sub send {
    my($self, $reqno) = @_;
       
    if    ($self->transport eq 'email')  { return $self->send_by_email($reqno); }
    elsif ($self->transport eq 'http')   { return $self->send_by_http($reqno);  }    
    else {
        $self->error_message("invalid transport (" .  $self->transport . ")");
        return $FALSE;
    }
}

sub format {
    my($self) = @_;
 
    $self->error_message("invalid message type (" . $self->type . ")");
}


sub subject {
    my($self, $reqno) = @_;

    return "Document Delivery Request $reqno for " . $self->patron_text;

}

sub send_by_email {
    my($self, $reqno) = @_;

    my $message = $self->format($reqno);

    if (defined $self->error_message) { 
        error $self->error_message;
        return $FALSE; 
    }

    if (aws($self->email)) { 
        $self->error_message("blank message email address");
        return $FALSE;
    }

    ##------------------------------------------------------------

    my $sender_name  = $self->sender_name;
    my $sender_email = $self->sender_email;
    my $email        = $self->email;
    my $subject      = $self->subject($reqno);

    my $tmp =<< "End_of_Message";
From: $sender_name <$sender_email>
To: $email
Reply-To: $sender_email
Subject: $subject

$message
End_of_Message
     
    $self->_log_ill_message($tmp, 'input');

    #### debug "send_by_email email:  ", $self->email;

    use CGI qw(:remote_host);

    ##
    ## to add back copy add 'CC:  $GODOT::Config::GODOT_ADMIN_MAILLIST' to header below  ( or CC:  klong\@sfu.ca)
    ##
    if (naws($message))   {
     
        use FileHandle;
        my $fh = new FileHandle "| $GODOT::Config::SENDMAIL";

        if (defined $fh) { 

            my $sender_name  = $self->sender_name;
            my $sender_email = $self->sender_email;

            my $email        = $self->email;
            if (remote_host() eq 'hs72260.lib.sfu.ca') { $email = 'klong@sfu.ca'; }          

            my $subject      = $self->subject($reqno);

	    print $fh <<End_of_Message;
From: $sender_name <$sender_email>
To: $email
Reply-To: $sender_email
Subject: $subject

$message
End_of_Message
	$fh->close;
       } 
       else {
           $self->error_message("Couldn't open mail program.");
           return $FALSE;
       }
 
    }               
    return $TRUE;
}

sub send_by_http {
    my($self, $reqno) = @_;

    if (aws($self->host)) { 
        $self->error_message("blank host for message");
        return $FALSE;
    }

    my $url = $self->message_url;
    if (aws($url)) { 
        $self->error_message("unable to determine URL for message");
        return $FALSE;
    }

    use URI::URL;
    use LWP::UserAgent;

    my $ua = new LWP::UserAgent;

    $url .= '?' . $self->format($reqno);

    if (defined $self->error_message) { return $FALSE; }

    $self->_log_ill_message($self->_split_on_ampersand($url), 'input');
    
    my $request = new HTTP::Request 'GET' => $url;
    my $res = $ua->request($request);

    unless ($res->is_success) {
        error "Unable to run GET request for $url (" . $res->message . ").";        
        $self->error_message("Unable to run GET request for $url.");        
        return $FALSE;
    }


    $self->_log_ill_message($res->content, 'output');

    unless ($self->check_http_return($res->content)) {
        error "message GET request did not return the expected text:\nurl:  " . $url . "\ncontent:  " . $res->content . "\n";
        $self->error_message("Submission of ILL request failed for " . $self->message_url . ".");
        return $FALSE;
    }

    return $TRUE;
}


sub date {
    my($self) = @_;

    my $string = join(' ', $self->citation->parsed('MONTH'), $self->citation->parsed('DAY'), $self->citation->parsed('YEAR')); 

    return trim_beg_end(comp_ws($string));
}

sub wrap {
    my($self, $labv, $strv, $delim_arg, $manv, $widv, $pagv) = @_;

    ## returns string, reformatted with labels; 
    ## wraps on pagv, pads labels to widv

    my ($char);
    my ($string) = "";
    my $delim = (defined $delim_arg) ? $delim_arg : $self->_delim;

    $widv = (defined $widv) ? $widv : $self->_wrap_indent;
    $pagv = (defined $pagv) ? $pagv : $self->_wrap_len;

    ## check that args make sense
 
    if ($pagv <= $widv)    { 
        error "$0:  error in wrap - pagv <= widv"; 
        return; 
    }

    $strv = trim_beg_end($strv);

    ## if it's not mandatory, and there is no data, forget it

    if ((!$manv) && length($strv) eq 0) {
        return;
    } 

    ## set up a spacer variable for left margin

    my $spacer = " ";
    my($countv,$brk,$wraps) = 1;
    while ($countv < $widv) {
        $spacer = $spacer . " ";
	$countv++;
    }

    ## add $delim to label, pad to widv, add data

    $labv = $labv.$delim;
    while (length($labv) < $widv) {
	$labv = $labv . " ";
    }
     
    $strv = $labv . $strv;

    if (length($strv) <= $pagv)  { return "$strv\n"; } 

    ## wrap it

    while (length($strv)  > $pagv) {
	$brk = $pagv;
	$char = substr($strv, $brk, 1);

	while (($char !~ m/[\s;:-]/))  {
	    $brk--;
	    if ($brk == $widv) {
	        $brk = $pagv;
	        $char = " ";
	    }
	    else  {
		$char = substr($strv, $brk, 1);
	    }
	}

	$string .= (substr($strv, 0, $brk)."\n");
 
	$strv = $spacer . substr($strv, $brk);

    }
   
    $string .= $strv . "\n";

    return $string;
}

sub message_note   {
    my($self, $reqno, $widv, $pagv) = @_;
              
    my(@misc_arr) = $self->_message_note_fields($reqno);

    my $note;

    my @do_not_include = $self->_do_not_include;

    foreach my $list_ref (@misc_arr) {

        my($id, $value, $label) = @{$list_ref};
 
        next if (grep {$id eq $_} @do_not_include);
        next if (aws($value));

        ##
        ## do proper indent on note while maintaining existing linefeeds
        ##
                    
        foreach my $line (split(/\n/, "$label:  $value\n")) {
            $note .= $self->wrap('', $line, '', $FALSE, $widv, $pagv);
        }
    }

    ##
    ## -added logic to put leading star on each line so Aviso parser does not get confused about end point of mail message (kl)
    ##

    if (naws($note) && $self->_add_leading_char)   {
        $note =~ s#\n$##g;            # take off last linefeed
        $note =~ s#\n#\n*#g;          # add leading stars to all but first line
        $note = '*' . $note . "\n";   # add star for first line and add back last linefeed
    }

    return $note;
}


sub _message_note_fields {
    my($self, $reqno) = @_;

    return (['reqno',          $reqno,                                  'REQ NO'],
            ['holdings_site',  $self->holdings_site,                    'SITES'],
            ['eric_no',        $self->citation->parsed('ERIC_NO'),      'ERIC DOC NO'],
            ['eric_av',        $self->citation->parsed('ERIC_AV'),      'ERIC AVAILABILITY'],
            ['mlog_no',        $self->citation->parsed('MLOG_NO'),      'MICROLOG NO'],

            ['umi_diss_no',    $self->citation->parsed('UMI_DISS_NO'),  'UMI DISS NO'],
            ['sysid',          $self->citation->parsed('SYSID'),        'SYSTEM NO'],

            ['patent_no',      $self->citation->parsed('PATENT_NO'),    'PATENT NO'],
            ['patentee',       $self->citation->parsed('PATENTEE'),     'PATENTEE'],
            ['patent_year',    $self->citation->parsed('PATENT_YEAR'),  'PATENT YEAR'],

            ['fax',            $self->fax,                              'FAX NO'],
            ['note',           $self->citation->parsed('NOTE'),         'CITATION NOTE'],

            ['patron_note',    $self->patron->note,                     'PATRON NOTE'],
            ['pickup',         $self->patron->pickup,                   'PICKUP LOCATION'],
            ['rush_req',       $self->rush_req,                         'RUSH'],
            ['payment_method', $self->patron->payment_method,           'PAY METHOD'],
            ['account_number', $self->patron->account_number,           'ACCOUNT'],
            ['notification',   $self->patron->notification,             'NOTIFY'],
            ['type',           $self->patron->type,                     'TYPE'],
            ['not_req_after',  $self->not_req_after,                    'NOT REQ AFTER'],
            ['email',          $self->patron->email,                    'EMAIL'],
            ['department',     $self->patron->department,               'DEPARTMENT'],
            ['province',       $self->patron->province,                 'PROVINCE'],
            ['phone',          $self->patron->phone,                    'PHONE'],
            ['phone_work',     $self->patron->phone_work,               'PHONE WORK'],
            ['building',       $self->patron->building,                 'BUILDING'],
            ['street',         $self->patron->street,                   'STREET'],
            ['city',           $self->patron->city,                     'CITY'],
            ['postal_code',    $self->patron->postal_code,              'POSTAL CODE'],

            ['holdings',       $self->holdings,                         'HOLDINGS']
	   );
}


##
## return formatted source field for use in request messages 
##
sub source {
    my($self) = @_;

    my($string);

    $string = $self->citation->dbase. ", ";
   
    my %request_type_mapping = ('D' => 'Direct', 'M' => 'Mediated', 'S' => 'Retrieval', 'W' => 'New');

    if (defined $request_type_mapping{$self->request_type}) { 
        $string .= $request_type_mapping{$self->request_type} . ' '; 
    }
    else { 
        error location, ' - unexpected request type (', $self->request_type, ')'; 
    }

    use GODOT::ILL::Site;

    my $site = GODOT::ILL::Site->dispatch({'site' => $self->site});
    $site->nuc($self->nuc);

    my $lender_site = GODOT::ILL::Site->dispatch({'site' => $self->lender_site});
    $lender_site->nuc($self->lender_nuc);

    if  (($self->request_type eq 'S') || ($self->request_type eq 'W'))    {
         
         $string .= "from " . $site->description; 
    }
    else {
	$string .= "from " . $site->description . " to " . $lender_site->description;

        my $email = trim_beg_end($self->lender_email);
        $string .= " ($email)" if (naws($email));       
    }


    return $string;
}


sub transport { return 'email'; }

sub message_url {
    my($self) = @_;

    error location, ":  no generic 'message_url' method is available";
    return '';
}

sub check_http_return {
    my($self) = @_;

    error location, ":  no generic 'check_http_return' method is available";
    return $FALSE;
}



sub ill_no_letters   {
    my($self) = @_;

    my $ERIC_NO_TEXT           = 'ERIC DOC NO';
    my $MLOG_NO_TEXT           = 'MICROLOG NO';            
    my $UMI_DISS_NO_TEXT       = 'UMI DISS NO';

    my($field, $label, $note, $line, $value);

    my $citation = $self->citation;

    my(@misc_arr) = ([$citation->parsed('REPNO'),        ''],
                     [$citation->parsed('ERIC_NO'),      $ERIC_NO_TEXT],                              
                     [$citation->parsed('MLOG_NO'),      $MLOG_NO_TEXT],            
                     [$citation->parsed('UMI_DISS_NO'),  $UMI_DISS_NO_TEXT]); 

    foreach my $list(@misc_arr) {

        ($value, $label) = @{$list};
   
        unless (aws($value)) {
            ##
            ## -do proper indent on note while maintaining existing linefeeds
            ##    
            if ($note ne '') { $note .= '/'; } 
            $note .= "$label: $value";    
        }  
    }
    return $note;
}



sub patron_address {
    my($self) = @_;

    my @arr;

    my $patron = $self->patron;

    foreach my $value ($patron->building, $patron->street, $patron->city, $patron->province, $patron->postal_code) {
        push(@arr, $value) unless (aws($value));                       
    }

    return join('; ', @arr);
}

sub patron_phone {
    my($self) = @_;

    my $string;

    my $patron = $self->patron;

    if (naws($patron->phone))  { $string = $patron->phone . ' (H)'; }
 
    if (naws($patron->phone_work))  { 
        $string .= '; ' unless aws($string);
        $string .= $patron->phone_work . ' (W)';
    }

    return $string;
}


sub patron_type {
    my($self) = @_;
    return $self->patron->type;
}


##
## Only making a copy of the first level
##
sub copy {
    my($self, $copy_this) = @_;

    foreach my $field (@{$self->{'_permitted'}}) {

        next if (grep {$field eq $_} qw(type lender_site lender_nuc request_type email host));

        $self->{$field} = $copy_this->{$field};
    }
    return $self;    
}


sub _delim            { return $DELIM; }

sub _wrap_indent      { return $WRAP_INDENT; }

sub _wrap_len         { return $WRAP_LEN;  }

sub _add_leading_char { return $FALSE; }

sub _do_not_include {
    my($self) = @_;

    return qw(reqno);
}

sub _log_ill_message {
    my($self, $message, $id) = @_;

    log_message_to_file(join('.', 'ill_message', $self->type, $id), $message);   
}

sub _split_on_ampersand {
    my($self, $string) = @_;

    use CGI qw(:unescape);

    $string =~ s#\046#\n\046#g;    ## -ampersand is '\046'
    return unescape($string);
}



1;
