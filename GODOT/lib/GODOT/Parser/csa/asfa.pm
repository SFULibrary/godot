package GODOT::Parser::csa::asfa;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::csa::asfa") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##
	
	$citation->parsed('ISS', $citation->pre('ISS'));
	$citation->parsed('VOL', $citation->pre('VOL'));
	$citation->parsed('PGS', $citation->pre('PG'));
	
	if ($citation->is_journal()) {
		$citation->parsed('ARTAUT', $citation->pre('CA'));
		$citation->parsed('NOTE', $citation->pre('NU'));
		
		# Frieze (U.K.), no. 52, May 2001, pp. 53-5, 11 illus. (10 colour)
		# Flash Art (Italy), vol. 33, no. 215, Nov.-Dec. 2000, pp. 66-8, 4 illus. (1 colour) biog
		# Developmental Brain Research [Dev. Brain Res.], vol. 128, no. 1, pp. 53-62, 31 May 2001
		# Bull. Fish. Res. Inst. Mie. no. 8, pp. 1-6. 2000.
		
		my $title;
		if ( $source =~ /^(.+?[,\.])\s+(no|vol)/i ||
		     $source =~ /^(.+?)\s+\d+,No/i ||
		     $source =~ /^(.+?)\.\s+/
		                                              ) {
			$title = $1;
		}

		$title =~ s/\[[^]]+?\]//;  # remove journal abbreviation in square brackets
		$title =~ s/,$//;  # remove trailing comma if one is caught in first regex above

		$citation->parsed('TITLE', $title)    unless $citation->parsed('TITLE');

		if ($source =~ /Vol\.\s*([\d-]+)/i || $source =~ /(\d+),No/i) {
			$citation->parsed('VOL', $1)  unless $citation->parsed('VOL');
		}
		if ($source =~ /No\.\s*([\d-]+)/i || $source =~ /Vol\.?\s+\d+\(([\d-]+)\)/i) {
			$citation->parsed('ISS', $1)  unless $citation->parsed('ISS');
		}
		if ($source =~ /p\.\s*([\dPp-]+)/) {
			$citation->parsed('PGS', $1)  unless $citation->parsed('PGS');
		}
		if ($source =~ /(\d{4})[,\.]/) {
			$citation->parsed('YEAR', $1) unless $citation->parsed('YEAR');
		}

		# Some CSA journals have the ISSN in an ISBN field.  Brilliant.
		
		if ($citation->pre('ISBN') =~ /\d{7}[\dxX]/ && !$citation->parsed('ISSN')) {
			$citation->parsed('ISSN', $citation->pre('ISBN'));
		}


	} elsif ($citation->is_book_article()) {
		if ($source =~ /^\s*Chpt\s+in\s+([-A-Z,\.\s:\/]+),\s+[a-zA-Z][a-z]/) {
			$citation->parsed('TITLE', $1);
		} else {
			$citation->parsed('TITLE', $source);
		}


		
		$citation->parsed('ARTAUT', $citation->pre('AU'));
		$citation->parsed('ARTTIT', $citation->pre('TI'));
	} elsif ($citation->is_book()) {
	} elsif ($citation->is_conference()) {
		# Conference proceedings can look like book articles and may have trailing
		# date and page information:
		# Proceedings of the 15th international diatom symposium, Perth, Australia 28 September - 2 October 1998. pp. 135-141. 2002.

		if ($source =~ s/pp\.\s*([-\dpP]+)\.\s*(\d{4})\s*\.?\s*$//) {
			$citation->parsed('PGS', $1);
			$citation->parsed('YEAR', $2) unless $citation->parsed('YEAR');
			$citation->parsed('TITLE', $source);
		} elsif ($citation->pre('CF') =~ /\S/) {
			$citation->parsed('TITLE', $citation->pre('CF'));
		}
		
		
	
        } elsif ($citation->is_tech()) {
		$citation->parsed('PUB', $citation->pre('PUB'));
	}

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::csa::asfa") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

	if ($citation->parsed('PUBTYPE') =~ /journal\sarticle/) {
		$reqtype = $GODOT::Constants::ARTICLE_TYPE;	
	} elsif ($citation->parsed('PUBTYPE') =~ /chapter/) {
		$reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE; 
	} elsif ($citation->parsed('PUBTYPE') =~ /conference/) {
		$reqtype = $GODOT::Constants::CONFERENCE_TYPE;
        } elsif ($citation->parsed('PUBTYPE') =~ /report/) {
		$reqtype = $GODOT::Constants::TECH_TYPE;
	}

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__


__TESTS__

[

	{
		'pre' => {
                            'ISBN' => '09130012',
                            'NU' => '5336645',
                            'SO' => 'Bull. Fish. Res. Inst. Mie. no. 8, pp. 1-6. 2000.',
                            'TI' => 'Mortal condition of sand lance Ammodytes personatus in Ise Bay during estivation.',
                            'PT' => 'Journal Article',
                            'AU' => 'Yamada, Hirokatsu; Kuno, Masahiro',
                          },
                 'req_type' => 'JOURNAL',
                 'parsed' => {
                               'YEAR' => '2000',
                               'ARTTIT' => 'Mortal condition of sand lance Ammodytes personatus in Ise Bay during estivation.',
                               'SOURCE' => 'Bull. Fish. Res. Inst. Mie. no. 8, pp. 1-6. 2000.',
                               'PGS' => '1-6',
                               'PUBTYPE' => 'journal article',
                               'ISSN' => '09130012',
                               'NOTE' => '5336645',
                               'ISS' => '8',
                               'TITLE' => 'Bull. Fish. Res. Inst. Mie.',
                               'ARTAUT' => 'Yamada, Hirokatsu; Kuno, Masahiro'
                             },
		'fail_note' => 'JOURNAL request, ISSN in ISBN field, Journal title abbreviation only, no volume.'
	},
                'pre' => {
                            'PUB' => 'ICES',
                            'NU' => '5362399',
                            'SO' => 'ICES. [vp].',
                            'TI' => 'Trends in reproductive parameters of North Sea plaice and cod: implications for stock assessment and management advice',
                            'PT' => 'Report; Summary',
                            'AU' => 'Grift, RE; Pastoors, MA; Rijnsdorp, AD',
                          },
                 'req_type' => 'TECH',
                 'parsed' => {
                               'ARTTIT' => 'Trends in reproductive parameters of North Sea plaice and cod: implications for stock assessment and management advice',
                               'SOURCE' => 'ICES. [vp].',
                               'PUBTYPE' => 'report; summary',
                               'PUB' => 'ICES',
                               'TITLE' => 'ICES. [vp].',
                               'ARTAUT' => 'Grift, RE; Pastoors, MA; Rijnsdorp, AD'
                             }
                 'fail_note' => 'TECH request (report/summary).  No ISNs, volume or issue.',
         },
         
         





]

__DBASE__

bless( {
	'dbase_local' => 'csa',
	'dbase' => 'csa',
	'dbase_type' => 'csa',
	'dbase_syntax' => 'orig_syntax',
	'dbase_fullname' => 'Cambridge Scientific Abstracts'
}, 'GODOT::Database' )
