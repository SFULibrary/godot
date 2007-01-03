package GODOT::Parser::georef;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;
use GODOT::String;

@ISA = "GODOT::Parser";


use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::georef") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	# Determine whether fulltext is available and set flag
        if (defined($citation->pre('UR')) && $citation->pre('UR') ne "") {
                $citation->fulltext_available(1);
        }

	# Some records have multiple ISNs.  Take the first one for lack of anything
	# more intelligent to do.  They are generally seperated by spaces and a vertical bar.
	
	if ($citation->pre('IB') =~ /^([-\dXx]+)\s*\|/) {
		$citation->parsed('ISBN', clean_ISBN($1));
	}
	if ($citation->pre('IS') =~ /^([-\dXx]+)\s*\|/) {
		$citation->parsed('ISSN', clean_ISSN($1));
	}

	my $source = $citation->parsed('SOURCE');

        if ($citation->is_journal()) {
		# Current Research - Geological Survey. 6; Pages 73-78. 1988. .
		# Journal of Sedimentary.57; 4, Pages 774-776. 1987. .
		# Journal of Sedimentary Research, Section A: Sedimentary Petrology and Processes.68; 1, Pages 220-222. 1998. . 
		# Geologic Investigations. 1971. .
		# Environmental Geology (Berlin). 40; 4-5, Pages 495-506. 2001.

		$citation->parsed('TITLE', $citation->pre('ST'));
		$citation->parsed('PUB', $citation->pre('PB'));

		if ($source =~ m#^\s*(.+)\.\s*(\d+);\s*([-\d]+),\s*Pages\s+(.+)\.\s*(\d{4})\.\s*#) {
			$citation->parsed('TITLE', $1);
			$citation->parsed('VOL', $2);
			$citation->parsed('ISS', $3);
			$citation->parsed('PGS', $4);
			$citation->parsed('YEAR', $5);
		} elsif ($source =~ m#^\s*(.+)\.\s*(\d+);\s*Pages\s+(.+)\.\s*(\d{4})\.\s*#) {
			$citation->parsed('TITLE', $1);
			$citation->parsed('VOL', $2);
			$citation->parsed('PGS', $3);
			$citation->parsed('YEAR', $4);
		} elsif ($source =~ m#^\s*(.+)\.\s*(\d+);\s*(\d{4})\.\s*#) {
			$citation->parsed('TITLE', $1);
			$citation->parsed('VOL', $2);
			$citation->parsed('YEAR', $3);
		} elsif ($source =~ m#^\s*(.+)\.\s*Pages\s+(.+)\s*\.\s*(\d{4})\.\s*#) {
			$citation->parsed('TITLE', $1);
			$citation->parsed('PGS', $2);
			$citation->parsed('YEAR', $3);
		} elsif ($source =~ m#^\s*(.+)\.\s*(\d{4})\.\s*#) {
			$citation->parsed('TITLE', $1);
			$citation->parsed('YEAR', $2);
		}
	} else {
		##
		## Non-journal requests types
		##
		
		# Title
		my $title = $citation->pre('BK');
		$title =~ s#^\s*in:\s*##i;   # Strip out "In:" for book articles
		$citation->parsed('TITLE', $title);
		
		# Set author to BA (Book Author) field
		$citation->parsed('AUT', $citation->pre('BA'));
		
		# Append CA (Corporate Author) to author field
		if (! aws($citation->pre('CA'))) {
			my $aut = $citation->parsed('AUT');
			if (! aws($aut)) {
				$aut .= '; ';
			}
			$aut .= $citation->pre('CA');
			$citation->parsed('AUT', $aut);
		}
		
		##
		## Deal with the SOURCE field if it exists to get page ranges, etc.
		##
		
		if ($citation->pre('SO') =~ m#^\s*(.+)\.\s+(\d+);\s*\d{4}\.\s*\.?\s*$#) {
			# Breviora.473; 1983. .

			$citation->parsed('SERIES', $1);
			$citation->parsed('VOL', $2);
		} elsif ($citation->pre('SO') =~ m#^\s*(.+)\s*\.\s*(\d+);\s*Pages\s+(.+)\.\s*\d{4}\.\s*\.?\s*$#) {
			# AGID Special Publication Series.19; Pages 529-536. 1996. .

			$citation->parsed('SERIES', $1);
			$citation->parsed('VOL', $2);
			$citation->parsed('PGS', $3);
		} elsif ($citation->pre('SO') =~ m#^\s*(.+)\s*\.\s*Pages\s+(.+)\.\s*\d{4}\.\s*\.?\s*$#) {
			# U.S. Geological Survey Professional Paper. Pages C1-C72. 1993. .

			$citation->parsed('SERIES', $1);
			$citation->parsed('PGS', $2);
		} elsif ($citation->pre('SO') =~ m#^\s*(\d+);\s*\d{4}\.\s*\.?\s*$#) {
			# 2;1982. .

			$citation->parsed('VOL', $1);
		} elsif ($citation->pre('SO') =~ m#^\s*Pages\s+([-VIX\d\055\.]+)\.\s*\d{4}\.\s*\.?\s*$#) {
			# Pages 817-892.1984. .
			# Pages VII.15-VII.23.1976. .

			$citation->parsed('PGS', $1);
		} elsif ($citation->pre('SO') =~ m#^\s*Vol\.\s*(.+);\s*Pages\s+([-\d\055]+)\.\s*\d{4}\.\s*\.?\s*$#) {
			# Vol.14A; Pages 197-258. 1978. .
			
			$citation->parsed('VOL', $1);
			$citation->parsed('PGS', $2);
		} elsif (($citation->pre('DT') =~ m#map#i) && ($citation->pre('SO') =~ m#^\s*(.+)\s*;\s*\d{4}\.\s*\.?\s*$#)) {
                	$citation->parsed('PGS', $1);
                }

		## Deal with various publisher strings, some with pages in them.
		
		# Harvard University, Museum of Comparative Zoology. Cambridge, MA, United States. Pages: 35. 1983.
		# U. S. Dep. Agric., Soil Conserv. Serv.. Washington, DC, United States. Pages: 172. 1984.
		# Natl. Geophys. Data Cent., United States. Pages: 1 sheet. 1985.

		if ($citation->pre('PB') =~ m#^\s*(.+)\.\s+Pages:\s*(.+)\.\s*\d{4}\.\s*$#i) {
			$citation->parsed('PUB', $1);
			if (aws($citation->parsed('PGS'))) { $citation->parsed('PGS', $2); }  # Don't overwrite pages
		} elsif ($citation->pre('PB') =~ m#^\s*Pages:\s*(.+)\.\s*\d{4}\.\s*$#i) {
			# Pages: 7. 1996.
			$citation->parsed('PGS', $1);
		} elsif ($citation->pre('PB') =~ m#^\s*(.+)\s*\d{4}\.\s*$#i) {
			$citation->parsed('PUB', $1);
		} else {
			$citation->parsed('PUB', $citation->pre('PB'));
		}
	}
	
	## 'Translated Title:' - use translated version for now
	
	if ($citation->parsed('TITLE') =~ m#^(.+)[\n\s]*[Tt]ranslated\s+[Tt]itle:\s*(.+)$#i) {
		$citation->parsed('TITLE', $2);
	}
	
	if ($citation->parsed('ARTTIT') =~ m#^(.+)[\n\s]*[Tt]ranslated\s+[Tt]itle:\s*(.+)$#) {
		$citation->parsed('ARTTIT', $2);
	}

        ## Append degree granting institution to pub field
        
        my $pre_di = $citation->pre('DI');
        if ($pre_di =~ m#^\s*(.+)\.\s+Pages:\s*([-\055\d]+)\.\s*\d{4}\.\s*$#i) {
        	$pre_di = $1;
        	$citation->parsed('PGS', $2);
        }
        if (! aws($pre_di)) {
        	my $pub = $citation->parsed('PUB');
        	if (! aws($pub)) {
        		$pub .= '; ';
        	}
        	$pub .= $pre_di;
        	$citation->parsed('PUB', $pub);
        }

        ## NOTE field pieces

	my $note = $citation->parsed('NOTE');

        if (! aws($citation->pre('NT'))) {
            if (! aws($note)) { $note .= '; '; }
            $note  .= $citation->pre('NT');
        }

        ## CN pre field - conference information field
        if (! aws($citation->pre('CN'))) {       
            if (! aws($note)) { $note .= '; '; }
            $note  .= $citation->pre('CN');
        }

        ## CT pre field - collection title info
        if (! aws($citation->pre('CT'))) {  
           if (! aws($note)) { $note .= '; '; }
           $note .= $citation->pre('CT');
        }

        ## NN pre field - annotation field
        if (! aws($citation->pre('NN'))) {  
           if (! aws($note)) { $note .= '; '; }
           $note .= $citation->pre('NN');
        }

        ## AV pre field - availability info
        if (! aws($citation->pre('AV'))) {  
           if (! aws($note)) { $note .= '; '; }
           $note .= $citation->pre('AV');
        }

        $citation->parsed('NOTE', $note);

	##
	## Other random fields
	##

        $citation->parsed('SYSID', $citation->pre('AN'));
        $citation->parsed('THESIS_TYPE', $citation->pre('DG'));
        $citation->parsed('REPNO', $citation->pre('RN'));

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::georef") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation);

	if ($citation->parsed('PUBTYPE') =~ /abstract/i) {
		$citation->parsed('WARNING', 'WARNING<P>		
		You have selected a citation for an abstract (a brief summary of a longer 
		document).  If you request this item, you will receive a copy of the 
		abstract, rather than the original document.<P>
		If you wish to proceed and request a copy of the abstract, click on CONTINUE.<P>
		If you wish to request the original document, please transfer the relevant 
		bibliographic information to a blank ILL form.  Please ask at the Library 
		Reference Desk if you require assistance.');
	}

	# Due to the very strange citations in Georef, assume that if there's
	# an ISSN that it should be looked up as a journal.  Otherwise, make
	# a guess based on the pubtype.  Order does matter, but I don't really
	# know what order makes the most sense!

	if ($citation->pre('IS') =~ /\d{4}-\d{3}[\dxX]/) {
		$reqtype = $GODOT::Constants::JOURNAL_TYPE;
	} elsif ($citation->parsed('PUBTYPE') =~ m#conference-document#i) { 
		$reqtype = $GODOT::Constants::CONFERENCE_TYPE;   
	} elsif ($citation->parsed('PUBTYPE') =~ m#thesis-or-dissertation#i) { 
		$reqtype = $GODOT::Constants::THESIS_TYPE;
	} elsif ($citation->parsed('PUBTYPE') =~ m#report#i) { 
		$reqtype = $GODOT::Constants::TECH_TYPE;       
	} elsif ($citation->parsed('PUBTYPE') =~ m#serial#i) { 
		$reqtype = $GODOT::Constants::JOURNAL_TYPE; 
	} elsif ($citation->parsed('PUBTYPE') =~ m#book#i) {
		if (! aws($citation->pre('TI')) && $citation->pre('BK') =~ m#^in:#i) {
			$reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE;
		} elsif (! aws($citation->pre('BK'))) {
			$reqtype = $GODOT::Constants::BOOK_TYPE;         
		}
	}
	
	return $reqtype;
}


1;

__END__

__TESTS__

[
	{
		'pre' => {
			'BA' => 'Esdale-Julie-Anne',
			'BK' => 'Geoarchaeological studies at the Dog Creek site, northern Yukon.',
			'BL' => 'Monograph',
			'CP' => 'Canada',
			'DG' => 'Master\'s',
			'DI' => 'University of Alberta. Edmonton, AB, Canada. Pages: unpaginated. 1999.',
			'DT' => 'Thesis-or-Dissertation',
			'AN' => '2001-077484',
			'PY' => '1999',
		},
		'req_type' => 'THESIS',
		'parsed' => {
			'YEAR' => '1999',
			'SOURCE' => '',
			'PUB' => 'University of Alberta. Edmonton, AB, Canada. Pages: unpaginated. 1999.',
			'REPNO' => '',
			'THESIS_TYPE' => 'Master\'s',
			'AUT' => 'Esdale-Julie-Anne',
			'PUBTYPE' => 'thesis-or-dissertation',
			'SERIES' => '',
			'TITLE' => 'Geoarchaeological studies at the Dog Creek site, northern Yukon.',
			'SYSID' => '2001-077484'
		},
		'fail_notes' => 'THESIS request type test.',
	},
	{
		'pre' => {
			'IS' => '0036-8075',
			'BL' => 'Analytic',
			'CP' => 'United-States',
			'SO' => 'Science. 293; 5530, Pages 619-620. 2001. ',
			'DT' => 'Serial',
			'PB' => 'American Association for the Advancement of Science. Washington, DC, United States. 2001.',
			'AN' => '2001-065746',
			'TI' => 'The smile of the Cheshire Cat.',
			'AU' => 'Kramers-Jan',
			'PY' => '2001',
		},
		'req_type' => 'JOURNAL',
		'parsed' => {
			'YEAR' => '2001',
			'ARTTIT' => 'The smile of the Cheshire Cat.',
			'SOURCE' => 'Science. 293; 5530, Pages 619-620. 2001.',
			'VOL' => '293',
			'PUB' => 'American Association for the Advancement of Science. Washington, DC, United States. 2001.',
			'REPNO' => '',
			'THESIS_TYPE' => '',
			'PGS' => '619-620',
			'PUBTYPE' => 'serial',
			'SERIES' => '',
			'ISSN' => '00368075',
			'ISS' => '5530',
			'TITLE' => 'Science',
			'SYSID' => '2001-065746',
			'ARTAUT' => 'Kramers-Jan'
		},
		'fail_notes' => 'JOURNAL request type test.  Volume, issue, and pages.',
	},
	{
		'pre' => {
			'IS' => '0583-7731',
			'BL' => 'Analytic',
			'CP' => 'Venezuela',
			'SO' => 'Boletin de la Sociedad Venezolana de Espeleologia. 31; Pages 26-30. 1997. ',
			'DT' => 'Serial',
			'PB' => 'Sociedad Venezolana de Espeleologia. Caracas, Venezuela. 1997.',
			'AN' => '1999-041158',
			'TI' => 'Arqueologia en los abrigos rocosos de La Maneta, Merida, Venezuela
Translated Title:  Archaeology of the rock shelters of La Maneta, Merida, Venezuela.',
			'AU' => 'Gil-Daza-Jose-Antonio',
			'PY' => '1997',
		},
		'req_type' => 'JOURNAL',
		'parsed' => {
			'YEAR' => '1997',
			'ARTTIT' => 'Archaeology of the rock shelters of La Maneta, Merida, Venezuela.',
			'SOURCE' => 'Boletin de la Sociedad Venezolana de Espeleologia. 31; Pages 26-30. 1997.',
			'VOL' => '31',
			'PUB' => 'Sociedad Venezolana de Espeleologia. Caracas, Venezuela. 1997.',
			'REPNO' => '',
			'THESIS_TYPE' => '',
			'PGS' => '26-30',
			'PUBTYPE' => 'serial',
			'SERIES' => '',
			'ISSN' => '05837731',
			'TITLE' => 'Boletin de la Sociedad Venezolana de Espeleologia',
			'SYSID' => '1999-041158',
			'ARTAUT' => 'Gil-Daza-Jose-Antonio'
		},
		'fail_notes' => 'JOURNAL request type test.  Volume, pages, and translated title.',
	},
	{
		'pre' => {
			'BA' => 'Hince-Bernadette',
			'BK' => 'The Antarctic dictionary; a complete guide to Antarctic English.',
			'BL' => 'Monograph',
			'CP' => 'Australia',
			'DT' => 'Book',
			'PB' => 'CSIRO Publishing. Collingwood, Australia. Pages: 394. 2000.',
			'AN' => '2001-080162',
			'IB' => '0-9577471-1-X',
			'PY' => '2000',
		},
		'req_type' => 'BOOK',
		'parsed' => {
			'YEAR' => '2000',
			'SOURCE' => '',
			'PUB' => 'CSIRO Publishing. Collingwood, Australia',
			'REPNO' => '',
			'THESIS_TYPE' => '',
			'PGS' => '394',
			'AUT' => 'Hince-Bernadette',
			'ISBN' => '095774711X',
			'PUBTYPE' => 'book',
			'SERIES' => '',
			'TITLE' => 'The Antarctic dictionary; a complete guide to Antarctic English.',
			'SYSID' => '2001-080162'
		},
		'fail_notes' => 'BOOK request type test.',
	},
	{
		'pre' => {
			'BA' => 'Zhuravlev-Andrey-Yu (editor); Riding-Robert (editor)',
			'BK' => 'In: The ecology of the Cambrian radiation.',
			'BL' => 'Analytic',
			'CP' => 'United-States',
			'CT' => 'In the collection: Critical moments in paleobiology and Earth history. 2001.; In the collection: (8.)',
			'SO' => 'Pages 474-493. 2001. ',
			'DT' => 'Book',
			'PB' => 'Columbia University Press. New York, United States. 2001.',
			'AN' => '2001-080023',
			'TI' => 'Molecular fossils demonstrate Precambrian origin of dinoflagellates.',
			'IB' => '0-231-10612-2 | 0-231-10613-0',
			'AU' => 'Moldowan-J-Michael; Jacobson-Stephen-R; Dahl-Jeremy; Al-Hajji-Adnan; Huizinga-Bradley-J; Fago-Frederick-J',
			'PY' => '2001',
		},
		'req_type' => 'BOOK-ARTICLE',
		'parsed' => {
			'YEAR' => '2001',
			'ARTTIT' => 'Molecular fossils demonstrate Precambrian origin of dinoflagellates.',
			'SOURCE' => 'Pages 474-493. 2001.',
			'PUB' => 'Columbia University Press. New York, United States.',
			'REPNO' => '',
			'THESIS_TYPE' => '',
			'PGS' => '474-493',
			'AUT' => 'Zhuravlev-Andrey-Yu (editor); Riding-Robert (editor)',
			'ISBN' => '0231106122',
			'PUBTYPE' => 'book',
			'SERIES' => '',
			'NOTE' => 'In the collection: Critical moments in paleobiology and Earth history. 2001.; In the collection: (8.)',
			'TITLE' => 'The ecology of the Cambrian radiation.',
			'SYSID' => '2001-080023',
			'ARTAUT' => 'Moldowan-J-Michael; Jacobson-Stephen-R; Dahl-Jeremy; Al-Hajji-Adnan; Huizinga-Bradley-J; Fago-Frederick-J'
		},
		'fail_notes' => 'BOOK-ARTICLE request type test.  Multiple ISBNs, pages in source field, book in BK field "In:...".',
	},
	{
		'pre' => {
			'IS' => '0092-332X',
			'BK' => 'In: Surface-water-quality assessment of the Yakima River basin, Washington; overview of major findings, 1987-91.',
			'BL' => 'Analytic',
			'CA' => 'U. S. Geological Survey, United States',
			'RN' => 'WRI 98-4113',
			'CP' => 'United-States',
			'SO' => 'Water-Resources Investigations - U. S. Geological Survey. Pages 41-62. 1999. ',
			'DT' => 'Serial; Report',
			'PB' => 'U. S. Geological Survey. [Reston, VA], United States. 1999.',
			'AN' => '2001-017291',
			'TI' => 'Nutrients.',
			'AU' => 'Pogue-Ted-R Jr.; Fuhrer-Gregory-J; Skach-Kenneth-A',
			'PY' => '1999',
		},
		'req_type' => 'JOURNAL',
		'parsed' => {
			'YEAR' => '1999',
			'ARTTIT' => 'Nutrients.',
			'SOURCE' => 'Water-Resources Investigations - U. S. Geological Survey. Pages 41-62. 1999.',
			'PUB' => 'U. S. Geological Survey. [Reston, VA], United States. 1999.',
			'REPNO' => 'WRI 98-4113',
			'THESIS_TYPE' => '',
			'PGS' => '41-62',
			'PUBTYPE' => 'serial; report',
			'SERIES' => '',
			'ISSN' => '0092332X',
			'TITLE' => 'Water-Resources Investigations - U. S. Geological Survey',
			'SYSID' => '2001-017291',
			'ARTAUT' => 'Pogue-Ted-R Jr.; Fuhrer-Gregory-J; Skach-Kenneth-A'
		},
		'fail_notes' => 'JOURNAL request.  Includes BK field AND ISSN, so treat as a JOURNAL.',
	},

]

__DBASE__

bless( {
	'dbase_local' => 'I(GE38)J(0000013697)',
	'dbase' => 'georef',
	'dbase_type' => 'erl',
	'dbase_syntax' => 'orig_syntax',
	'dbase_fullname' => 'Georef',
}, 'GODOT::Database' )
