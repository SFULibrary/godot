##
## Copyright (c) 2001, Todd Holbrook, Simon Fraser University
##
## Various GODOT configuration variables
##

package GODOT::Config;

use GODOT::Constants;
use strict;

my $TRUE = 1;
my $FALSE = 0;

# Database Mappings

use vars qw (
	%DBASE_PARSER_MAPPING
        %DBASE_TYPE_PARSER_MAPPING
	%DBASE_LOCAL_MAPPING
	%DBASE_INFO_HASH
	@DBASE_ARR
);


#
# %DBASE_PARSER_MAPPING examples
# 'database' => 'parser'       --- map database to parser under GODOT/Parser
# 'database' => 'XXX::parser'  --- map database to subclassed parser under GODOT/Parser/XXX
# 'database' => { 'erl' => 'parser1', 'brs' => 'parser2' }   --- takes the database "type" into consideration when mapping the database to a parser


%DBASE_PARSER_MAPPING = (
	# EBSCOhost databases
	'ahw' => 'ebsco',
	'ase' => 'ebsco',
	'asp' => 'ebsco',
	'atlas' => 'ebsco',
	'bse' => 'ebsco',
	'bsp' => 'ebsco',
	'cmasfe' => 'ebsco',
	'crc' => 'ebsco',
        'eb-ageline'   => 'ebsco',
        'eb-agric'   => 'ebsco',
        'eb-atla'   => 'ebsco',
        'eb-bnna' => 'ebsco',
        'eb-biomed'  => 'ebsco',
        'eb-canlit'  => 'ebsco',
        'eb-cinahl-ft' => 'ebsco',
        'eb-cinahl' => 'ebsco',
        'eb-csi'    => 'ebsco',
	'eb-econlit' => 'ebsco',
        'eb-epi' => 'ebsco',        
	'eb-eric' => 'ebsco::eric', 
        'eb-georef' => 'ebsco',
        'eb-glblhealth' => 'ebsco',
        'eb-hti' => 'ebsco',
        'eb-ipsa' => 'ebsco',
        'eb-libref' => 'ebsco',
        'eb-libista' => 'ebsco',
	'eb-medline' => 'ebsco',
	'eb-milgov' => 'ebsco',
	'eb-mla' => 'ebsco',
	'eb-mlap' => 'ebsco',
	'eb-ota' => 'ebsco',
	'eb-nta' => 'ebsco',
	'eb-psyc' => 'ebsco',
	'eb-psycart' => 'ebsco',
	'eb-psycextra' => 'ebsco',
        'eb-psycbooks' => 'ebsco',
	'eb-sportd' => 'ebsco',
	'eb-ssi' => 'ebsco',
	'eb-soci' => 'ebsco',
	'eb-socift' => 'ebsco',
	'eb-cmmc' => 'ebsco',
	'eb-ahi' => 'ebsco',
	'eoc' => 'ebsco',
	'hsce' => 'ebsco',
	'hsnae' => 'ebsco',
	'masterfile' => 'ebsco',
        'masu'    => 'ebsco',
	'middle' => 'ebsco',
	'mlft' => 'ebsco',
	'primary' => 'ebsco',
	'sociabs' => 'ebsco',
	'socicol' => 'ebsco::socicol',
	'worhisf' => 'ebsco',
        'eb-wldecoww' => 'ebsco',
	'eb-wsi'  => 'ebsco',
	
	# MARC format databases (catalogues)
	
	'cisx' => 'MARC::cisx',
	'ecdb' => 'MARC::ecdb',
	'sfu_iii' => 'MARC',
	'umanitoba' => 'MARC',
	'usask' => 'MARC',
	'uvic' => 'MARC',
	'ucalgary' => 'MARC',
	'ualberta' => 'MARC',
	'ubc' => 'MARC',
	'utoronto' => 'MARC',
	
	# Wilson databases
	
	'arts' => 'Wilson',
	'educ' => 'Wilson',
	'gensci' => 'Wilson',
	'hssi' => 'Wilson',
	'humanities' => 'Wilson',
	'humanitiesabs' => 'Wilson',
	'rgab' => 'Wilson',
	'scie' => 'Wilson',
	'socsci' => 'Wilson',
	'socsciabs' => 'Wilson',
	'bioagri' => 'Wilson',

	# CSA databases
	
        'CSA:eric-set-c' => 'openurl::csa::eric',
	
	# OpenUrl databases 

	'asfa'     => 'openurl',

        'axiom'    => 'openurl',                 ## -is this still used ?? - should have been replaced 
                                                 ##  with %DBASE_TYPE_PARSER_MAPPING
        'iopp'     => 'openurl',

	'OvidWebspirs:mla' => 'openurl',

	'unknown'  => 'openurl',       

        'ISI:endnote' => 'openurl',
	'ISI:WoS' => 'openurl::isi::wos',
	'ISI:WoK' => 'openurl::isi::wos',
	'BMC:F1000' => 'openurl::force_journal',
	
	#Others ---- added by yyua
	'pais' => 'paissel',
	
);



%DBASE_TYPE_PARSER_MAPPING = (

     'ABC-CLIO'    => 'openurl',
     'AMS'         => 'openurl::mathscinet',
     'annualreviews' => 'openurl',
     'arXiv'       => 'openurl',
     'blackwell'   => 'openurl',
     'BMC'         => 'openurl',
     'BOWKER'      => 'openurl',
     'CAS'         => 'openurl',
     'CIOS'        => 'openurl',
     'CISTI'       => 'openurl',
     'CSA'         => 'openurl::csa',
     'DIALOG'      => 'openurl',
     'digitool'    => 'openurl',
     'EBSCO'       => 'openurl',
     'Elsevier'    => 'openurl',
     'EI'          => 'openurl',
     'Endeavor'    => 'openurl',
     'Entrez'      => 'openurl',
     'FamilyScholar' => 'openurl',
     'FirstSearch' => 'openurl::firstsearch',
     'gale'        => 'openurl',
     'Gale'        => 'openurl',
     'GEODOK'      => 'openurl',
     'Google'      => 'openurl',
     'Harmonie'    => 'openurl',
     'ICPSR'       => 'openurl',
     'III'         => 'openurl',
     'HWW'         => 'openurl',
     'IOP'         => 'openurl::axiom',
     'jstor'       => 'openurl',
     'LC'          => 'openurl',
     'mimas'       => 'openurl',
     'NISC'        => 'openurl',
     'openly'      => 'openurl',
     'OUP'	   => 'openurl',
     'OVID'        => 'openurl',
     'proquest'    => 'openurl::proquest',
     'ProQ'        => 'openurl',
     'pqil'        => 'openurl',
     'RLG'         => 'openurl::rlg',
     'SFU'         => 'openurl',
     'ukoln'       => 'openurl',
     'Refworks'    => 'openurl',
     'rsc'         => 'openurl',
     'Wiley'       => 'openurl',
     'LC'          => 'openurl',
     'SilverPlatter' => 'openurl',
     'SFX'         => 'openurl',
     'STN'         => 'openurl',
     'SP'          => 'openurl',
     'swets'       => 'openurl',
     'RefPress'    => 'openurl',
     'Elsevier'    => 'openurl',
     'SFX'         => 'openurl'
);


%DBASE_LOCAL_MAPPING = (
        'AMS:MathSciNet'                        => 'mathscinet',        
        'CSA.asfa1-set-n'                       => 'asfa',
	'ebscohost.Academic Search Elite'       => 'ase',
	'ebscohost.Academic Search Premier'     => 'asp',
	'ebscohost.Alt-HealthWatch'             => 'ahw',
	'ebscohost.Alt HealthWatch'             => 'ahw',
        'ebscohost.AgeLine'                     => 'eb-ageline',
        'ebscohost.Agricola'                    => 'eb-agric',
        'ebscohost.American Humanities Index'   => 'eb-ahi',
        'ebscohost.ATLA Religion Database with ATLASerials' => 'eb-atla',
        'ebscohost.ATLA Religion Database'      => 'eb-atla',
	'ebscohost.ATLAS Full Text Plus'        => 'atlas',
	'ebscohost.Bibliography of Native North Americans' => 'eb-bnna',
	'ebscohost.Business Source Premier'     => 'bsp', 
	'ebscohost.Business Source Elite'       => 'bse',
        'ebscohost.Biomedical Reference Collection: Comprehensive'  => 'eb-biomed',
	'ebscohost.Canadian Literary Centre'    => 'eb-canlit',
	'ebscohost.Canadian MAS FullTEXT Elite' => 'cmasfe',
	'ebscohost.Canadian Reference Centre'   => 'crc',
	'ebscohost.CINAHL with Full Text'       => 'eb-cinahl-ft',
	'ebscohost.CINAHL'                      => 'eb-cinahl',
	'ebscohost.Communication & Mass Media Complete' => 'eb-cmmc',
        'ebscohost.Computer Science Index' => 'eb-csi',
	'ebscohost.EBSCO Online Citations'      => 'eoc',
	'ebscohost.Econlit'                     => 'eb-econlit',
        'ebscohost.Environmental Issues & Policy Index'  => 'eb-epi',
	'ebscohost.ERIC'                        => 'eb-eric', 
	'ebscohost.GeoRef'                      => 'eb-georef',
        'ebscohost.Global Health'               => 'eb-glblhealth',
	'ebscohost.Health Source - Consumer Edition' => 'hsce', 
	'ebscohost.Health Source: Consumer Edition'  => 'hsce', 
	'ebscohost.Health Source: Nursing/Academic Edition' => 'hsnae',
	'ebscohost.Hospitality & Tourism Index'    => 'eb-hti',
	'ebscohost.Hospitality & Tourism Complete' => 'eb-hti',
        'ebscohost.International Political Science Abstracts' => 'eb-ipsa',
        'ebscohost.Library Reference Center'    => 'eb-libref',
        'ebscohost.Library, Information Science & Technology Abstracts' => 'eb-libista',
        'ebscohost.MAS Ultra - School Edition'  => 'masu',
	'ebscohost.MasterFILE Elite'            => 'masterfile', 
	'ebscohost.Middle Search Plus'          => 'middle', 
	'ebscohost.Military Library FullTEXT'   => 'mlft',
	'ebscohost.Military & Government Collection'	=> 'eb-milgov',
	'ebscohost.MEDLINE'                     => 'eb-medline',
	'ebscohost.MLA International Bibliography' => 'eb-mla',
	'ebscohost.MLA Directory of Periodicals'   => 'eb-mlap',
        'ebscohost.New Testament Abstracts'     => 'eb-nta',
	'ebscohost.Old Testament Abstracts'     => 'eb-ota',
	'ebscohost.Primary Search'              => 'primary', 
	'ebscohost.PsycARTICLES'                => 'eb-psycart',
        'ebscohost.PsycBOOKS'                   => 'eb-psycbooks',
	'ebscohost.PsycINFO'		        => 'eb-psyc',
	'ebscohost.PsycINFO 1887-Current'       => 'eb-psyc',
	'ebscohost.PsycEXTRA'			=> 'eb-psycextra',
	'ebscohost.Short Story Index'		=> 'eb-ssi',
	'ebscohost.SocINDEX'			=> 'eb-soci',
	'ebscohost.SocINDEX with Full Text'	=> 'eb-socift',
	'ebscohost.Sociological Abstracts'      => 'sociabs', 
	'ebscohost.Sociological Collection'     => 'socicol', 
	'ebscohost.SPORTDiscus'                 => 'eb-sportd', 
        'ebscohost.Wildlife & Ecology Studies Worldwide' => 'eb-wldecoww',
	'ebscohost.Women\'s Studies International' => 'eb-wsi', 
	'ebscohost.World History FullTEXT'      => 'worhisf', 
	'cisti.cistisource'                     => 'cistisource',
	'erl.2E' => 'bip',
	'erl.AE' => 'econlit',
	'erl.EC' => 'econlit',    # Added 10/18/2002 - th
	'erl.AL' => 'ageline',
	'erl.AG' => 'agric',
	'erl.BE' => 'bioethics',
	'erl.BI' => 'biosis',
	'erl.BN' => 'bnna',
	'erl.B7' => 'cnews',
	'erl.BP' => 'cbca',
	'erl.BX' => 'biosis',
	'erl.C4' => 'cnews',
	'erl.C6' => 'cnews',
	'erl.CA' => 'cancer',
	'erl.CI' => 'caba',
	'erl.CB' => 'cbca',
	'erl.9Z' => 'cbcafe',
	'erl.CC' => 'curcon',
	'erl.CF' => 'treecd',
	'erl.CO' => 'compendex',
	'erl.CQ' => 'crim',
	'erl.J0' => 'crim',
	'erl.CS' => 'naswcr',
	'erl.CW' => 'cwi',
	'erl.G0' => 'gensci',
	'erl.GE' => 'georef',
	'erl.GG' => 'geography',
	'erl.E0' => 'cei',
	'erl.EN' => 'emneuro',
	'erl.ER' => 'eric',
	'erl.FS' => 'fsta',
	'erl.GB' => 'geobase',
	'erl.HA' => 'heracles',
	'erl.HG' => 'humanitiesabs',
	'erl.HP' => 'healthstar',
	'erl.IB' => 'inspec',
	'erl.IT' => 'ipsa',
	'erl.IP' => 'ipsa',
	'erl.IPSA' => 'ipsa',
	'erl.LL' => 'llba',
	'erl.LS' => 'lfsc',
	'erl.M9' => 'mlog',
	'erl.MB' => 'mla',
	'erl.MLAB' => 'mla',
	'erl.ME' => 'medline',
	'erl.ML' => 'medline',
	'erl.MX' => 'medline',
	'erl.NU' => 'cinahl',
	'erl.NP' => 'georef',
	'erl.P1' => 'poltox',
	'erl.P7' => 'paissel',
	'erl.PA' => 'pais',
	'erl.PH' => 'philind',
	'erl.PL' => 'psyclit',
	'erl.PP' => 'pais',
	'erl.PS' => 'psyclit',
	'erl.PY' => 'psy',
	'erl.R2' => 'repere',
	'erl.SJ' => 'georef',
	'erl.SL' => 'serline',
	'erl.SO' => 'socio',
	'erl.SP' => 'sportd',
	'erl.SW' => 'socwork',
	'erl.TC' => 'icl',
	'erl.TF' => 'atlaf',
	'erl.TZ' => 'atla',
	'erl.WC' => 'bioagri',
	'erl.WE' => 'gensci',
	'erl.WH' => 'humanitiesabs',
	'erl.WJ' => 'socsciabs',
	'erl.WO' => 'socsci',
	'erl.WQ' => 'egli',
	'erl.WR' => 'rgab',
	'erl.WS' => 'asti',
	'erl.WU' => 'humanities',
	'erl.WX' => 'arts',
	'erl.WZ' => 'legal',
	'erl.X2' => 'socsciabs',
	'erl.ZO' => 'zoo',
	'erl.ZZ' => 'treecd',
	'proquest.proquest' => 'proquest',
        'IOP.AXIOM'         => 'axiom',
	'IOPP.jnl_ref'      => 'iopp',
	'unknown.unknown'   => 'unknown'    # only allow this for OpenURL syntax
);


%DBASE_INFO_HASH = (
	'asfa' => {'fullname' =>  'CSA: Aquatic Sciences and Fisheries Abstracts', 'type' => 'CSA'},
	'ahw'  => {'fullname' =>  'EBSCOHost: Alt-HealthWatch', 'type' => 'ebsco'},
	'ageline'	=> {'fullname' =>  'Ageline', 'type' => 'erl'},
	'agric'	=> {'fullname' =>  'Agricola', 'type' => 'erl'},
	'arts'	=> {'fullname' =>  'Arts Index', 'type' => 'slri'},
	'ase'	=> {'fullname' =>  'Academic Search FullTEXT Elite', 'type' => 'ebsco'},
	'asp'	=> {'fullname' =>  'Academic Search Premier', 'type' => 'ebsco'},
	'asti'	=> {'fullname' =>  'Applied Science & Technology Index', 'type' => 'erl'},
	'atla'	=> {'fullname' =>  'ATLA Religion Database', 'type' => 'erl'},
	'atlas' => {'fullname' =>  'ATLAS Full Text Plus on EbscoHOST', 'type' => 'ebsco'},
	'atlaf'	=> {'fullname' =>  'ATLAS Religion Database Fulltext', 'type' => 'erl'},
	'axiom'	=> {'fullname' =>  'Axiom Databases', 'type' => 'IOP'},
	'bioagri'	=> {'fullname' =>  'Biological and Agricultural Index', 'type' => 'erl'},
	'bioethics'	=> {'fullname' =>  'Bioethicsline', 'type' => 'erl'},
	'biosis'	=> {'fullname' =>  'Biological Abstracts', 'type' => 'erl'},
	'bip'	=> {'fullname' =>  'Books in Print', 'type' => 'erl'},
	'blank'	=> {'fullname' =>  'Blank form', 'type' => 'unknown'},
	'bnna'	=> {'fullname' =>  'Bibliography of Native North Americans', 'type' => 'erl'},
	'bse'   => {'fullname' =>  'Business Source Elite', 'type' => 'ebsco'},
	'bsp'	=> {'fullname' =>  'Business Source Premier', 'type' => 'ebsco'},
	'caba'	=> {'fullname' =>  'CAB Abstracts', 'type' => 'erl'},
	'cancer'	=> {'fullname' =>  'Cancer-CD', 'type' => 'erl'},
	'cbca'	=> {'fullname' =>  'Canadian Business and Current Affairs', 'type' => 'slri'},
	'cbcafe'	=> {'fullname' =>  'Canadian Business and Current Affairs Fulltext Education', 'type' => 'erl'},
	'cmasfe'	=> {'fullname' =>  'Canadian MAS FullTEXT Elite', 'type' => 'ebsco'},
	'cei'	=> {'fullname' =>  'Canadian Education Index', 'type' => 'erl'},
	'cinahl'	=> {'fullname' =>  'Cinhal', 'type' => 'erl'},
	'cistisource'	=> {'fullname' =>  'CISTI Source', 'type' => 'unknown'},
	'compendex'	=> {'fullname' =>  'EI Compendex', 'type' => 'erl'},
	'cnews'	=> {'fullname' =>  'Canadian Newsdisc', 'type' => 'erl'},
	'curcon'	=> {'fullname' =>  'Current Contents', 'type' => 'erl'},
	'crc'  => {'fullname' =>  'EBSCOHost: Canadian Reference Centre', 'type' => 'ebsco'},
	'crim'	=> {'fullname' =>  'Criminal Justice Abstracts', 'type' => 'erl'},
	'csa'	=> {'fullname' =>  'Cambridge Scientific Abstracts', 'type' => 'unknown'},
	'csti'	=> {'fullname' =>  'CISTI serials mounted on BRS at SFU', 'type' => 'unknown'},
	'cwi'	=> {'fullname' =>  'Contemporary Women\'s Issues', 'type' => 'erl'},
	'eb-ageline'    => {'fullname' =>  'AgeLine on EbscoHOST', 'type' => 'ebsco'},
	'eb-agric'      => {'fullname' =>  'Agricola on EbscoHOST', 'type' => 'ebsco'},
	'eb-ahi'        => {'fullname' =>  'American Humanities Index on EbscoHOST', 'type' => 'ebsco'},
	'eb-atla'       => {'fullname' =>  'ATLA Religion on EbscoHOST', 'type' => 'ebsco'},
	'eb-bnna'       => {'fullname' =>  'Bibliography of Native North Americans', 'type' => 'ebsco'},
	'eb-biomed'     => {'fullname' =>  'Biomedical Reference Collection: Comprehensive', 'type' => 'ebsco'},
	'eb-canlit'     => {'fullname' =>  'Canadian Literary Centre on EbscoHOST', 'type' => 'ebsco'},
	'eb-cinahl-ft'  => {'fullname' =>  'CINAHL with Full Text on EbscoHOST', 'type' => 'ebsco'},
	'eb-cinahl'     => {'fullname' =>  'CINAHL on EbscoHOST', 'type' => 'ebsco'},
	'eb-cmmc'       => {'fullname' =>  'Communication & Mass Media Complete on EBSCO', 'type' => 'ebsco'},
	'eb-csi'        => {'fullname' =>  'Computer Science Index', 'type' => 'ebsco'},
	'eb-econlit'	=> {'fullname' =>  'Econlit on EbscoHOST', 'type' => 'ebsco'},
	'eb-epi'	=> {'fullname' =>  'Environmental Issues & Policy Index on EbscoHOST', 'type' => 'ebsco'},
	'eb-eric'	=> {'fullname' =>  'ERIC on EbscoHOST',  'type' => 'ebsco'},
	'eb-georef'	=> {'fullname' =>  'GeoRef on EbscoHOST',  'type' => 'ebsco'},
	'eb-glblhealth'	=> {'fullname' =>  'Global Health on EbscoHOST',  'type' => 'ebsco'},
	'eb-hti'	=> {'fullname' =>  'Hospitality and Tourism Complete on EbscoHOST',  'type' => 'ebsco'},
	'eb-ipsa'       => {'fullname' =>  'International Political Science Abstracts on EbscoHOST',  'type' => 'ebsco'},
	'eb-libref'     => {'fullname' =>  'Library Reference Center on EbscoHOST', 'type' => 'ebsco'},
	'eb-libista'    => {'fullname' =>  'Library, Information Science & Technology Abstracts on EbscoHOST', 'type' => 'ebsco'},
	'eb-medline'    => {'fullname' =>  'MEDLINE on EBSCO', 'type' => 'ebsco'},
	'eb-milgov'     => {'fullname' =>  'Military & Government Collection on EBSCO', 'type' => 'ebsco'},
	'eb-mla'        => {'fullname' =>  'MLA International Bibliography on EBSCO', 'type' => 'ebsco'},
	'eb-mlap'       => {'fullname' =>  'MLA Directory of Periodicals on EBSCO', 'type' => 'ebsco'},
	'eb-nta'        => {'fullname' =>  'New Testament Abstracts on EBSCO', 'type' => 'ebsco'},
	'eb-ota'        => {'fullname' =>  'Old Testament Abstracts on EBSCO', 'type' => 'ebsco'},
	'eb-psyc'	=> {'fullname' =>  'PsycINFO on EbscoHOST', 'type' => 'ebsco'},
	'eb-psycart'    => {'fullname' =>  'PsycARTICLES on EbscoHOST', 'type' => 'ebsco'},
	'eb-psycextra'  => {'fullname' =>  'PsycEXTRA on EbscoHOST', 'type' => 'ebsco'},
	'eb-psycbooks'  => {'fullname' =>  'PsycBOOKS on EbscoHOST', 'type' => 'ebsco'},
	'eb-sportd'	=> {'fullname' =>  'SPORTDiscus on EbscoHOST',  'type' => 'ebsco'},
	'eb-ssi'	=> {'fullname' =>  'Short Story Index on EBSCO', 'type'=> 'ebsco'},
	'eb-soci'	=> {'fullname' =>  'SocINDEX on EBSCO', 'type' => 'ebsco'},
	'eb-socift'	=> {'fullname' =>  'SocINDEX on EBSCO with Full Text', 'type' => 'ebsco'},
	'eb-wldecoww'   => {'fullname' =>  'Wildlife & Ecology Studies Worldwide', 'type' => 'ebsco'},
	'ecdb'	=> {'fullname' =>  'COPPUL/ELN Union Serials List', 'type' => 'slri'},
	'econlit'	=> {'fullname' =>  'Econlit', 'type' => 'erl'},
	'educ'	=> {'fullname' =>  'Wilson Education Index', 'type' => 'slri'},
	'egli'  => {'fullname' => 'Essays and General Literature', 'type' => 'erl'},
	'emneuro'	=> {'fullname' =>  'Embase Neurosciences', 'type' => 'erl'},
	'eoc'	=> {'fullname' =>  'Ebsco Online Citation', 'type' => 'ebsco'},
	'eric'	=> {'fullname' =>  'ERIC', 'type' => 'erl'},
	'fsta'	=> {'fullname' =>  'Food Science and Technology Abstracts', 'type' => 'erl'},
	'gensci'	=> {'fullname' =>  'Wilson General Science Index', 'type' => 'erl'},
	'geobase'	=> {'fullname' =>  'Geobase', 'type' => 'erl'},
	'geography'	=> {'fullname' =>  'same parsing as Geobase', 'type' => 'erl'},
	'georef'	=> {'fullname' =>  'Georef', 'type' => 'erl'},
	'hssi'	=> {'fullname' =>  'Combined Wilson Humanities and Social Sciences Indexes', 'type' => 'slri'},
	'hsce'  => {'fullname' =>  'EBSCOHost: Health Source: Consumer Edition', 'type' => 'ebsco'},
	'hsnae'  => {'fullname' =>  'EBSCOHost: Health Source: Nursing/Academic Edition', 'type' => 'ebsco'},
	'humanities'	=> {'fullname' =>  'Wilson Humanities Index', 'type' => 'erl'},
	'humanitiesabs'	=> {'fullname' =>  'Wilson Humanities Abstracts', 'type' => 'erl'},
	'healthstar'	=> {'fullname' =>  'HealthStar', 'type' => 'erl'},
	'icl'	=> {'fullname' =>  'Index to Canadian Legal Literature', 'type' => 'erl'},
	'inspec'	=> {'fullname' =>  'Inspec', 'type' => 'erl'},
	'ipsa'	=> {'fullname' =>  'International Political Science Abstracts', 'type' => 'erl'},
	'iopp'	=> {'fullname' =>  'Institute of Physics Publishing e-journals', 'type' => 'unknown'},
	'lfsc'	=> {'fullname' =>  'Life Sciences', 'type' => 'erl'},
	'llba'	=> {'fullname' =>  'Linguistic and Language Behaviour Abstracts', 'type' => 'erl'},
	'masterfile'	=> {'fullname' =>  'MasterFILE Elite', 'type' => 'ebsco'},
	'masu'	=> {'fullname' =>  'MAS Ultra - School Edition', 'type' => 'ebsco'},
	'mathscinet'	=> {'fullname' =>  'MathSciNet', 'type' => 'AMS'},
	'medline'	=> {'fullname' =>  'Medline', 'type' => 'erl'},
	'middle'	=> {'fullname' =>  'Middle Search Plus', 'type' => 'ebsco'},
	'mla'	=> {'fullname' =>  'MLA', 'type' => 'erl'},
	'mlft'  => {'fullname' =>  'Military Library FullTEXT on EBSCO', 'type' => 'ebsco'},
	'mlog'	=> {'fullname' =>  'Canadian Research Index (formerly Microlog)', 'type' => 'erl'},
	'pais'	=> {'fullname' =>  'PAIS International', 'type' => 'erl'},
	'paissel'	=> {'fullname' =>  'PAIS Select', 'type' => 'erl'},
	'philind'	=> {'fullname' =>  'Philosopher\'s Index', 'type' => 'erl'},
	'primary'	=> {'fullname' =>  'Primary Search', 'type' => 'ebsco'},
	'proquest'	=> {'fullname' =>  'Proquest Direct', 'type' => 'proquest'},
	'psy'	=> {'fullname' =>  'Psycinfo', 'type' => 'erl'},
	'psyclit'	=> {'fullname' =>  'Psyclit', 'type' => 'erl'},
	'repere'	=> {'fullname' => 'Repere', 'type' => 'erl'},
	'rgab'	=> {'fullname' =>  'Wilson Reader\'s Guide Abstracts', 'type' => 'slri'},
	'scie'	=> {'fullname' =>  'Three Wilson science indexes combined', 'type' => 'slri'},
	'sfu_iii'	=> {'fullname' =>  'SFU Catalog via SLRI', 'type' => 'slri'},
	'sociabs'	=> {'fullname' =>  'Sociological Abstracts', 'type' => 'ebsco'},
	'socicol'	=> {'fullname' =>  'Sociological Collection', 'type' => 'ebsco'},
	'socio'	=> {'fullname' =>  'Sociofile (Sociology Abstracts)', 'type' => 'erl'},
	'socsci'	=> {'fullname' =>  'Wilson Social Sciences Index', 'type' => 'erl'},
	'socsciabs'	=> {'fullname' =>  'Wilson Social Sciences Abstracts', 'type' => 'erl'},
	'socwork'	=> {'fullname' =>  'Social Work Abstracts', 'type' => 'erl'},
	'soul'	=> {'fullname' =>  'Serials at Ontario University Libraries', 'type' => 'unknown'},
	'sportd'	=> {'fullname' =>  'Sport Discus', 'type' => 'erl'},
	'treecd'	=> {'fullname' =>  'Tree CD', 'type' => 'erl'},
	'ualberta'	=> {'fullname' =>  'U of A catalogue via SLRI', 'type' => 'slri'},
	'ubc'	=> {'fullname' =>  'UBC Catalogue', 'type' => 'slri'},
	'ucalgary'	=> {'fullname' =>  'U of C catalogue', 'type' => 'slri'},
	'umanitoba'	=> {'fullname' =>  'U of M catalogue', 'type' => 'slri'},
	'unknown'	=> {'fullname' =>  'Only allowed for OpenURL syntax', 'type' => 'unknown'},
	'usask'	=> {'fullname' =>  'U of S catalogue', 'type' => 'slri'},
	'utoronto'	=> {'fullname' =>  'U of Toronto', 'type' => 'slri'},
	'uvic'	=> {'fullname' =>  'U Victoria catalogue via SLRI', 'type' => 'slri'},
	'eb-wsi'=> {'fullname' =>  'Women\'s Studies International', 'type' => 'ebsco'},
	'worhisf'	=> {'fullname' =>  'World History FullTEXT', 'type' => 'ebsco'},
	'zoo'	=> {'fullname' =>  'Zoological Abstracts', 'type' => 'erl'}
);


##
## -@DBASE_ARR lists databases that can be parsed
##
##
@DBASE_ARR = (
              'asfa',           ## -Aquatic Sciences and Fisheries Abstracts (CSA)
              'ahw',
              'ageline', 
              'agric',
              'arts', 
              'ase',            ## -Academic Search FullTEXT Elite (Ebsco)        
              'asp',            ## -Academic Search Premier (Ebsco)  
              'asti', 
              'atla', 
              'atlaf',
              'atlas',
              'axiom', 
              'bioagri',
              'bioethics',
              'biosis',
              'bip',
              'blank',          ## -a blank form that allows you to enter citation information
              'bnna',             
              'bse',
              'bsp',             
              'caba', 
              'cancer',
              'cbca',
 	      'cbcafe',
              'cmasfe',         ## -Canadian MAS FullTEXT Elite (Ebsco)
              'cei', 
              'cinahl', 
              'cisx', 
              'cistisource',    ## CISTI Online
              'compendex', 
              'cnews', 
              'curcon',  
              'crc',
              'crim', 
              'csa',
              'cwi',     
              'eb-ageline',       
              'eb-agric',       
	      'eb-ahi',
              'eb-atla',  
              'eb-bnna',
              'eb-biomed',
              'eb-canlit',
              'eb-cinahl-ft',
              'eb-cinahl',
	      'eb-cmmc',
              'eb-csi',
              'eb-econlit',
              'eb-epi',         
              'eb-eric',        ## -ERIC on EbscoHOST      
              'eb-georef',      ## -GeoRef on EbscoHOST      
              'eb-glblhealth',
              'eb-hti',
              'eb-ipsa',
              'eb-libref',
              'eb-libista',             
              'eb-medline',
              'eb-milgov',
              'eb-mla',
              'eb-mlap',
              'eb-nta',
              'eb-ota',
              'eb-psyc',        ## -PsycINFO on EbscoHOST      
              'eb-psycart',
              'eb-psycbooks',
              'eb-psycextra',             
	      'eb-sportd',      ## -SPORTDiscus on EbscoHOST
	      'eb-ssi',
	      'eb-soci',
	      'eb-socift',
              'eb-wldecoww',
              'ecdb',           ## -COPPUL/ELN Union Serials List
              'econlit',
              'educ', 
              'egli',
              'emneuro',
              'eoc',            ## -Ebsco Online Citations (Ebsco)
              'eric',
              'fsta',    
              'gensci',         ## -Wilson General Sciences Index
	      'geobase',
	      'geography',
              'georef',
              'healthstar',
              'hsce',
              'hsnae',
              'hssi',           ## -combined Wilson Humanities and Social Sciences Indexes
              'humanities',     ## -Wilson Humanities Index
              'humanitiesabs',  ## -Wilson Humanities Abstracts
              'icl',
              'inspec',
              'ipsa',
              'iopp',            ## -Institute of Physics Publishing e-journals
              'lfsc',
              'llba',
              'masterfile', 
              'masu',
              'mathscinet', 
              'medline', 
              'middle', 
              'mla',  
              'mlft',
              'mlog',
              'pais',           ## PAIS International
              'paissel',        ## PAIS Select    
              'philind',
              'primary',
              'proquest',       ## Use as a place holder for the database name, which is not available 
                                ## for the godot link in the Proquest interface.
	      'psy',
              'psyclit',
	      'repere',
              'rgab', 
              'scie',           ## -3 Wilson science indexes combined
              'sfu_iii',        ## -SFU Catalog via SLRI
              'sociabs',
              'socicol',
              'socio',
              'socsci',         ## -Wilson Social Sciences Index
              'socsciabs',      ## -Wilson Social Sciences Abstracts 
              'socwork',        ## -Social Work Abstracts
              'soul',           ## -Serials at Ontario University Libraries
              'sportd', 
              'treecd',  
              'ualberta',       ## -U of A catalogue via SLRI
              'ubc',            ## (25-aug-1998 kl) - currently may be using DRA web or SLRI
              'ucalgary',       ## -U of C catalogue via SLRI
              'umanitoba',      ## -U of M catalogue via SLRI
              'unknown',        ## -for now only allow this for OpenURL syntax
              'usask',          ## -U of S catalogue via SLRI
              'utoronto',       ## (05-dec-1998 kl)
              'uvic',           ## -U Victoria catalogue via SLRI
              'worhisf',
              'eb-wsi',  
              'zoo'
);

use vars qw(@NO_BACK_TO_DATABASE_DBASE_ARR @NO_BACK_TO_DATABASE_DBASE_TYPE_ARR);

@NO_BACK_TO_DATABASE_DBASE_ARR = ('iopp', 
                                  'unknown', 
                                  'ase',
                                  'asp',
                                  'ahw',
                                  'atlas', 
                                  'cmasfe',
                                  'eoc',
                                  'eb-nta',
                                  'eb-ota',
                                  'eb-psyc',
                                  'eb-psycextra',
                                  'eb-psycbooks',
                                  'eb-sportd', 
                                  'eb-hti',
                                  'eb-eric', 
                                  'eb-mla', 
                                  'eb-mlap', 
                                  'masterfile',
                                  'masu',
                                  'middle',
                                  'primary',
                                  'bsp',
                                  'sociabs',
                                  'socicol',
                                  'worhisf',
                                  'eb-wsi',
                                  'hsce',
                                  'hsnae',
                                  'eb-georef',
	                          'eb-econlit', 
                                  'eb-epi', 
                                  'eb-atla', 
                                  'eb-medline', 
                                  'eb-ageline', 
                                  'eb-agric', 
                                  'eb-milgov',
                                  'eb-csi',
                                  'eb-ssi',
                                  'eb-soci',
                                  'eb-socift',
                                  'eb-libref',
                                  'eb-libista',
                                  'eb-ipsa');



@NO_BACK_TO_DATABASE_DBASE_TYPE_ARR = ('ABC-CLIO', 
                                       'CIOS',
                                       'CSA', 
                                       'FirstSearch', 
                                       'Gale',
                                       'gale',
                                       'GEODOK', 
                                       'Google',
                                       'ISI', 
                                       'NISC', 
                                       'openly',
                                       'proquest', 
                                       'RLG', 
                                       'ukoln',
                                       'Refworks',
                                       'LC',
                                       'HWW',
                                       'OVID',
                                       'SFX');


# Warning/error control variables

use vars qw (
	$WARN_ON_DEFAULT_PARSER
	$TRACE_CALLS
);

$WARN_ON_DEFAULT_PARSER = 1;
$TRACE_CALLS = 0;

use vars qw(%MAILLIST_HASH);
%MAILLIST_HASH = (
	'parser' => $GODOT::Config::PARSER_ADMIN_MAILLIST,
	'godot'  => $GODOT::Config::GODOT_ADMIN_MAILLIST
);


use vars qw($PARA_SERVER_TIMEOUT $PARA_SERVER_QUERY_TIMEOUT $Z3950_TIMEOUT);

##
## !!!!!!!!!!!!!!!!!!!! do not change order of these !!!!!!!!!!!!!!!!!!!!!!!!!!!
##

$Z3950_TIMEOUT             = 60; # (timeout for live monograph Z39.50 searches - in seconds)
#### $Z3950_TIMEOUT             = 6; # (timeout for live monograph Z39.50 searches - in seconds)
$PARA_SERVER_QUERY_TIMEOUT = $Z3950_TIMEOUT + 5;
$PARA_SERVER_TIMEOUT       = $PARA_SERVER_QUERY_TIMEOUT + 10; 

##
## -pool of parallel servers
##

use vars qw(@PARALLEL_SERVERS);

##
## (21-feb-2006 kl) - have replaced method by which data is sent from httpd process to parallel server and back 
##                  - *** only localhost is valid now ***
##
## (24-sep-2003 kl) - to spread load, added the ability to use one of a pool of parallel servers
##

@PARALLEL_SERVERS = (['localhost',       $GODOT::Config::PARALLEL_SERVER_PORT]);

##
## -this needs to be a reasonably (at least 5?) large number, otherwise not all your 
##  'first pics' will get searched but sites in union serials list will still appear .....
##
## -will work better when more sites are configured to use their catalogues instead
##  of the union serials list
##
use vars qw($MAX_QUERY_IN_PARALLEL $MIN_BRANCH_WITH_HOLDINGS);
$MAX_QUERY_IN_PARALLEL    = 5;
$MIN_BRANCH_WITH_HOLDINGS = 4;



use vars qw(@BUNDLE_GENRE_ARR $JOURNAL_GENRE $BOOK_GENRE $CONFERENCE_GENRE);
@BUNDLE_GENRE_ARR = ( 
   $JOURNAL_GENRE    = 'journal', 
   $BOOK_GENRE       = 'book',
   $CONFERENCE_GENRE = 'conference'
); 
          
use vars qw(@INDIVIDUAL_ITEM_GENRE_ARR $ARTICLE_GENRE $PREPRINT_GENRE $PROCEEDING_GENRE $BOOKITEM_GENRE);
@INDIVIDUAL_ITEM_GENRE_ARR = (
   $ARTICLE_GENRE    = 'article',
   $PREPRINT_GENRE   = 'preprint',
   $PROCEEDING_GENRE = 'proceeding',
   $BOOKITEM_GENRE   = 'bookitem'
);

use vars qw(%GENRE_TO_REQTYPE_HASH);
%GENRE_TO_REQTYPE_HASH = (
    ##
    ## -treat this as a journal article and prompt user, if necessary, for the article information
    ##
    $JOURNAL_GENRE    => $GODOT::Constants::JOURNAL_TYPE,
    $BOOK_GENRE       => $GODOT::Constants::BOOK_TYPE,
    $CONFERENCE_GENRE => $GODOT::Constants::CONFERENCE_TYPE,
    $ARTICLE_GENRE    => $GODOT::Constants::JOURNAL_TYPE,
    $PREPRINT_GENRE   => $GODOT::Constants::PREPRINT_TYPE,         ## a preprint
    $PROCEEDING_GENRE => $GODOT::Constants::CONFERENCE_TYPE,
    $BOOKITEM_GENRE   => $GODOT::Constants::BOOK_ARTICLE_TYPE,     
);

use vars qw(@DISS_ABS_ISSN_ARR);
@DISS_ABS_ISSN_ARR = ('04194209', '04194217', '00993123', '00959154', '0420073X', '0420073x', '08989095');


use vars qw($REDIRECTION_ALLOWED); 
$REDIRECTION_ALLOWED = $FALSE;


1;

__END__
