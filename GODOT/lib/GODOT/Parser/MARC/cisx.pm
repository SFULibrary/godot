package GODOT::Parser::MARC::cisx;

use GODOT::Debug;
use GODOT::Constants;
use GODOT::Config;
use GODOT::Parser::MARC;

@ISA = "GODOT::Parser::MARC";
 
use strict;

sub get_req_type {
	my ($self, $citation, $pubtype) = @_;
	debug("get_req_type() in GODOT::Parser::MARC::cisx") if $GODOT::Config::TRACE_CALLS;

	# All cisx catalogue items are journals
	return $GODOT::Constants::JOURNAL_TYPE;
}

1;

