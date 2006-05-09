package GODOT::Parser::asti;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";


use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::asti") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	##---------------Customized code goes here-------------------##

	my $source = $citation->parsed('SOURCE');

        if ($citation->is_journal())  {

	    #Journal of Coastal Research v 17 no1 Winter 2001 p. 244-5
	    #Aviation Week and Space Technology v 149 no21 Nov 23 1998 p. 53-4
	    #Oil and Gas Journal v 94 Jan 22 1996 p. 23
	    #Ergonomics v 36 Jan-Mar 1993 p. 43-9
	    #Laser Focus v 22 Jan 1986 p. 56+

	    if ($source =~ /^(.*)\s+v\s+([\d-]+)\s+(no\d+)*\s*(.*)\s+\d{4,4}\s+p\.\s+([\d+-]+)/) {
		$citation->parsed('TITLE', $1);
		$citation->parsed('VOL', $2);
		$citation->parsed('MONTH', $4);
		$citation->parsed('PGS', $5);
		if ($3) {
		   my $iss = $3;
		   $iss =~ s/no//g;
		   $citation->parsed('ISS', $iss);
		}
	    }
	    else {
	       print STDERR "Warning: asti journal parsing failed!\n"; 
	    }
	}
	else {
	    print STDERR "Warning: asti: parse_citation: unexpected type!\n";
	}

	    
	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::asti") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

        if ($citation->pre('JN')) { 
	    $reqtype = $GODOT::Constants::JOURNAL_TYPE; 
	}
        else {
	    print STDERR "Warning: asti: get_req_type: unrecognized type\n";
	}

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

