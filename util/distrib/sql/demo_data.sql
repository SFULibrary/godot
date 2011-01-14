INSERT INTO accounts (key, name, email, phone, password, administrator) VALUES ('admin', 'Default Administrator', '', '', 'adx5P1MEHU372', true);

INSERT INTO sites (key, name, active) values ('AEU',       'University of Alberta',                      true);
INSERT INTO sites (key, name, active) values ('BVAS',      'Simon Fraser University',                    true);
INSERT INTO sites (key, name, active) values ('BVASB',     'Simon Fraser University - Belzberg',         true);
INSERT INTO sites (key, name, active) values ('BVASS',     'Simon Fraser University - Surrey',           true);
INSERT INTO sites (key, name, active) values ('BVIV',      'University of Victoria',                     true);
INSERT INTO sites (key, name, active) values ('BVAU',      'University of British Columbia',             true);
INSERT INTO sites (key, name, active) values ('BVAU-KRNR', 'University of British Columbia - Koerner',   true);
INSERT INTO sites (key, name, active) values ('BVAU-EL',   'University of British Columbia - Education', true);
INSERT INTO sites (key, name, active) values ('MWUC',      'University of Winnipeg',                     true);

INSERT INTO site_chains (site, rank, chain) values (3, 1, 2);
INSERT INTO site_chains (site, rank, chain) values (4, 1, 2);

INSERT INTO site_config (site, field, value) values (2, 'display_related_info_links', '1');
INSERT INTO site_config (site, field, value) values (2, 'display_command_links', '1');
INSERT INTO site_config (site, field, value) values (2, 'expand_fulltext_by_default', '0');
INSERT INTO site_config (site, field, value) values (2, 'display_citation_capture_links', '1');
INSERT INTO site_config (site, field, value) values (2, 'expand_holdings_by_default', '0');
INSERT INTO site_config (site, field, value) values (2, 'patr_building', 'N');
INSERT INTO site_config (site, field, value) values (2, 'patr_patron_noti', 'N');
INSERT INTO site_config (site, field, value) values (2, 'ill_fax', '(604) 291-4908');
INSERT INTO site_config (site, field, value) values (2, 'ill_copy_to_local_system', '1');
INSERT INTO site_config (site, field, value) values (2, 'ill_cache_patron_info', '1');
INSERT INTO site_config (site, field, value) values (2, 'group', 'COPPUL_AND_ELN');
INSERT INTO site_config (site, field, value) values (2, 'from_name', 'Interlibrary Loans');
INSERT INTO site_config (site, field, value) values (2, 'from_email', 'klong@sfu.ca');
INSERT INTO site_config (site, field, value) values (2, 'patr_note', 'U');
INSERT INTO site_config (site, field, value) values (2, 'ill_email_ack_msg', '1');
INSERT INTO site_config (site, field, value) values (2, 'ill_email_ack_msg_text', 'This confirms that your Interlibrary Loan request has been placed successfully.');
INSERT INTO site_config (site, field, value) values (2, 'error_not_parseable', 'The holdings/requesting option for this database is currently under development.');
INSERT INTO site_config (site, field, value) values (2, 'system_type', 'III');
INSERT INTO site_config (site, field, value) values (2, 'use_z3950', '1');
INSERT INTO site_config (site, field, value) values (2, 'same_nuc_email', 'R');
INSERT INTO site_config (site, field, value) values (2, 'no_holdings_req', '1');
INSERT INTO site_config (site, field, value) values (2, 'other_request', 'D');
INSERT INTO site_config (site, field, value) values (2, 'eric_coll_avail', 'T');
INSERT INTO site_config (site, field, value) values (2, 'eric_coll_text', 'Most post 1990 ERIC documents are available online at no cost to SFU students and faculty 
through ERIC (EBSCO) or ERIC (CSA). Members of the general public can access these documents 
at the US government website at http://www.eric.ed.gov/
 
Microfiche copies of pre 1990 documents can be obtained through Interlibrary Loans.');
INSERT INTO site_config (site, field, value) values (2, 'mlog_coll_avail', '1');
INSERT INTO site_config (site, field, value) values (2, 'mlog_coll_text', '1979-[1981]- JL 044 37 LOCATION: MICRO;
1981-85 covers B.C. and Quebec only; 
1986-88 covers B.C. and Federal government only; 
1989- covers federal and all provincial governments');
INSERT INTO site_config (site, field, value) values (2, 'lend', '1');
INSERT INTO site_config (site, field, value) values (2, 'patron_email_no_match_text', 'You have listed a non-SFU email address in the email address field. All
ILL requests submitted must include a proper SFU email address. Please see
Academic Computing Services about activating your account or learning how
to forward email out of your SFU account.');
INSERT INTO site_config (site, field, value) values (2, 'patr_patron_type_disp', '0');
INSERT INTO site_config (site, field, value) values (2, 'patr_fine_limit', '5.00');
INSERT INTO site_config (site, field, value) values (2, 'request_msg_fmt', 'GENERIC_SCRIPT');
INSERT INTO site_config (site, field, value) values (2, 'request_msg_email', 'klong@sfu.ca');
INSERT INTO site_config (site, field, value) values (2, 'other_request_non_journal', 'N');
INSERT INTO site_config (site, field, value) values (2, 'strip_apostrophe_s', '0');
INSERT INTO site_config (site, field, value) values (2, 'zsysid_search_avail', '1');
INSERT INTO site_config (site, field, value) values (2, 'source_name', 'SFU Catalogue');
INSERT INTO site_config (site, field, value) values (2, 'patron_api_type', 'III_HTTP');
INSERT INTO site_config (site, field, value) values (2, 'patron_api_port', '4500');
INSERT INTO site_config (site, field, value) values (2, 'patron_need_pin', '0');
INSERT INTO site_config (site, field, value) values (2, 'patr_patron_type_edit_allowed', '0');
INSERT INTO site_config (site, field, value) values (2, 'ill_nuc', 'BVAS');
INSERT INTO site_config (site, field, value) values (2, 'use_blank_citation_form', '1');
INSERT INTO site_config (site, field, value) values (2, 'ill_req_form', 'T');
INSERT INTO site_config (site, field, value) values (2, 'ill_req_form_non_journal', 'T');
INSERT INTO site_config (site, field, value) values (2, 'no_holdings_req_non_journal', '1');
INSERT INTO site_config (site, field, value) values (2, 'holdings_list', 'CAN_BORROW_ONLY');
INSERT INTO site_config (site, field, value) values (2, 'zhost', 'troy.lib.sfu.ca');
INSERT INTO site_config (site, field, value) values (2, 'use_fulltext_links', '1');
INSERT INTO site_config (site, field, value) values (2, 'use_856_links', '1');
INSERT INTO site_config (site, field, value) values (2, 'password_needed', 'NOT_REQUIRED');
INSERT INTO site_config (site, field, value) values (2, 'skip_required_if_password', '0');
INSERT INTO site_config (site, field, value) values (2, 'ill_req_form_limit_text', 'Undergraduate students are invited to ask at the Reference Desk for assistance finding alternative materials.');
INSERT INTO site_config (site, field, value) values (2, 'zport', '210');
INSERT INTO site_config (site, field, value) values (2, 'zdbase', 'innopac');
INSERT INTO site_config (site, field, value) values (2, 'zuse_att_journal_title', '33');
INSERT INTO site_config (site, field, value) values (2, 'ztrunc_att_sw_title', '100');
INSERT INTO site_config (site, field, value) values (2, 'ztrunc_att_sw_journal_title', '100');
INSERT INTO site_config (site, field, value) values (2, 'use_javascript', '1');
INSERT INTO site_config (site, field, value) values (2, 'include_fulltext_as_holdings', '1');
INSERT INTO site_config (site, field, value) values (2, 'parallel_server_msg', '1');
INSERT INTO site_config (site, field, value) values (2, 'use_request_confirmation_screen', '0');
INSERT INTO site_config (site, field, value) values (2, 'use_request_acknowledgment_screen', '1');
INSERT INTO site_config (site, field, value) values (2, 'patr_last_name', 'R');
INSERT INTO site_config (site, field, value) values (2, 'patr_first_name', 'R');
INSERT INTO site_config (site, field, value) values (2, 'patr_library_id', 'R');
INSERT INTO site_config (site, field, value) values (2, 'blocking', 'F_MEDIATED');
INSERT INTO site_config (site, field, value) values (2, 'patr_patron_type', 'R');
INSERT INTO site_config (site, field, value) values (2, 'patr_not_req_after', 'R');
INSERT INTO site_config (site, field, value) values (2, 'patr_prov', 'N');
INSERT INTO site_config (site, field, value) values (2, 'patr_department', 'R');
INSERT INTO site_config (site, field, value) values (2, 'patr_patron_email', 'R');
INSERT INTO site_config (site, field, value) values (2, 'patr_pickup', 'N');
INSERT INTO site_config (site, field, value) values (2, 'patr_phone', 'N');
INSERT INTO site_config (site, field, value) values (2, 'patr_street', 'N');
INSERT INTO site_config (site, field, value) values (2, 'patr_city', 'N');
INSERT INTO site_config (site, field, value) values (2, 'ill_local_system', 'OPENILL');
INSERT INTO site_config (site, field, value) values (2, 'ill_local_system_email', 'klong@sfu.ca');
INSERT INTO site_config (site, field, value) values (2, 'patr_postal_code', 'N');
INSERT INTO site_config (site, field, value) values (2, 'patr_rush_req', 'N');
INSERT INTO site_config (site, field, value) values (2, 'patr_paid', 'N');
INSERT INTO site_config (site, field, value) values (2, 'patr_phone_work', 'N');
INSERT INTO site_config (site, field, value) values (2, 'auto_req', '1');
INSERT INTO site_config (site, field, value) values (2, 'other_rank', '1');
INSERT INTO site_config (site, field, value) values (2, 'other_rank_display_group', '');
INSERT INTO site_config (site, field, value) values (2, 'other_rank_search_group', '');
INSERT INTO site_config (site, field, value) values (2, 'other_auto_req_show', '1');
INSERT INTO site_config (site, field, value) values (2, 'auto_req_non_journal', '1');
INSERT INTO site_config (site, field, value) values (2, 'other_rank_non_journal', '0');
INSERT INTO site_config (site, field, value) values (2, 'other_rank_non_journal_display_group', '');
INSERT INTO site_config (site, field, value) values (2, 'other_rank_non_journal_search_group', '');
INSERT INTO site_config (site, field, value) values (2, 'other_auto_req_show_non_journal', '1');
INSERT INTO site_config (site, field, value) values (2, 'skip_main_holdings_screen_if_no_holdings', '0');
INSERT INTO site_config (site, field, value) values (2, 'use_site_holdings', '1');
INSERT INTO site_config (site, field, value) values (2, 'abbrev_name', 'SFU Burnaby');
INSERT INTO site_config (site, field, value) values (2, 'disable_holdings_statement_display', '1');


INSERT INTO site_config (site, field, value) values (3, 'ill_nuc', 'BVAS');
INSERT INTO site_config (site, field, value) values (3, 'group', 'COPPUL_AND_ELN');
INSERT INTO site_config (site, field, value) values (3, 'eric_coll_avail', 'T');
INSERT INTO site_config (site, field, value) values (3, 'eric_coll_text', ' Most post-1993 ERIC documents are available online to members of the SFU community. Paper copies of these documents are available via Interlibrary Loan.');
INSERT INTO site_config (site, field, value) values (3, 'lend', '1');
INSERT INTO site_config (site, field, value) values (3, 'request_msg_fmt', 'GENERIC_SCRIPT');
INSERT INTO site_config (site, field, value) values (3, 'request_msg_email', 'klong@sfu.ca');
INSERT INTO site_config (site, field, value) values (3, 'use_site_holdings', '1');
INSERT INTO site_config (site, field, value) values (3, 'abbrev_name', 'SFU Downtown');
INSERT INTO site_config (site, field, value) values (3, 'catalogue_source_default', 'BVAS');
INSERT INTO site_config (site, field, value) values (3, 'disable_holdings_statement_display', '1');


INSERT INTO site_config (site, field, value) values (4, 'ill_nuc', 'BVAS');
INSERT INTO site_config (site, field, value) values (4, 'group', 'COPPUL_AND_ELN');
INSERT INTO site_config (site, field, value) values (4, 'lend', '1');
INSERT INTO site_config (site, field, value) values (4, 'request_msg_fmt', 'GENERIC_SCRIPT');
INSERT INTO site_config (site, field, value) values (4, 'request_msg_email', 'klong@sfu.ca');
INSERT INTO site_config (site, field, value) values (4, 'use_site_holdings', '1');
INSERT INTO site_config (site, field, value) values (4, 'abbrev_name', 'SFU Surrey');
INSERT INTO site_config (site, field, value) values (4, 'catalogue_source_default', 'BVAS');
INSERT INTO site_config (site, field, value) values (4, 'disable_holdings_statement_display', '1');



INSERT INTO site_config (site, field, value) values (1, 'group', 'COPPUL');
INSERT INTO site_config (site, field, value) values (1, 'source_name', 'NEOS Libraries\' Catalogue');
INSERT INTO site_config (site, field, value) values (1, 'system_type', 'SIRSI');
INSERT INTO site_config (site, field, value) values (1, 'use_z3950', '1');
INSERT INTO site_config (site, field, value) values (1, 'zhost', 'ualapp.library.ualberta.ca');
INSERT INTO site_config (site, field, value) values (1, 'zport', '2200');
INSERT INTO site_config (site, field, value) values (1, 'zdbase', 'unicorn');
INSERT INTO site_config (site, field, value) values (1, 'zpos_att_sw_title', '1');
INSERT INTO site_config (site, field, value) values (1, 'zstruct_att_sw_title', '1');
INSERT INTO site_config (site, field, value) values (1, 'ztrunc_att_sw_title', '100');
INSERT INTO site_config (site, field, value) values (1, 'zpos_att_title', '1');
INSERT INTO site_config (site, field, value) values (1, 'zstruct_att_title', '1');
INSERT INTO site_config (site, field, value) values (1, 'ztrunc_att_title', '100');
INSERT INTO site_config (site, field, value) values (1, 'lend', '1');
INSERT INTO site_config (site, field, value) values (1, 'request_msg_fmt', 'CISTI');
INSERT INTO site_config (site, field, value) values (1, 'request_msg_email', 'klong@sfu.ca');
INSERT INTO site_config (site, field, value) values (1, 'use_site_holdings', '1');
INSERT INTO site_config (site, field, value) values (1, 'abbrev_name', 'U of Alberta');
INSERT INTO site_config (site, field, value) values (1, 'disable_item_and_circulation_display', '1');


INSERT INTO site_config (site, field, value) values (5, 'ill_nuc', 'BVIV');
INSERT INTO site_config (site, field, value) values (5, 'group', 'COPPUL_AND_ELN');
INSERT INTO site_config (site, field, value) values (5, 'eric_coll_avail', 'T');
INSERT INTO site_config (site, field, value) values (5, 'eric_coll_text', 'This item is an ERIC document and should be available in UVic\'s microfiche collection. Please check in the Micro Room in the McPherson Library.');
INSERT INTO site_config (site, field, value) values (5, 'source_name', 'McPherson Catalogue');
INSERT INTO site_config (site, field, value) values (5, 'system_type', 'ENDEAVOR');
INSERT INTO site_config (site, field, value) values (5, 'use_z3950', '1');
INSERT INTO site_config (site, field, value) values (5, 'zhost', 'voyager.library.uvic.ca');
INSERT INTO site_config (site, field, value) values (5, 'zport', '7090');
INSERT INTO site_config (site, field, value) values (5, 'zdbase', 'voyager');
INSERT INTO site_config (site, field, value) values (5, 'zpos_att_sw_title', '1');
INSERT INTO site_config (site, field, value) values (5, 'zcompl_att_sw_title', '3');
INSERT INTO site_config (site, field, value) values (5, 'zcompl_att_title', '3');
INSERT INTO site_config (site, field, value) values (5, 'strip_apostrophe_s', '0');
INSERT INTO site_config (site, field, value) values (5, 'lend', '1');
INSERT INTO site_config (site, field, value) values (5, 'request_msg_fmt', 'GENERIC_SCRIPT');
INSERT INTO site_config (site, field, value) values (5, 'request_msg_email', 'klong@sfu.ca');
INSERT INTO site_config (site, field, value) values (5, 'use_site_holdings', '1');
INSERT INTO site_config (site, field, value) values (5, 'abbrev_name', 'UVic Main');


INSERT INTO site_config (site, field, value) values (6, 'source_name', 'UBC Catalogue');
INSERT INTO site_config (site, field, value) values (6, 'system_type', 'ENDEAVOR');
INSERT INTO site_config (site, field, value) values (6, 'use_z3950', '1');
INSERT INTO site_config (site, field, value) values (6, 'zhost', 'portage.library.ubc.ca');
INSERT INTO site_config (site, field, value) values (6, 'zport', '7090');
INSERT INTO site_config (site, field, value) values (6, 'zdbase', 'voyager');
INSERT INTO site_config (site, field, value) values (6, 'zpos_att_sw_title', '1');
INSERT INTO site_config (site, field, value) values (6, 'zcompl_att_sw_title', '3');
INSERT INTO site_config (site, field, value) values (6, 'zcompl_att_title', '3');
INSERT INTO site_config (site, field, value) values (6, 'lend', '0');

INSERT INTO site_config (site, field, value) values (7, 'group', 'COPPUL_AND_ELN');
INSERT INTO site_config (site, field, value) values (7, 'lend', '1');
INSERT INTO site_config (site, field, value) values (7, 'request_msg_fmt', 'ISO_EMAIL');
INSERT INTO site_config (site, field, value) values (7, 'request_msg_email', 'klong@sfu.ca');
INSERT INTO site_config (site, field, value) values (7, 'use_site_holdings', '1');
INSERT INTO site_config (site, field, value) values (7, 'abbrev_name', 'UBC-Koerner');
INSERT INTO site_config (site, field, value) values (7, 'catalogue_source_default', 'BVAU');


INSERT INTO site_config (site, field, value) values (8, 'group', 'COPPUL_AND_ELN');
INSERT INTO site_config (site, field, value) values (8, 'lend', '1');
INSERT INTO site_config (site, field, value) values (8, 'request_msg_fmt', 'ISO_EMAIL');
INSERT INTO site_config (site, field, value) values (8, 'request_msg_email', 'klong@sfu.ca');
INSERT INTO site_config (site, field, value) values (8, 'use_site_holdings', '1');
INSERT INTO site_config (site, field, value) values (8, 'abbrev_name', 'UBC-Education');
INSERT INTO site_config (site, field, value) values (8, 'catalogue_source_default', 'BVAU');


INSERT INTO site_config (site, field, value) values (9, 'ill_nuc', 'MWUC');
INSERT INTO site_config (site, field, value) values (9, 'group', 'COPPUL_AND_ELN');
INSERT INTO site_config (site, field, value) values (9, 'eric_coll_avail', 'T');
INSERT INTO site_config (site, field, value) values (9, 'eric_coll_text', 'This item is an ERIC document and should be available in UVic\'s microfiche collection. Please check in the Micro Room in the McPherson Library.');
INSERT INTO site_config (site, field, value) values (9, 'source_name', 'U of Winnipeg Catalogue');
INSERT INTO site_config (site, field, value) values (9, 'system_type', 'III');
INSERT INTO site_config (site, field, value) values (9, 'use_z3950', '1');
INSERT INTO site_config (site, field, value) values (9, 'zhost', 'innopac.uwinnipeg.ca');
INSERT INTO site_config (site, field, value) values (9, 'zport', '210');
INSERT INTO site_config (site, field, value) values (9, 'zdbase', 'innopac');
INSERT INTO site_config (site, field, value) values (9, 'ztrunc_att_sw_title', '100');
INSERT INTO site_config (site, field, value) values (9, 'lend', '1');
INSERT INTO site_config (site, field, value) values (9, 'request_msg_fmt', 'GENERIC_SCRIPT');
INSERT INTO site_config (site, field, value) values (9, 'request_msg_email', 'klong@sfu.ca');
INSERT INTO site_config (site, field, value) values (9, 'use_site_holdings', '1');
INSERT INTO site_config (site, field, value) values (9, 'abbrev_name', 'U of Winnipeg');

INSERT INTO config_rank (id, site, rank, rank_site, display_group, search_group, auto_req) values (4, 2, 0, '2', 1, 1, true); 
INSERT INTO config_rank (id, site, rank, rank_site, display_group, search_group, auto_req) values (5, 2, 1, '3', 1, 1, true);
INSERT INTO config_rank (id, site, rank, rank_site, display_group, search_group, auto_req) values (6, 2, 2, '4', 1, 1, true);

INSERT INTO config_rank_non_journal (id, site, rank, rank_site, display_group, search_group, auto_req) values (4, 2, 0, '2', 1, 1, true); 
INSERT INTO config_rank_non_journal (id, site, rank, rank_site, display_group, search_group, auto_req) values (5, 2, 1, '3', 1, 1, true);
INSERT INTO config_rank_non_journal (id, site, rank, rank_site, display_group, search_group, auto_req) values (6, 2, 2, '4', 1, 1, true);

INSERT INTO config_patr_patron_type_choice (id, site, rank, type) values (1, 2, 0, 'Faculty');
INSERT INTO config_patr_patron_type_choice (id, site, rank, type) values (2, 2, 1, 'Graduate');
INSERT INTO config_patr_patron_type_choice (id, site, rank, type) values (3, 2, 2, 'Undergraduate');
INSERT INTO config_patr_patron_type_choice (id, site, rank, type) values (4, 2, 3, 'Staff');

