##
## Copyright Kristina Long - Simon Fraser University (2005)
##
## This file is normally written by the install script, but can be modified by hand if necessary later.
##
package GODOT::Config;

use strict;

use vars qw ($DEFAULT_SITE 
             $INSTALLATION_ID
             $SESSION_INSTALLATION_NAME
             $GODOT_ROOT
             $REQNO_DIR
             $SESSION_DIR
             $TEMPLATE_DIR 
             $SANDBOX_OBJECT_DIR
             $LOG_FILE
             $PARALLEL_SERVER_PORT
             $CITATION_MANAGER_URL
             $CUFTS_SERVER_URL         
             $PARSER_ADMIN_MAILLIST
             $GODOT_ADMIN_MAILLIST
             $ADMIN_ID_TEXT
             $SENDMAIL);

$DEFAULT_SITE = 'BVAS';

$INSTALLATION_ID = 'SFU2';       
$SESSION_INSTALLATION_NAME = 'GODOT';

$GODOT_ROOT = '/home/kristina/godot_ni';

$REQNO_DIR = "/usr/local/bin/godot/reqno";

$SESSION_DIR = "$GODOT_ROOT/GODOT/sessions";
$TEMPLATE_DIR  = "$GODOT_ROOT/GODOT/templates";

$SANDBOX_OBJECT_DIR = "/home/kristina/godot_ni/GODOT/sandbox/objects";

$LOG_FILE  = "$GODOT_ROOT/logs/hold_tab.log";

$PARALLEL_SERVER_PORT = '3793';                                

$CITATION_MANAGER_URL = 'http://stalefish.lib.sfu.ca/CitationManager/cm.cgi';

##
## (08-feb-2006 kl) - for testing cufts v2 query 
##
$CUFTS_SERVER_URL     = 'http://192.168.24.222:8088/CUFTS/resolve.cgi';
#### $CUFTS_SERVER_URL     = 'http://judy.ruc.dk/CUFTS/Resolver/site';

$PARSER_ADMIN_MAILLIST = 'klong@delos.lib.sfu.ca';
$GODOT_ADMIN_MAILLIST  = 'klong@delos.lib.sfu.ca';
$ADMIN_ID_TEXT = "klong\@delos.lib.sfu.ca";


$SENDMAIL  = '/usr/lib/sendmail -t -n';


1;
