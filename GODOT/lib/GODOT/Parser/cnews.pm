package GODOT::Parser::cnews;

use GODOT::Debug;
use GODOT::Constants;

@ISA = "GODOT::Parser";
 
use strict;

sub parse_citation {
        my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::cnews") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	if ($citation->is_journal()) {

		# The Toronto Star, June 16, 2000, First Edition
		# The Gazette (Montreal), June 16, 2000, Final Edition, p.E5

		my ($title, $month, $year, $edition, $pages) = split /\s*,\s*/, $citation->parsed('SOURCE');
		if ($pages eq '' && $edition =~ /^pp?\./) {
			$pages = $edition;
			$edition = ''
		}
		$pages =~ s/pp?\.//;

		$citation->parsed('TITLE', $title);
		$month .= " ($edition)" if $edition ne '';
		$citation->parsed('MONTH', $month);
		$citation->parsed('EDITION', $edition);
		$citation->parsed('YEAR', $year) if $year =~ /\d{4}/;
		$citation->parsed('PGS', $pages) if $pages ne '';

		$citation->parsed('ARTAUT', $citation->pre('BY'));
	}

	return $citation;
}

sub get_req_type {
	my ($self, $citation, $pubtype) = @_;
	debug("get_req_type() in GODOT::Parser::cnews") if $GODOT::Config::TRACE_CALLS;;
	
	# Default to JOURNAL type since 100%(?) of CNEWS is newspapers - don't
	# bother with the default get_req_type
	
	return $GODOT::Constants::JOURNAL_TYPE;
}

1;

__END__
