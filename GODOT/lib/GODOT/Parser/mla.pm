package GODOT::Parser::mla;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;
use GODOT::String;

@ISA = "GODOT::Parser";


use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::mla") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	
	if (defined($citation->pre('UR')) && $citation->pre('UR') ne "") {
		$citation->fulltext_available(1);
	}
	
	if ($citation->is_journal())  {
		my $source = $citation->parsed('SOURCE');
		
		# Canadian-Journal-of-Native-Studies (Canadian Journal of Native Studies). 1996; 16(1): 37-66.
		# UTS-Review:-Cultural-Studies-and-New-Writing (UTSRev) 2007, Australia. 1999 May; 5(1): 157-77
		# Journal-of-Aesthetics-and-Art-Criticism (JAAC) Louisville, KY. 2000 Fall; 58(4): 361-72.
		# Mystery-Scene. 1997; 59: 48-49, 71.

		# Try for all fields
		if ($source =~ /^((?:The|Les)?\s*\S+)\s*.*\.\s*\d{4}\s*([^;]*);\s*([^:]+):\s*(.+)/) {
			$citation->parsed('TITLE', $1);
			$citation->parsed('MONTH', $2);
			$citation->parsed('VOLISS', $3);
			$citation->parsed('PGS', $4);
		# Try for all fields except for pages
		} elsif ($source =~ /^((?:The\s)?\S+)\s*.*\.\s*\d{4}\s*([^;]*);\s*(.+)/) {
			$citation->parsed('TITLE', $1);
			$citation->parsed('MONTH', $2);
			$citation->parsed('VOLISS', $3);
		}		

		if ($citation->parsed('VOLISS') =~ /(\w+)\((.+)\)/) {
			$citation->parsed('VOL', $1);
			$citation->parsed('ISS', $2);
		} else {
			$citation->parsed('VOL', $citation->parsed('VOLISS'));
		}

		# Replace - and -- in title.
		my $title = $citation->parsed('TITLE');
		$title =~ s/([^\-])-(?!-)/$1 /g;
		$title =~ s/--/-/g;
		$citation->parsed('TITLE', $title);

	} elsif ($citation->is_book() || $citation->is_book_article()) {
	
		# MLA now has all publication information in the PB field, including the
		# book title for BOOK-ARTICLE citations
		
		my $tmpstr = trim_beg_end($citation->pre('PB'));
		
		$citation->parsed('PUB', $tmpstr);
		
		if ($citation->is_book_article()) {
			
			$tmpstr =~ s#;\s+#;#g;     # so author string will have no whitespace
			$tmpstr =~ s#\.?\s+\(ed\.\s*\&\s*([\S]+?)\.?\)#(ed&$1)#g;
			$tmpstr =~ s#\.?\s+\(ed\.\s*and\s*([\S]+?)\.?\)#(ed&$1)#g;
			$tmpstr =~ s#\.?\s+\(ed\.?\)#(ed)#g;
			$tmpstr =~ s#\.?\s+\(fwd.\)#(fwd)#g;
			$tmpstr =~ s#\.?\s+\(bibliog.\)#(bibliog)#g;
			$tmpstr =~ s#\.?\s+\(bibliography\)#(bibliography)#g;
			$tmpstr =~ s#\.?\s+\(pref.\)#(pref)#g;
			$tmpstr =~ s#\.?\s+\(preface\)#(preface)#g;
			$tmpstr =~ s#\.?\s+\(introd.\)#(introd)#g;
			$tmpstr =~ s#\.?\s+\(tr.\)#(tr)#g;
			$tmpstr =~ s#\.?\s+\(epilogue\)#(epilogue)#g;
			$tmpstr =~ s#\.?\s+\(rebuttal\)#(rebuttal)#g;
			$tmpstr =~ s#\.?\s+\(foreword\)#(foreword)#g;
			$tmpstr =~ s#\.?\s+\(postscript\)#(postscript)#g;

#			print STDERR "...... $tmpstr\n";
			
			# Strip 'III:' type entries from the beginning of the PB field
			$tmpstr =~ s/^[A-Za-z]+?:\s*//;

			##
			##  418-41 IN Kachru-Braj-B.; Lees-Robert-B.; Malkiel-Yakov; Pietrangeli-Angelina; Saporta-Sol.
			##  Issues in Linguistics:Papers in Honor of Henry and Renee Kahane.
			##  Chicago : U. of Ill. P, 1973. 933 pp. .
			##
			
			# Title, authors, year, pages
			if ($tmpstr =~ m#^\s*([\w\-]+)\s+IN\s+(\S+)\.\s+(.+),\s+\d{4}\.#) {
				$citation->parsed('PGS', $1);
				$citation->parsed('AUT', $2);
				$citation->parsed('TITLE', $3);
			# Title, no authors, year, pages
			} elsif ($tmpstr =~ m#^\s*([\w\-]+)\s+IN\s+(.+),\s+\d{4}\.#) {
				$citation->parsed('PGS', $1);
				$citation->parsed('TITLE', $2);
			# Title, authors, no year, pages
			} elsif ($tmpstr =~ m#^\s*([\w\-]+)\s+IN\s+(\S+)\.\s+(.+)\s*\.\s*\d+\s+pp#) {
				$citation->parsed('PGS', $1);
				$citation->parsed('AUT', $2);
				$citation->parsed('TITLE', $3);
			# Assume something got cut off at some point due to a stray & and hope it's after the title
			} elsif ($tmpstr =~ m#^\s*([\w\-]+)\s+IN\s+(\S+)\.\s+(.+)\.#) {
				$citation->parsed('PGS', $1);
				$citation->parsed('AUT', $2);
				$citation->parsed('TITLE', $3);
			} else {
				$citation->parsed('TITLE', $tmpstr);
			}
			
			my $aut = $citation->parsed('AUT');
			$aut   =~ s#;#; #g;    ## put back semi-colons
			$citation->parsed('AUT', $aut);
				
			if ($citation->parsed('TITLE') =~ m#([^\.]+)\.(.+)#) {
				$citation->parsed('TITLE', $1);
				$citation->parsed('PUB', $2);
			}
			
			
		} else {
			$citation->parsed('PGS', '');
			$citation->parsed('ARTAUT', '');
			$citation->parsed('ARTTIT', '');
			$citation->parsed('PUB', trim_beg_end($citation->parsed('PUB')));
		}
		
		##
		## clean up series
		## ex. Varieties-of-English-Around-the-World, Amsterdam, Netherlands (VEAW); 11
		##
		
		if ($citation->parsed('SERIES') =~ m#([^\s]+),\s+(.+)#i) {
			$citation->parsed('SERIES', $1);
			if (aws($citation->parsed('PUB'))) {
				$citation->parsed('PUB', $2);
			}
		}
	}
	
	if ($citation->is_thesis()) {
		$citation->parsed('NOTE', trim_beg_end($citation->pre('PB')));
		
		if ($citation->pre('PB') =~ m#granting institution:(.+),\s*\d{4}#i) {
			$citation->parsed('PUB', $1);
		}
	}

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::mla") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

	# Order is important!

	if ($citation->parsed('PUBTYPE') =~ /book-article/i) {
		$reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE;
	} elsif ($citation->parsed('PUBTYPE') =~ /book/i) {
		$reqtype = $GODOT::Constants::BOOK_TYPE;
	} elsif ($citation->parsed('PUBTYPE') =~ /dissertation/i) {
		$reqtype = $GODOT::Constants::THESIS_TYPE;
	} elsif ($citation->parsed('PUBTYPE') =~ /journal/i) {
		$reqtype = $GODOT::Constants::JOURNAL_TYPE;
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
			'SO' => 'Ukrajins\'ka-Dumk. 1980; 11 June',
			'AN' => '1980221538',
			'TI' => 'Pisnja nadzemna',
			'PT' => 'journal-article',
			'AU' => 'Berdnyk,-O.',
			'PY' => '1980',
		},
		'req_type' => 'JOURNAL',
		'parsed' => {
			'YEAR' => '1980',
			'ARTTIT' => 'Pisnja nadzemna',
			'SOURCE' => 'Ukrajins\'ka-Dumk. 1980; 11 June',
			'VOLISS' => '11 June',
			'VOL' => '11 June',
			'MONTH' => '',
			'PUBTYPE' => 'journal-article',
			'SERIES' => '',
			'TITLE' => 'Ukrajins\'ka Dumk',
			'ARTAUT' => 'Berdnyk,-O.'
		},
		'fail_note' => 'JOURNAL request.  title. year; date for volume no pages',
	},
	{
		'pre' => {
			'SO' => 'Laurentian-Univ.-Rev. 1976; 8(2): 31-43',
			'AN' => '1976112518',
			'TI' => 'Journey to Daylight-Land: Through Ojibwa Eyes',
			'PT' => 'journal-article',
			'AU' => 'Dumont,-James',
			'PY' => '1976',
		},
		'req_type' => 'JOURNAL',
		'parsed' => {
			'YEAR' => '1976',
			'ARTTIT' => 'Journey to Daylight-Land: Through Ojibwa Eyes',
			'SOURCE' => 'Laurentian-Univ.-Rev. 1976; 8(2): 31-43',
			'VOLISS' => '8(2)',
			'VOL' => '8',
			'MONTH' => '',
			'PGS' => '31-43',
			'PUBTYPE' => 'journal-article',
			'SERIES' => '',
			'ISS' => '2',
			'TITLE' => 'Laurentian Univ. Rev',
			'ARTAUT' => 'Dumont,-James'
		},
		'fail_note' => 'JOURNAL request.  title. year; volume(issue): page-range.  Typical journal request.',
	},
	{
		'pre' => {
			'IS' => '0004-1610',
			'SO' => 'Arizona-Quarterl Tucson, A. 1976; 32: 138-45',
			'AN' => '1976109819',
			'TI' => 'Journey to Ixtlan: Inside the American Indian Oral Tradition',
			'PT' => 'journal-article',
			'AU' => 'Brown,-Carl-R.-V.',
			'PY' => '1976',
		},
		'req_type' => 'JOURNAL',
		'parsed' => {
			'YEAR' => '1976',
			'ARTTIT' => 'Journey to Ixtlan: Inside the American Indian Oral Tradition',
			'SOURCE' => 'Arizona-Quarterl Tucson, A. 1976; 32: 138-45',
			'VOLISS' => '32',
			'VOL' => '32',
			'MONTH' => '',
			'PGS' => '138-45',
			'PUBTYPE' => 'journal-article',
			'SERIES' => '',
			'ISSN' => '00041610',
			'TITLE' => 'Arizona Quarterl',
			'ARTAUT' => 'Brown,-Carl-R.-V.'
		},
		'fail_note' => 'JOURNAL request. title. year; volume: page-range.',
	},
	{
		'pre' => {
			'PB' => 'Seattle, WA : U of Washington P, 2000. xvii, 155 pp. ',
			'AN' => '2001970913',
			'TI' => 'The Women on the Island: A Novel',
			'IB' => '0295980869 (hbk.); 0295981083 (pbk.)',
			'PT' => 'book',
			'AU' => 'Hao,-Phan-Thanh (translator); Bacchi,-Celeste (translator); Karlin,-Wayne (translator and introd.)',
			'PY' => '2000',
		},
		'req_type' => 'BOOK',
		'parsed' => {
			'ARTTIT' => '',
			'YEAR' => '2000',
			'SOURCE' => '',
			'PUB' => 'Seattle, WA : U of Washington P, 2000. xvii, 155 pp.',
			'AUT' => 'Hao,-Phan-Thanh (translator); Bacchi,-Celeste (translator); Karlin,-Wayne (translator and introd.)',
			'PGS' => '',
			'PUBTYPE' => 'book',
			'SERIES' => '',
			'TITLE' => 'The Women on the Island: A Novel',
			'ARTAUT' => ''
		},
		'fail_note' => 'BOOK request.',
	},
	{
		'pre' => {
			'PB' => '286-308 IN Hume-Robert-D. The London Theatre World, 1660-1800. Carbondale : Southern Illinois UP, London: Feffer. 394 pp. ',
			'AN' => '1980105351',
			'TI' => 'Dramatic Censorship',
			'PT' => 'book-article',
			'AU' => 'Winton,-Calhoun',
		},
		'req_type' => 'BOOK-ARTICLE',
		'parsed' => {
			'YEAR' => '',
			'ARTTIT' => 'Dramatic Censorship',
			'SOURCE' => '',
			'PUB' => 'Carbondale : Southern Illinois UP, London: Feffer',
			'PGS' => '286-308',
			'AUT' => 'Hume-Robert-D',
			'PUBTYPE' => 'book-article',
			'SERIES' => '',
			'TITLE' => 'The London Theatre World, 1660-1800',
			'ARTAUT' => 'Winton,-Calhoun'
		},
		'fail_note' => 'BOOK-ARTICLE request.  pgs IN author. title. total pages.',
	},
	{
		'pre' => {
			'PB' => 'II: 417-428 IN Saggi e ricerche in memoria di Ettore Li Gotti. Florence : Sansoni antiquariato, 1962. ',
			'AN' => '1963108827',
			'TI' => '\'. . .chi per lungo silenzio parea fioco\'; Centro di studi filol. e ling. siciliani Ballettino 6. Palermo, 1962. 3 vols.',
			'PT' => 'book-article',
			'AU' => 'Pagliaro,-Antonino',
			'PY' => '1962',
		},
		'req_type' => 'BOOK-ARTICLE',
		'parsed' => {
			'YEAR' => '1962',
			'ARTTIT' => '\'. . .chi per lungo silenzio parea fioco\'; Centro di studi filol. e ling. siciliani Ballettino 6. Palermo, 1962. 3 vols.',
			'SOURCE' => '',
			'PUB' => 'Florence : Sansoni antiquariato',
			'PGS' => '417-428',
			'PUBTYPE' => 'book-article',
			'SERIES' => '',
			'TITLE' => 'Saggi e ricerche in memoria di Ettore Li Gotti',
			'ARTAUT' => 'Pagliaro,-Antonino'
		},
		'fail_note' => 'BOOK-ARTICLE request.  XX: pgs IN title. year.',
	},
	{
		'pre' => {
			'PB' => '127-36 IN Hall-David-R. (ed. and introd.); Hewings-Ann (ed. and introd.). Innovation in English Language Teaching: A Reader. London, England : Routledge, with Macquarie University and Open University, 2001. xiv, 289 pp. ',
			'AN' => '2001650251',
			'TI' => 'Adapting Individualization Techniques for Large Classes',
			'IB' => '0415241235 (hbk); 0415241243 (pbk)',
			'PT' => 'book-article',
			'AU' => 'Sarwar,-Zakia',
			'PY' => '2001',
		},
		'req_type' => 'BOOK-ARTICLE',
		'parsed' => {
			'YEAR' => '2001',
			'ARTTIT' => 'Adapting Individualization Techniques for Large Classes',
			'SOURCE' => '',
			'PUB' => 'London, England : Routledge, with Macquarie University and Open University',
			'PGS' => '127-36',
			'AUT' => 'Hall-David-R(ed&introd); Hewings-Ann(ed&introd)',
			'PUBTYPE' => 'book-article',
			'SERIES' => '',
			'TITLE' => 'Innovation in English Language Teaching: A Reader',
			'ARTAUT' => 'Sarwar,-Zakia'
		},
		'fail_note' => 'BOOK-ARTICLE request.  pgs IN authors, title. pub, year. book pages.',
	},
	{
		'pre' => {
			'IS' => '0419-4217',
			'PB' => 'Dissertation-Abstracts-International,-Section-B:-The-Sciences-and-Engineering (DAIB) Ann Arbor, MI. 2001 Feb; 61(8): 4476  DAI No.: DA9985414. Degree granting institution: Michigan State U, 2000',
			'AN' => '2001900636',
			'TI' => 'Response to Persuasive Messages from Ingroup and Outgroup Source in Two Cultures: Taiwan and the United States',
			'PT' => 'dissertation-abstract',
			'AU' => 'Lapinski,-Maria-Knight',
			'PY' => '2001',
		},
		'req_type' => 'THESIS',
		'parsed' => {
			'YEAR' => '2001',
			'SOURCE' => '',
			'PUB' => 'Michigan State U',
			'AUT' => 'Lapinski,-Maria-Knight',
			'PUBTYPE' => 'dissertation-abstract',
			'SERIES' => '',
			'ISSN' => '',
			'NOTE' => 'Dissertation-Abstracts-International,-Section-B:-The-Sciences-and-Engineering (DAIB) Ann Arbor, MI. 2001 Feb; 61(8): 4476  DAI No.: DA9985414. Degree granting institution: Michigan State U, 2000',
			'TITLE' => 'Response to Persuasive Messages from Ingroup and Outgroup Source in Two Cultures: Taiwan and the United States'
		},
		'fail_note' => 'THESIS request.  Dissertation Abstracts, special cased into request for thesis.',
	},
	{
		'pre' => {
			'IS' => '0360-1013',
			'SO' => 'The Ohio-Revie (OhR) Athens, OH. 1992; 48: 7-18',
			'AN' => '1992022047',
			'TI' => 'Biography and the Poet',
			'PT' => 'journal-article',
			'AU' => 'Levertov,-Denise',
			'PY' => '1992',
		},
		'req_type' => 'JOURNAL',
		'parsed' => {
			'YEAR' => '1992',
			'ARTTIT' => 'Biography and the Poet',
			'SOURCE' => 'The Ohio-Revie (OhR) Athens, OH. 1992; 48: 7-18',
			'VOLISS' => '48',
			'VOL' => '48',
			'MONTH' => '',
			'PGS' => '7-18',
			'PUBTYPE' => 'journal-article',
			'SERIES' => '',
			'ISSN' => '03601013',
			'TITLE' => 'The Ohio Revie',
			'ARTAUT' => 'Levertov,-Denise'
		},
		'fail_note' => 'JOURNAL request.  Contains "The ..." in the SOURCE field.  Stupid.',
	},

]


__DBASE__

bless( {
	'dbase_local' => 'I(MBAA)J(0000427344)',
	'dbase' => 'mla',
	'dbase_type' => 'erl',
	'dbase_syntax' => 'orig_syntax',
	'dbase_fullname' => 'MLA'
}, 'GODOT::Database' )


