
use strict;

use Apache::DBI ();
use DBI ();
use CGI qw(-compile -no_xhtml :all Vars);
use Class::Accessor;
use Class::DBI;
use Class::DBI::AbstractSearch;
use SQL::Abstract;
use Exception::Class;
use Exception::Class::DBI;
use LWP;
use LWP::UserAgent ();
use Text::Template;
use URI::Escape;
use Apache::Session;
use Data::Dumper;


use catalogue;
use clink;
use gconst;
use glib;
use glog;
use hold_tab;
use link_template;
use openurl;
use para;
use parse;
use password;

use GODOT::Debug;
use GODOT::Config;
use GODOTConfig::Configuration;
use GODOTConfig::Cache;

## !!!!!!!!!!!!!!!! shouldn't need this any more !!!!!!!!!!!!!!!!!!!!!!
##
## For now, easiest way to set up virtual methods for detail fields....  
## Otherwise will get error message along lines of:
##
## Can't locate object method "use_fulltext_links" via package 
## "Class::DBI::Relationship::HasDetails::Details::GODOTConfig::DB::Site_Config
## 
## my $config = new GODOTConfig::Configuration($GODOT::Config::DEFAULT_SITE);
## my $junk = $config->abbrev_name;

#### warn Dumper($config);

1;
