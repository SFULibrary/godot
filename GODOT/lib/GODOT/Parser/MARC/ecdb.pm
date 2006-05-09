package GODOT::Parser::MARC::ecdb;

use GODOT::Debug;
use GODOT::Constants;
use GODOT::Config;
use GODOT::String;
use GODOT::Parser::MARC;

@ISA = "GODOT::Parser::MARC";
 

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::MARC::ecdb") if $GODOT::Config::TRACE_CALLS;
       
	$self->SUPER::parse_citation($citation);   # Calls GODOT::MARC::parse_citation()
	
	$citation->parsed('SYSID', strip_subfield(keep_marc_subfield($citation->pre('T035'), [qw(a l)])));
       
        ##
        ## (16-mar-2005 kl) - incoming record from ecdb has subfield-a before indicators 
        ##                    (eg. '^_a 00 ^_a  Maclean's.') so we need to strip indicators
        ##

        (my $title = $citation->parsed('TITLE')) =~ s#^\d+##g;
        $citation->parsed('TITLE', $title);        

	return $citation;
}

sub get_req_type {
	my ($self, $citation, $pubtype) = @_;
	debug("get_req_type() in GODOT::Parser::MARC::ecdb") if $GODOT::Config::TRACE_CALLS;

	# All union catalogue items are journals
	return $GODOT::Constants::JOURNAL_TYPE;
}

1;

__END__

