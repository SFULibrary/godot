package Install::GODOTConfig;

use strict;

use vars qw($CONFIG_FILE $HEADER @CONFIG_VARS %CONFIG_VARS_DESC %DEFAULT_VALUES @INCLUDE_DIRS);

$CONFIG_FILE = 'GODOTConfig/BasicConfig.pm';

$HEADER =<< 'EOF';

##
## Copyright Todd Holbrook - Simon Fraser University (2003)
##
## This file is normally written by the install script, but can be modified by
## hand if necessary later.
##
package GODOTConfig::Config;

EOF


@CONFIG_VARS = qw(

    GODOT_ROOT

    GODOT_GLOBAL_TEMPLATE_DIR
    GODOT_SITE_TEMPLATE_DIR

    GODOT_GLOBAL_CSS_DIR
    GODOT_SITE_CSS_DIR

    GODOT_GLOBAL_CSS_HTTP_BASE
    GODOT_SITE_CSS_HTTP_BASE

    GODOT_CONFIG_TOOL_SESSION_DIR
    GODOT_CONFIG_TOOL_BASE_TEMPLATE_DIR

    GODOT_CONFIG_CACHE_DIR

    GODOT_DB
    GODOT_USER
    GODOT_PASSWORD
);

%CONFIG_VARS_DESC = (
    'GODOT_ROOT'                           => 'Base directory for configuration tool',
 
    'GODOT_GLOBAL_TEMPLATE_DIR'            => 'Global template directory for GODOT',
    'GODOT_SITE_TEMPLATE_DIR'              => 'Site specific template directory for GODOT',

    'GODOT_GLOBAL_CSS_DIR'                 => 'Global CSS directory for GODOT',
    'GODOT_SITE_CSS_DIR'                   => 'Site specific CSS directory for GODOT',

    'GODOT_GLOBAL_CSS_HTTP_BASE'           => 'HTTP base for global CSS for GODOT',
    'GODOT_SITE_CSS_HTTP_BASE'             => 'HTTP base for site specific CSS for GODOT',

    'GODOT_CONFIG_TOOL_SESSION_DIR'        => 'Session directory for GODOT configuration tool',
    'GODOT_CONFIG_TOOL_BASE_TEMPLATE_DIR'  => 'Template directory for GODOT configuration tool',

    'GODOT_CONFIG_CACHE_DIR'               => 'Directory for configuration profile cache',

    'GODOT_DB'                             => 'Database for configuration tool',
    'GODOT_USER'                           => 'Database user',
    'GODOT_PASSWORD'                       => 'Database password'
);


##
## -'eval' will be run on values
## -only variables with default values are included
##

%DEFAULT_VALUES = (
    'GODOT_ROOT'                           => '$base_dir',
 
    'GODOT_GLOBAL_TEMPLATE_DIR'            => '$config->{\'GODOT_ROOT\'}/GODOT/templates',
    'GODOT_SITE_TEMPLATE_DIR'              => '$config->{\'GODOT_ROOT\'}/GODOTConfig/site_templates',

    'GODOT_GLOBAL_CSS_DIR'                 => '$config->{\'GODOT_ROOT\'}/GODOT/htdocs/GODOT/css',
    'GODOT_SITE_CSS_DIR'                   => '$config->{\'GODOT_ROOT\'}/GODOT/htdocs/GODOT/css/site',

    'GODOT_GLOBAL_CSS_HTTP_BASE'           => '/GODOT/css',
    'GODOT_SITE_CSS_HTTP_BASE'             => '/GODOT/css/site',

    'GODOT_CONFIG_TOOL_SESSION_DIR'        => '$config->{\'GODOT_ROOT\'}/GODOTConfig/sessions',
    'GODOT_CONFIG_TOOL_BASE_TEMPLATE_DIR'  => '$config->{\'GODOT_ROOT\'}/GODOTConfig/templates',

    'GODOT_CONFIG_CACHE_DIR'               => '$config->{\'GODOT_ROOT\'}/GODOTConfig/cache',

    'GODOT_DB'                             => 'GODOTConfig',
);


@INCLUDE_DIRS = qw(GODOTConfig/lib);

sub directories_to_write {
    my($config) = @_;
    
    my @dirs;
    
    push @dirs, "$config->{'GODOT_SITE_TEMPLATE_DIR'}/backup", 
                "$config->{'GODOT_SITE_TEMPLATE_DIR'}/active", 
                "$config->{'GODOT_SITE_TEMPLATE_DIR'}/sandbox", 
                $config->{'GODOT_SITE_CSS_DIR'}, 
                $config->{'GODOT_CONFIG_TOOL_SESSION_DIR'}, 
                "$config->{'GODOT_CONFIG_TOOL_SESSION_DIR'}/lock", 
                $config->{'GODOT_CONFIG_CACHE_DIR'}; 
       

    return @dirs;
}



1;





