package GODOT::RefWorks::CGI;
## 
## Copyright (c) 2009, Kristina Long, Simon Fraser University
##
## (30-oct-2010 kl) 
## Incoming citation data is assumed to be encoded as latin1.  
## Output of citation data to file (for input into Refworks) is also latin1. 
## For now, no decoding or encoding is done by this package or by GODOT::RefWorks::RIS as input and output encoding is the same. 
##
use CGI qw(:standard :escape);
use FileHandle;

use Data::Dump qw(dump);

use GODOT::Object;
use GODOT::Debug;
use GODOT::Citation;
use GODOT::File;
use GODOT::String;
use GODOT::RefWorks::RIS;

use base qw(GODOT::Object);

use strict;

my $FILTER  = 'RIS Format';

my $DIR               = '/tmp';
my $FILE_PREFIX       = '';
my $FILE_SUFFIX       = "refworks";
my $FILE_RETRY        = 10;
my $FILE_ID_RAND_MAX  = 999999999; 

my @FIELDS = ('refworks_root_url',
              'file',
              'file_id');

sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    debug "-- new --";
    debug "class:  $class";

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}


##
## returns html to display
##
sub run {
    my($self, $state) = @_;

    debug "-- run --";
    debug Data::Dump::dump($self);

    if (grep {$state eq $_} qw(import export)) {
        no strict;
        my $method = $state . '_citation';
        my $result = $self->$method;
        use strict;
        return $result;
    }
    else {
        return header . start_html . "Invalid state ($state)." .  end_html;
    }
}

##
## 'Import' citation to this script (storing as file in temp directory)
##
## (22-jan-2009 kl)
## !!! Do not call this method 'import' since the 'the use function calls the import method for the package used'
## !!! and therefore it will be called earlier than you intended.                                          
## 
sub import_citation {
    my($self) = @_;
    
    #### foreach my $param (param()) {  debug "<incoming>  $param = ", param($param); }

    debug "-- import 1 --";
    debug Data::Dump::dump($self);

    my $database = new GODOT::Database;
    $database->dbase(param('DBASE'));
    my $citation = new GODOT::Citation $database;
   
    ##
    ## (30-oct-2010 kl) 
    ## Subroutine init_from_parsed_params does no decoding, so strictly speaking we should be decoding incoming parameters here.  However
    ## manipulation of $citation object is minimal before we are again doing output which we want in latin1 anyways.... so leave for now.   
    ##
    $citation->init_from_parsed_params();    

    #### debug "\n\n", Data::Dump::dump($citation), "\n";

    my $filter = new GODOT::RefWorks::RIS; 

    my $filtered = $filter->export_citation($citation);

    #### debug "\n---------- ris filtered ------------";
    #### debug Data::Dump::dump($filtered);
    #### debug "\n------------------------------------\n";

    my $db = $database->dbase;

    debug "-- import 2 --";
    debug Data::Dump::dump($self);

    $self->generate_file_name;

    if (aws($self->file)) {
        return header . start_html . "Unable to generate name for temporary file." . end_html;        
    }
  
    debug location_plus, "file:  ", $self->file;

    my $fh = new FileHandle;
    unless (open $fh, ('> ' . $self->file)) {
        return header . start_html . "Unable to open temporary file (" . $self->file . ") for writing." . end_html;        
    } 

    print $fh $filtered;

    debug location_plus, "file_id:  ",  $self->file_id;

    #### foreach my $tmp (keys %ENV) {
    ####    debug location_plus, "ENV -- $tmp -- $ENV{$tmp}"; 
    #### }
    
    ##
    ## (09-dec-2010 kl) -- CGI::script_name now returns query string as well so switch to using $ENV{'SCRIPT_NAME'}  
    ##
    #### my $export_url = join('', 'http://', server_name, ':', server_port, script_name, '?state=export&id=', escape($self->file_id));
   
    my $export_url = join('', 'http://', server_name, ':', server_port, $ENV{'SCRIPT_NAME'}, '?state=export&id=', escape($self->file_id));


    debug location_plus, "export_url:  ",  $export_url;


    ##
    ## (21-apr-2005 kl) - the vendor and database do not show up in refworks.  This is a problem for other 
    ##                    links to refworks as well.  Nina has previously requested that refworks add 
    ##                    the vendor/database import.
    ##

    my $rw_url =  join('', 
                       $self->refworks_root_url, 
                       '?vendor=', 
                       '&filter=', escape($FILTER),
                       '&database=', escape($db),
                       '&url=', escape($export_url)); 

    $rw_url = param('proxy') . $rw_url;

    debug location_plus, "rw_url:  $rw_url\n";

    return redirect($rw_url);
}


##
## Export citation to refworks.
##
sub export_citation {
    my($self) = @_;

    $self->file_id(param('id'));

    $self->generate_file_name;

    if (aws($self->file)) {
        return header . start_html . "Unable to generate name for temporary file." . end_html;        
    }

    my $fh = new FileHandle;
    unless (open $fh, $self->file) {
        return  header . start_html . "Unable to open temporary file (" . $self->file . ") for reading." . end_html;        
    } 
    
    my @filtered = <$fh>;    
     
    ##
    ## (30-oct-2010 kl) -- header default is latin1 but add explicitly for clarity
    ##
    #### return header('text/plain') . join('', @filtered);
    ####
    return header(-type => 'text/plain', -charset => 'ISO-8859-1') . join('', @filtered);
}

##
## -if $id is blank then generate a new id, otherwise use passed id; 
##
sub generate_file_name {
    my($self) = @_;

    debug "-- generate_file_name --";
    debug Data::Dump::dump($self);

    my($file, $file_id) = (aws($self->file_id)) ? get_tmp_file_new_id($DIR, $FILE_PREFIX, $FILE_SUFFIX, $FILE_RETRY, $FILE_ID_RAND_MAX)
                                                : get_tmp_file_for_id($DIR, $FILE_PREFIX, $FILE_SUFFIX, $self->file_id);

    $self->file($file);
    $self->file_id($file_id);
}

1;

__END__

