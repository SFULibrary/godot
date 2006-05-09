package GODOT::Parser::emneuro;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::emneuro") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##

	if ($citation->is_conference()) {
	    $citation->parsed('TITLE', $citation->pre('CT'));
	    $citation->parsed('PUB', $citation->pre('AD'));

	    # grab pages from source field
	    $source =~ /\(([^)]+)\)/;
	    $citation->parsed('PGS', $1);
	}
	    # match "Normalized-title. Title. Vol/Iss (pp) year."
	elsif ($source =~ /^\s*[^.]+\.\s*([^.]+)\.\s*([^\/]+)\/([^(]+)\(([^)]+)\).*$/) {
	    $citation->parsed('TITLE', $1);
	    $citation->parsed('VOL', $2);
	    $citation->parsed('ISS', $3);
	    $citation->parsed('PGS', $4);

	    my $iss = $citation->parsed('ISS');
	    $iss =~ s/\s*$//; # trim extra whitespace at end
	    $citation->parsed('ISS', $iss);
	}

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::emneuro") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

	$citation->parsed('PUBTYPE', lc($citation->parsed('PUBTYPE'))); # so we don't need /i in matches.

	if ($citation->parsed('PUBTYPE') =~ /conference/) {
	    $reqtype = $GODOT::Constants::CONFERENCE_TYPE;
	}
	else {
	    $reqtype = $GODOT::Constants::JOURNAL_TYPE;
	}

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

