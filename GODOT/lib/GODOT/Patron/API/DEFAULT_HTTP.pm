package GODOT::Patron::DEFAULT_HTTP;

##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use GODOT::Patron::API;
@ISA = qw(GODOT::Patron::API);

use GODOT::String;
use GODOT::Object;
use GODOT::Debug;
use CGI qw(:escape);

use strict;

my %INCOMING_TO_OBJ_MAPPING = ('firstname' => 'first_name',
                               'lastname'  => 'last_name',
                               'email'     => 'email');
sub get_patron {
    my($self, $patron_name, $patron_lib_no, $patron_pin_no) = @_;

    ##
    ## -return TRUE because no error has occurred, all that this means is that site is not configured to get patron info
    ##
    return $TRUE unless $self->available;
  
    my %patron_field_hash = $self->_incoming_to_object_mapping;
  
    use LWP::UserAgent;

    ##
    ## Ignore $patron_port, it should be combined with patron_host in this case
    ##
    my $url = $self->host . $patron_lib_no;

    my $ua = new LWP::UserAgent;
    my $request = new HTTP::Request GET => $url;
    $request->header('Accept' => 'text/html');
    my $res = $ua->request($request);

    unless ($res->is_success) {
        error "$0: failed GET request - $url - " . $res->message . "(" . $res->message . ") - ";
        $self->error_message('Unable to reach patron authentication server.'); 
        return $FALSE;
    }

    my $web_page = $res->content;

    $web_page =~ s#</?HTML>##gi;
    $web_page =~ s#</?BODY>##gi;
    $web_page = trim_beg_end($web_page);    

    use GODOT::Patron::Data;
    my $patron = GODOT::Patron::Data->dispatch({'site' => $self->site, 'api' => $self->api});
    $self->patron($patron);

    my %rec_hash;

    no strict 'refs';

    foreach my $line (split(/<BR>/i, $web_page)) {

        $line = trim_beg_end($line);
     
        if ($line =~ m#^(.+?):\s*(.+)#) {
             my $field = $1;
             my $value = trim_beg_end($2);

             $rec_hash{$field} = $value;

             if (defined $patron_field_hash{$field}) {

                 my $patron_field = $patron_field_hash{$field};

                 if ($patron_field eq 'last_name') {

                     my $first;
                     ($value, $first) = split(/,/, $value);
                 
                     $patron->first_name(trim_beg($first));
                 }
 
                 my $tmp = $patron->$patron_field if (defined $patron->$patron_field);
                 if (naws($tmp)) { $tmp .= '; '; }
                 $patron->$patron_field($tmp . $value);
             }             
        } else {            
            error "$0: incorrectly formatted line while retrieving patron data for ", $self->site;
        }
    }

    use strict;

    ##
    ## Bad barcode if there's no user fields?
    ##

    if ($patron->is_empty) {
        $self->error_message('Unable to retrieve patron record.');
    	return $FALSE;
    }

    return $TRUE;
}


sub available {
    my($self) = @_;

    return ($self->api_enabled && (defined $self->host)) ? $TRUE : $FALSE; 
}

sub _incoming_to_obj_mapping {
    my($self) = @_;

    return %INCOMING_TO_OBJ_MAPPING;
}




