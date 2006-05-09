package GODOT::Parser::egli;

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
    
	if ($citation->is_book_article()) {
		my $source = $citation->pre('SO');

		if ($source =~ s/^in:\s+//i) {

			if ($source =~ s/\s*p\.\s+([-\d]+)\s*$//) {
				$citation->parsed('PGS', $1);
			}
			
			# Call the title everything up to the first period as the data
			# includes the publisher with no good delimiters

			if ($source =~ /^(.+?)\.(.+)$/) {
				$citation->parsed('TITLE', $1);
				$citation->parsed('PUB', $2);
			} else {
				$citation->parsed('TITLE', $source);
			}
		}
		
		$citation->parsed('ARTTIT', $citation->pre('TI'));
	} else {
		$citation->parsed('TITLE', $citation->pre('TI'));
	}


	if (defined($citation->pre('PB')) && $citation->pre('PB') ne '') {
		$citation->parsed('PUB', $citation->pre('PB'));
	}


	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::philind") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

    	if ($citation->pre('DT') =~ /chapter/i) {
    	   $reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE;	
    	} else {
    	   $reqtype = $GODOT::Constants::BOOK_TYPE;
    	}

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

