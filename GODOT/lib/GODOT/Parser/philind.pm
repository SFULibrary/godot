package GODOT::Parser::philind;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::philind") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##
    
	if ($citation->is_journal()) {
		# Revista-de-Filosofia-(Spain). 1998; 11(20), 5-21
		# Environmental-Ethics. Sum 01; 23(2): 189-201
		if ($source =~ /^\s*([^\.]+)\s*\.\s*\(?([-\s\w\d]*?)\)?\s*\d{2,4}\s*;\s*([\d\w\s]+)\s*\(?([^\)]*)\)?\s*[,:]\s*([\w\d\-\+]+)\s*$/) {
                        $citation->parsed('TITLE', $1);
                        $citation->parsed('MONTH', $2);
			$citation->parsed('VOL', $3);						                         
			$citation->parsed('ISS', $4);
			$citation->parsed('PGS', $5);
		}
		# Revista-de-Filosofia-(Spain). 1998; 5-21
		elsif ($source =~ /^\s*([^\.]+)\s*\.\s*\(?([-\s\w\d]*?)\)?\s*\d{2,4}\s*;\s*([\w\d\-\+]+)\s*$/) {
                        $citation->parsed('TITLE', $1);
                        $citation->parsed('MONTH', $2);
			$citation->parsed('PGS', $3);
		}
	}
	elsif ($citation->is_book_article()) {
		# "Dewey: Pragmatic Technology and Community Life" in Classical American Pragmatism: Its Contemporary Vitality, Rosenthal, Sandra B (ed)
		if ($citation->pre('TI') =~ /^'(.+)'\s+[iI][nN]\s+'(.+)',\s*([a-zA-Z, ]+)($| \()[^\d]*([0-9-]*)/) {
		    $citation->parsed('ARTTIT', $1);
		    $citation->parsed('TITLE', $2);
		    $citation->parsed('AUT', $3);
		    $citation->parsed('PGS', $5);
		}
		elsif ($citation->pre('TI') =~ /^'(.+)'\s+[iI][nN]\s+(.+),\s*([a-zA-Z, ]+)($| \()[^\d]*([0-9-]*)/) {
		    $citation->parsed('ARTTIT', $1);
		    $citation->parsed('TITLE', $2);
		    $citation->parsed('AUT', $3);
		    $citation->parsed('PGS', $5);
		}

	}	
	$citation->parsed('SYSID', $citation->pre('AN'));
	$citation->parsed('PUB', $citation->pre('PB'));


	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::philind") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

    	if ($citation->pre('DT') =~ /Contribution/i) {
    	   $reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE;	
    	} elsif ($citation->pre('DT') =~ /Journal/i) {
    	   $reqtype = $GODOT::Constants::JOURNAL_TYPE;
    	} else {
    	   $reqtype = $GODOT::Constants::BOOK_TYPE;
    	}

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

