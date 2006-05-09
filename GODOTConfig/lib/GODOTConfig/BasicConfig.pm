##
## Copyright Todd Holbrook - Simon Fraser University (2003)
##
## This file is normally written by the install script, but can be modified by
## hand if necessary later.
##
package GODOTConfig::Config;

use strict;

use vars qw(
	$GODOT_BASE_DIR

	$GODOT_SITE_TEMPLATE_DIR
	$GODOT_GLOBAL_TEMPLATE_DIR

	$GODOT_GLOBAL_CSS_DIR
	$GODOT_SITE_CSS_DIR

	$GODOT_GLOBAL_CSS_HTTP_BASE
	$GODOT_SITE_CSS_HTTP_BASE

        $GODOT_CONFIG_TOOL_SESSION_DIR
        $GODOT_CONFIG_TOOL_BASE_TEMPLATE_DIR

        $GODOT_CONFIG_CACHE_DIR

	$GODOT_DB
	$GODOT_USER
	$GODOT_PASSWORD
);


$GODOT_BASE_DIR = '/home/kristina/godot_ni/GODOTConfig';

$GODOT_SITE_TEMPLATE_DIR = "${GODOT_BASE_DIR}/site_templates";

$GODOT_GLOBAL_TEMPLATE_DIR = "/home/kristina/godot_ni/GODOT/templates";

$GODOT_GLOBAL_CSS_DIR = "/home/kristina/godot_ni/GODOT/htdocs/GODOT/css";
$GODOT_SITE_CSS_DIR   = "/home/kristina/godot_ni/GODOT/htdocs/GODOT/css/site";

$GODOT_GLOBAL_CSS_HTTP_BASE = "/GODOT/css";
$GODOT_SITE_CSS_HTTP_BASE   = "/GODOT/css/site";

$GODOT_CONFIG_TOOL_SESSION_DIR       = "${GODOTConfig::Config::GODOT_BASE_DIR}/sessions";
$GODOT_CONFIG_TOOL_BASE_TEMPLATE_DIR = "${GODOTConfig::Config::GODOT_BASE_DIR}/templates";

$GODOT_CONFIG_CACHE_DIR              = "${GODOTConfig::Config::GODOT_BASE_DIR}/cache";

$GODOT_DB = 'GODOT_config';
$GODOT_USER = 'tholbroo';
$GODOT_PASSWORD = '';


1;

