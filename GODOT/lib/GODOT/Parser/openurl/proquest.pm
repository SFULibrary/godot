package GODOT::Parser::openurl::proquest;

use GODOT::Config;
use GODOT::String;
use GODOT::Date;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Parser::openurl;
use CGI qw/unescapeHTML/;

@ISA = "GODOT::Parser::openurl";

my $TRUE  = 1;
my $FALSE = 0;


use strict;

sub parse_citation {

    my ($self, $citation) = @_;
    debug("parse_citation() in GODOT::Parser::openurl::proquest") if $GODOT::Config::TRACE_CALLS;

    $self->SUPER::parse_citation($citation); 

    ##
    ## -strip '[H.W. Wilson - AST]' or similar from 'title'
    ##

    if ($citation->parsed('TITLE') =~ m#(.+)\s+(\[H\.W\. Wilson\s+\055\s+.+\])#)  {

        $citation->parsed('TITLE', $1);      
    }


    ##
    ## -date format from proquest - mm/dd/yyyy
    ##
 
    my $dd;
    my $mm;
    my $yyyy;
    

    if ($citation->pre('date') =~ m#^(\d\d)/(\d\d)/(\d\d\d\d)$#)  {
 
        $mm   = $1;  
        $dd   = $2;  
        $yyyy = $3; 
    }
    ##
    ## -date format for BasicBIOSIS
    ##
    elsif ($citation->pre('date') =~ m#^(\d\d\d\d)(\d\d)(\d\d)$#) {

	$yyyy = $1;
        $mm   = $2;
        $dd   = $3; 
    }
    elsif ($citation->pre('date') =~ m#^(\d\d\d\d)(\d\d)$#) {

	$yyyy = $1;
	$mm   = $2;
    }
    elsif ($citation->pre('date') =~ m#^(\d\d\d\d)$#) {

	$yyyy = $1;
    }

    if ($yyyy && $mm && $dd) {
        $citation->parsed('YYYYMMDD', $yyyy . $mm . $dd);
    }

    if ($mm) {
        $mm =~ s#^0+##;        
        $citation->parsed('MONTH', &GODOT::Date::date_mm_to_mon($mm));
    }


    if ($dd) {
        $dd =~ s#^0+##;        ## -after saving 'YYYYMMDD', strip leading zeros
        $citation->parsed('DAY',   $dd);
    }





    ##
    ## pid=STYPE=<STYPE>|DOCID=<DOCID>
    ##

    if ($citation->pre('pid') =~ m#STYPE=(.*)\|DOCID=(.+)#) {
       
        warn ">>>>>>>>>>>> we have a match <<<<<<<<<<<<<<<<<\n";

	$citation->parsed('SYSID', $2);
    }
}


sub get_req_type {
    my ($self, $citation) = @_;
    debug("get_req_type() in GODOT::Parser::openurl::proquest") if $GODOT::Config::TRACE_CALLS;

    my $reqtype = $self->SUPER::get_req_type($citation); 

    return $reqtype;
}

1;

__END__

