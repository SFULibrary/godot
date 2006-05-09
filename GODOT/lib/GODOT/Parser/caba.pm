##23-aug-2001 yyua: tested with DB at USask (http://library.usask.ca/scripts/access?CAB)

package GODOT::Parser::caba;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::caba") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	##---------------Customized code goes here-------------------##

	my $source = $citation->parsed('SOURCE');

        if ($citation->is_journal())  {

            ##
            ## Mosquito-News. 1975, 35: 1, 83-84; 1 ref.
            ##
            if ($source =~ m#([\w-]+)\.\s*([\d\-]+),\s*(\d+):\s*([\d\-]+),\s*([\d\-]+);#)
            {
                $citation->parsed('ISS', $4);      
                $citation->parsed('VOL', $3);
                $citation->parsed('PGS', $5);
                $citation->parsed('TITLE', $1);
            }

            ##
            ## Hassadeh. 1980, 60: 5, 875-877.
            ##
            elsif ($source =~ m#([\w-]+)\.\s*([\d\-]+),\s*(\d+):\s*([\d\-]+),\s*([\d\-]+).#)
            {
                $citation->parsed('ISS', $4);      
                $citation->parsed('VOL', $3);
                $citation->parsed('PGS', $5);
                $citation->parsed('TITLE', $1);
            }

            ##
            ##  misc formats & non journal-articles
            ##  -> catch title
            ##
            elsif ($source =~ m#(^[\w\-\,]+)\.#)
            {
                $citation->parsed('TITLE', $1);
            }
        } elsif ($citation->is_book())  {
            $citation->parsed('TITLE', $citation->pre('TI'));
        } 


	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::caba") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); ##yyua

	##---------------Customized code goes here-------------------##

        if ($citation->parsed('PUBTYPE') =~ m#journal-article#i) {
            $reqtype = $GODOT::Constants::JOURNAL_TYPE;
        }
        else {
            $reqtype = $GODOT::Constants::BOOK_TYPE;
        }

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

