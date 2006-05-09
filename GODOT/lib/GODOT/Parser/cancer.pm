package GODOT::Parser::cancer;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::cancer") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	##---------------Customized code goes here-------------------##

	my $source = $citation->parsed('SOURCE');

	if ($citation->is_book_article()) {
	    # match "title. vol(iss):pp year."
	    if ($source =~ /^\s*([^.]+)\.\s*([^(]+)\(([^)]+)\):(.*?)\s+\d{4}$/) {
		$citation->parsed('TITLE', $1);
		$citation->parsed('VOL', $2);
		$citation->parsed('ISS', $3);
		$citation->parsed('PGS', $4);
	    }

	    # match "title. vol:pp year."
	    elsif ($source =~ /^\s*([^.]+)\.\s*([^:]+):(.*?)\s+\d{4}$/) {
		$citation->parsed('TITLE', $1);
		$citation->parsed('VOL', $2);
		$citation->parsed('PGS', $3);
	    }
	}
	else {
	    # match "Normalized-Title. Title. Vol/Iss (pp) year."
	    if ($source =~ /^\s*[^.]+\.\s*([^.]+)\.\s*([^\/]+)\/([^(]+)\(([^)]+)\).*$/) {
		$citation->parsed('TITLE', $1);
		$citation->parsed('VOL', $2);
		$citation->parsed('ISS', $3);
		$citation->parsed('PGS', $4);

		my $iss = $citation->parsed('ISS'); 
		$iss =~ s/\s*$//; # trim extra whitespace at end
		$citation->parsed('ISS', $iss);
	    }

	    # match "Title. vol iss:pp year."
	    elsif ($source =~ /^\s*([^.]+)\.\s*([^(\s]+)\s+([^:]+):(.*?)\s+\d{4}$/) {
		$citation->parsed('TITLE', $1);
		$citation->parsed('VOL', $2);
		$citation->parsed('ISS', $3);
		$citation->parsed('PGS', $4);
	    }

	    # match "Title. vol(iss):pp year."
	    elsif ($source =~ /^\s*([^.]+)\.\s*([^(]+)\(([^)]+)\):(.*?)\s+\d{4}$/) {
		$citation->parsed('TITLE', $1);
		$citation->parsed('VOL', $2);
		$citation->parsed('ISS', $3);
		$citation->parsed('PGS', $4);
	    }

	    # match "Title. vol:pp year."
	    elsif ($source =~ /^\s*([^.]+)\.\s*([^:]+):(.*?)\s+\d{4}$/) {
		$citation->parsed('TITLE', $1);
		$citation->parsed('VOL', $2);
		$citation->parsed('PGS', $3);
	    }
	}


	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::cancer") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); ##yyua

	##---------------Customized code goes here-------------------##

	$citation->parsed('PUBTYPE', lc($citation->parsed('PUBTYPE'))); # so we don't need /i in matches.

	if ($citation->parsed('PUBTYPE') =~ /monograph/)  {

	     # the next line is *not* a mistake!
	     $reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE;
	}
	else {
	    $reqtype = $GODOT::Constants::JOURNAL_TYPE;
	}


	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

