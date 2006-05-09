package GODOT::Session;

## GODOT::Session
##
## Copyright (c) 2002, Kristina Long, Simon Fraser University
##

use GODOT::Constants;
use GODOT::Config;
use GODOT::Debug;
use GODOT::String;

use GODOT::Session::Config;

use Apache::Session::File;

use strict;

use vars qw($AUTOLOAD);

my %fields = (
    'new_session' => undef,
    'session'     => undef
);

sub new {
    my $that = shift;
    my $session_id = shift;
    my $class = ref($that) || $that;

    my $fields_ref = (@_) ? {@_} : \%fields;

    my $self = {
        '_permitted' => $fields_ref,
        %{$fields_ref}
    };

    bless $self, $class;

    ##
    ## Tries to retrieve a session key from client side cookies
    ## and retrieve it from the local session store.  If there is no
    ## session, one is created.
    ##

    my $base_dir = $GODOT::Config::SESSION_DIR;

    if (!defined($base_dir)) {
	warn("Error, badly configured system, no session directory set.");
	return undef;
    }

    $base_dir .= '/' unless $base_dir =~ m#/$#;

    my $installation_name = $GODOT::Config::SESSION_INSTALLATION_NAME;

    if (!defined($installation_name)) {
	warn("Error, badly configured system, no installation name set.");
	return undef;
    }

    my $session_config_hash = { 'Directory'     => $base_dir,
                                'LockDirectory' => $base_dir . 'lock'
                              };

    ##---------------------------------------------------------------------------------

    if ((! $self->new_session) && ($session_id =~ /^\w+$/)) {

	debug("Got session cookie: $session_id");
    }

    ##---------------------------------------------------------------------------------

    my %session;

    eval { tie %session, $CGI_SESSION_TYPE, $session_id, $session_config_hash; };

    if ($@ =~ /Object does not exist in the data store/) {
	eval { tie %session, $CGI_SESSION_TYPE, undef, $session_config_hash; };
    }
    if ($@) {
	warn("Error creating session: $@");
	return undef;
    }

    # Double check we haven't got another system's session

    if (!defined($session{'installation_name'})) {

	$session{'installation_name'} = $installation_name;
    } 
    else {

	if ($session{'installation_name'} ne $installation_name) {
	    warn("Error, badly configured system, installation name in cookies does not match.");
	    return undef;
	}
    }

    #### foreach my $tmp (keys %session) {  debug "<< session >>:  $tmp = $session{$tmp}"; }

    $self->{'session'} = \%session;

    return $self;
}



sub session_id {
    my ($self) = @_;

    return $self->session->{'_session_id'};
}

sub var {
    my $self = shift;
    my $field = shift;

    if (@_) { return $self->{'session'}->{$field} = shift; }
    else    { return $self->{'session'}->{$field}; }	      
}



##----------------------------------------------------------------------------------------------------------

sub AUTOLOAD {
    my $self = shift;
    my $class = ref($self) || error("Page::AUTOLOAD - self is not an object");
    my $field = $AUTOLOAD;    

    $field =~ s/.*://;               ## -strip fully qualified part
   
    unless (exists $self->{_permitted}->{$field}) {
	error "Page::AUTOLOAD - '$field' is an invalid field for an object of class $class";
    }    

    if (@_) { return $self->{$field} = shift; }
    else    { return $self->{$field}; }	      
}

sub DESTROY {
    my $self = shift;
}



1;

__END__

