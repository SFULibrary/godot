package GODOT::Parser::repere;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";


use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::repere") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');


	# Culture, 5, no 1, 1985, p. 75-79
	# L'Actualité, 27, no 17, 1er nov. 2002, p. 125-126
	# Fêtes et saisons, no 567, août-sept. 2002, p. 1-65
	# La Vie, no 2960, 23 mai 2002, p. 34-36
	# Vie des arts, no 157, hiver 1994-1995, p. 24-26
	# Entreprendre, 8, no 1, févr.-mars 1995, encart, p. 1-23
	# Revue commerce, 91e année, no 4, avril 1989, p. 158
	# Courrier international, no 613-614-615, 1er août 2002, p. 28-35
	
	my $date;
	if ($source =~ /^(.+),\s+([^,]+),\s+no\s+([^,]+),\s+(.+)\s+[-\d]{4,},(\s+encart,)?\s+p\.\s+([-\d]+)/) {
		$citation->parsed('TITLE', $1);
		$citation->parsed('VOL', $2);
		$citation->parsed('ISS', $3);
		$date = $4;
		$citation->parsed('PGS', $6);
	} elsif ($source =~ /^(.+),\s+no\s+([^,]+),\s+(.+)\s+[-\d]{4,},(\s+encart,)?\s+p\.\s+([-\d]+)/) {
		$citation->parsed('TITLE', $1);
		$citation->parsed('VOL', $2);
		$date = $3;
		$citation->parsed('PGS', $5);
	} else {
		$citation->parsed('TITLE', $source);
	}
	if ($date =~ /(\d+\w*)\s+(.+)/) {
		$citation->parsed('DAY', $1);
		$citation->parsed('MONTH', $2);
	} else {
		$citation->parsed('MONTH', $date);
	}

	
	##---------------Customized code ends here-------------------##
	
	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::repere") if $GODOT::Config::TRACE_CALLS;

	# Everything in Repere is a journal type... I hope.
	
	return $GODOT::Constants::JOURNAL_TYPE;
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
	'dbase_local' => 'I(R2J2)J(0000294739)',
	'dbase' => 'repere',
	'dbase_type' => 'erl',
	'dbase_syntax' => 'orig_syntax',
	'dbase_fullname' => 'Repere',
}, 'GODOT::Database' )