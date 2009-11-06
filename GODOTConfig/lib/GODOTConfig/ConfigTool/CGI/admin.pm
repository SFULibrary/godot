## GODOTConfig::ConfigTool::CGI::admin
##
## Routines for handling system maintenance screens
##
## Copyright (c) 1997-2003, Todd Holbrook
##

package GODOTConfig::ConfigTool::CGI;

use GODOTConfig::ConfigTool::CGI::Config;
use GODOTConfig::Debug;

use strict;

sub process_admin_menu {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');
	
	my $url = url(-relative=>1);

	my @menu = (
		['Accounts', "$url?state=admin_accounts"],
		['Sites', "$url?state=admin_sites"],
		#### ['System Settings', "$url?state=admin_settings"],
		#### ['Messages', "$url?state=admin_messages"],
	);


	$self->template->process('admin_menu', {'menu' => \@menu}, $self->get_append_content);
	$self->page_heading_image('title_admin.jpg');

	return 'complete';
}


# ------------------------ SITES ---------------------------

sub process_admin_sites {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;
	
	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');

	my @sites = GODOTConfig::DB::Sites->retrieve_all();
	
	$self->template->process('admin_sites', {'sites' => \@sites, 'url' => url(-relative=>1), 'results' => $self->results}, $self->get_append_content);
	$self->page_heading_image('title_admin_sites.jpg');
	
	return 'complete';	
}

sub process_admin_view_site {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;
	
	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to admin ');

	my $site_id = param('site_id') or
		GODOTConfig::Exception::App::CGI->throw('site_id not defined.');

	my $site = GODOTConfig::DB::Sites->retrieve($site_id);
	defined($site) or
		GODOTConfig::Exception::App::CGI->throw("Unable to load site: $site_id");
	
	my $hash = { 'site' => $site, 'url' => url(-relative=>1) };
	$self->template->process('admin_view_site', $hash, $self->get_append_content);
	$self->page_heading_image('title_admin_sites.jpg');
	
	return 'complete';	
}



sub process_admin_edit_site {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;
	
	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');

	my $site_id = param('site_id') or
		GODOTConfig::Exception::App::CGI->throw("No site id found in admin_edit_site");
	
	my $site = GODOTConfig::DB::Sites->retrieve($site_id);
	unless (defined($site)) {
		GODOTConfig::Exception::App::CGI->throw("Unable to load site id: $site_id");
	}

	my @accounts_list = GODOTConfig::DB::Accounts->retrieve_all;
	
	my $hash = { 'site' => $site,
	             'accounts' => \@accounts_list,
	             'site_accounts' => [map {$_->id} $site->accounts],
	           };

	$self->template->process('admin_edit_site', $hash, $self->get_append_content);
	$self->page_heading_image('title_admin_sites.jpg');

	return 'complete';
}

sub process_admin_submit_edit_site {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');
	
	my $site_id = param('site_id') or
		GODOTConfig::Exception::App::CGI->throw("No site id found in admin_submit_edit_site");
	
	my $site = GODOTConfig::DB::Sites->retrieve($site_id);
	defined($site) or
		GODOTConfig::Exception::App::CGI->throw("Unable to load site id: $site_id");

	my @errors;
	assert_ne(param('site_name')) or
		push @errors, 'Site name cannot be blank';
	assert_ne(param('site_key')) or
		push @errors, 'Site key cannot be blank';
	assert(no_white_space(param('site_key'))) or
		push @errors, 'Site key cannot contain blanks including leading and trailing ones.';

	if (scalar(@errors) > 0) {
		$self->submission_errors(\@errors);
		return 'admin_edit_site';
	}

	$site->name(param('site_name'));
	$site->key(param('site_key'));
	if (assert_ne(param('site_email'))) {
		$site->email(param('site_email'));
	} else {
		$site->set('email', undef);
	}
	$site->active(param('site_active') ? 'true' : 'false');

	# Remove sites and recreate links, then save the site
	
	eval {
		GODOTConfig::DB::Accounts_Sites->search('site' => $site_id)->delete_all;
	
		my @accounts = param('site_accounts');
		foreach my $account (@accounts) {
			$site->add_to_accounts({ 'account' => $account});
		}

		$site->update;
	};
	if ($@) {
		$site->dbi_rollback;
		if (ref($@) && $@->can('rethrow')) {
			$@->rethrow;
		} else {
			die($@);
		}
	}

	$site->dbi_commit;
        
        ## Save to cache
        
        use GODOTConfig::Cache;
        my $cache = new GODOTConfig::Cache;
        $cache->write_to_cache_store($site->key) or GODOTConfig::Exception::App::CGI->throw("Unable to write site " . $site->key . " to cache.");


	$self->results(['Site saved: ' . $site->name]);

	return 'admin_sites';	
}

sub process_admin_delete_site {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');

	param('site_id') or
		GODOTConfig::Exception::App::CGI->throw('site_id not defined in delete_admin_site');


        # Save values before site is deleted
        
	my $obj =  GODOTConfig::DB::Sites->search('id' => param('site_id'))->first;
        (defined $obj) or GODOTConfig::Exception::App::CGI->throw('more than one site returned for id ' . param('site_id'));
        my $key = $obj->key;
        my $name = $obj->name;


	# Log out of the current site if you're deleting it.

	if (defined($self->current_site) && $self->current_site->id == param('site_id')) {
		$self->set('current_site', undef);
		delete $self->session()->{'current_site_id'};
	}

	GODOTConfig::DB::Sites->retrieve(param('site_id'))->delete;
	GODOTConfig::DB::Sites->dbi_commit;
	
        ## Delete from cache

        use GODOTConfig::Cache;
        GODOTConfig::Cache->delete_from_cache_store($key) or GODOTConfig::Exception::App::CGI->throw('unable to delete ' . $key . ' cache');

	$self->results(["$name deleted"]);

	return 'admin_sites';
}	


sub process_admin_new_site {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');

	my @accounts_list = GODOTConfig::DB::Accounts->retrieve_all;

	$self->template->process('admin_new_site', {'url' => url(-relative=>1), 'accounts' => \@accounts_list}, $self->get_append_content);
	$self->page_heading_image('title_admin_sites.jpg');

	return 'complete';
}


sub process_admin_submit_new_site {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;
	
	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');

	my @errors;
	assert_ne(param('site_name')) or
		push @errors, 'Account name cannot be blank';
	assert_ne(param('site_key')) or
		push @errors, 'Account module cannot be blank';

	if (scalar(@errors) > 0) {
		$self->submission_errors(\@errors);
		return 'admin_new_site';
	}

	my $site_hash = {
		name => param('site_name') || '',
		key => param('site_key') || '',
		email => param('site_email') || '',
		active => param('site_active') ? 'true' : 'false',
	};

	my $site;
	eval {
		$site = GODOTConfig::DB::Sites->create($site_hash);
	};
	if ($@) {
		GODOTConfig::DB::Sites->dbi_rollback;
		if (ref($@) && $@->can('rethrow')) {
			$@->rethrow;
		} else {
			die($@);
		}
	}

	# Add services then save the site

	my @accounts = param('site_accounts');
	if (scalar(@accounts) > 0) {
		eval {
			$site->name;		# Force a reload from the database just to make sure everything worked okay.
		
			foreach my $account (@accounts) {
				warn("Adding account '$account'");
				$site->add_to_accounts({account => $account});			
			}

			$site->update;
		};   
		if ($@) {
			$site->dbi_rollback;
			if (ref($@) && $@->can('rethrow')) {
				$@->rethrow;
			} else {
				die($@);
			}
		}
	}

	# Create a template directory for the site
	
	my $new_site_id = $site->id;
	mkdir "$GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/active/$new_site_id" or
		GODOTConfig::Exception::App::CGI->throw("Unable to create active user template directory: $GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/active/$new_site_id : $!");
	mkdir "$GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/sandbox/$new_site_id" or
		GODOTConfig::Exception::App::CGI->throw("Unable to create sandbox user template directory: $GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/sandbox/$new_site_id : $!");
	mkdir "$GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/backup/$new_site_id" or
		GODOTConfig::Exception::App::CGI->throw("Unable to create backup user template directory: $GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/backup/$new_site_id : $!");

	mkdir "$GODOTConfig::Config::GODOT_SITE_CSS_DIR/active/$new_site_id" or
		GODOTConfig::Exception::App::CGI->throw("Unable to create active user css directory: $GODOTConfig::Config::GODOT_SITE_CSS_DIR/active/$new_site_id : $!");
	mkdir "$GODOTConfig::Config::GODOT_SITE_CSS_DIR/sandbox/$new_site_id" or
		GODOTConfig::Exception::App::CGI->throw("Unable to create sandbox user css directory: $GODOTConfig::Config::GODOT_SITE_CSS_DIR/sandbox/$new_site_id : $!");
	mkdir "$GODOTConfig::Config::GODOT_SITE_CSS_DIR/backup/$new_site_id" or
		GODOTConfig::Exception::App::CGI->throw("Unable to create backup user css directory: $GODOTConfig::Config::GODOT_SITE_CSS_DIR/backup/$new_site_id : $!");

	$site->dbi_commit;

        ##
        ## Write cache file whether active or not
        ##

        use GODOTConfig::Cache;
        my $cache = new GODOTConfig::Cache;
        $cache->write_to_cache_store($site_hash->{'key'}) or GODOTConfig::Exception::App::CGI->throw("Unable to write site " . $site_hash->{'key'} . " to cache.");
	
	param('site_id', $new_site_id);
	return 'admin_view_site';	
}


# ----------------------- ACCOUNTS ----------------------------


sub process_admin_accounts {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;
	
	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');

	my @accounts = GODOTConfig::DB::Accounts->retrieve_all();
	
	$self->template->process('admin_accounts', { 'accounts' => \@accounts, 'url' => url(-relative=>1), 'results' => $self->results }, $self->get_append_content);
	$self->page_heading_image('title_admin_accounts.jpg');
	
	return 'complete';	
}

sub process_admin_view_account {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;
	
	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to admin ');

	my $account_id = param('account_id') or
		GODOTConfig::Exception::App::CGI->throw('account_id not defined.');

	my $account = GODOTConfig::DB::Accounts->retrieve($account_id);
	defined($account) or
		GODOTConfig::Exception::App::CGI->throw("Unable to load account: $account_id");
	
	$self->template->process('admin_view_account', { 'account' => $account, 'url' => url(-relative=>1) }, $self->get_append_content);
	$self->page_heading_image('title_admin_accounts.jpg');
	
	return 'complete';	
}

sub process_admin_edit_account {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;
	
	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to global account editting');

	my $account_id = param('account_id') or
		GODOTConfig::Exception::App::CGI->throw("No account id found in edit_global_account");
	
	my $account = GODOTConfig::DB::Accounts->retrieve($account_id);
	unless (defined($account)) {
		GODOTConfig::Exception::App::CGI->throw("Unable to load account id: $account_id");
	}

	my @sites_list = GODOTConfig::DB::Sites->retrieve_all;

	my $hash = { 'account' => $account,
	             'sites' => \@sites_list,
	             'account_sites' => [map {$_->id} $account->sites],
	           };
        $self->template->process('admin_edit_account', $hash, $self->get_append_content);
	$self->page_heading_image('title_admin_accounts.jpg');

	return 'complete';
}

sub process_admin_submit_edit_account {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');
	
	my $account_id = param('account_id') or
		GODOTConfig::Exception::App::CGI->throw("No account id found in submit_edit_admin_account");
	
	my $account = GODOTConfig::DB::Accounts->retrieve($account_id);
	defined($account) or
		GODOTConfig::Exception::App::CGI->throw("Unable to load account id: $account_id");

	my @errors;
	assert_ne(param('account_name')) or
		push @errors, 'Account name cannot be blank';
	assert_ne(param('account_key')) or
		push @errors, 'Account key cannot be blank';
	if (defined(param('verify_password') || defined('account_password'))) {
		param('verify_password') eq param('account_password') or
			push @errors, 'Account password fields do not match';
	}

	if (scalar(@errors) > 0) {
		$self->submission_errors(\@errors);
		return 'admin_edit_account';
	}

	$account->name(param('account_name'));
	$account->key(param('account_key'));
	$account->email(param('account_email'));
	$account->phone(param('account_phone'));
	$account->password(crypt(param('account_password'), param('account_key'))) if defined(param('account_password')) && param('account_password') ne '';
	$account->active(param('account_active') ? 'true' : 'false');
	$account->administrator(param('account_administrator') ? 'true' : 'false');

	# Remove sites and recreate links, then save the account
	
	eval {
		GODOTConfig::DB::Accounts_Sites->search('account' => $account_id)->delete_all;
	
		my @sites = param('account_sites');
		foreach my $site (@sites) {
			$account->add_to_sites({site => $site});			
		}

		$account->update;
	};
	if ($@) {
		$account->dbi_rollback;
		if (ref($@) && $@->can('rethrow')) {
			$@->rethrow;
		} else {
			die($@);
		}
	}

	$account->dbi_commit;

	$self->results(["Saved account: " . $account->key]);

	return 'admin_accounts';	
}

sub process_admin_delete_account {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	($self->account->administrator || $self->account->edit_admin) or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to admin account editting');

	param('account_id') or
		GODOTConfig::Exception::App::CGI->throw('account_id not defined in delete_admin_accounts');
	
	GODOTConfig::DB::Accounts->retrieve(param('account_id'))->delete;
	GODOTConfig::DB::Accounts->dbi_commit;

	$self->results(["Deleted account."]);
	
	return 'admin_accounts';
}	

sub process_admin_new_account {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;


	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');

	my @sites_list = GODOTConfig::DB::Sites->retrieve_all;

	$self->template->process('admin_new_account', {'url' => url(-relative=>1), 'sites' => \@sites_list}, $self->get_append_content);
	$self->page_heading_image('title_admin_accounts.jpg');

	return 'complete';
}


sub process_admin_submit_new_account {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;
	
	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');

	my @errors;
	assert_ne(param('account_name')) or
		push @errors, 'Account name cannot be blank';
	assert_ne(param('account_key')) or
		push @errors, 'Account module cannot be blank';
	assert_ne(param('account_password')) or
		push @errors, 'Account provider cannot be blank';
	assert_ne(param('verify_password')) or
		push @errors, 'Account provider cannot be blank';
	param('verify_password') eq param('account_password') or
		push @errors, 'Account password fields do not match';

	if (scalar(@errors) > 0) {
		$self->submission_errors(\@errors);
		return 'new_admin_account';
	}

	local GODOTConfig::DB::Accounts->db_Main->{ AutoCommit };

	my $account_hash = {
		name => param('account_name'),
		key => param('account_key'),
		email => param('account_email'),
		phone => param('account_phone'),
		password => crypt(param('account_password'), param('account_key')),
		active => param('account_active') ? 'true' : 'false',
		administrator => param('account_administrator') ? 'true' : 'false',
	};

	my $account;
	eval {
		$account = GODOTConfig::DB::Accounts->create($account_hash);
	};
	if ($@) {
		GODOTConfig::DB::Accounts->dbi_rollback;
		if (ref($@) && $@->can('rethrow')) {
			$@->rethrow;
		} else {
			die($@);
		}
	}

	# Add services then save the account

	my @sites = param('account_sites');
	if (scalar(@sites) > 0) {
		eval {
			$account->name;		# Force a reload from the database just to make sure everything worked okay.
		
			foreach my $site (@sites) {
				$account->add_to_sites({site => $site});			
			}
	
			$account->update;
		};
		if ($@) {
			$account->dbi_rollback;
			if (ref($@) && $@->can('rethrow')) {
				$@->rethrow;
			} else {
				die($@);
			}
		}
	}

	$account->dbi_commit;

	param('account_id', $account->id);

	return 'admin_view_account';	
}


# ------------------------------ Global Templates --------------------------

sub process_global_templates {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');

	my @active_templates;
	if (opendir ACTIVE_DIR, "$GODOTConfig::Config::GODOT_GLOBAL_TEMPLATE_DIR/") {
		@active_templates = grep !/^\./, readdir ACTIVE_DIR;   # Get all non dot files
	}

	my @sandbox_templates;
	if (opendir SANDBOX_DIR, "$GODOTConfig::Config::GODOT_GLOBAL_TEMPLATE_DIR/sandbox") {
		@sandbox_templates = grep !/^\./, readdir SANDBOX_DIR;   # Get all non dot files
	}

	$self->template->process('global_templates', {'all_templates' => \@GODOTConfig::Config::GODOT_TEMPLATES, 'active_templates' => \@active_templates, 'sandbox_templates' => \@sandbox_templates, 'results' => $self->results}, $self->get_append_content);

	return 'complete';
}


sub process_global_view_template {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');

	my $type = param('type') or
		GODOTConfig::Exception::App::CGI->throw('Template type not set in global_view_template');
	my $template_name = param('template') or
		GODOTConfig::Exception::App::CGI->throw('Template name not set in global_view_template');
	$self->validate_template_type($type);

	my $filename = $type eq 'active' ?
		"$GODOTConfig::Config::GODOT_GLOBAL_TEMPLATE_DIR/$template_name" :
		"$GODOTConfig::Config::GODOT_GLOBAL_TEMPLATE_DIR/$type/$template_name";
		
	my $template;
	if (open TEMPLATE, "$filename") {
		while (<TEMPLATE>) { $template .= $_ };
		close TEMPLATE;
	}

	$self->template->process('global_view_template', {'template_data' => $template}, $self->get_append_content);

	return 'complete';
}


sub process_global_edit_template {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');

	my $template_name = param('template') or
		GODOTConfig::Exception::App::CGI->throw('Template name not set in global_view_template');

	my $template;
	if (-e "$GODOTConfig::Config::GODOT_GLOBAL_TEMPLATE_DIR/sandbox/$template_name") {
		if (open TEMPLATE, "$GODOTConfig::Config::GODOT_GLOBAL_TEMPLATE_DIR/sandbox/$template_name") {
			while (<TEMPLATE>) { $template .= $_ };
			close TEMPLATE;
		}
	} else {
		if (open TEMPLATE, "$GODOTConfig::Config::GODOT_GLOBAL_TEMPLATE_DIR/$template_name") {
			while (<TEMPLATE>) { $template .= $_ };
			close TEMPLATE;
		}
	}	

	$self->template->process('global_edit_template', {'template_name' => $template_name, 'template_data' => $template}, $self->get_append_content);

	return 'complete';
}

sub process_global_submit_edit_template {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');

	my $template_name = param('template') or
		GODOTConfig::Exception::App::CGI->throw('Template name not set in global_view_template');

	open TEMPLATE, ">$GODOTConfig::Config::GODOT_GLOBAL_TEMPLATE_DIR/sandbox/$template_name" or
		GODOTConfig::Exception::App::CGI->throw("Unable to open template for writing: $!");

	print TEMPLATE param('template_data');
	close TEMPLATE;

	$self->results(["Global template saved: $template_name"]);

	return 'global_templates';
}


sub process_global_delete_template {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');

	my $template_name = param('template') or
		GODOTConfig::Exception::App::CGI->throw('Template name not set in global_delete_template');
	my $type = param('type');

	$self->validate_template_type($type);	
	
	unlink("$GODOTConfig::Config::GODOT_GLOBAL_TEMPLATE_DIR/$type/$template_name") or
		GODOTConfig::Exception::App::CGI->throw("Unable to delete template file: $!");

	$self->results(["Global template deleted: $template_name"]);
		
	return 'global_templates';
}


sub process_global_transfer_template {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');

	my $template_name = param('template') or
		GODOTConfig::Exception::App::CGI->throw('Template name not set in global_transfer_template');

	# Backup any existing active template
	my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time);
	$mon++;
	$year += 1900;
	my $timestamp = "${year}-${mon}-${mday}_${hour}:${min}:${sec}";

	-e "$GODOTConfig::Config::GODOT_GLOBAL_TEMPLATE_DIR/$template_name" and
		`mv $GODOTConfig::Config::GODOT_GLOBAL_TEMPLATE_DIR/$template_name $GODOTConfig::Config::GODOT_GLOBAL_TEMPLATE_DIR/backup/$template_name.$timestamp`;

	# Copy sandbox template over
	`cp $GODOTConfig::Config::GODOT_GLOBAL_TEMPLATE_DIR/sandbox/$template_name $GODOTConfig::Config::GODOT_GLOBAL_TEMPLATE_DIR/$template_name`;

	$self->results(["Global template transfered: $template_name"]);
	
	return 'global_templates';
}


sub process_global_upload_template {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');

	my $template_name = param('template') or
		GODOTConfig::Exception::App::CGI->throw('Template name not set in global_upload_template');
	my $template_file = param('template_file') or
		GODOTConfig::Exception::App::CGI->throw('Template file not set for uploading in global_upload_template');
		
	open(OUTFILE, ">$GODOTConfig::Config::GODOT_GLOBAL_TEMPLATE_DIR/sandbox/$template_name") or
		GODOTConfig::Exception::App::CGI->throw("Unable to open file ($GODOTConfig::GODOT_GLOBAL_TEMPLATE_DIR/sandbox/$template_name) for uploading: $!");
		
	my $buffer;
	while (read($template_file, $buffer, 1024)) {
		print OUTFILE $buffer;
	}
	close OUTFILE;
	
	$self->results(["Global template uploaded: $template_name"]);
	
	return 'global_templates';
}

# ------------------------------ Global CSS Files --------------------------

sub process_global_css {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');

	my @active_css;
	if (opendir ACTIVE_DIR, "$GODOTConfig::Config::GODOT_GLOBAL_CSS_DIR/") {
		@active_css = grep !/^\./, readdir ACTIVE_DIR;   # Get all non dot files
	}

	my @sandbox_css;
	if (opendir SANDBOX_DIR, "$GODOTConfig::Config::GODOT_GLOBAL_CSS_DIR/sandbox") {
		@sandbox_css = grep !/^\./, readdir SANDBOX_DIR;   # Get all non dot files
	}

	$self->template->process('global_css', {'all_css' => \@GODOTConfig::Config::GODOT_CSS, 'active_css' => \@active_css, 'sandbox_css' => \@sandbox_css, 'results' => $self->results}, $self->get_append_content);

	return 'complete';
}


sub process_global_view_css {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');

	my $type = param('type') or
		GODOTConfig::Exception::App::CGI->throw('CSS type not set in global_view_css');
	my $css_name = param('css') or
		GODOTConfig::Exception::App::CGI->throw('CSS name not set in global_view_css');
	$self->validate_css_type($type);

	my $filename = $type eq 'active' ?
		"$GODOTConfig::Config::GODOT_GLOBAL_CSS_DIR/$css_name" :
		"$GODOTConfig::Config::GODOT_GLOBAL_CSS_DIR/$type/$css_name";
		
	my $css;
	if (open CSS, "$filename") {
		while (<CSS>) { $css .= $_ };
		close CSS;
	}

	$self->template->process('global_view_css', {'css_data' => $css}, $self->get_append_content);

	return 'complete';
}


sub process_global_edit_css {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');

	my $css_name = param('css') or
		GODOTConfig::Exception::App::CGI->throw('CSS name not set in global_view_css');

	my $css;
	if (open CSS, "$GODOTConfig::Config::GODOT_GLOBAL_CSS_DIR/sandbox/$css_name") {
		while (<CSS>) { $css .= $_ };
		close CSS;
	}

	$self->template->process('global_edit_css', {'css_name' => $css_name, 'css_data' => $css}, $self->get_append_content);

	return 'complete';
}

sub process_global_submit_edit_css {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');

	my $css_name = param('css') or
		GODOTConfig::Exception::App::CGI->throw('CSS name not set in global_view_css');

	open CSS, ">$GODOTConfig::Config::GODOT_GLOBAL_CSS_DIR/sandbox/$css_name" or
		GODOTConfig::Exception::App::CGI->throw("Unable to open css for writing: $!");

	print CSS param('css_data');
	close CSS;

	$self->results(["Global css saved: $css_name"]);

	return 'global_css';
}


sub process_global_delete_css {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');

	my $css_name = param('css') or
		GODOTConfig::Exception::App::CGI->throw('CSS name not set in global_delete_css');
	my $type = param('type');

	$self->validate_css_type($type);	
	
	unlink("$GODOTConfig::Config::GODOT_GLOBAL_CSS_DIR/$type/$css_name") or
		GODOTConfig::Exception::App::CGI->throw("Unable to delete css file: $!");

	$self->results(["Global css deleted: $css_name"]);
		
	return 'global_css';
}


sub process_global_transfer_css {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');

	my $css_name = param('css') or
		GODOTConfig::Exception::App::CGI->throw('CSS name not set in global_transfer_css');

	# Backup any existing active css
	my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time);
	$mon++;
	$year += 1900;
	my $timestamp = "${year}-${mon}-${mday}_${hour}:${min}:${sec}";

	-e "$GODOTConfig::Config::GODOT_GLOBAL_CSS_DIR/$css_name" and
		`mv $GODOTConfig::Config::GODOT_GLOBAL_CSS_DIR/$css_name $GODOTConfig::Config::GODOT_GLOBAL_CSS_DIR/backup/$css_name.$timestamp`;

	# Copy sandbox css over
	`cp $GODOTConfig::Config::GODOT_GLOBAL_CSS_DIR/sandbox/$css_name $GODOTConfig::Config::GODOT_GLOBAL_CSS_DIR/$css_name`;

	$self->results(["Global css transfered: $css_name"]);
	
	return 'global_css';
}


sub process_global_upload_css {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->account->administrator or
		GODOTConfig::Exception::App::CGI->throw('User not authorized for access to administration functions');

	my $css_name = param('css') or
		GODOTConfig::Exception::App::CGI->throw('CSS name not set in global_upload_css');
	my $css_file = param('css_file') or
		GODOTConfig::Exception::App::CGI->throw('CSS file not set for uploading in global_upload_css');
		
	open(OUTFILE, ">$GODOTConfig::Config::GODOT_GLOBAL_CSS_DIR/sandbox/$css_name") or
		GODOTConfig::Exception::App::CGI->throw("Unable to open file ($GODOTConfig::GODOT_GLOBAL_CSS_DIR/sandbox/$css_name) for uploading: $!");
		
	my $buffer;
	while (read($css_file, $buffer, 1024)) {
		print OUTFILE $buffer;
	}
	close OUTFILE;
	
	$self->results(["Global css uploaded: $css_name"]);
	
	return 'global_css';
}


1;
