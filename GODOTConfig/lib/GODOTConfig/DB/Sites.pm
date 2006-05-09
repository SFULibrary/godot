#
# Copyright Todd Holbrook, Simon Fraser University (2003)
#

package GODOTConfig::DB::Sites;
use base 'GODOTConfig::DB::DBI';

use GODOT::Debug;

use GODOTConfig::DB::Accounts_Sites;
use GODOTConfig::DB::Site_Chains;
use GODOTConfig::DB::Site_Config;

use GODOTConfig::DB::Config_Ill_Account;
use GODOTConfig::DB::Config_Ill_Req_Form_Limit;

use GODOTConfig::DB::Config_Patr_Department_Choice;
use GODOTConfig::DB::Config_Patr_Paid_Choice;
use GODOTConfig::DB::Config_Patr_Patron_Type_Choice;
use GODOTConfig::DB::Config_Patr_Pickup_Choice;

use GODOTConfig::DB::Config_Rank;
use GODOTConfig::DB::Config_Rank_Non_Journal;

use GODOTConfig::DB::Config_Request;
use GODOTConfig::DB::Config_Request_Non_Journal;


use Class::DBI::Relationship::HasDetails;

use strict;


__PACKAGE__->table('sites');

__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
	id
	key
	name
	email
	active
	created
	modified
));           
                                                                                             
__PACKAGE__->columns(Essential => __PACKAGE__->columns);

__PACKAGE__->sequence('sites_id_seq');

__PACKAGE__->has_many('accounts', ['GODOTConfig::DB::Accounts_Sites' => 'account'], 'site');
__PACKAGE__->has_many('chains' => 'GODOTConfig::DB::Site_Chains', 'site');

__PACKAGE__->has_many('ill_account'             => 'GODOTConfig::DB::Config_Ill_Account', 'site', {'order_by' => 'rank'});
__PACKAGE__->has_many('ill_req_form_limit'      => 'GODOTConfig::DB::Config_Ill_Req_Form_Limit', 'site', {'order_by' => 'rank'});

__PACKAGE__->has_many('patr_department_choice'  => 'GODOTConfig::DB::Config_Patr_Department_Choice', 'site', {'order_by' => 'rank'});
__PACKAGE__->has_many('patr_paid_choice'        => 'GODOTConfig::DB::Config_Patr_Paid_Choice', 'site', {'order_by' => 'rank'});

__PACKAGE__->has_many('patr_patron_type_choice' => 'GODOTConfig::DB::Config_Patr_Patron_Type_Choice', 'site', {'order_by' => 'rank'});
__PACKAGE__->has_many('patr_pickup_choice'      => 'GODOTConfig::DB::Config_Patr_Pickup_Choice', 'site', {'order_by' => 'rank'});

__PACKAGE__->has_many('rank'             => 'GODOTConfig::DB::Config_Rank', 'site', {'order_by' => 'rank'});
__PACKAGE__->has_many('rank_non_journal' => 'GODOTConfig::DB::Config_Rank_Non_Journal', 'site', {'order_by' => 'rank'});

__PACKAGE__->has_many('request'             => 'GODOTConfig::DB::Config_Request', 'site', {'order_by' => 'rank'});
__PACKAGE__->has_many('request_non_journal' => 'GODOTConfig::DB::Config_Request_Non_Journal', 'site', {'order_by' => 'rank'});

sub config_has_many {
        return(qw(rank 
                  rank_non_journal 
                  request 
                  request_non_journal 
                  patr_patron_type_choice
                  patr_pickup_choice
                  ill_req_form_limit
                  patr_paid_choice
                  ill_account
                  patr_department_choice));
}

__PACKAGE__->has_details('config', 'GODOTConfig::DB::Site_Config' => 'site');

__PACKAGE__->config_columns(qw(

	display_citation_capture_links
	display_command_links
	display_related_info_links
	expand_fulltext_by_default
	expand_holdings_by_default      

        parallel_server_msg

        skip_main_holdings_screen_if_no_holdings
        use_request_confirmation_screen
        use_request_acknowledgment_screen

        request_form_date_type
        ill_local_system_date_format
        request_msg_date_format
		  
	abbrev_name
        ill_nuc
        group
        ill_fax
        openurl_cookie_pusher_image
        use_javascript
        contact
        
        error_not_parseable

        auto_req
        other_rank
        other_rank_display_group
        other_rank_search_group
        other_auto_req_show
        
        auto_req_non_journal
        other_rank_non_journal
        other_rank_non_journal_display_group
        other_rank_non_journal_search_group
        other_auto_req_show_non_journal

        eric_coll_avail
        eric_coll_text
        mlog_coll_avail
        mlog_coll_text
                        
        link_from_cat_name
        link_name

        from_name
        from_email
 
        ill_local_system
        ill_local_system_host
        ill_local_system_email
        ill_copy_to_local_system
        ill_id
        ill_max_cost
 
        holdings_list
        blocking_holdings
        include_fulltext_as_holdings
	blocking

        no_holdings_req
        no_holdings_req_non_journal

        ill_req_form
        ill_req_form_non_journal

        ill_req_form_limit_text

        other_request
        other_request_non_journal

        ill_email_ack_msg

        lend
        request_msg_fmt
        request_msg_email
        same_nuc_email

        ill_cache_patron_info
        skip_required_if_password

        patr_last_name
        patr_first_name
        patr_library_id
        patr_library_id_def
        patr_patron_type
        patr_patron_type_edit_allowed
        patr_patron_type_disp
        patr_not_req_after
        patr_prov
        patr_department
        patr_patron_email
        patron_email_pattern
        patron_email_no_match_text
        patr_pickup
        patr_phone
        patr_phone_work
        patr_building
        patr_patron_noti
        patr_street
        patr_city
        patr_postal_code
        patr_rush_req
        patr_paid
        patr_account_no
        patr_note
        patr_fine_limit

        use_patron_api
        patron_api_type
        patron_api_host
        patron_api_port
        patron_need_pin

        password_needed
        password_value

        use_blank_citation_form
        use_856_links

        system_type
        
        use_z3950
        zhost
        zport
        zdbase
        zid
        zpassword
        zsysid_search_avail

        zuse_att_sysid
        zuse_att_isbn
        zuse_att_issn
        zuse_att_title
        zuse_att_journal_title

        zpos_att_sw_title
        zstruct_att_sw_title
        ztrunc_att_sw_title
        zcompl_att_sw_title

        zpos_att_title
        zstruct_att_title
        ztrunc_att_title
        zcompl_att_title

        zpos_att_sw_journal_title
        zstruct_att_sw_journal_title
        ztrunc_att_sw_journal_title
        zcompl_att_sw_journal_title

        zpos_att_journal_title
        zstruct_att_journal_title
        ztrunc_att_journal_title
        zcompl_att_journal_title

        strip_apostrophe_s
        
        disable_journal_details
        disable_non_journal_details
      
        use_fulltext_links

        source_name    
        ill_email_ack_msg_text

        use_site_holdings
        disable_holdings_statement_display
        disable_item_and_circulation_display
        catalogue_source_journal
        catalogue_source_non_journal
        catalogue_source_default

));


sub all_config_options {
    my($class) = @_;
    return ($class->config_has_many, $class->config_columns); 
}

    
1;










