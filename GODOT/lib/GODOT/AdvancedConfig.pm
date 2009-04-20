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
        ##
	## EBSCOhost databases
        ## (25-jul-2006 kl) - now only need per database logic for ebscohost databases if they require a database
        ##                    specific parser
        ##
	'eb-eric' => 'ebsco::eric', 
	'socicol' => 'ebsco::socicol',
	
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
        'axiom'    => 'openurl',                 ## -is this still used ?? - should have been replaced with %DBASE_TYPE_PARSER_MAPPING
        'iopp'     => 'openurl',
	'OvidWebspirs:mla' => 'openurl',
	'unknown'  => 'openurl',       
        'ISI:endnote' => 'openurl',
	'ISI:WoS' => 'openurl::isi::wos',
	'ISI:WoK' => 'openurl::isi::wos',
        'www.isinet.com:WoK:WOS' => 'openurl::isi::wos',    ## (26-mar-2009 kl) -- moved from GODOT::Database       
	'BMC:F1000' => 'openurl::force_journal',
	
	#Others ---- added by yyua
	'pais' => 'paissel',
	
);



%DBASE_TYPE_PARSER_MAPPING = (

     'ABC-CLIO'      => 'openurl',
     'AMS'           => 'openurl::mathscinet',
     'annualreviews' => 'openurl',
     'APA'           => 'openurl',
     'arXiv'         => 'openurl',
     'blackwell'     => 'openurl',
     'BMC'           => 'openurl',
     'BOWKER'        => 'openurl',
     'BBS'           => 'openurl',
     'CAS'           => 'openurl::cas',             ## SciFinder Scholar
     'CIOS'          => 'openurl',
     'CISTI'         => 'openurl',
     'CSA'           => 'openurl::csa',
     'dbwiz'         => 'openurl',
     'DIALOG'        => 'openurl',
     'digitool'      => 'openurl',
     'EBSCO'         => 'openurl',
     'ebscohost'     => 'ebsco',
     'Elsevier'      => 'openurl',
     'elsevier.com'  => 'openurl',
     'EI'            => 'openurl',
     'Endeavor'      => 'openurl',
     'Entrez'        => 'openurl',
     'FamilyScholar' => 'openurl',
     'FirstSearch'   => 'openurl::firstsearch',
     'gale'          => 'openurl',
     'Gale'          => 'openurl',
     'GEODOK'        => 'openurl',
     'Google'        => 'openurl',                  ## is this still needed?
     'google'        => 'openurl',
     'Harmonie'      => 'openurl',
     'ICPSR'         => 'openurl',
     'III'           => 'openurl',
     'HWW'           => 'openurl',
     'IOP'           => 'openurl::axiom',
     'jstor'         => 'openurl',
     'LC'            => 'openurl',
     'libx'          => 'openurl',
     'mimas'         => 'openurl',
     'NISC'          => 'openurl',
     'openly'        => 'openurl',
     'oup'           => 'openurl',
     'OUP'	     => 'openurl',
     'OVID'          => 'openurl',
     'proquest'      => 'openurl::proquest',
     'ProQ'          => 'openurl',
     'pqil'          => 'openurl',
     'RLG'           => 'openurl::rlg',
     'SFU'           => 'openurl',
     #### 'ukoln'    => 'openurl',                ## can now handle unknown sid/rfr_id
     'Refworks'      => 'openurl',
     'rsc'           => 'openurl',
     'Wiley'         => 'openurl',
     'LC'            => 'openurl',
     'SilverPlatter' => 'openurl',
     'SFX'           => 'openurl',
     'STN'           => 'openurl',
     'SP'            => 'openurl',
     'swets'         => 'openurl',
     'RefPress'      => 'openurl',
     'Elsevier'      => 'openurl',
     'SFX'           => 'openurl',
     'undefined'     => 'openurl',               ## libx may send if you have set sid to blank
     'UW'            => 'openurl'
);


%DBASE_LOCAL_MAPPING = (
        'AMS:MathSciNet'                        => 'mathscinet',        
        'CSA.asfa1-set-n'                       => 'asfa',

	'ebscohost.ERIC'                        => 'eb-eric', 
	'ebscohost.Sociological Collection'     => 'socicol', 

	'cisti.cistisource'                     => 'cistisource',
	'erl.2E' => 'bip',
	'erl.AE' => 'econlit',
	'erl.EC' => 'econlit', 
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
	'asfa'          => {'fullname' =>  'CSA: Aquatic Sciences and Fisheries Abstracts', 'type' => 'CSA'},
	'ageline'	=> {'fullname' =>  'Ageline', 'type' => 'erl'},
	'agric'	        => {'fullname' =>  'Agricola', 'type' => 'erl'},
	'arts'	        => {'fullname' =>  'Arts Index', 'type' => 'slri'},
	'asti'	        => {'fullname' =>  'Applied Science & Technology Index', 'type' => 'erl'},
	'atla'	        => {'fullname' =>  'ATLA Religion Database', 'type' => 'erl'},
	'atlaf'	        => {'fullname' =>  'ATLAS Religion Database Fulltext', 'type' => 'erl'},
	'axiom'	        => {'fullname' =>  'Axiom Databases', 'type' => 'IOP'},
	'bioagri'	=> {'fullname' =>  'Biological and Agricultural Index', 'type' => 'erl'},
	'bioethics'	=> {'fullname' =>  'Bioethicsline', 'type' => 'erl'},
	'biosis'	=> {'fullname' =>  'Biological Abstracts', 'type' => 'erl'},
	'bip'	        => {'fullname' =>  'Books in Print', 'type' => 'erl'},
	'blank'	        => {'fullname' =>  'Blank form', 'type' => 'unknown'},
	'bnna'	        => {'fullname' =>  'Bibliography of Native North Americans', 'type' => 'erl'},
	'caba'	        => {'fullname' =>  'CAB Abstracts', 'type' => 'erl'},
	'cancer'	=> {'fullname' =>  'Cancer-CD', 'type' => 'erl'},
	'cbca'	        => {'fullname' =>  'Canadian Business and Current Affairs', 'type' => 'slri'},
	'cbcafe'	=> {'fullname' =>  'Canadian Business and Current Affairs Fulltext Education', 'type' => 'erl'},
	'cei'	        => {'fullname' =>  'Canadian Education Index', 'type' => 'erl'},
	'cinahl'	=> {'fullname' =>  'Cinhal', 'type' => 'erl'},
	'cistisource'	=> {'fullname' =>  'CISTI Source', 'type' => 'unknown'},
	'compendex'	=> {'fullname' =>  'EI Compendex', 'type' => 'erl'},
	'cnews'	        => {'fullname' =>  'Canadian Newsdisc', 'type' => 'erl'},
	'curcon'	=> {'fullname' =>  'Current Contents', 'type' => 'erl'},
	'crim'	        => {'fullname' =>  'Criminal Justice Abstracts', 'type' => 'erl'},
	'csa'	        => {'fullname' =>  'Cambridge Scientific Abstracts', 'type' => 'unknown'},
	'csti'	        => {'fullname' =>  'CISTI serials mounted on BRS at SFU', 'type' => 'unknown'},
	'cwi'	        => {'fullname' =>  'Contemporary Women\'s Issues', 'type' => 'erl'},

	'eb-eric'	=> {'fullname' =>  'ERIC on EbscoHOST',  'type' => 'ebsco'},

	'ecdb'	        => {'fullname' =>  'COPPUL/ELN Union Serials List', 'type' => 'slri'},
	'econlit'	=> {'fullname' =>  'Econlit', 'type' => 'erl'},
	'educ'	        => {'fullname' =>  'Wilson Education Index', 'type' => 'slri'},
	'egli'          => {'fullname' =>  'Essays and General Literature', 'type' => 'erl'},
	'emneuro'	=> {'fullname' =>  'Embase Neurosciences', 'type' => 'erl'},

	'eric'	        => {'fullname' =>  'ERIC', 'type' => 'erl'},
	'fsta'	        => {'fullname' =>  'Food Science and Technology Abstracts', 'type' => 'erl'},
	'gensci'	=> {'fullname' =>  'Wilson General Science Index', 'type' => 'erl'},
	'geobase'	=> {'fullname' =>  'Geobase', 'type' => 'erl'},
	'geography'	=> {'fullname' =>  'same parsing as Geobase', 'type' => 'erl'},
	'georef'	=> {'fullname' =>  'Georef', 'type' => 'erl'},
	'hssi'	        => {'fullname' =>  'Combined Wilson Humanities and Social Sciences Indexes', 'type' => 'slri'},
	'humanities'	=> {'fullname' =>  'Wilson Humanities Index', 'type' => 'erl'},
	'humanitiesabs'	=> {'fullname' =>  'Wilson Humanities Abstracts', 'type' => 'erl'},
	'healthstar'	=> {'fullname' =>  'HealthStar', 'type' => 'erl'},
	'icl'	        => {'fullname' =>  'Index to Canadian Legal Literature', 'type' => 'erl'},
	'inspec'	=> {'fullname' =>  'Inspec', 'type' => 'erl'},
	'ipsa'	        => {'fullname' =>  'International Political Science Abstracts', 'type' => 'erl'},
	'iopp'	        => {'fullname' =>  'Institute of Physics Publishing e-journals', 'type' => 'unknown'},
	'lfsc'	        => {'fullname' =>  'Life Sciences', 'type' => 'erl'},
	'llba'	        => {'fullname' =>  'Linguistic and Language Behaviour Abstracts', 'type' => 'erl'},
	'mathscinet'	=> {'fullname' =>  'MathSciNet', 'type' => 'AMS'},
	'medline'	=> {'fullname' =>  'Medline', 'type' => 'erl'},
	'mla'	        => {'fullname' =>  'MLA', 'type' => 'erl'},
	'mlog'	        => {'fullname' =>  'Canadian Research Index (formerly Microlog)', 'type' => 'erl'},
	'pais'	        => {'fullname' =>  'PAIS International', 'type' => 'erl'},
	'paissel'	=> {'fullname' =>  'PAIS Select', 'type' => 'erl'},
	'philind'	=> {'fullname' =>  'Philosopher\'s Index', 'type' => 'erl'},
	'proquest'	=> {'fullname' =>  'Proquest Direct', 'type' => 'proquest'},
	'psy'	        => {'fullname' =>  'Psycinfo', 'type' => 'erl'},
	'psyclit'	=> {'fullname' =>  'Psyclit', 'type' => 'erl'},
	'repere'	=> {'fullname' =>  'Repere', 'type' => 'erl'},
	'rgab'	        => {'fullname' =>  'Wilson Reader\'s Guide Abstracts', 'type' => 'slri'},
	'scie'	        => {'fullname' =>  'Three Wilson science indexes combined', 'type' => 'slri'},
	'sfu_iii'	=> {'fullname' =>  'SFU Catalog via SLRI', 'type' => 'slri'},

	'socicol'	=> {'fullname' =>  'Sociological Collection', 'type' => 'ebsco'},
	'socio'	        => {'fullname' =>  'Sociofile (Sociology Abstracts)', 'type' => 'erl'},
	'socsci'	=> {'fullname' =>  'Wilson Social Sciences Index', 'type' => 'erl'},
	'socsciabs'	=> {'fullname' =>  'Wilson Social Sciences Abstracts', 'type' => 'erl'},
	'socwork'	=> {'fullname' =>  'Social Work Abstracts', 'type' => 'erl'},
	'soul'	        => {'fullname' =>  'Serials at Ontario University Libraries', 'type' => 'unknown'},
	'sportd'	=> {'fullname' =>  'Sport Discus', 'type' => 'erl'},
	'treecd'	=> {'fullname' =>  'Tree CD', 'type' => 'erl'},
	'ualberta'	=> {'fullname' =>  'U of A catalogue via SLRI', 'type' => 'slri'},
	'ubc'	        => {'fullname' =>  'UBC Catalogue', 'type' => 'slri'},
	'ucalgary'	=> {'fullname' =>  'U of C catalogue', 'type' => 'slri'},
	'umanitoba'	=> {'fullname' =>  'U of M catalogue', 'type' => 'slri'},
	'unknown'	=> {'fullname' =>  'Only allowed for OpenURL syntax', 'type' => 'unknown'},
	'usask'	        => {'fullname' =>  'U of S catalogue', 'type' => 'slri'},
	'utoronto'	=> {'fullname' =>  'U of Toronto', 'type' => 'slri'},
	'uvic'	        => {'fullname' =>  'U Victoria catalogue via SLRI', 'type' => 'slri'},
	'zoo'	        => {'fullname' =>  'Zoological Abstracts', 'type' => 'erl'}
);


##
## -@DBASE_ARR lists databases that can be parsed
##
##
@DBASE_ARR = (
              'asfa',           ## -Aquatic Sciences and Fisheries Abstracts (CSA)
              'ageline', 
              'agric',
              'arts', 
              'asti', 
              'atla', 
              'atlaf',
              'axiom', 
              'bioagri',
              'bioethics',
              'biosis',
              'bip',
              'blank',          ## -a blank form that allows you to enter citation information
              'bnna',             
              'caba', 
              'cancer',
              'cbca',
 	      'cbcafe',
              'cei', 
              'cinahl', 
              'cisx', 
              'cistisource',    ## CISTI Online
              'compendex', 
              'cnews', 
              'curcon',  
              'crim', 
              'csa',
              'cwi',     
              'eb-eric',
              'ecdb',           ## -COPPUL/ELN Union Serials List
              'econlit',
              'educ', 
              'egli',
              'emneuro',
              'eric',
              'fsta',    
              'gensci',         ## -Wilson General Sciences Index
	      'geobase',
	      'geography',
              'georef',
              'healthstar',
              'hssi',           ## -combined Wilson Humanities and Social Sciences Indexes
              'humanities',     ## -Wilson Humanities Index
              'humanitiesabs',  ## -Wilson Humanities Abstracts
              'icl',
              'inspec',
              'ipsa',
              'iopp',            ## -Institute of Physics Publishing e-journals
              'lfsc',
              'llba',
              'mathscinet', 
              'medline', 
              'mla',  
              'mlog',
              'pais',           ## PAIS International
              'paissel',        ## PAIS Select    
              'philind',
              'proquest',       ## Use as a place holder for the database name, which is not available for the godot link in the Proquest interface.                                
	      'psy',
              'psyclit',
	      'repere',
              'rgab', 
              'scie',           ## -3 Wilson science indexes combined
              'sfu_iii',        ## -SFU Catalog via SLRI
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
              'eb-wsi',  
              'zoo'
);

use vars qw(@NO_BACK_TO_DATABASE_DBASE_ARR @NO_BACK_TO_DATABASE_DBASE_TYPE_ARR);

@NO_BACK_TO_DATABASE_DBASE_ARR = ('iopp', 
                                  'unknown');

@NO_BACK_TO_DATABASE_DBASE_TYPE_ARR = ('ABC-CLIO', 
                                       'APA',
                                       'CIOS',
                                       'CSA',
                                       'dbwiz',
                                       'ebscohost', 
                                       'FirstSearch', 
                                       'Gale',
                                       'gale',
                                       'GEODOK', 
                                       'Google',
                                       'google',
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

use vars qw(@BUNDLE_GENRE_ARR $JOURNAL_GENRE $BOOK_GENRE $CONFERENCE_GENRE $REPORT_GENRE $ISSUE_GENRE $DOCUMENT_GENRE);
@BUNDLE_GENRE_ARR = ( 
   $JOURNAL_GENRE    = 'journal', 
   $ISSUE_GENRE      = 'issue',         ## (02-mar-2009 kl) for openurl 0.1
   $BOOK_GENRE       = 'book',
   $CONFERENCE_GENRE = 'conference',
   $REPORT_GENRE     = 'report',        ## (02-mar-2009 kl) for openurl 0.1
   $DOCUMENT_GENRE   = 'document'       ## (02-mar-2009 kl) for openurl 0.1
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
    ## -treat 'journal' and 'issue' genres as journal articles and prompt user, if necessary, for the article information
    ##
    $JOURNAL_GENRE    => $GODOT::Constants::JOURNAL_TYPE,
    $ISSUE_GENRE      => $GODOT::Constants::JOURNAL_TYPE,          ## (02-mar-2009 kl) for openurl 0.1
    $BOOK_GENRE       => $GODOT::Constants::BOOK_TYPE,
    $CONFERENCE_GENRE => $GODOT::Constants::CONFERENCE_TYPE,
    $ARTICLE_GENRE    => $GODOT::Constants::JOURNAL_TYPE,
    $PREPRINT_GENRE   => $GODOT::Constants::PREPRINT_TYPE,       
    $PROCEEDING_GENRE => $GODOT::Constants::CONFERENCE_TYPE,
    $BOOKITEM_GENRE   => $GODOT::Constants::BOOK_ARTICLE_TYPE,   
    $REPORT_GENRE     => $GODOT::Constants::TECH_TYPE,             ## (02-mar-2009 kl) for openurl 0.1  
    $DOCUMENT_GENRE   => $GODOT::Constants::TECH_TYPE              ## (02-mar-2009 kl) for openurl 0.1
);

use vars qw(@DISS_ABS_ISSN_ARR);
@DISS_ABS_ISSN_ARR = ('04194209', '04194217', '00993123', '00959154', '0420073X', '0420073x', '08989095');

##
## (19-apr-2009 kl) -- for testing from home
##
use vars qw($REMOTE_HOST_FOR_TESTING);
$REMOTE_HOST_FOR_TESTING = 's0106001ee59d8cae.vf.shawcable.net';

use vars qw($REDIRECTION_ALLOWED); 
$REDIRECTION_ALLOWED = $FALSE;


1;

__END__
