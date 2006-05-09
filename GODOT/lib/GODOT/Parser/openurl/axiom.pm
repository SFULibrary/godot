package GODOT::Parser::openurl::axiom;

use GODOT::Config;
use GODOT::String;
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
	debug("parse_citation() in GODOT::Parser::openurl::axiom") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation); 

        ##
        ## -temporary fix -- need to email tim.marsh@iop.org
        ##

	if (($citation->pre('pid') =~ m#<patent>#) && (&GODOT::String::aws($citation->parsed('TITLE')))) {
       
	    $citation->parsed('TITLE', $citation->pre('atitle'));
	    $citation->parsed('ARTTIT', '');

	    $citation->parsed('NO_HOLDINGS_SEARCH', $TRUE);
           
	}

        ##
        ## <patent>PN=$PN&PA=$PA&PY=$PY</patent> (Patent number, patentee and patent year)
        ##

        if ($citation->pre('pid') =~ m#<patent>PN=(.+)&PA=(.+)&PY=(\d+)</patent>#) {

 
	    $citation->parsed('PATENT_NO',   $1);
	    $citation->parsed('PATENTEE',    $2);
            $citation->parsed('PATENT_YEAR', $3);
        }
}


sub get_req_type {
    my ($self, $citation) = @_;
    debug("get_req_type() in GODOT::Parser::openurl::axiom") if $GODOT::Config::TRACE_CALLS;

    my $reqtype = $self->SUPER::get_req_type($citation); 

    if ((! $citation->pre('genre')) && ($citation->pre('pid') =~ m#<patent>#)) {    
 
        $reqtype = $GODOT::Constants::TECH_TYPE;
    }

    return $reqtype;
}

1;

__END__

