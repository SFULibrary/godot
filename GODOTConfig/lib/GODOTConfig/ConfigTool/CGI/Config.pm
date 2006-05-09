##
## Copyright Todd Holbrook - Simon Fraser University (2003)
##
## 
##
package GODOTConfig::ConfigTool::CGI::Config;


use GODOTConfig::Config;
use Exporter;
@ISA = 'Exporter';

##
## Export variables
##

@EXPORT = qw(
	$C_CGI_DEBUG
	$C_CGI_TRACE

	$C_CGI_CSS
	$C_CGI_CSS_DIR
	$C_CGI_JAVASCRIPT
	
	$C_CGI_SESSION_TYPE
	$C_CGI_SESSION_CONFIG
	$C_CGI_INSTALLATION_NAME

	$C_CGI_FIELD_LABELS
);

use strict;

##
## General Certinet and CGI settings
##
	
use vars qw(
	$C_CGI_DEBUG
	$C_CGI_TRACE

	$C_CGI_CSS
	$C_CGI_CSS_DIR
	$C_CGI_JAVASCRIPT

	$C_CGI_SESSION_TYPE
	$C_CGI_SESSION_CONFIG
	$C_CGI_INSTALLATION_NAME

	$C_CGI_DISPLAY_PER_PAGE

	$C_CGI_FIELD_LABELS
);



$C_CGI_SESSION_TYPE = 'Apache::Session::File';
$C_CGI_SESSION_CONFIG = undef;		# Default: SESSION_DIR + SESSION_DIR/lock

$C_CGI_INSTALLATION_NAME = 'GODOTmaint';

$C_CGI_CSS = './css/general.css';		# Main cascading style sheet

$C_CGI_CSS_DIR = './css/';			# Default path to cascading style sheets
$C_CGI_JAVASCRIPT = './js/default.js';		# Default path to Javascript include files

$C_CGI_DEBUG = 1;      # Dump CGI debug information
$C_CGI_TRACE = 1;      # Trace CGI specific code

$C_CGI_DISPLAY_PER_PAGE = 50;

$C_CGI_FIELD_LABELS = {
	'active' => 'active',
	'auth_name' => 'authorization name',
	'auth_passwd' => 'authorization password',
	'module' => 'module',
	'name' => 'name',
	'provider' => 'provider',
	'resource_identifier' => 'resource identifier',
	'resource_type' => 'resource type',
	'database_url' => 'database URL',
	'notes_for_local' => 'configuration notes',
};

1;
