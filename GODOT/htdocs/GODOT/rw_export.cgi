use strict;

use CGI qw(:standard :escape);
use FileHandle;

my $RW_ROOT = 'http://www.refworks.com/express/ExpressImport.asp';
my $FILTER  = 'RIS Format';
my $DIR     = '/tmp';
my $SUFFIX  = "refworks";

my $state = param('state');

unless (grep {$state eq $_} qw(import export)) {
    print header, start_html, "Invalid state ($state).", end_html;
    return;
}

no strict;
&{$state};
use strict;

##
## 'Import' citation to this script (storing as file in temp directory)
##
sub import {

    my($id) = param('id');

    unless($id) {
	print header, start_html, "No ID was passed.", end_html;
        return;
    }

    use GODOT::Object;
    use GODOT::Citation;
    use GODOT::Debug;

    #### foreach my $param (param()) {  debug "<incoming>  $param = ", param($param); }

    my $database = new GODOT::Database;
    $database->dbase(param('DBASE'));
    my $citation = new GODOT::Citation $database;
   
    $citation->init_from_parsed_params();    

    #### use Data::Dumper;
    #### debug Dumper "\n\n", $citation, "\n";

    use GODOT::RefWorks::RIS;

    my $filter = new GODOT::RefWorks::RIS; 

    my $filtered = $filter->export_citation($citation);

    #### debug "\n---------- ris filtered ------------";
    #### debug $filtered;
    #### debug "\n------------------------------------\n";

    my $db = $database->dbase;

    my $file = &file_name($id);

    my $fh = new FileHandle;
    unless (open $fh, "> $file") {
        print header, start_html, "Unable to open temporary file ($file) for writing.", end_html;
        return;
    } 

    print $fh $filtered;

    my $export_url = join('', 'http://', server_name, ':', server_port, script_name, '?state=export&id=', escape($id));

    ##
    ## (21-apr-2005 kl) - the vendor and database do not show up in refworks.  This is a problem for other 
    ##                    links to refworks as well.  Nina has previously requested that refworks add 
    ##                    the vendor/database import.
    ##

    my $rw_url =  join('', $RW_ROOT, 
                       '?vendor=', 
                       '&filter=', escape($FILTER),
                       '&database=', escape($db),
                       '&url=', escape($export_url)); 

    $rw_url = param('proxy') . $rw_url;

    debug "rw_url:  $rw_url\n";

    print redirect($rw_url);
}

##
## Export citation to refworks.
##
sub export {

    my $id = param('id');

    my $file = &file_name($id);

    my $fh = new FileHandle;
    unless (open $fh, "$file") {
        print header, start_html, "Unable to open temporary file ($file) for reading.", end_html;
        return;
    } 
    
    my @filtered = <$fh>;    

    print header('text/plain'), join('', @filtered);
}




sub file_name {
    my($id) = @_;

    return "$DIR/$id.$SUFFIX";   
}





