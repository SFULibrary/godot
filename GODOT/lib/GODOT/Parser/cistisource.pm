package GODOT::Parser::cistisource;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::cistisource") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	##---------------Customized code goes here-------------------##


        if ($citation->is_journal()) {
	    $citation->parsed('TITLE', substr($citation->pre('SO'), 0, 150));
            $citation->parsed('ARTTIT', substr($citation->pre('TI'), 0, 150));
            $citation->parsed('ARTAUT', $citation->pre('CA'));        

	    $citation->parsed('ISS', $citation->pre('ISS')) if ($citation->pre('ISS'));
	    $citation->parsed('PGS', $citation->pre('PG')) if ($citation->pre('PG'));
	    $citation->parsed('VOL', $citation->pre('VOL')) if ($citation->pre('VOL'));

	    # Computer Weekly, 1999, Jun 10, p.4, 2p.
    	    if ($citation->pre('PUB') =~ /^.*[\.,]\s*(\d{4})\s*,(.*)$/) {
                $citation->parsed('YEAR', $1);

		my $remainder = $2;
    	    	if ($remainder =~ /^\s*(\w{3}\s*\d{0,2})\s*,/) {
		    $citation->parsed('MONTH', $1);
		}
		if ($remainder =~ /v\.([^,]+)/) {
		    $citation->parsed('VOL', $1);
		}   
    	    	if ($remainder =~ /n\.([^,]+)/) {
		    $citation->parsed('ISS', $1);
    	    	}
    	    	if ($remainder =~ /p\.([^,]+)/) {
		    $citation->parsed('PGS', $1);
		}
    	    } else {
		warn "Unable to parse out title/date from PUB: " . $citation->pre('PUB') . "\n";
	    }
        }

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::cistisource") if $GODOT::Config::TRACE_CALLS;

#	Only have one type, so don't need call super method.
#	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##
	my $reqtype;

    	# All CISTI Source stuff is Journal at this point - TH
	$reqtype =  $GODOT::Constants::JOURNAL_TYPE;

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

23-aug-2001 yyua: tested with DB at UCalgary (http://httprelay.lib.ucalgary.ca:32888/DB=SWETSCAN)
15-jan-2002 tholbroo: fixed minor issue with PUB field parsing (period or comma before date). At this time PUB and PY fields are not being passed through from CISTISource, Kristina is following up with them.

