package GODOT::Parser::zoo;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;
use GODOT::String;

@ISA = "GODOT::Parser";


use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::zoo") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');


	##---------------Customized code goes here-------------------##
	
	if ($citation->is_journal()) {
	
		$source =~ s#\(special issue\)##i;
		
		##
		## <title>, <month> : <pages>
		##
		
		my $commav = index($source, ',');
		my $colonv = index($source, ':', $commav + 1);
		my $dotv = index($source, '.', $commav + 1);
		
		$citation->parsed('TITLE', trim_beg_end(substr($source, 0, $commav)));
		$citation->parsed('MONTH', trim_beg_end(substr($source, $commav + 1, $colonv - ($commav + 1))));
		$citation->parsed('VOL', '');
		$citation->parsed('PGS', trim_beg_end(substr($source, $colonv + 1, $dotv - ($colonv + 1))));
		
		
		if ($source =~ m#(.+)\s+([\d\055\(\)]+)\s*[, ]\s*(.+)\s+(\d\d\d\d)\s*:\s*([\w\055]+)#) {
			##
			## ACTA PROTOZOOLOGICA 34(4), November 1995: 271-288, illustr..
			## HYDROBIOLOGIA      317(1), january 5 1996: 31-40, illustr..
			##

			$citation->parsed('TITLE', $1);
			$citation->parsed('VOL', $2);
			$citation->parsed('MONTH', $3);
			$citation->parsed('PGS', $5);
		} elsif ($source =~ m#(.+)\s+([\d\055\(\)]+)\s*[, ]\s*(\d\d\d\d)\s*:\s*([\w\055]+)#) {
			##
			## ZOOSYSTEMATICA ROSSICA 4(1) 1995(1996): 139-152, illustr..
			##

			$citation->parsed('TITLE', $1);	
			$citation->parsed('VOL', $2);
			$citation->parsed('MONTH', '');
			$citation->parsed('PGS', $4);
		} elsif ($source =~ m#(.+)\s+([\d\055\(\)]+)\s+(\d\d\d\d)\s*\(\d\d\d\d\)\s*:\s*([\w\055]+)#)  {
			$citation->parsed('TITLE', $1);
			$citation->parsed('VOL', $2);
			$citation->parsed('MONTH', '');
			$citation->parsed('PGS', $4);
		} elsif ($source =~ m#(.+)\.\s+\s*\d{4}\s*([\s\w]*);\s+(.+)\s*:\s*(.+)$#) {
			##
			## Verhandlungen-der-Deutschen-Zoologischen-Gesellschaft. 1992; 85(2): 55-7
			## Nature-(London). 2002 25 July; 418(6896): 405-409
			##
			
			$citation->parsed('TITLE', $1);
			$citation->parsed('MONTH', $2);
			$citation->parsed('VOL', $3);
			$citation->parsed('PGS', $4);
			
			if ($citation->parsed('MONTH') =~ /(\d+)\s+(\w+)/) {
				$citation->parsed('DAY', $1);
				$citation->parsed('MONTH', $2);
			}
		}
		
		##
		## -split up vol and issue
		##
		if ($citation->parsed('VOL') =~ m#(.+)\((.+)\)#) {
			$citation->parsed('VOL', $1);
			$citation->parsed('ISS', $2);
		}
		
		if ($citation->parsed('TITLE') =~ m#(.+)\s+\((.+)\)#) {
			$citation->parsed('TITLE', $1);
			$citation->parsed('PUB', $2);
		}
		
		##
		## Get rid of dashes in titles
		##
		
		if ($citation->parsed('TITLE') !~ /\s/ && $citation->parsed('TITLE') =~ /-/) {
			my $temp = $citation->parsed('TITLE');
			$temp =~ s/-([^-])/ $1/g;
			$citation->parsed('TITLE', $temp);
		}
	}
	
	if (($citation->is_book()) || ($citation->is_book_article()))  {

		if ($citation->pre('BK') =~ /(.*?)\s*\[Ed[\.s]*\]\.\s*\[?([^\.]+)\.\]?/) {
			##
			## Dugatkin, Lee Alan [Ed.]. Model systems in behavioral ecology: integrating conceptual, theoretical, and empirical approaches. Princeton University Press, Princeton & Oxford. 2001: i-xxii, 1-551. Chapter pagination: 265-287.
			## Alekseev, V.P.; Butovskaya, M.L. [Eds]. [Biological preconditions for anthroposociogenesis. Volume 1.] Akademiya Nauk SSSR, Institut Etnografii. Moscow. 1989: 1-129. Chapter pagination: 23-80.
			##

			$citation->parsed('AUT', $1);
			$citation->parsed('TITLE', $2);
		} elsif ($citation->pre('BK') =~ /(.*?)\s*\[([^]]+)\]/) {
			# Grab the English translated title, since it's easier to parse anyway

			##
			## Brichetti, P.; Gariboldi, A. [Practical manual of ornithology.] Edagricole - Edizioni Agricole della Calderini s.r.l. Bologna. 1997: i-xiii, 1-362. Chapter pagination: 259-267.
			##
			
			$citation->parsed('AUT', $1);
			$citation->parsed('TITLE', $2);
		}
		
		# Get page ranges from end of BK field
		
		if ($citation->pre('BK') =~ /pagination:\s*(\d+-?\d*)/) {
			$citation->parsed('PGS', $1);
		}
			


		$citation->parsed('PUB', $citation->pre('BK'));

		# Remove square brackets from around article title if present
		if ($citation->parsed('ARTTIT') =~ /^\[(.+)\]$/) {
			$citation->parsed('ARTTIT', $1);
		}
	}
	
	if ($citation->is_thesis()) {
		$citation->parsed('NOTE', trim_beg_end($source));
	}
	
	##---------------Customized code ends here-------------------##
	
	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::zoo") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##
	
	if ($reqtype eq $GODOT::Constants::UNKNOWN_TYPE) {
		if ($citation->pre('DT') =~ /Article/) {
			$reqtype = $GODOT::Constants::JOURNAL_TYPE;
		}
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
                            'IS' => '0268-9634',
                            'SO' => 'Bulletin-of-the-Oriental-Bird-Club. 2002 June; 35: 15-16',
                            'DT' => 'Article; Print',
                            'AD' => '{a} Russian-Vietnamese Tropical Center, 30, Nguyen Thien Thuat, Nha Trang, Vietnam (Socialist Republic of)',
                            'AN' => '13809006007',
                            'TI' => 'Recent ornithological observations in Ma Da Forest, Dong Nai Province, southern Vietnam.',
                            'AU' => 'Zinoviev,-Andrei-V {a}',
                            'PY' => '2002',
		},
		'req_type' => 'JOURNAL',
		'parsed' => {
                             'YEAR' => '2002',
                             'ARTTIT' => 'Recent ornithological observations in Ma Da Forest, Dong Nai Province, southern Vietnam.',
                             'SOURCE' => 'Bulletin-of-the-Oriental-Bird-Club. 2002 June; 35: 15-16',
                             'VOL' => '35',
                             'MONTH' => 'June',
                             'PGS' => '15-16',
                             'PUBTYPE' => 'article; print',
                             'ISSN' => '02689634',
                             'TITLE' => 'Bulletin of the Oriental Bird Club',
                             'ARTAUT' => 'Zinoviev,-Andrei-V {a}'
                },
                'fail_note' => 'JOURNAL request, month, year, no day, volume, no issue, page range',
	},
	{
		'pre' => {
                            'IS' => '0313-5888',
                            'SO' => 'Bird-Observer-(Nunawading). 1993 December; 737: 2',
                            'DT' => 'Article; Print',
                            'AN' => '13100002081',
                            'TI' => 'Bandicoots at Gellibrand Hill Park.',
                            'AU' => 'Anon',
                            'PY' => '1993',
                          },
                 'req_type' => 'JOURNAL',
                 'parsed' => {
                            'YEAR' => '1993',
                            'ARTTIT' => 'Bandicoots at Gellibrand Hill Park.',
                            'SOURCE' => 'Bird-Observer-(Nunawading). 1993 December; 737: 2',
                            'VOL' => '737',
                            'MONTH' => 'December',
                            'PGS' => '2',
                            'PUBTYPE' => 'article; print',
                            'SERIES' => '',
                            'ISSN' => '03135888',
                            'TITLE' => 'Bird Observer (Nunawading)',
                            'ARTAUT' => 'Anon'
                 },
		'fail_note' => 'JOURNAL request, month, year, no day, volume, no issue, single page',
	}
]




__DBASE__

bless( {
	'dbase_local' => 'I(ZOOR0006)J(0000000013)',
	'dbase' => 'zoo',
	'dbase_type' => 'erl',
	'dbase_syntax' => 'orig_syntax',
	'dbase_fullname' => 'Zoological Abstracts'
}, 'GODOT::Database' )
