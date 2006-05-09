package GODOT::Parser::econlit;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;
use GODOT::String;

@ISA = "GODOT::Parser";


use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::econlit") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	if ($citation->parsed('PUBTYPE') =~ /book-review/i) { 
	    $citation->fulltext_available(1);
	} 


	if ($citation->is_journal()) {

		##
		## Journal-of-Economic-Surveys. March 1994; 8(1): 1-34.
		##
		
		my ($title, $restv) = split(/;/, $citation->parsed('SOURCE'));

		if ($title =~ s/^(\S+)\.\s+(.+)$/$1/) {
			my $date = $2;

			$title =~ s/([^-])-/$1 /g;
			$title =~ s/--/-/g;
			

			$date =~ s/^\s*(.+)\s*\d{4}\s*$/$1/;
			$citation->parsed('MONTH', $date);

		}

		$citation->parsed('TITLE', $title);

		$restv = comp_ws($restv);
		$restv = strip_trailing_punc_ws($restv);	# remove '..'
		
		my ($vol, $pages) = split /:\s*/, $restv;
		
		$citation->parsed('PGS', $pages);

		if ($vol =~ m#^\s*(\d+)\((\d+)\)#) {
			$citation->parsed('VOL', $1);
			$citation->parsed('ISS', $2);
		} else {
			$citation->parsed('VOL', $vol);
		}
		
        } elsif ($citation->is_book()) {
        
		##
		##  PB: Multidisciplinary Studies in Social Theory. New York and London: Guilford Press, 1995; x, 214
		##
		
        	$citation->parsed('PUB', $citation->pre('PB'));
        	
        	# Try to grab pages seperately
        	
        	if ($citation->pre('PB') =~ /(\d+)\s*\.?\s*$/) {
        		$citation->parsed('PGS', $1);
        	}

		# Grab any ISBN if one isn't found automatically... just in case there's more than
		# one in the default field.
        	
        	if (defined($citation->pre('IB')) && !defined($citation->parsed('ISBN'))) {
        		if ($citation->pre('IB') =~ /(\d{10})/) {
        			$citation->parsed('ISBN', $1);
        		}
		}	
        } elsif ($citation->is_book_article()) {
        
        	##
        	## Elgar Reference Collection. The foundations of monetary economics. Volume 1. Cheltenham, U.K. and Northampton, Mass.: Elgar; distributed by American International Distribution Corporation, Williston, Vt., 1999; 505-16. Previously published: 1967.        
		##
        	
		my $title = $citation->pre('PB');
		if ($title =~ /(.+)\.\s+(.+),\s+\d{4};\s+([-\d]+)/) {
			$title = $1;
			$citation->parsed('PUB', $2);
			$citation->parsed('PGS', $3);
			
			if ($title =~ s/^(\S+\s+by\s+.+?)\.\s+//) {
				$citation->parsed('AUT', $1);
			}				

		}

		# If there's editors in the title, try to grab them
		
		if ($title =~ s/^(.+),\s+eds\.\s+//) {
			$citation->parsed('AUT', $1);
		}

		$citation->parsed('TITLE', $title);

		# Grab any ISBN if one isn't found automatically... just in case there's more than
		# one in the default field.

        	if (defined($citation->pre('IB')) && !defined($citation->parsed('ISBN'))) {
        		if ($citation->pre('IB') =~ /(\d{10})/) {
        			$citation->parsed('ISBN', $1);
        		}
		}
		
		$citation->parsed('ARTAUT', $citation->pre('AU'));
		$citation->parsed('ARTTIT', $citation->pre('TI')); 

            
        } elsif ($citation->is_thesis()) {
        
        	$citation->parsed('TITLE', $citation->pre('TI'));
        	
        	##
        	## PB: Ph.D.  University of Michigan 1989
        	##
        	
        	if ($citation->pre('PB') =~ /(\S+)\s*(.+)\s*\d{4}\s*$/) {
        		$citation->parsed('THESIS_TYPE', $1);
        		$citation->parsed('PUB', $2);
        	} else {
        		$citation->parsed('PUB', $citation->parsed('PB'));
        	}
        } elsif ($citation->is_tech()) {   ## working paper
        
        	##
        	## PB: University of Bristol, Leverhulme Centre for Market and Public Organisation (CMPO) Working Paper: 01/039 August 2001; 14
		##

		# Try for getting the "working paper" or "discussion paper" details out.  If not,
		# fall back to grabbing the date/pages at least.

		if ($citation->pre('PB') =~ /^(.+):\s+(\S+)\s+(\w+)\s+\d{4};\s+(\d+)/) {
			$citation->parsed('PUB', $1);
			$citation->parsed('SERIES', $1);
			$citation->parsed('REPNO', $2);
			$citation->parsed('MONTH', $3);
			$citation->parsed('PGS', $4);
		} elsif ($citation->pre('PB') =~ /(\w+)\s+\d{4};([-\d]+)\s*$/) {
			$citation->parsed('MONTH', $1);
			$citation->parsed('PGS', $2);

			$citation->parsed('PUB', $citation->pre('PB'));
		}
			
		$citation->parsed('NOTE', trim_beg_end($citation->pre('AV')));

		$citation->parsed('TITLE', $citation->pre('TI'));
		$citation->parsed('ARTTIT', '');

		$citation->parsed('AUT', $citation->pre('AU'));
		$citation->parsed('ARTAUT', '');
		
	}

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::econlit") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation);

        ##
	## book article maps to "Collective-Volume-Article"
        ##

	if ($citation->parsed('PUBTYPE') =~ m#journal-article#)  { return $GODOT::Constants::JOURNAL_TYPE; }
	if ($citation->parsed('PUBTYPE') =~ m#collective-volume-article#i) { return $GODOT::Constants::BOOK_ARTICLE_TYPE; }
	if ($citation->parsed('PUBTYPE') =~ m#working-paper#i)             { return $GODOT::Constants::TECH_TYPE; }
	
	return $reqtype;
}


1;

__END__

=head1 NAME

template.pm - GODOT parser template

=head1 COMMENTS

2002-10-18 : TH : Revised due to Ovid (Silverplatter) "remastering" the database.
2002-10-30 : TH : Finished changes and added regression test data.

=cut

__TESTS__

[
	{
		'pre' => {
			'AU' => 'Widdig,-Bernd',
			'IB' => '0520222903',
			'PB' => 'Weimar and Now: German Cultural Criticism, vol. 26. Berkeley and London: University of California Press, 2001; xvi, 277',
			'TI' => 'Culture and inflation in Weimar Germany',
			'DT' => 'Book',
			'AN' => '0594252',
			'PY' => '2001',
		},
		'req_type' => 'BOOK',
		'parsed' => {
			'YEAR' => '2001',
			'ISBN' => '0520222903',
			'PUB' => 'Weimar and Now: German Cultural Criticism, vol. 26. Berkeley and London: University of California Press, 2001; xvi, 277',
			'AUT' => 'Widdig,-Bernd',
			'PUBTYPE' => 'book',
			'TITLE' => 'Culture and inflation in Weimar Germany',
			'PGS' => '277',
		},
		'fail_notes' => 'BOOK request type test.',
	},
	{
		'pre' => {
			'AU' => 'Natter,-Wolfgang; Schatzki,-Theodore-R; Jones,-John-Paul, III,-eds',
			'IB' => '0898625424, cloth; 0898625459, pbk',
			'PB' => 'Multidisciplinary Studies in Social Theory. New York and London: Guilford Press, 1995; x, 214',
			'TI' => 'Objectivity and its other',
			'DT' => 'Book',
			'AN' => '0353698',
			'PY' => '1995',
		},
		'req_type' => 'BOOK',
		'parsed' => {
			'YEAR' => '1995',
			'ISBN' => '0898625424',
			'PUB' => 'Multidisciplinary Studies in Social Theory. New York and London: Guilford Press, 1995; x, 214',
			'AUT' => 'Natter,-Wolfgang; Schatzki,-Theodore-R; Jones,-John-Paul, III,-eds',
			'PUBTYPE' => 'book',
			'TITLE' => 'Objectivity and its other',
			'PGS' => '214',
		},
		'fail_notes' => 'BOOK request type test.',
	},
	{
		'pre' => {
			'AU' => 'Gill,-Indermit-S; Dar,-Amit',
			'IB' => '0195215907',
			'PB' => 'Oxford and New York: Vocational education and training reform: Matching skills to  markets and  budgets.  Oxford University Press for the World Bank, 2000; 485-513',
			'TI' => 'Germany',
			'DT' => 'Collective-Volume-Article',
			'AN' => '0611057',
			'PY' => '2000',
		},
		'req_type' => 'BOOK-ARTICLE',
		'parsed' => {
			'YEAR' => '2000',
			'ISBN' => '0195215907',
			'PUB' => 'Oxford University Press for the World Bank',
			'ARTAUT' => 'Gill,-Indermit-S; Dar,-Amit',
			'PUBTYPE' => 'collective-volume-article',
			'ARTTIT' => 'Germany',
			'PGS' => '485-513',
			'TITLE' => 'Oxford and New York: Vocational education and training reform: Matching skills to  markets and  budgets',
		},
		'fail_notes' => 'BOOK-ARTICLE request type test.',
	},
	{
		'pre' => {
			'AU' => 'Jung,-Chul-Ho',
			'PB' => 'Ph.D.  University of Michigan 1989',
			'TI' => 'Essays on Inventory Model, International Reserves, Forecasting, and Loglinear Regression Model',
			'DT' => 'Dissertation',
			'AN' => '0236744',
			'PY' => '1989',
		},
		'req_type' => 'THESIS',
		'parsed' => {
			'YEAR' => '1989',
			'PUB' => 'University of Michigan',
			'AUT' => 'Jung,-Chul-Ho',
			'PUBTYPE' => 'dissertation',
			'TITLE' => 'Essays on Inventory Model, International Reserves, Forecasting, and Loglinear Regression Model',
			'THESIS_TYPE' => 'Ph.D.',
		},
		'fail_notes' => 'THESIS request type test.',
	},
	{
		'pre' => {
			'AU' => 'Danthine,-Jean-Pierre; Giavazzi,-Francesco; von-Thadden,-Ernst-Ludwig',
			'PB' => 'Universite de Lausanne, Cahiers de Recherches Economiques: 00/03 February 2000; 40',
			'TI' => 'European Financial Markets After EMU: A First Assessment',
			'DT' => 'Working-Paper',
			'AN' => '0598323',
			'PY' => '2000',
		},
		'req_type' => 'TECH',
		'parsed' => {
			'YEAR' => '2000',
			'PUB' => 'Universite de Lausanne, Cahiers de Recherches Economiques',
			'SERIES' => 'Universite de Lausanne, Cahiers de Recherches Economiques',
			'AUT' => 'Danthine,-Jean-Pierre; Giavazzi,-Francesco; von-Thadden,-Ernst-Ludwig',
			'PUBTYPE' => 'working-paper',
			'TITLE' => 'European Financial Markets After EMU: A First Assessment',
			'REPNO' => '00/03',
			'MONTH' => 'February',
			'PGS', => 40,
		},
		'fail_notes' => 'THESIS request type test.',
	},



]

__DBASE__

bless( {
	'dbase_local' => 'I(ECON0000)J(0000024193)',
	'dbase' => 'econlit',
	'dbase_type' => 'erl',
#	'dbase_syntax' => 'orig_syntax',
#	'dbase_fullname' => 'Georef',
}, 'GODOT::Database' )
