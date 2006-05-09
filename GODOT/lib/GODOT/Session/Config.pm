package GODOT::Session::Config;

##
## Copyright (c) 2004, Kristina Long, Simon Fraser University
##

use Exporter;
@ISA = qw( Exporter );

@EXPORT = qw($CGI_SESSION_TYPE);

use strict;

use vars qw($CGI_SESSION_TYPE);

$CGI_SESSION_TYPE      = 'Apache::Session::File';


1;

__END__
