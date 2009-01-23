BEGIN {
    srand(time|$$);        ## -see notes in hold_tab.cgi
}

use strict;

use CGI qw(:standard :escape);
use GODOT::Debug;
use GODOT::RefWorks::CGI;

my $RW_ROOT = 'http://refworks.scholarsportal.info/express/ExpressImport.asp';
my $cgi = new GODOT::RefWorks::CGI {'refworks_root_url' => [ $RW_ROOT ]};
print $cgi->run(param('state'));




