##23-aug-2001 yyua: tested with DB at UVic (http://webspirs.uvic.ca/cgi-bin/ipsa.bat)

package GODOT::Parser::ipsa;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::ipsa") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##

	if ($citation->is_journal()) {

		## Immigrants and Minorities 17 (3), Nov.1998: 1-21
		## Foreign Affairs 77 (5), Sept.-Oct.1998: 95-108
		## Politique internationale 77, automne 97: 87-106
		## Ocean Development and International Law 24 (1), Jan.-March 93: 41-62
		
		if ($source =~ /^\s*(.+?)\s+(\d+)\s*\(?([-\d]*)\)?,\s*([-\w\.]*)\s*(\d{2,4})\s*:\s*([-\d]+)/) {
			$citation->parsed('TITLE', $1);
			$citation->parsed('VOL', $2);
			$citation->parsed('ISS', $3);
			$citation->parsed('MONTH', $4);
			$citation->parsed('YEAR', $5);
			$citation->parsed('PGS', $6);
		
			if ($citation->parsed('YEAR') =~ /^\d\d$/) {
				$citation->parsed('YEAR', $citation->parsed('YEAR') + ($citation->parsed('YEAR') < 20 ? 2000 : 1900));
			}

		## Political Quarterly Suppl.1991: 1-167
		
		} elsif ($source =~ /^\s*(.+?)\s+\d{2,4}\s*:\s*([-\d]+)/) {
			$citation->parsed('TITLE', $1);
			$citation->parsed('PGS', $2);
		}
	}

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::ipsa") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

	if ($reqtype eq $GODOT::Constants::UNKNOWN_TYPE) {
	    $reqtype = $GODOT::Constants::JOURNAL_TYPE;
	}

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

