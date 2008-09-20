## GODOT::Constants
##
## Copyright (c) 2001, Todd Holbrook, Simon Fraser University
##
## Various GODOT constants - these should NOT be modified by any other
## code, and in fact some may be subroutine calls to enforce that and do
## some error checking.
##

package GODOT::Constants;

use Exporter();
@ISA = qw(Exporter);
@EXPORT = qw($TRUE 
	     $FALSE
             $JOURNAL_TYPE         
             $CONFERENCE_TYPE
             $TECH_TYPE
             $BOOK_TYPE
             $BOOK_ARTICLE_TYPE
             $THESIS_TYPE
             $PREPRINT_TYPE
             $UNKNOWN_TYPE);

use strict;


##
## (31-jan-2007 kl) - any additions to @REQTYPE_ARR should be added to %GODOT::Citation::REQTYPE_TO_GENRE_MAP
##

use vars qw(@REQTYPE_ARR $JOURNAL_TYPE $CONFERENCE_TYPE $TECH_TYPE $BOOK_TYPE $BOOK_ARTICLE_TYPE $THESIS_TYPE $PREPRINT_TYPE
            $UNKNOWN_TYPE);

@REQTYPE_ARR = (
    $JOURNAL_TYPE      = 'JOURNAL',
    $CONFERENCE_TYPE   = 'CONFERENCE',
    $TECH_TYPE         = 'TECH',
    $BOOK_TYPE         = 'BOOK',
    $BOOK_ARTICLE_TYPE = 'BOOK-ARTICLE',
    $THESIS_TYPE       = 'THESIS',
    $PREPRINT_TYPE     = 'PREPRINT',       ## (10-mar-2001) - added for OpenURL links
    $UNKNOWN_TYPE      = 'UNKNOWN',
);

use vars qw($HOLD_TAB_PREFIX);
$HOLD_TAB_PREFIX = 'hold_tab_';

use vars qw($DBASE_TYPE_FIELD $DBASE_LOCAL_FIELD);
$DBASE_TYPE_FIELD         = 'hold_tab_dbase_type';
$DBASE_LOCAL_FIELD        = 'hold_tab_dbase_local';

##
## Used for ebscohost as they needed shortnames due to size restrictions at their end
##
use vars qw($DBASE_TYPE_ABBREV_FIELD $DBASE_LOCAL_ABBREV_FIELD $BRANCH_ABBREV_FIELD
            %CITN_PRE_ABBREV_HASH @ABBREV_SYNTAX_FIELDS_ARR);

$DBASE_TYPE_ABBREV_FIELD  = 'dbt';
$DBASE_LOCAL_ABBREV_FIELD = 'dbl';
$BRANCH_ABBREV_FIELD      = 'htb';           ## (01-dec-2003 kl)

%CITN_PRE_ABBREV_HASH = (
    'ti'   =>  'hold_tab_ti',
    'so'   =>  'hold_tab_so',
    'ca'   =>  'hold_tab_ca',
    'issn' =>  'hold_tab_issn',
    'sid'  =>  'hold_tab_sid',
    'mon'  =>  'hold_tab_mon',
    'vol'  =>  'hold_tab_vol',
    'iss'  =>  'hold_tab_iss',
    'pg'   =>  'hold_tab_pg',
    'ft'   =>  'hold_tab_ft',
    'p'    =>  'hold_tab_pb',
);

@ABBREV_SYNTAX_FIELDS_ARR = (
	$DBASE_TYPE_ABBREV_FIELD,
	$DBASE_LOCAL_ABBREV_FIELD,
        $BRANCH_ABBREV_FIELD,
	keys(%CITN_PRE_ABBREV_HASH),
	't',
	'isbn',
	'sici',
        'an',       # kl - added 2006-09-07.  Use for 'an={AN}' instead of 'sid={AN}' as using 'sid' confuses OpenURL fuzzy matching. 
	'newwin',
	'_us.ri',   # th - added 2002-08-08.  New EBSCO field, no clue what it does but it broke GODOT in init_dbase.
);


use vars qw(@SYNTAX_ARR $ORIG_SYNTAX $ABBREV_SYNTAX $OPENURL_SYNTAX);
@SYNTAX_ARR = (
    $ORIG_SYNTAX    = 'orig_syntax',
    $ABBREV_SYNTAX  = 'abbrev_syntax',
    $OPENURL_SYNTAX = 'openurl_syntax'
); 

use vars qw($TRUE $FALSE);
$TRUE  = 1;
$FALSE = 0;

use vars qw (@DBASE_TYPE_ARR);

@DBASE_TYPE_ARR = ('ABC-CLIO',
                   'AMS',
                   'annualreviews',
                   'APA',
                   'arXiv',
                   'BBS',
                   'blackwell',
                   'BOWKER',
                   'BMC',
                   'CAS',
                   'cisti',
                   'CIOS',
                   'CISTI',
                   'CitationManager', 
                   'ContentScan',
                   'CSA',
                   'dbwiz',
                   'DIALOG',
                   'digitool',                 
                   'dra', 
                   'EBSCO',
                   'ebscohost', 
                   'erl', 
                   'FamilyScholar',
                   'EI',
                   'Elsevier',
                   'elsevier.com',
                   'Endeavor',
                   'Entrez',
                   'FirstSearch', 
                   'gale',
                   'Gale',
                   'GEODOK',
                   'GODOTCitationFinder',
                   'Google',                 ## -is this still needed?        
                   'google',
                   'Harmonie',
                   'HWW',
                   'ICPSR',
                   'III',
                   'IOP', 
                   'IOPP',
                   'ISI',
                   'jstor',
                   'LC',
                   'libx',
                   'mimas',
                   'NISC',
                   'openly',
                   'oup',
                   'OUP',  
                   'OVID',
                   'OvidWebspirs',
                   'OvidGateway', 
                   'ProQ',
                   'proquest',
                   'pqil', 
                   'RefPress',
                   'Refworks',
                   'RLG', 
                   'rsc',
                   'SAMPLE',
                   'SFU',
                   'SilverPlatter',
                   'slri',
                   'swets',
                   'SP',
                   'STN',
                   'SFX',
                   'ukoln',
                   'undefined',            ## -libx may send if sid is set to blank
                   'unknown',
                   'UW',
                   'WilsonWeb',
                   'Wiley',
);




use vars qw($PROG_NAME);
$PROG_NAME = 'GODOT';

use vars qw(@ITEM_DB_ARR);
@ITEM_DB_ARR = ('blank', 
                'cisx', 
                'csti', 
                'ecdb', 
                'soul',
                'sfu_iii',
                'umanitoba', 
                'usask',
                'uvic',
                'ucalgary',
                'ualberta',
                'ubc', 
                'utoronto'
);            

use vars qw(@OPENURL_DB_ARR);
@OPENURL_DB_ARR = ('unknown',
                   'asfa',
                   'axiom',
                   'dbwiz',
		   'iopp',
		   'jstor',
                   'matchscinet',
                   'openly',
                   'proquest',
		   'Google',      
		   'Harmonie',
                   'HWW',
                   'Wiley',
                   'pqil',
                   'RefPress',
                   'Refworks',
                   'rsc',
                   'LC',
                   'SilverPlatter',
                  );


use vars qw(%SCREENS);


##
## -screen and subroutines names must match up with those in GODOT_ORIG/hold_tab.pm and in GODOT/CGI.pm
##
## -hash values are default actions for when form is submitted without a button being pushed 
##  (possible when there is only one data entry field on a form -- all user has to do is push enter 
##   and form gets submitted)
##


%SCREENS =     ('no_screen_screen'              => '',
                'main_holdings_screen'          => '',
                'catalogue_screen'              => '',
                'catalogue_interface_screen'    => '',
                'warning_screen'                => '',
                'permission_denied_screen'      => '',
                'article_form_screen'           => '',
                'request_info_screen'           => '',
                'password_screen'               => '',
                'password_error_screen'         => '',
                'check_patron_screen'           => '',  
                'request_form_screen'           => '',
                'request_input_error_screen'    => '',
                'request_confirmation_screen'   => '',
                'request_other_error_screen'    => '',
                'request_acknowledgment_screen' => '',
                'error_screen'                  => '',
		);



1;









