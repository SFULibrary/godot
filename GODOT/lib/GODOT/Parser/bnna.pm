package GODOT::Parser::bnna;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::bnna") if $GODOT::Config::TRACE_CALLS;
	
	$self->SUPER::parse_citation($citation);
	
	##---------------Customized code goes here-------------------##
	
	my $source = $citation->parsed('SOURCE');
	
	if ($citation->is_journal()) {
	
		if ($source =~ m#^([\w\s]+),\s+(\d*),?\s*nos?\.\s*([-\/\d\w]+);\s*[-\d]+\.\s*pp?\.\s*([-\/\d\w,]+)#) {

			# Humanity and Society, 13, no.4; 1989. p. 386-402.
			# BC Studies, no. 110; 1996. p. 69-96
		
			$citation->parsed('TITLE', $1);
			$citation->parsed('VOL', $2);
			if (defined($citation->parsed('VOL')) && $citation->parsed('VOL') ne '') {
				$citation->parsed('ISS', $3);
			} else {
				$citation->parsed('VOL', $3);
			}
			$citation->parsed('PGS', $4);

		} elsif ($source =~ m#^([\w\s]+),\s+(\d+);\s*[-\d]+\.\s*pp?\.\s*([\/-\d\w,]+)# ) {

			# California Law Review, 63;1975. p. 601-666/601-661.
		
			$citation->parsed('TITLE', $1);
			$citation->parsed('VOL', $2);
			$citation->parsed('PGS', $3);
		
		} elsif ($source =~ m#^([\w\s]+)\s+--?\s+Vol\.\s+([-\/\d]+),\s+([^;]+);\s*[-\d]+\.\s*pp?\.\s*([\/-\d\w,]+)#) {

			# Journal of ethnic studies -- Vol. 18, no. 1; 1990. p.127-142.

			my ($title, $volume, $issue, $pages) = ($1, $2, $3, $4);
						
			$citation->parsed('TITLE', $title);
			$citation->parsed('VOL', $volume);

			if ($issue =~ /nos?\.\s*([-\/\d]+)/) {
				$citation->parsed('ISS', $1);
			} else {
				$citation->parsed('ISS', $issue);
			}

			$citation->parsed('PGS', $pages);

		}
	} elsif ($citation->is_book()) {
		$citation->parsed('TITLE', $citation->pre('TI'));
	} elsif ($citation->is_book_article()) {
		$citation->parsed('TITLE', $citation->pre('TI'));
		$citation->parsed('ARTTIT', $citation->pre('CT'));

		if ($source =~ s/\s*pp?\.\s*([-\d\/\w]+)$//) {
			$citation->parsed('PGS', $1);
		}
	
		$citation->parsed('PUB', $source);
	} elsif ($citation->is_tech()) {
		$citation->parsed('TITLE', $citation->pre('TI'));
		$citation->parsed('AUT', $citation->pre('AU'));

		$citation->parsed('ARTTIT', '');
		$citation->parsed('ARTAUT', '');
		
		$citation->parsed('PUB', $source);	
	}
	
	if ($citation->pre('AV') =~ /ERIC:?\s*(ED\s*\d+)/i) {
		$citation->parsed('ERIC_NO', $1);   ## accession number
		$citation->parsed('ERIC_AV', '1');   ## level of availability
	}                        

	$citation->parsed('SYSID', $citation->pre('AN'));

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::bnna") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); ##yyua

	##---------------Customized code goes here-------------------##
	
	if ($citation->pre('DT') =~ /journal/i || $citation->pre('DT') =~ /article/i) {
		$reqtype = $GODOT::Constants::JOURNAL_TYPE;
	} elsif ($citation->pre('DT') =~ /essay/i) {
		$reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE;
	} elsif ($citation->pre('DT') =~ /document/i) {
		$reqtype = $GODOT::Constants::TECH_TYPE;
	} else {
		$reqtype = $GODOT::Constants::BOOK_TYPE;
	}

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

