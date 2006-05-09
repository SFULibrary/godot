package GODOT::Parser::bip;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::bip") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##

        $citation->parsed('PUB', $citation->pre('SO'));
        $citation->parsed('AUT', $citation->pre('AU'));
        $citation->parsed('TITLE', $citation->pre('TI'));
        $citation->parsed('YEAR', $citation->pre('PY'));


	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::bip") if $GODOT::Config::TRACE_CALLS;

#	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

        my $reqtype = $GODOT::Constants::BOOK_TYPE;

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

