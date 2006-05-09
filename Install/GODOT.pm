package Install::GODOT;

use strict;

use vars qw($CONFIG_FILE $HEADER @CONFIG_VARS @WRITE_TO_DIRECTORIES %CONFIG_VARS_DESC %DEFAULT_VALUES @INCLUDE_DIRS);

$CONFIG_FILE = 'GODOT/BasicConfig.pm';

$HEADER =<< 'EOF';

##
## Copyright Kristina Long - Simon Fraser University (2005)
##
## This file is normally written by the install script, but can be modified by
## hand if necessary later.
##
package GODOT::Config;

EOF

@CONFIG_VARS = qw(
    DEFAULT_SITE
    INSTALLATION_ID
    SESSION_INSTALLATION_NAME
    GODOT_ROOT
    REQNO_DIR
    SESSION_DIR
    TEMPLATE_DIR
    SANDBOX_OBJECT_DIR
    LOG_FILE
    PARALLEL_SERVER_PORT
    CITATION_MANAGER_URL
    CUFTS_SERVER_URL
    PARSER_ADMIN_MAILLIST
    GODOT_ADMIN_MAILLIST
    ADMIN_ID_TEXT
    SENDMAIL
);

%CONFIG_VARS_DESC = (
    'DEFAULT_SITE'               => 'Default site key',
    'INSTALLATION_ID'            => 'Used in request id to differentiate requests from different GODOT installations.',
    'SESSION_INSTALLATION_NAME'  => 'ID to use for session manager',
    'GODOT_ROOT'                 => 'Root GODOT directory',
    'REQNO_DIR'                  => 'Request number file directory',
    'SESSION_DIR'                => 'Session file directory', 
    'TEMPLATE_DIR'               => 'Global template directory',
    'SANDBOX_OBJECT_DIR'         => 'Sandbox objects directory',
    'LOG_FILE'                   => 'Log file',
    'PARALLEL_SERVER_PORT'       => 'Port on which parallel server is running',
    'CITATION_MANAGER_URL'       => 'URL for Citation Manager',
    'CUFTS_SERVER_URL'           => 'URL for CUFTS server',        
    'PARSER_ADMIN_MAILLIST'      => 'Email address for parser errors',
    'GODOT_ADMIN_MAILLIST'       => 'Email address for general errors',
    'ADMIN_ID_TEXT'              => 'Email address for error messages',
    'SENDMAIL'                   => 'Sendmail',
);

##
## -'eval' will be run on values
## -only variables with default values are included
##

%DEFAULT_VALUES = (
    'DEFAULT_SITE'               => 'BVAS', 
    'INSTALLATION_ID'            => 'GODOT',
    'SESSION_INSTALLATION_NAME'  => 'GODOT',
    'GODOT_ROOT'                 => '$base_dir',
    'REQNO_DIR'                  => '$config->{\'GODOT_ROOT\'}/GODOT/reqno',
    'SESSION_DIR'                => '$config->{\'GODOT_ROOT\'}/GODOT/sessions', 
    'TEMPLATE_DIR'               => '$config->{\'GODOT_ROOT\'}/GODOT/templates',
    'SANDBOX_OBJECT_DIR'         => '$config->{\'GODOT_ROOT\'}/GODOT/sandbox/objects',
    'LOG_FILE'                   => '$config->{\'GODOT_ROOT\'}/GODOT/logs/godot.log',
    'PARALLEL_SERVER_PORT'       => '3790',
    'CITATION_MANAGER_URL'       => '$ENV{\'GODOT_CITATION_MANAGER_URL\'}',
    'CUFTS_SERVER_URL'           => '$ENV{\'GODOT_CUFTS_SERVER_URL\'}',
    'PARSER_ADMIN_MAILLIST'      => '$ENV{\'GODOT_ADMIN_EMAIL\'}',
    'GODOT_ADMIN_MAILLIST'       => '$ENV{\'GODOT_ADMIN_EMAIL\'}',
    'ADMIN_ID_TEXT'              => '$ENV{\'GODOT_ADMIN_EMAIL\'}',
    'SENDMAIL'                   => '/usr/lib/sendmail -t -n',
);


@INCLUDE_DIRS = qw(local GODOT/lib GODOT_ORIG GODOTConfig/lib);


sub directories_to_write {
    my($config) = @_;
    
    my @dirs;
    push @dirs, $config->{'REQNO_DIR'};
    push @dirs, $config->{'SESSION_DIR'};
    push @dirs, "$config->{'SESSION_DIR'}/lock"; 
    push @dirs, $config->{'SANDBOX_OBJECT_DIR'};

    my $log_file = $config->{'LOG_FILE'};

    my @split = split('/', $log_file);
    pop @split;
    my $log_dir = join('/', @split);

    push @dirs, $log_dir;
    return @dirs;
}


1;


