##23-aug-2001 yyua: tested with DB at UVic(http://webspirs.uvic.ca/cgi-bin/tree.bat)

package GODOT::Parser::treecd;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;
use GODOT::String;

@ISA = "GODOT::Parser";


use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::treecd") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	##---------------Customized code goes here-------------------##

	my $source = $citation->parsed('SOURCE');

	if (! aws($source))  {     
        
	    #if ($source =~ m#(.+)$citation->parsed('YEAR')#)  {
	    my $year = $citation->parsed('YEAR');
	    if ($source =~ m#(.+)$year#)  {
	        $citation->parsed('TITLE', $1);
	    }
        
	    if ($source =~ m#\,\s+(\d+):\s(\d+)#)  {
	        $citation->parsed('VOL', $1);
	        $citation->parsed('ISS', $2);
	        $citation->parsed('VOLISS', "$1 ($2)");
            }
 
	    if ($source =~ m#\,\s+(\d+\-\d+)#)  {
	        $citation->parsed('PGS', $1);
            }
        }


	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::treecd") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); ##yyua

	##---------------Customized code goes here-------------------##

	if ($citation->parsed('PUBTYPE') =~ m#miscellaneous#)  {      
            $reqtype = $GODOT::Constants::BOOK_TYPE; 
        }

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

