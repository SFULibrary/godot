## GODOTConfig::Config
##
## Copyright Todd Holbrook - Simon Fraser University (2003)
##
## 
##
package GODOTConfig::Config;

use Exception::Class::DBI;
use GODOTConfig::BasicConfig;

use strict;

use vars qw(
	$GODOT_DB_ATTR
	$GODOT_DB_STRING
	@GODOT_DB_CONNECT

        @GODOT_SITE_GROUPS
        @GODOT_ILL_LOCAL_SYSTEM
        @GODOT_REQUEST_MESSAGE_FORMATS
        @GODOT_PATRON_API_CHOICES
        @GODOT_SYSTEM_TYPES

	@GODOT_TEMPLATES
	%GODOT_TEMPLATE_CONFIG

	@GODOT_CSS
	%GODOT_CSS_DESCRIPTIONS

	%GODOT_OPTION_CONFIG
);



$GODOT_DB_STRING = "dbi:Pg:dbname=${GODOT_DB}";
$GODOT_DB_ATTR = { 'PrintError' => 0, 'RaiseError' => 0, 'HandleError' => Exception::Class::DBI->handler() };
@GODOT_DB_CONNECT = ($GODOT_DB_STRING, $GODOT_USER, $GODOT_PASSWORD, $GODOT_DB_ATTR);

@GODOT_SITE_GROUPS = qw(COPPUL ELN COPPUL_AND_ELN OCUL NEOS NOVANET OTHER);
@GODOT_ILL_LOCAL_SYSTEM = qw(AVISO_3 AVISO_4 CISTI GENERIC_SCRIPT OPENILL RSS_FORM RSS_FORM_2);
@GODOT_REQUEST_MESSAGE_FORMATS = qw(CISTI GENERIC_SCRIPT ISO_EMAIL);
@GODOT_PATRON_API_CHOICES = qw(III_HTTP DEFAULT DEFAULT_HTTP);
@GODOT_SYSTEM_TYPES = qw(ALEPH BRS DYNIX ENDEAVOR EPIXTECH GEAC III MULTILIS NOTIS OCLC SIRSI OTHER);


my @DATE_FORMATS = qw(MM/DD/YY 
                      MM-DD-YY 
                      MM/DD/YYYY 
                      MM-DD-YYYY 
                      DD/MM/YY 
                      DD-MM-YY 
                      DD/MM/YYYY 
                      DD-MM-YYYY 
                      YYYYMMDD
                      DDmmmYY 
                      DD-mmm-YY 
                      DDmmmYYYY 
                      DD-mmm-YYYY 
                      YYYYmmmDD 
                      YYYY-mmm-DD 
);

my @DATE_TYPES = qw(non-US US);

my @REQUEST_FORM_FIELDS_CHOICES = qw(N U R);

my @POSITION_ATTRIBS = qw(1 2 3);
my @STRUCTURE_ATTRIBS = qw(1 2 4 5 101);
my @TRUNCATION_ATTRIBS = qw(1 100 101); 
my @COMPLETENESS_ATTRIBS  = qw(1 3);

my @REQUEST_TYPES = qw(N M D I);


%GODOT_TEMPLATE_CONFIG = (

##
## Article Form
##

'article_form_screen' => {
	'description' => '',
	'level' => 3,
	'group' => 'article_form',
	
},
'article_form_text' => {
	'description' => 'Text displayed at the top of the article form screen.',
	'level' => 2,
	'group' => 'article_form',
	'related' => ['config_article_form_text'],
},
'config_article_form_text' => {
	'description' => 'Text displayed at the top of the article form screen.',
	'level' => 1,
	'group' => 'article_form',
	'related' => ['article_form_text'],
},
'config_article_form_fields' => {
	'description' => 'Field names for article fields.',
	'level' => 2,
	'group' => 'article_form',
	'related' => ['article_form_screen'],
},
'config_article_form_title' => {
	'description' => 'Title for the article form page.',
	'level' => 2,
	'group' => 'article_form',
	'related' => ['article_form_screen'],
},


##
## Main
##

'html_header' => {
	'description' => 'Displays the HTML header including page title, CSS links, Javascript, etc.',
	'level' => 2,
	'group' => 'main',
},
'main_layout' => {
	'description' => 'Controls the overall display of the page, including HTML start/end tags.  This template calls the specific screen template to fill in the page for the current action.',
	'level' => 3,
	'related' => ['page_header', 'page_footer', 'sidebar', 'html_header'],
	'group' => 'main',
},
'page_footer' => {
	'description' => 'Displays the page footer wrapped in the default div block.  The actual footer should be set in config_page_footer.',
	'level' => 2,
	'related' => ['config_page_footer'],
	'group' => 'main',
},
'page_header' => {
	'description' => 'Displays the page header wrapped in the default div block.  The actual header should be set in config_page_header.',
	'level' => 2,
	'related' => ['config_page_header'],
	'group' => 'main',
},
'page_title' => {
	'description' => 'Sets the page title based on the current page and config_*_title',
	'level' => 3,
	'related' => ['html_header'],
	'group' => 'main',
},
'sidebar' => {
	'description' => 'Displays a sidebar div block which could be used to integrate a menu or informative side panel.  Currently blank in the default configuration.',
	'level' => 3,
	'group' => 'main',
},
'config_page_header' => {
	'description' => 'Page header for the site.  Your site logo or banner should go here.',
	'level' => 1,
	'related' => ['page_header'],
	'group' => 'main',
},
'config_page_footer' => {
	'description' => 'Page footer for the site.  Copyright, trademark, extra contact information, etc.  The default is to display the GODOT is a COPPUL product message.',
	'level' => 1,
	'related' => ['page_footer'],
	'group' => 'main',
},

##
## Main Holdings
##

'config_auto_req' => {
	'description' => 'Heading and link text for the ILL auto requesting link.',
	'level' => 1,
	'related' => ['main_holdings_auto_req'],
	'group' => 'main_holdings',
},
'config_main_holdings_title' => {
	'description' => 'Title for the main holdings page',
	'level' => 2,
	'group' => 'main_holdings',
	'related' => ['main_holdings_screen'],
},
'config_holdings_text' => {
	'description' => 'Used to display a specific message before the holdings are displayed.  Using the "page.scrno" variable, you can have the message only appear on certain pages.',
	'level' => 1,
	'group' => 'main_holdings',
},
'config_help_url' => {
	'description' => 'A URL to the site\'s local help files.  This is used by the main_holdings_contact_us template by default.',
	'level' => 1,
	'related' => ['main_holdings_contact_us'],
	'group' => 'main_holdings',
},
'config_no_holdings_text' => {
	'description' => 'Four messages which are displayed when holdings are not found for combinations of journal/monograph and database/no database.',
	'level' => 1,
	'related' => ['main_holdings_no_holdings'],
	'group' => 'main_holdings',
},
'config_no_fulltext_available_text' => {
	'description' => 'Message to display when no fulltext holdings are found.  This can be left blank to display nothing.  You can also check whether print holdings were found ("print_available" variable) and modify the message based on that.',
	'level' => 1,
	'related' => ['main_holdings_screen'],
	'group' => 'main_holdings',
},
'main_holdings_command_links' => {
	'description' => 'Currently displays "Back to database", may be used for other advanced links in the future.',
	'level' => 3,
	'group' => 'main_holdings',
},
'main_holdings_cufts' => {
	'description' => 'Displays the fulltext holdings links coming from CUFTS (not 856 links).  A block at the beginning of this template controls the wording of links to various service levels (journal, issue, database, etc.)',
	'level' => 3,
	'related' => ['main_holdings_cufts_url'],
	'group' => 'main_holdings',
},
'main_holdings_cufts_url' => {
	'description' => 'Allows for modifying the URLs used in CUFTS before they\'re displayed.',
	'level' => 3,
	'related' => ['main_holdings_cufts'],
	'group' => 'main_holdings',
},
'main_holdings_preprint' => {
	'description' => 'Displays links to preprint archives (e-print).',
	'level' => 3,
	'group' => 'main_holdings',
},
'main_holdings_show_all' => {
	'description' => 'Displays a link to show more libraries\' holdings.',
	'level' => 3,
	'group' => 'main_holdings',
},
'main_holdings_contact_us' => {
	'description' => 'Displays a link to help, could be used for other contact links',
	'level' => 2,
	'related' => ['config_help_url'],
	'group' => 'main_holdings',
},
'main_holdings_print' => {
	'description' => 'Displays the holdings information with links for requesting and detailed holdings if configured for it',
	'level' => 3,
	'group' => 'main_holdings',
},	
'main_holdings_related_info' => {
	'description' => 'Displays links to other online resources such as Google and Teoma.',
	'level' => 2,
	'group' => 'main_holdings',
},
'main_holdings_ill_form' => {
	'description' => 'Displays a link to place an ILL request not directed to a specific library',
	'level' => 3,
	'group' => 'main_holdings',
},
'main_holdings_screen' => {
	'description' => 'Displays the main holdings screen, including citation, fulltext, print holdings, related information, etc.  You can adjust this template to change what order things display in.',
	'level' => 2,
	'related' => ['citation_display', 'main_holdings_search_messages', 'config_holdings_text', 'main_holdings_cufts', 'main_holdings_marc_856', 'main_holdings_preprint', 'config_no_fulltext_available_text', 'main_holdings_no_holdings', 'main_holdings_search_all', 'main_holdings_show_all', 'main_holdings_scrno', 'main_holdings_ill_form', 'main_holdings_auto_req', 'main_holdings_related_info', 'main_holdings_cm', 'main_holdings_contact_us', 'main_holdings_command_links'],
	'group' => 'main_holdings',
},
'main_holdings_items' => {
	'description' => 'Utility template for creating lists with optional hidden sections.  Used by main_holdings_cufts, main_holdings_print, etc.',
	'level' => 3,
	'group' => 'main_holdings',
},
'main_holdings_auto_req' => {
	'description' => 'Displays a link to place an ILL request if autorequesting is turned on.  Uses config_auto_req to control wording.',
	'level' => 3,
	'related' => ['config_auto_req'],
	'group' => 'main_holdings',
},
'main_holdings_marc_856' => {
	'description' => 'Displays links to journals generated from 856 fields.',
	'level' => 3,
	'group' => 'main_holdings',
},
'main_holdings_scrno' => {
	'description' => 'Used to move to the next stage (screen) of searching.',
	'level' => 3,
	'group' => 'main_holdings',
},
'main_holdings_cm' => {
	'description' => 'Soon to be obsolete. Change to main_holdings_citation_capture. Displays a link to export the citation to Citation Manager. This can be turned off using the configuration options rather than editing a template.  ',
	'level' => 3,
	'group' => 'main_holdings',
},
'main_holdings_citation_capture' => {
	'description' => 'Citation capture links. This can be turned off using the configuration options rather than editing a template.',
	'level' => 3,
	'group' => 'main_holdings',
},
'main_holdings_cm_link' => {
	'description' => 'Constructs a link to export the citation to Citation Manager.',
	'level' => 3,
	'group' => 'main_holdings',
},
'main_holdings_refworks' => {
	'description' => 'Constructs a link to export the citation to RefWorks.',
	'level' => 3,
	'group' => 'main_holdings',
},
'config_main_holdings_refworks' => {
	'description' => 'Configuration (link name, proxy) for link to RefWorks.',
	'level' => 3,
	'group' => 'main_holdings',
},
'main_holdings_no_holdings' => {
	'description' => 'Displays text when there is no print holdings information found.',
	'level' => 3,
	'related' => ['config_no_holdings_text'],
	'group' => 'main_holdings',
},
'main_holdings_search_all' => {
	'description' => 'Displays a link to continue searching libraries for holdings if the search stopped after finding the minimum number.',
	'level' => 3,
	'group' => 'main_holdings',
},
'main_holdings_search_messages' => {
	'description' => 'Displays the GODOT searching messages if full display is on, otherwise it just displays any errors which may have occured (such as being unable to connect to a catalogue).',
	'level' => 3,
	'group' => 'main_holdings',
},
'catalogue_screen' => {
	'description' => 'Displays detailed catalogue holdings for a specific site',
	'level' => 3,
	'group' => 'main_holdings',
	'related' => ['catalogue_print', 'main_holdings_no_holdings', 'main_holdings_contact_us', 'citation_display', 'main_holdings_command_links'],
},
'catalogue_print' => {
	'description' => 'Displays the detailed holdings on the catalogue screen with a request link',
	'level' => 3,
	'group' => 'main_holdings',
	'related' => ['catalogue_screen'],
},
'config_catalogue_title' => {
	'description' => 'Title for the detailed holdings catalogue screen',
	'level' => 2,
	'group' => 'main_holdings',
	'related' => ['catalogue_screen'],
},

##
## Miscellaneous
##

'config_back_to_database' => {
	'description' => 'Text to display for the "Back to Database" link',
	'level' => 1,
	'group' => 'misc',
},
'config_skip_if_no_holdings_text' => {
	'description' => 'Text to display if the "If there are no holdings, then just skip to the next screen" option is enabled',
	'level' => 1,
	'group' => 'misc',
},
'citation_display' => {
	'description' => 'Displays the block containing the citation information.  Formatting for authors, date, etc. is done here.',
	'level' => 2,
	'group' => 'misc',
},
'setup_variables' => {
	'description' => 'Utility template that sets a bunch of useful variables like "fulltext_available" and "print_available".',
	'level' => 3,
	'group' => 'misc',
},
'error_screen' => {
	'description' => 'Displays error messages.',
	'level' => 2,
	'group' => 'misc',
},	
'config_error_title' => {
	'description' => 'Title for the error screen page',
	'level' => 2,
	'group' => 'misc',
	'related' => ['error_screen'],
},
'skipped_main' => {
	'description' => 'Displays a message if a main holdings page was skipped (??)',
	'level' => 2,
	'group' => 'misc',
	'related' => ['skipped_main_auto_req', 'skipped_main_no_holdings'],
},
'skipped_main_auto_req' => {
	'description' => 'Displays a message if a main holdings page was skipped during an auto-request (??)',
	'level' => 2,
	'group' => 'misc',
	'related' => ['skipped_main'],
},
'skipped_main_no_holdings' => {
	'description' => 'Displays a message if a main holdings page was skipped and no holdings were found (??)',
	'level' => 2,
	'group' => 'misc',
	'related' => ['skipped_main'],
},
'form_element' => {
	'description' => 'Helper template for display form input fields',
	'level' => 3,
	'group' => 'misc',
},

##
## Password screen
##

'password_screen' => {	
	'description' => 'Prompts for a password for DocDirect style requesting.',
	'level' => 3,
	'group' => 'password',
},
'config_password_title' => {	
	'description' => 'Title for the password prompting screen',
	'level' => 2,
	'group' => 'password',
	'related' => ['password_screen'],
},
'password_error_screen' => {	
	'description' => 'Reports an error if the DocDirect password is incorrect.',
	'level' => 3,
	'group' => 'password',
},
'config_password_error_title' => {	
	'description' => 'Title for the password error screen',
	'level' => 2,
	'group' => 'password',
	'related' => ['password_error_screen'],
},

##
## Patron information
##

'request_form_screen' => {
	'description' => 'Gather patron information.',
	'level' => 3,
	'group' => 'patron',
	'related' => ['config_request_form_fields', 'get_form_element_info', 'skipped_main', 'request_form_text', 'citation_display'],
},
'request_form_text' => {
	'description' => 'Displays text before patron information form',
	'level' => 2,
	'group' => 'patron',
	'related' => ['config_request_form_local_text', 'config_request_form_text'],
},
'config_request_form_fields' => {
	'description' => 'Labels for patron fields.',
	'level' => 1,
	'group' => 'patron',
	'related' => ['request_form_screen'],
},
'config_request_form_text' => {
	'description' => 'Text displayed before patron information form',
	'level' => 1,
	'group' => 'patron',
	'related' => ['config_request_form_local_text', 'request_form_text'],
},
'config_request_form_title' => {
	'description' => 'Title for the patron information screen',
	'level' => 1,
	'group' => 'patron',
	'related' => ['request_form_screen'],
},
'config_request_form_local_text' => {
	'description' => 'Text displayed before patron information form for new/mediate/retrieval requests',
	'level' => 1,
	'group' => 'patron',
	'related' => ['config_request_form_text', 'request_form_text'],
},
'check_patron_screen' => {
	'description' => 'Patron barcode and PIN screen',
	'level' => 3,
	'group' => 'patron',
	'related' => ['config_request_form_fields', 'config_check_patron_text'],
},
'config_check_patron_text' => {
	'description' => 'Text to display before patron barcode and PIN form.',
	'level' => 1,
	'group' => 'patron',
	'related' => ['check_patron_screen'],
},
'config_check_patron_title' => {
	'description' => 'Title for check_patron screen.',
	'level' => 2,
	'group' => 'patron',
	'related' => ['check_patron_screen'],
},
'check_patron_error_screen' => {
	'description' => 'Displays an error if the patron is not allowed to submit a request.',
	'level' => 3,
	'group' => 'patron',
	'related' => ['config_bad_patron_message'],
},
'config_check_patron_error_title' => {
	'description' => 'Title for check_patron_error screen.',
	'level' => 2,
	'group' => 'patron',
	'related' => ['check_patron_error_screen'],
},
'config_bad_patron_message' => {
	'description' => 'Message to display when the patron is not allowed to submit a request',
	'level' => 1,
	'group' => 'patron',
	'related' => ['check_patron_error_screen'],
},
'request_input_error_screen' => {
	'description' => 'Informs the patron of data missing from their patron information',
	'level' => 3,
	'group' => 'patron',
},
'config_request_input_error_screen' => {
	'description' => 'Title for the input error screen',
	'level' => 2,
	'group' => 'patron',
},
'request_other_error_screen' => {
	'description' => 'Informs the patron of an error placing their request',
	'level' => 3,
	'group' => 'patron',
},
'config_request_input_error_screen' => {
	'description' => 'Title for the request error screen',
	'level' => 2,
	'group' => 'patron',
},

##
## Request screens
##

'permission_denied_screen' => {
	'description' => 'Displays a screen showing limits on borrowing when no holdings have been found.',
	'level' => 3,
	'group' => 'request',
	'related' => ['config_permission_denied_title'],
},
'config_permission_denied_title' => {
	'description' => 'Title for the permission denied screen',
	'level' => 2,
	'group' => 'request',
	'related' => ['permission_denied_screen'],
},
'request_acknowledgment_screen' => {
	'description' => 'Displays a screen acknowledging that the request has been placed.',
	'level' => 3,
	'group' => 'request',
	'related' => ['request_acknowledgment_text', 'config_acknowledgment_title'],
},
'request_acknowledgment_text' => {
	'description' => 'Displays text for acknowledging that the request has been placed.',
	'level' => 2,
	'group' => 'request',
	'related' => ['request_acknowledgment_screen', 'config_acknowledgment_text', 'config_acknowledgment_local_text'],
},
'config_acknowledgment_text' => {
	'description' => 'Text acknowledging that the request has been placed.',
	'level' => 1,
	'group' => 'request',
	'related' => ['request_acknowledgment_screen', 'request_acknowledgment_text', 'config_acknowledgment_local_text'],
},
'config_acknowledgment_local_text' => {
	'description' => 'Text acknowledging that the request has been placed when there are local holdings (defaults to config_acknowledgment_text).',
	'level' => 1,
	'group' => 'request',
	'related' => ['request_acknowledgment_screen', 'request_acknowledgment_text', 'config_acknowledgment_text'],
},
'config_request_acknowledgment_title' => {
	'description' => 'Title for the request acknowledgment screen',
	'level' => 2,
	'group' => 'request',
	'related' => ['request_acknowledgment_screen', 'request_acknowledgment_text', 'config_acknowledgment_local_text'],
},
'request_confirmation_screen' => {
	'description' => 'Displays a screen asking for final confirmation before placing the request.',
	'level' => 3,
	'group' => 'request',
	'related' => ['request_confirmation_text', 'config_confirmation_title'],
},
'request_confirmation_text' => {
	'description' => 'Displays text asking for final confirmation before placing the request.',
	'level' => 2,
	'group' => 'request',
	'related' => ['request_confirmation_screen', 'config_confirmation_text', 'config_confirmation_local_text'],
},
'config_confirmation_text' => {
	'description' => 'Text confirming the patron wishes to place the request.',
	'level' => 1,
	'group' => 'request',
	'related' => ['request_confirmation_screen', 'request_confirmation_text', 'config_confirmation_local_text'],
},
'config_confirmation_local_text' => {
	'description' => 'Text confirming the patron wishes to place the request when there are local holdings (defaults to config_confirmation_text).',
	'level' => 1,
	'group' => 'request',
	'related' => ['request_confirmation_screen', 'request_confirmation_text', 'config_confirmation_text'],
},
'config_request_confirmation_title' => {
	'description' => 'Title for the request confirmation screen',
	'level' => 2,
	'group' => 'request',
	'related' => ['request_confirmation_screen'],
},
'request_info_screen' => {
	'description' => 'Screen displayed when the request type is for "Information Only" (I)',
	'level' => 3,
	'group' => 'request',
	'related' => ['request_info_text', 'config_info_title'],
},
'request_info_text' => {
	'description' => 'Displays text when the request type is for "Information Only" (I)',
	'level' => 2,
	'group' => 'request',
	'related' => ['request_info_screen', 'config_request_info_text', 'config_request_mono_info_text'],
},
'config_request_info_text' => {
	'description' => 'Text displayed for journals when the request type is for "Information Only" (I)',
	'level' => 1,
	'group' => 'request',
},
'skipped_main' => {
	'description' => 'Displays a message if a main holdings page was skipped (??)',
	'level' => 2,
	'group' => 'misc',
	'related' => ['skipped_main_auto_req', 'skipped_main_no_holdings'],
},

##
## Warning screen
##

'warning_screen' => {
	'description' => '"Your library has holdings" warning screen for ILL requests where local holdings have been found',
	'level' => 3,
	'related' => ['config_warning_title', 'config_your_library_has_warning_text'],
	'group' => 'warning',
},
'config_warning_title' => {
	'description' => '"Your library has holdings" warning title for page.',
	'level' => 2,
	'related' => ['config_warning_title', 'config_your_library_has_warning_text'],
	'group' => 'warning',
},
'config_your_library_has_warning_text' => {
	'description' => '"Your library has holdings" warning text.',
	'level' => 1,
	'related' => ['config_warning_title', 'config_your_library_has_warning_text'],
	'group' => 'warning',
},


);	

@GODOT_TEMPLATES = keys(%GODOT_TEMPLATE_CONFIG);

@GODOT_CSS = qw(
	godot.css
);

%GODOT_CSS_DESCRIPTIONS = (
	'godot.css' => 'Main GODOT Cascading Style Sheet',
);

#
# (23-mar-2005)
#
# Contains the following information for the fields listed:
#
#      type:          possible values: LIST          
#      required:      is a value required?
#      verification:  routine to check for a valid value and possibly change/filter it
#      choices:       list of the possible values? (if the default is not given, the first value in the list 
#                     is assumed to be the default) 
#      default:       the default value
#
# NB:  Only options that have values for these fields are listed.  For a complete list of options, see lib/GODOT/Sites.pm.
#

%GODOT_OPTION_CONFIG = (

	'display_citation_capture_links' => {
                'verification' => 'boolean_default_false',
	},
	'display_command_links' => {
                'verification' => 'boolean_default_false',
	},
	'display_related_info_links' => {
                'verification' => 'boolean_default_false',
	},
	'expand_fulltext_by_default' => {
                'verification' => 'boolean_default_false',
	},
	'expand_holdings_by_default' => {
                'verification' => 'boolean_default_false',
	},
        'parallel_server_msg' => {
                'verification' => 'boolean_default_false',
	},
        'skip_main_holdings_screen_if_no_holdings' => {
                'verification' => 'boolean_default_false',
	},
        'use_request_confirmation_screen' => {
                'verification' => 'boolean_default_false',
	},
        'use_request_acknowledgment_screen' => {
                'verification' => 'boolean_default_false',
	},
        'request_form_date_type' => {
                'choices' => [@DATE_TYPES]
	},
        'ill_local_system_date_format' => {
                'choices' => ['', @DATE_FORMATS]
	},
        'request_msg_fmt' => {
                'choices' => ['', @GODOT_REQUEST_MESSAGE_FORMATS]
	},		  
        'request_msg_date_format' => {
                'choices' => ['', @DATE_FORMATS]
	},		  		  
	'abbrev_name' => {
                'required' => 1
        },
        'ill_nuc'=> {
                'required' => 1
        },
        'group' => {
                'required' => 1,
                'choices' => ['', @GODOT_SITE_GROUPS]                
        },        
	'use_javascript'  => {
                'verification' => 'boolean_default_true',
	},

       	'auto_req'   => {
                'verification' => 'boolean_default_false',
	},

       	'auto_req_non_journal'   => {
                'verification' => 'boolean_default_false',
	},

	'rank' => { 
                'type'    => 'LIST',
                'choices' => [['rank_site',     'ALL_SITES'], 
                              ['display_group', ['', 1 .. 10]], 
                              ['search_group',  ['', 1 .. 10]],
                              ['auto_req',      ['show', '']]] 
        },

	'other_rank'    => {
                'verification' => 'boolean_default_false',
	},
	'other_rank_display_group' => {
                'choices' => ['', qw(1 2 3 4 5 6 7 8 9 10)],                
	},
	'other_rank_search_group' => {
                'choices' => ['', qw(1 2 3 4 5 6 7 8 9 10)],
	},
	'other_auto_req_show'=> {
                'verification' => 'boolean_default_false',
	},
	'rank_non_journal' => {
                'type'    => 'LIST', 
                'choices' => [['rank_site',     'ALL_SITES'],
                              ['display_group', ['', 1 .. 10]],
                              ['search_group',  ['', 1 .. 10]],
                              ['auto_req',      ['show', '']]]
        },
	'other_rank_non_journal'   => {
                'verification' => 'boolean_default_false',
	},
        'other_rank_non_journal_display_group'  => {
                'choices' => ['', qw(1 2 3 4 5 6 7 8 9 10)],
	},
        'other_rank_non_journal_search_group' => {
                'choices' => ['', qw(1 2 3 4 5 6 7 8 9 10)],
	},
	'other_auto_req_show_non_journal'=> {
                'verification' => 'boolean_default_false'
	},
	'eric_coll_avail' => {
                'choices' => [qw(T F T_IF_FULLTEXT_LINK)],
                'default' => qw(F)
	},
	'mlog_coll_avail' => {
                'verification' => 'boolean_default_false',
	},                        
        'ill_local_system' => {
                'required' => 1, 
                'choices'  => ['', @GODOT_ILL_LOCAL_SYSTEM]
        },
	'ill_local_system_email' => {
                'required' => 1,
	},
	'ill_copy_to_local_system' => {
                'verification' => 'boolean_default_true',
	},

        'ill_account'  => {
                'type'    => 'LIST',
                'choices' => [['account_site', 'ALL_SITES'],
                              ['number',       '']]
        },
	'holdings_list' => {
                'verification' => 'boolean_default_false',
	},
	'include_fulltext_as_holdings' => {
                'verification' => 'boolean_default_false',
	},
        'blocking'=> {
                'choices' => [qw(T F F_MEDIATED F_MEDIATED_NO_WARNING F_WARNING)],
                'default' => qw(F) 
	},
        'no_holdings_req' => {
                'verification' => 'boolean_default_false',
	},
	'no_holdings_req_non_journal' => {
                'verification' => 'boolean_default_false',
	},
	'ill_req_form' =>  {
                'choices' => [qw(T T_NO_REQ_AVAIL F)],
                'default' => qw(F)
	}, 
        'ill_req_form_non_journal' =>  {
                'choices' => [qw(T T_NO_REQ_AVAIL F)],
                'default' => qw(F)
        },  

        'ill_req_form_limit'  => {
                'type'    => 'LIST', 
                'choices' => [['patron_type', ''],
                              ['message', '']]
        },
        'request'  => {
                'type'    => 'LIST',
                'choices' => [['rank_site',  'ALL_SITES'],
                              ['type',       [@REQUEST_TYPES]]]
        },
	'other_request' => {
                'choices' => [@REQUEST_TYPES],
                'default' => qw(N)
        },
        'request_non_journal'  => {
                'type'    => 'LIST',
                'choices' => [['rank_site',  'ALL_SITES'],
                              ['type',       [@REQUEST_TYPES]]]
        }, 
	'other_request_non_journal' => {
                'choices' => [@REQUEST_TYPES],
                'default' => qw(N)
	},
        ill_email_ack_msg => {
                'verification' => 'boolean_default_false'
	},
	'lend' => {
                'verification' => 'boolean_default_false'
        },
	'same_nuc_email' => {
                'choices' => [qw(N L R)],
	},
	'ill_cache_patron_info' => {
                'verification' => 'boolean_default_false'
	},
	'skip_required_if_password' => {
                'verification' => 'boolean_default_false'
	},
	'patr_last_name' => {
                'choices' => [@REQUEST_FORM_FIELDS_CHOICES]
	},
	'patr_first_name' => {
                'choices' => [@REQUEST_FORM_FIELDS_CHOICES]
	},
	'patr_library_id' => {
                'choices' => [@REQUEST_FORM_FIELDS_CHOICES]
	},
	'patr_patron_type' => {
                'choices' => [@REQUEST_FORM_FIELDS_CHOICES]
	},
	'patr_patron_type_edit_allowed' => {
                'verification' => 'boolean_default_false'
	},
	'patr_patron_type_disp' => {
                'verification' => 'boolean_default_false'
	},

        'patr_patron_type_choice'  => {
                'type'    => 'LIST',
                'choices' => [['type', '']]
        },

	'patr_not_req_after'=> {
                'choices' => [@REQUEST_FORM_FIELDS_CHOICES]
	},
	'patr_prov'=> {
                'choices' => [@REQUEST_FORM_FIELDS_CHOICES]
	},
	'patr_department' => {
                'choices' => [@REQUEST_FORM_FIELDS_CHOICES]
	},
	'patr_department_choice' => {
                'type'    => 'LIST',
                'choices' => [['department', '']]
        },
	'patr_patron_email' => {
                'choices' => [@REQUEST_FORM_FIELDS_CHOICES]
	},
	'patr_pickup'=> {
                'choices' => [@REQUEST_FORM_FIELDS_CHOICES]
	},

        'patr_pickup_choice'  => {
                'type'    => 'LIST',
                'choices' => [['location', '']]
        },
	'patr_phone' => {
                'choices' => [@REQUEST_FORM_FIELDS_CHOICES]
	},
        'patr_phone_work' => {
                'choices' => [@REQUEST_FORM_FIELDS_CHOICES]
        },
	'patr_building' => {
                'choices' => [@REQUEST_FORM_FIELDS_CHOICES]
	},
	'patr_patron_noti' => {
                'choices' => [@REQUEST_FORM_FIELDS_CHOICES]
	},
	'patr_street' => {
                'choices' => [@REQUEST_FORM_FIELDS_CHOICES]
	},
	'patr_city' => {
                'choices' => [@REQUEST_FORM_FIELDS_CHOICES]
	},
	'patr_postal_code' => {
                'choices' => [@REQUEST_FORM_FIELDS_CHOICES]
	},
	'patr_rush_req' => {
                'choices' => [@REQUEST_FORM_FIELDS_CHOICES]
	},
	'patr_paid' => {
                'choices' => [@REQUEST_FORM_FIELDS_CHOICES]
	},

        'patr_paid_choice'  => {
                'type'    => 'LIST',
                'choices' => [['payment_method', ''], 
                              ['input_box',      'BOOLEAN']]
        },

	'patr_account_no' => {
                'choices' => [@REQUEST_FORM_FIELDS_CHOICES]
	},

	'patr_note' => {
                'choices' => [@REQUEST_FORM_FIELDS_CHOICES]
        },

        'use_patron_api'  => {
                'verification' => 'boolean_default_false'
	},
        'patron_api_type' => {
                'choices' => ['', @GODOT_PATRON_API_CHOICES]
	},
	'patron_need_pin' => {
                'verification' => 'boolean_default_false'
	},
	'password_needed' => {
                'choices' => ['', qw(ALL JOURNAL MONO)],
        },
	'use_blank_citation_form' => {
                'verification' => 'boolean_default_false'
	},
	'use_856_links' => {
                'verification' => 'boolean_default_false'
	},
	'system_type' => {
                'choices' => ['', @GODOT_SYSTEM_TYPES]
	},
	'use_z3950' => {
                'verification' => 'boolean_default_false'
	},
	'zsysid_search_avail' => {
                'verification' => 'boolean_default_false'
	},

	'zuse_att_sysid' => { 
                #### 'verification' => ,
        },
        'zuse_att_isbn' => { 
                #### 'verification' => ,
        },
        'zuse_att_issn' => { 
                #### 'verification' => ,
        },
        'zuse_att_title' => { 
                #### 'verification' => ,
        },
        'zuse_att_journal_title' => { 
                #### 'verification' => ,
        },

	'zpos_att_sw_title' => {
                'choices' => ['', @POSITION_ATTRIBS]
	},
	'zstruct_att_sw_title' => {
                'choices' => ['', @STRUCTURE_ATTRIBS]
	},
        'ztrunc_att_sw_title' => {
                'choices' => ['', @TRUNCATION_ATTRIBS]
	},
        'zcompl_att_sw_title' => {
                'choices' => ['', @COMPLETENESS_ATTRIBS]
	},

        'zpos_att_title' => {
                'choices' => ['', @POSITION_ATTRIBS]
	},
	'zstruct_att_title' => {
                'choices' => ['', @STRUCTURE_ATTRIBS]
	},
        'ztrunc_att_title' => {
                'choices' => ['', @TRUNCATION_ATTRIBS]
	},
        'zcompl_att_title' => {
                'choices' => ['', @COMPLETENESS_ATTRIBS]
	},


        'zpos_att_sw_journal_title' => {
                'choices' => ['', @POSITION_ATTRIBS]
	},
	'zstruct_att_sw_journal_title'=> {
                'choices' => ['', @STRUCTURE_ATTRIBS]
	},
        'ztrunc_att_sw_journal_title' => {
                'choices' => ['', @TRUNCATION_ATTRIBS]
	},
        'zcompl_att_sw_journal_title' => {
                'choices' => ['', @COMPLETENESS_ATTRIBS]
	},


        'zpos_att_journal_title' => {
                'choices' => ['', @POSITION_ATTRIBS]        
	},
	'zstruct_att_journal_title'=> {
                'choices' => ['', @STRUCTURE_ATTRIBS]
	},
        'ztrunc_att_journal_title' => {
                'choices' => ['', @TRUNCATION_ATTRIBS]
	},
        'zcompl_att_journal_title' => {
                'choices' => ['', @COMPLETENESS_ATTRIBS]
	},

	'strip_apostrophe_s'  => {
                'verification' => 'boolean_default_false'
	},        
	'disable_journal_details'  => {
                'verification' => 'boolean_default_false'
	},
	'disable_non_journal_details'  => {
                'verification' => 'boolean_default_false'
	},      
	'use_fulltext_links'  => {
                'verification' => 'boolean_default_false'
	},
        ##
        ## (09-nov-2005 kl)
        ##
	'use_site_holdings' => {
                'verification' => 'boolean_default_false'
	},
	'disable_holdings_statement_display' => {
                'verification' => 'boolean_default_false'
	},
	'disable_item_and_circulation_display' => {
                'verification' => 'boolean_default_false'
	},
);



1;
