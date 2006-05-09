##
## Copyright Todd Holbrook - Simon Fraser University (2003)
##
## 
##

# This simply loads the basic and advanced config options into the same package for 
# easy use by other classes.  The installation script should set up the BasicConfig.pm
# file for you, or you can edit it to change things like the base install directory,
# database name, etc.  AdvancedConfig contains stuff like built up database connection
# strings, etc.

use GODOTConfig::BasicConfig;
use GODOTConfig::AdvancedConfig;

1;
