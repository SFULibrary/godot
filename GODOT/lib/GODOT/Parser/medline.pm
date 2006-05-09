package GODOT::Parser::medline;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;
use GODOT::String;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;

	debug("parse_citation() in GODOT::Parser::medline") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');


	##---------------Customized code goes here-------------------##

        if ($citation->is_journal())  {
		## J-Epidemiol-Community-Health. 1995 Feb; 49(1): 94-101.
		## Vestn-Rentgenol-Radiol. 2000 Mar-Apr; (2): 55-64.
		
		my $dotv = index($source,".");
		my $semiv = index($source,";",$dotv);
		my $colonv = index($source,":",$semiv);
		
		if ( ($dotv > -1) && ($semiv > -1) && ($colonv > -1) ) {
			$citation->parsed('TITLE', trim_beg_end(substr($source,0,$dotv)));
			$citation->parsed('MONTH', trim_beg_end(substr($source,$dotv + 1,$semiv - ($dotv + 1))));
			$citation->parsed('VOLISS', trim_beg_end(substr($source, $semiv + 1,$colonv - ($semiv + 1))));
			$citation->parsed('PGS', trim_beg_end(substr($source, $colonv + 1, length($source) - ($colonv - 1))));

			## Split volume/issue
			## ex. 33 ( Pt 1)
			##     19(210)

			if ($citation->parsed('VOLISS') =~ m#([-\d]*)\s*\(([-\s\w]+)\)#)  {
				$citation->parsed('VOL', $1);
				$citation->parsed('ISS', $2);
			}
		} else {
			# Try regular pattern matches if the source field isn't well formed enough for indexing.

			##
			## Vestn-Rentgenol-Radiol.1996 May-Jun(3): 53-6.
			##
			if ($source =~  m#([^\s]+)\.\s*\d{4}\s+([-\w]+)\s*\(([-\w]+)\)\s*:\s*([-\w]+)#) {
				$citation->parsed('TITLE', $1);
				$citation->parsed('MONTH', $2);
				$citation->parsed('VOL', $3);
				$citation->parsed('VOLISS', $3);
				$citation->parsed('ISS', '');
				$citation->parsed('PGS', $4);
			##
			## Indian-J-Med-Res. 1998 Nov; 108212-24
			## Methods-Mol-Biol. 1999; 9621-8
			##
			} elsif ($source =~  /([^\s]+)\.\s+\d{4}\s*(.*);\s+([-\w]+)\s*$/) {
		
				$citation->parsed('TITLE', $1);
				$citation->parsed('MONTH', $2);
				$citation->parsed('PGS', $3);
			}
		}

		my $title = $citation->parsed('TITLE');
		$title =~ s/([^\-])-([^\-])/$1 $2/g;
		$title =~ s/--/-/g;
		$citation->parsed('TITLE', $title);
	}

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::medline") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

	if ($citation->pre('PT') =~ /Comment/) {
		$reqtype = $GODOT::Constants::JOURNAL_TYPE;
	} elsif (grep {$citation->pre('PT') eq $_} ('News', 'Congresses')) {
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
			'IS' => '0065-2598',
			'RN' => '0; 0; 116355-83-0',
			'CP' => 'UNITED-STATES',
			'SO' => 'Adv-Exp-Med-Biol. 1996; 392237-50',
			'AD' => 'National Center for Toxicological Research, Food and Drug Administration, Jefferson, Arkansas 72079, USA.',
			'AN' => '97003290',
			'TI' => 'The mycotoxin fumonisin induces apoptosis in cultured human cells and in livers and kidneys of rats.',
			'PT' => 'Journal-Article',
			'AU' => 'Tolleson,-W-H; Dooley,-K-L; Sheldon,-W-G; Thurman,-J-D; Bucci,-T-J; Howard,-P-C',
			'PY' => '1996',
		},
		'req_type' => 'JOURNAL',
		'parsed' => {
			'YEAR' => '1996',
			'ARTTIT' => 'The mycotoxin fumonisin induces apoptosis in cultured human cells and in livers and kidneys of rats.',
			'SOURCE' => 'Adv-Exp-Med-Biol. 1996; 392237-50',
			'VOLISS' => '',
			'MONTH' => '',
			'PGS' => '392237-50',
			'PUBTYPE' => 'journal-article',
			'SERIES' => '',
			'ISSN' => '00652598',
			'TITLE' => 'Adv Exp Med Biol',
			'ARTAUT' => 'Tolleson,-W-H; Dooley,-K-L; Sheldon,-W-G; Thurman,-J-D; Bucci,-T-J; Howard,-P-C'
		},
		'fail_note' => 'JOURNAL request.  Title. Year; page range.',
	},
	{
		'pre' => {
			'IS' => '0042-4676',
			'CP' => 'RUSSIA',
			'SO' => 'Vestn-Rentgenol-Radiol. 2000 Mar-Apr; (2): 55-64',
			'AD' => 'Medical Radiology Research Center, Russian Academy of Medical Sciences, Obninsk.',
			'AN' => '20390581',
			'TI' => 'Luchevaia diagnostika zhelchevyvodiashchei sistemy pered laparosopicheskoi kholetsistektomiei. Chast\' I: ul\'trazvukovye metody.
[Radiation diagnosis of biliary system befor laparoscopic cholecystectomy (review of literature). Part 1: ultrasonic techniques]',
			'PT' => 'Journal-Article; Review; Review,-Tutorial',
			'AU' => 'Dergachev,-A-I; Brodskii,-A-R',
			'PY' => '2000',
		},
		'req_type' => 'JOURNAL',
		'parsed' => {
			'YEAR' => '2000',
			'ARTTIT' => 'Luchevaia diagnostika zhelchevyvodiashchei sistemy pered laparosopicheskoi kholetsistektomiei. Chast\' I: ul\'trazvukovye metody.
[Radiation diagnosis of biliary system befor laparoscopic cholecystectomy (review of literature). Part 1: ultrasonic techniques]',
			'SOURCE' => 'Vestn-Rentgenol-Radiol. 2000 Mar-Apr; (2): 55-64',
			'VOLISS' => '(2)',
			'VOL' => '',
			'MONTH' => '2000 Mar-Apr',
			'PGS' => '55-64',
			'PUBTYPE' => 'journal-article; review; review,-tutorial',
			'SERIES' => '',
			'ISSN' => '00424676',
			'ISS' => '2',
			'TITLE' => 'Vestn Rentgenol Radiol',
			'ARTAUT' => 'Dergachev,-A-I; Brodskii,-A-R'
		},
		'fail_note' => 'JOURNAL request.  Title. year month-range; (issue): page-range.',
	},
	{
		'pre' => {
			'IS' => '0032-1052',
			'RN' => '0; 0; 0; 0; 0',
			'CP' => 'United-States',
			'SO' => 'Plast-Reconstr-Surg. 2001 Oct; 108(5): 1260-7',
			'AD' => 'Divisions of Plastic and Reconstructive Surgery at Stanford University Medical Center, CA 94305, USA.',
			'AN' => '21490927',
			'TI' => 'Differential expression of transforming growth factor-beta receptors in a rabbit zone II flexor tendon wound healing model.',
			'PT' => 'Journal-Article',
			'AU' => 'Ngo,-M; Pham,-H; Longaker,-M-T; Chang,-J',
			'PY' => '2001',
		},
		'req_type' => 'JOURNAL',
		'parsed' => {
			'YEAR' => '2001',
			'ARTTIT' => 'Differential expression of transforming growth factor-beta receptors in a rabbit zone II flexor tendon wound healing model.',
			'SOURCE' => 'Plast-Reconstr-Surg. 2001 Oct; 108(5): 1260-7',
			'VOLISS' => '108(5)',
			'VOL' => '108',
			'MONTH' => '2001 Oct',
			'PGS' => '1260-7',
			'PUBTYPE' => 'journal-article',
			'SERIES' => '',
			'ISSN' => '00321052',
			'ISS' => '5',
			'TITLE' => 'Plast Reconstr Surg',
			'ARTAUT' => 'Ngo,-M; Pham,-H; Longaker,-M-T; Chang,-J'
		},
		'fail_note' => 'JOURNAL request.  Title. year month; volume(issue): page-range.',
	},
]



__DBASE__
bless( {
	'dbase_local' => 'I(MLBH)J(0000216448)',
	'dbase' => 'medline',
	'dbase_type' => 'erl',
	'dbase_syntax' => 'orig_syntax',
	'dbase_fullname' => 'Medline'
}, 'GODOT::Database' )

