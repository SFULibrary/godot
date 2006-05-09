package GODOT::Patron::Config;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##
## Various configuration variables for the patron data retrieval logic.
##

use Exporter;
@ISA = qw( Exporter );

@EXPORT = qw($PATRON_API_TIMEOUT);

use strict;

use vars qw($PATRON_API_TIMEOUT);
$PATRON_API_TIMEOUT = 10;


1;

