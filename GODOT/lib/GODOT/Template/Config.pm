package GODOT::Template::Config;
##
## Copyright (c) 2004, Kristina Long, Simon Fraser University
##
## Various configuration variables for the screen templates.
##

use Exporter;
@ISA = qw( Exporter );

@EXPORT = qw($TEST_TEMPLATE_SUBDIR $LOCAL_TEMPLATE_DIR);

use strict;

use vars qw($TEST_TEMPLATE_SUBDIR $LOCAL_TEMPLATE_DIR);

$LOCAL_TEMPLATE_DIR   = "$GODOT::Config::GODOT_ROOT/local/templates";

$TEST_TEMPLATE_SUBDIR = 'test';



1;

__END__
