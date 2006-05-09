## GODOT::Config
##
## Copyright Kristina Long - Simon Fraser University (2005)
##
## 
##
## This loads the basic and advanced config options into the same package for 
## easy use by other classes.  The installation script should set up the BasicConfig.pm
## file for you, or you can edit it to change things like the base install directory, etc.  
## AdvancedConfig contains stuff like the database parser mappings.
##

use GODOT::BasicConfig;
use GODOT::AdvancedConfig;

1;
