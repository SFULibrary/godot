package GODOT::Parser::ebsco::socicol;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Parser::ebsco;
use CGI qw/unescapeHTML/;

@ISA = "GODOT::Parser::ebsco";

use strict;

#Convert some html encoding into normal character: e.g. &#039 -> '
sub post_parse{
	my ($self, $citation) = @_;
	debug("post_parse() in GODOT::Parser::ebsco::socicol") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::post_parse($citation); 

	my ($tmpstr, $key);
	foreach $key (@GODOT::Citation::PARSED_FIELDS) {
	    $tmpstr = $citation->parsed($key);
	    $tmpstr = unescapeHTML($tmpstr);
	    $citation->parsed($key, $tmpstr);
	}
}


1;

__END__

