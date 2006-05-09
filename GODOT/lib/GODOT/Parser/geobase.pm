package GODOT::Parser::geobase;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::geobase") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##

	if ($citation->is_journal() || $citation->is_tech()) {
		# Palaeogeography-Palaeoclimatology-Palaeoecology. 2000 JUL 15; 160(3-4): 171-178.
		# Canadian-Journal-of-Development-Studies. 1999; 1(1): 77-104.
		# Canadian-Mineralogist. 1996. 34/6, 1317-1322.
		# Journal-of-Geochemical-Exploration. 1997. 58/2-3, 101-118.
		# Shuili-Xuebao/Journal-of-Hydraulic-Engineering. 1997. 2/-, 39-44.
		# Journal-of-Geology. 1980. 88(1), pp 100-108, 8 figs, 13 refs.
		# Biological-Report,-US-Department-of-the-Interior,-National-Biological-Service. 1995. 30, 95 pp.
		
		if ($source =~ /^\s*(.+?)\s*\.\s*\d{4}\s*([\w\s]*)\s*[;\.]\s*(.+)\s*$/) {
			my $title = $1;
			$citation->parsed('MONTH', $2);
			my $remainder = $3;
			
			# Clean up month + day to just month.
			$citation->parsed('MONTH', $1) if $citation->parsed('MONTH') =~ /([a-zA-Z]+)\s+\d+/;

			# Replace - and -- in title.
			$title =~ s/([^\-])-(?!-)/$1 /g;
			$title =~ s/--/-/g;
			$citation->parsed('TITLE', $title);
			
			if ($citation->is_journal()) {
				if ($remainder =~ /^\s*([-\w\/]+)\s*\(([-\w\/]*)\)\s*[,:]\s*p?p?\s*([-+\w\/,]+)\s*[,\.]*/) {
					$citation->parsed('VOL', $1);
					$citation->parsed('ISS', $2);
					$citation->parsed('PGS', $3);
				} elsif ($remainder =~ /^\s*([-\w\s]+)\s*\/\s*([-\w]*)\s*[,:]\s*p?p?\s*([-+\w\/,]+)\s*[,\.]/) {
					$citation->parsed('VOL', $1);
					$citation->parsed('ISS', $2);
					$citation->parsed('PGS', $3);
				} elsif ($remainder =~ /^\s*([-\w]+)\s*[,:]\s*p?p?\s*([-\w\/,]+)\s*[,\.]/) {
					$citation->parsed('VOL', $1);
					$citation->parsed('PGS', $2);
				} elsif ($remainder =~ /;\s*([\w\-\,\/]+)\s*\.\s*$/) {
					# Go for pages at least - BOOK_ARTICLES need this only usually.
					$citation->parsed('PGS', $1);
				} else {
					$citation->parsed('PUB', $source);
				}
			} elsif ($citation->is_tech()) {
				if ($remainder =~ /^\s*([-\w]+)\s*[,:]/) {
					$citation->parsed('VOL', $1);
				} else {
					$citation->parsed('PUB', $source);
				}
			}
			
		} 

	} elsif ($citation->is_book_article()) {
		# in: The tectonics, sedimentation and palaeoceanography of the North Atlantic region. (Geological Society, London; Special Publication, 90), 1995, pp 217-225.
		
		if ($source =~ /^in:\s*(.+?)\s*[,\.]\s*\d{4}\s*[,\.]/i) {
			$citation->parsed('TITLE', $1);
		}
	}
		
	# Append AD (Address of Authors) to the PUB field
	$citation->parsed('PUB', $citation->parsed('PUB') . $citation->pre('AD'));

	# Set AUT to be ED (Editor) if it is defined.
	if (defined($citation->pre('ED')) && $citation->pre('ED') ne '') {
		$citation->parsed('AUT', $citation->pre('ED'));
	}

	# This database has lots of super/subscripts which have to be stripped in this weird format.
	my $title = $citation->parsed('TITLE');
	$title =~ s/<\/?(sup|inf)\.GT\.//gi;
	$citation->parsed('TITLE', $title);
	my $arttit = $citation->parsed('ARTTIT');
	$arttit =~ s/<\/?(sup|inf)\.GT\.//gi;
	$citation->parsed('ARTTIT', $arttit);


	$citation->parsed('SYSID', $citation->pre('AN'));

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::geobase") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

    	if ( (($citation->pre('PT') =~ /book/i) && ($citation->pre('PT') =~ /article/i)) ||
    	     ($citation->pre('SO') =~ /^in:/i) ) {
    		$reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE;
    	} elsif ($citation->pre('SO') =~ /[,\.]\s*\d+\s*pp\s*[,\.]/i) {
    		$reqtype = $GODOT::Constants::TECH_TYPE;
    	} else {
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
			'SO' => 'Journal-of-Great-Lakes-Research. 1996. 22/4, 818-829.',
			'AN' => '(1242516); 97L-99999',
			'TI' => 'Detrended correspondence analysis of phytoplankton abundance and distribution in Sandusky Bay and Lake Erie.',
			'AU' => 'Garono,-R.J.; Heath,-R.T.; Soon-Jin-Hwang',
			'PY' => '1996',
		},
		'req_type' => 'JOURNAL',
		'parsed' => {
			'YEAR' => '1996',
			'ARTTIT' => 'Detrended correspondence analysis of phytoplankton abundance and distribution in Sandusky Bay and Lake Erie.',
			'SOURCE' => 'Journal-of-Great-Lakes-Research. 1996. 22/4, 818-829.',
			'PUB' => '',
			'VOL' => '22',
			'MONTH' => '',
			'PGS' => '818-829',
			'PUBTYPE' => '',
			'SERIES' => '',
			'ISS' => '4',
			'TITLE' => 'Journal of Great Lakes Research',
			'SYSID' => '(1242516); 97L-99999',
			'ARTAUT' => 'Garono,-R.J.; Heath,-R.T.; Soon-Jin-Hwang'
		},
		'fail_note' => 'JOURNAL request, vol/issue, page range.',
	},
	{
		'pre' => {
			'SO' => 'Soil-and-Tillage-Research. 1996. 40/1-2, 73-88.',
			'AD' => 'D. Harris, Ctr for Arid Zone Studies, Univ of Wales, Bangor, Gwynedd, LL57 2UW, United Kingdom',
			'AN' => '(1233342); 97L-99999',
			'TI' => 'The effects of manure, genotype, seed priming, depth and date of sowing on the emergence and early growth of Sorghum bicolor (L.) Moench in semi-arid Botswana.',
			'AU' => 'Harris,-D.',
			'PY' => '1996',
		},
		'req_type' => 'JOURNAL',
		'parsed' => {
			'YEAR' => '1996',
			'ARTTIT' => 'The effects of manure, genotype, seed priming, depth and date of sowing on the emergence and early growth of Sorghum bicolor (L.) Moench in semi-arid Botswana.',
			'SOURCE' => 'Soil-and-Tillage-Research. 1996. 40/1-2, 73-88.',
			'PUB' => 'D. Harris, Ctr for Arid Zone Studies, Univ of Wales, Bangor, Gwynedd, LL57 2UW, United Kingdom',
			'VOL' => '40',
			'MONTH' => '',
			'PGS' => '73-88',
			'PUBTYPE' => '',
			'SERIES' => '',
			'ISS' => '1-2',
			'TITLE' => 'Soil and Tillage Research',
			'SYSID' => '(1233342); 97L-99999',
			'ARTAUT' => 'Harris,-D.'
		},
		'fail_note' => 'JOURNAL request, vol/issue-issue, page range.',
	},
	{
		'pre' => {
			'SO' => 'Science-of-the-Total-Environment. 1997. 194-195/-, 379-389.',
			'AD' => 'B.W. Webb, Dept Geog, Univ Exeter, Amory Bldg, Rennes Drive, Exeter Devon EX4 4RJ, United Kingdom',
			'AN' => '(1247634); 97J-99999',
			'TI' => 'Load estimation methodologies for the British rivers and their relevance to the LOIS RACS (R) programme.',
			'AU' => 'Webb,-B.W.; Phillips,-J.M.; Walling,-D.E.; Littlewood,-I.G.; Watts,-C.D.; Leeks,-G.J.L.',
			'PY' => '1997',
		},
		'req_type' => 'JOURNAL',
		'parsed' => {
			'YEAR' => '1997',
			'ARTTIT' => 'Load estimation methodologies for the British rivers and their relevance to the LOIS RACS (R) programme.',
			'SOURCE' => 'Science-of-the-Total-Environment. 1997. 194-195/-, 379-389.',
			'PUB' => 'B.W. Webb, Dept Geog, Univ Exeter, Amory Bldg, Rennes Drive, Exeter Devon EX4 4RJ, United Kingdom',
			'VOL' => '194-195',
			'MONTH' => '',
			'PGS' => '379-389',
			'PUBTYPE' => '',
			'SERIES' => '',
			'ISS' => '-',
			'TITLE' => 'Science of the Total Environment',
			'SYSID' => '(1247634); 97J-99999',
			'ARTAUT' => 'Webb,-B.W.; Phillips,-J.M.; Walling,-D.E.; Littlewood,-I.G.; Watts,-C.D.; Leeks,-G.J.L.'
		},
		'fail_note' => 'JOURNAL request, vol-vol/-, page range.',
	},
	{
		'pre' => {
			'SO' => 'Journal-of-Geophysical-Research. 1996. 101 D17/-, 22775-22785.',
			'AN' => '(1224733); 97J-99999',
			'TI' => 'Water table control of CH\'SUB 4\' emission ehancement by vascular plants in boreal peatlands.',
			'AU' => 'Waddington,-J.M.; Roulet,-N.T.; Swanson,-R.V.',
			'PY' => '1996',
		},
		'req_type' => 'JOURNAL',
		'parsed' => {
			'YEAR' => '1996',
			'ARTTIT' => 'Water table control of CH\'SUB 4\' emission ehancement by vascular plants in boreal peatlands.',
			'SOURCE' => 'Journal-of-Geophysical-Research. 1996. 101 D17/-, 22775-22785.',
			'PUB' => '',
			'VOL' => '101 D17',
			'MONTH' => '',
			'PGS' => '22775-22785',
			'PUBTYPE' => '',
			'SERIES' => '',
			'ISS' => '-',
			'TITLE' => 'Journal of Geophysical Research',
			'SYSID' => '(1224733); 97J-99999',
			'ARTAUT' => 'Waddington,-J.M.; Roulet,-N.T.; Swanson,-R.V.'
		},
		'fail_note' => 'JOURNAL request, volume with space/issue, page range.',
	},
	{
		'pre' => {
			'SO' => 'International-Ground-Water-Technology. 1997. 3/1, 10+12-15.',
			'AN' => '(1243242); 97J-99999',
			'TI' => 'Extraction method is field-friendly.',
			'AU' => 'Reddy,-K.J.',
			'PY' => '1997',
		},
		'req_type' => 'JOURNAL',
		'parsed' => {
			'YEAR' => '1997',
			'ARTTIT' => 'Extraction method is field-friendly.',
			'SOURCE' => 'International-Ground-Water-Technology. 1997. 3/1, 10+12-15.',
			'PUB' => '',
			'VOL' => '3',
			'MONTH' => '',
			'PGS' => '10+12-15',
			'PUBTYPE' => '',
			'SERIES' => '',
			'ISS' => '1',
			'TITLE' => 'International Ground Water Technology',
			'SYSID' => '(1243242); 97J-99999',
			'ARTAUT' => 'Reddy,-K.J.'
		},
		'fail_note' => 'JOURNAL request, volume/issue, page range with + in it.',
	},
	{
		'pre' => {
			'SO' => 'Biologiya-Morya-(Vladivostok). 1995. 21(3), pp 181-188.',
			'AD' => 'Pacific Rsch Inst of Fish ',
			'AN' => '(1142378); 96N-01666',
			'TI' => 'Seasonal development of plankton in the zones of different temperature structure in the region of the southern Kurile Islands.',
			'AU' => 'Bokhan,-L.-N.; Zuenko,-Yu.-I.',
			'PY' => '1995',
		},
		'req_type' => 'JOURNAL',
		'parsed' => {
			'YEAR' => '1995',
			'ARTTIT' => 'Seasonal development of plankton in the zones of different temperature structure in the region of the southern Kurile Islands.',
			'SOURCE' => 'Biologiya-Morya-(Vladivostok). 1995. 21(3), pp 181-188.',
			'PUB' => 'Pacific Rsch Inst of Fish',
			'VOL' => '21',
			'MONTH' => '',
			'PGS' => '181-188',
			'PUBTYPE' => '',
			'SERIES' => '',
			'ISS' => '3',
			'TITLE' => 'Biologiya Morya (Vladivostok)',
			'SYSID' => '(1142378); 96N-01666',
			'ARTAUT' => 'Bokhan,-L.-N.; Zuenko,-Yu.-I.'
		},
		'fail_note' => 'JOURNAL request, volume(issue), pp page range.',
	},
	{
		'pre' => {
			'SO' => 'Biological-Report,-US-Department-of-the-Interior,-National-Biological-Service. 1995. 30, 95 pp.',
			'AD' => 'Dept of Biology, East Carolina Univ, Greenville, NC, 27858-4353, USA',
			'AN' => '(1142933); 96N-01654',
			'TI' => 'Ecology of maritime forests of the southern Atlantic coast: a community profile.',
			'AU' => 'Bellis,-V.-J.; Keough,-J.-R.',
			'PY' => '1995',
		},
		'req_type' => 'TECH',
		'parsed' => {
			'YEAR' => '1995',
			'ARTTIT' => 'Ecology of maritime forests of the southern Atlantic coast: a community profile.',
			'SOURCE' => 'Biological-Report,-US-Department-of-the-Interior,-National-Biological-Service. 1995. 30, 95 pp.',
			'PUB' => 'Dept of Biology, East Carolina Univ, Greenville, NC, 27858-4353, USA',
			'VOL' => '30',
			'MONTH' => '',
			'PUBTYPE' => '',
			'SERIES' => '',
			'TITLE' => 'Biological Report, US Department of the Interior, National Biological Service',
			'SYSID' => '(1142933); 96N-01654',
			'ARTAUT' => 'Bellis,-V.-J.; Keough,-J.-R.'
		},
		'fail_note' => 'TECH request, volume, number of pages pp (pages not parsed)',
	},
	{
		'pre' => {
			'SO' => 'in: The tectonics, sedimentation and palaeoceanography of the North Atlantic region. (Geological Society, London; Special Publication, 90), 1995, pp 217-225.',
			'AD' => 'Fac of Applied Sci, Bath Coll of Higher Education, Newton Park, Newton St Loe, Bath, BA2 9BN, UK',
			'ED' => 'Scrutton,-R.A.; et-al',
			'AN' => '(1139856); 96N-01567',
			'TI' => 'Pliocene-Pleistocene radiolarian biostratigraphy and palaeoceanography of the North Atlantic.',
			'AU' => 'Haslett,-S.-K.',
			'PY' => '1995',
		},
		'req_type' => 'BOOK-ARTICLE',
		'parsed' => {
			'YEAR' => '1995',
			'ARTTIT' => 'Pliocene-Pleistocene radiolarian biostratigraphy and palaeoceanography of the North Atlantic.',
			'SOURCE' => 'in: The tectonics, sedimentation and palaeoceanography of the North Atlantic region. (Geological Society, London; Special Publication, 90), 1995, pp 217-225.',
			'PUB' => 'Fac of Applied Sci, Bath Coll of Higher Education, Newton Park, Newton St Loe, Bath, BA2 9BN, UK',
			'AUT' => 'Scrutton,-R.A.; et-al',
			'PUBTYPE' => '',
			'SERIES' => '',
			'TITLE' => 'The tectonics, sedimentation and palaeoceanography of the North Atlantic region. (Geological Society, London; Special Publication, 90)',
			'SYSID' => '(1139856); 96N-01567',
			'ARTAUT' => 'Haslett,-S.-K.'
		},
		'fail_note' => 'BOOK-ARTICLE request, number of pages pp (pages not parsed)',
	},
	{
		'pre' => {
			'SO' => 'Deep-Sea-Research,-Part-II. 1995. 42(4-5), pp 907-932.',
			'AD' => 'Dept of Analytical ',
			'AN' => '(1140254); 96N-01500',
			'TI' => 'A biogeochemical study in the Bellingshausen Sea: overview of the STERNA 1992 expedition.',
			'AU' => 'Turner,-D.-R.; Owens,-N.-J.-P.',
			'PY' => '1995',
		},
		'req_type' => 'JOURNAL',
		'parsed' => {
			'YEAR' => '1995',
			'ARTTIT' => 'A biogeochemical study in the Bellingshausen Sea: overview of the STERNA 1992 expedition.',
			'SOURCE' => 'Deep-Sea-Research,-Part-II. 1995. 42(4-5), pp 907-932.',
			'PUB' => 'Dept of Analytical',
			'VOL' => '42',
			'MONTH' => '',
			'PGS' => '907-932',
			'PUBTYPE' => '',
			'SERIES' => '',
			'ISS' => '4-5',
			'TITLE' => 'Deep Sea Research, Part II',
			'SYSID' => '(1140254); 96N-01500',
			'ARTAUT' => 'Turner,-D.-R.; Owens,-N.-J.-P.'
		},
		'fail_note' => 'JOURNAL request, volume(issue-issue), pp page range.',
	},
				


]

__DBASE__

bless( {
	'dbase_local' => 'I(GB06)J(0000000510)',
	'dbase' => 'geobase',
	'dbase_type' => 'erl',
	'dbase_syntax' => 'orig_syntax',
	'dbase_fullname' => 'Geobase'
}, 'GODOT::Database' )

