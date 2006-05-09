package GODOT::Parser::paissel;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";


use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::paissel") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##

	#Nueva-Sociedad; p 166-80 no 162 Jl/Ag 1999
	#China-Rights-Forum; p 34-7,73 Spring 1999
	#Congressional-Quarterly-Weekly-Report; 54:1243-52 My 4 1996
	#Hispanic-Business; 12:30-2+ N 1990
	#International-Journal-of-Social-Economics; 12:17-25 no 2 1985
	#Business-Week; p 40+ Ap 2 1979
	#Afrique-Industrie-Infrastructures; p 17-21+ Ja 1 1975

        if ($citation->is_journal())  {

	    my ($title);

	    if ($source =~ /^(.*?)\;\s+/) {
		$title = $1;
		$title =~ s/-/ /g;
		$citation->parsed('TITLE', $title);
	    }
	    if ($source =~ /(\d+):\d+/) {
		$citation->parsed('VOL', $1);
	    }
	    if ($source =~ /\s+no\s+([\d-]+)/) {
		$citation->parsed('ISS', $1);
	    }
	    if ($source =~ /\s+p\s+([\d+,-]+)/ || $source =~ /\d+:([\d+,-]+)/) {
		$citation->parsed('PGS', $1);
	    }
	    if ($source =~ /\s+([A-Z][^\s]*\s*[^\s]*)\s+\d{4}/) {
		$citation->parsed('MONTH', $1);
	    }
        }
        elsif ($citation->is_book())  {    
            $citation->parsed('PUB', $source);
        }
        if (defined($citation->pre('UR')) && $citation->pre('UR') ne "") {
                $citation->fulltext_available(1);
        }
        

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::paissel") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

