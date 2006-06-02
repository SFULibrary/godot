package GODOT::Redirect;
##
## Copyright (c) 2006, Kristina Long, Simon Fraser University
##
use strict;

use GODOT::Debug;
use GODOT::String;
use GODOT::Config;
use CGI qw(:cookie);

use vars qw($REDIRECT_COOKIE);
$REDIRECT_COOKIE = 'GODOT_REDIRECT_URL';


sub redirect_url {

    return (naws(cookie($REDIRECT_COOKIE)) && $GODOT::Config::REDIRECTION_ALLOWED) ? cookie($REDIRECT_COOKIE) : undef;
}

1;

__END__






