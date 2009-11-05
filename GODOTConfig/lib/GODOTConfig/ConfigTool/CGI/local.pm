## GODOTConfig::ConfigTool::CGI::local
##
## Routines for handling system maintenance screens
##
## Copyright (c) 1997-2003, Todd Holbrook
##

package GODOTConfig::ConfigTool::CGI;

use CGI::Cookie;

use GODOTConfig::ConfigTool::CGI::Config;
use GODOTConfig::Debug;
use GODOT::Template;
use GODOT::Debug;
use GODOT::String;


use strict;

sub process_local_edit_account {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;
	
	defined($self->account) or
		GODOTConfig::Exception::App::CGI->throw("Unable to load account for editing");

        $self->template->process('local_edit_account', {'account' => $self->account}, $self->get_append_content);
	$self->page_heading_image('title_admin_accounts.jpg');
	$self->css('local_edit_account.css');

	return 'complete';
}

sub process_local_submit_edit_account {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	my $account = $self->account;
	defined($account) or
		GODOTConfig::Exception::App::CGI->throw("Unable to load account for editing");

	my @errors;
	assert_ne(param('account_name')) or
		push @errors, 'Account name cannot be blank';
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
	$account->password(crypt(param('account_password'), $self->account->key)) if defined(param('account_password')) && param('account_password') ne '';
	$account->update;
	$account->dbi_commit;

	return 'main';
}


# ---------------- Templates ------------------


sub process_local_templates {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->template->process('local_templates', {'site' => $self->current_site}, $self->get_append_content);

	return 'complete';
}

sub process_local_list_templates {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	defined($self->current_site) or
		GODOTConfig::Exception::App::CGI->throw("Current site not set in local_templates");
	
	my $site_id = $self->current_site->id;

	my $group = param('group');
	my @templates = grep {$GODOTConfig::Config::GODOT_TEMPLATE_CONFIG{$_}->{'group'} eq $group} @GODOTConfig::Config::GODOT_TEMPLATES;

	@templates = sort {$GODOTConfig::Config::GODOT_TEMPLATE_CONFIG{$a}->{'level'} <=> $GODOTConfig::Config::GODOT_TEMPLATE_CONFIG{$b}->{'level'} or $a cmp $b} @templates;

	my @active_templates;
	if (opendir ACTIVE_DIR, "$GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/active/$site_id") {
		@active_templates = grep !/^\./, readdir ACTIVE_DIR;   # Get all non dot files
	}

	my @sandbox_templates;
	if (opendir SANDBOX_DIR, "$GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/sandbox/$site_id") {
		@sandbox_templates = grep !/^\./, readdir SANDBOX_DIR;   # Get all non dot files
	}

	my $template_count = $#templates + 9;
	$self->onload("var cookie = readCookie('browse_level'); if (cookie) { showLevel(cookie,'level',4,$template_count) }");

	$self->template->process('local_list_templates', {'site' => $self->current_site, 'all_templates' => \@templates, 'active_templates' => \@active_templates, 'sandbox_templates' => \@sandbox_templates, 'results' => $self->results, 'template_config' => \%GODOTConfig::Config::GODOT_TEMPLATE_CONFIG}, $self->get_append_content);

	return 'complete';
}

sub process_local_template_description {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;
	
	my $template = param('template') or
		GODOTConfig::Exception::App::CGI->throw('Template description to display is not defined.');
		
	$self->append_content($GODOTConfig::Config::GODOT_TEMPLATE_CONFIG{$template}->{'description'});
	$self->sidebar('');

	return 'complete';
}

sub process_local_view_template {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	defined($self->current_site) or
		GODOTConfig::Exception::App::CGI->throw('Current site not set in local_view_template');
	
	my $site_id = $self->current_site->id;
	my $type = param('type') or
		GODOTConfig::Exception::App::CGI->throw('Template type not set in local_view_template');
	my $template_name = param('template') or
		GODOTConfig::Exception::App::CGI->throw('Template name not set in local_view_template');
	$self->validate_template_type($type);

	my $template;
	if (open TEMPLATE, "$GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/$type/$site_id/$template_name") {
		while (<TEMPLATE>) { $template .= $_ };
		close TEMPLATE;
	}

	$self->template->process('local_view_template', {'template_data' => $template}, $self->get_append_content);

	return 'complete';
}


sub process_local_edit_template {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	defined($self->current_site) or
		GODOTConfig::Exception::App::CGI->throw('Current site not set in local_view_template');
	
	my $site_id = $self->current_site->id;
	my $template_name = param('template') or
		GODOTConfig::Exception::App::CGI->throw('Template name not set in local_view_template');

	my $template;
	if (-e "$GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/sandbox/$site_id/$template_name") {
		if (open TEMPLATE, "$GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/sandbox/$site_id/$template_name") {
			while (<TEMPLATE>) { $template .= $_ };
			close TEMPLATE;
		}
	} elsif (-e "$GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/active/$site_id/$template_name") {
		if (open TEMPLATE, "$GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/active/$site_id/$template_name") {
			while (<TEMPLATE>) { $template .= $_ };
			close TEMPLATE;
		}
	} else {
		if (open TEMPLATE, "$GODOTConfig::Config::GODOT_GLOBAL_TEMPLATE_DIR/$template_name") {
			while (<TEMPLATE>) { $template .= $_ };
			close TEMPLATE;
		}
	}		

	$self->template->process('local_edit_template', {'template_name' => $template_name, 'template_data' => $template, 'template_group' => $GODOTConfig::Config::GODOT_TEMPLATE_CONFIG{$template_name}->{'group'}}, $self->get_append_content);

	return 'complete';
}

sub process_local_submit_edit_template {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;
	                        
	defined($self->current_site) or
		GODOTConfig::Exception::App::CGI->throw('Current site not set in local_view_template');

	my $site_id = $self->current_site->id;
	my $template_name = param('template') or
		GODOTConfig::Exception::App::CGI->throw('Template name not set in local_view_template');

        ##
        ## (20-jan-2006 kl) - there may not be a sandbox directory for this site, so check first and if not
        ##                    create one
        ##
 
        my $dir = "$GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/sandbox/$site_id";
        unless (-e $dir && -d $dir) { mkdir $dir; } 

        my $template_file = "$dir/$template_name";
	open TEMPLATE, ">$template_file" or GODOTConfig::Exception::App::CGI->throw("Unable to open '$template_file' for writing: $!");

	print TEMPLATE param('template_data');
	close TEMPLATE;

	$self->results(["Site template saved: $template_name"]);

	return 'local_list_templates';
}


sub process_local_delete_template {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	defined($self->current_site) or
		GODOTConfig::Exception::App::CGI->throw('Current site not set in local_delete_template');
	
	my $site_id = $self->current_site->id;
	my $template_name = param('template') or
		GODOTConfig::Exception::App::CGI->throw('Template name not set in local_delete_template');
	my $type = param('type');

	$self->validate_template_type($type);	
	
	unlink("$GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/$type/$site_id/$template_name") or
		GODOTConfig::Exception::App::CGI->throw("Unable to delete template file: $!");

	$self->results(["Site template deleted: $template_name"]);
		
	param('group', $GODOTConfig::Config::GODOT_TEMPLATE_CONFIG{$template_name}->{'group'});
	return 'local_list_templates';
}


sub process_local_transfer_template {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	defined($self->current_site) or
		GODOTConfig::Exception::App::CGI->throw('Current site not set in local_transfer_template');
	
	my $site_id = $self->current_site->id;
	my $template_name = param('template') or
		GODOTConfig::Exception::App::CGI->throw('Template name not set in local_transfer_template');

	# Backup any existing active template
	my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time);
	$mon++;
	$year += 1900;
	my $timestamp = "${year}-${mon}-${mday}_${hour}:${min}:${sec}";

	-e "$GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/active/$site_id/$template_name" and
		`mv $GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/active/$site_id/$template_name $GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/backup/$site_id/$template_name.$timestamp`;

	# Copy sandbox template over
	`cp $GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/sandbox/$site_id/$template_name $GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/active/$site_id/$template_name`;

	$self->results(["Site template transfered: $template_name"]);
	
	param('group', $GODOTConfig::Config::GODOT_TEMPLATE_CONFIG{$template_name}->{'group'});
	return 'local_list_templates';
}


sub process_local_upload_template {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	defined($self->current_site) or
		GODOTConfig::Exception::App::CGI->throw('Current site not set in local_upload_template');
	
	my $site_id = $self->current_site->id;
	my $template_name = param('template') or
		GODOTConfig::Exception::App::CGI->throw('Template name not set in local_upload_template');
	my $template_file = param('template_file') or
		GODOTConfig::Exception::App::CGI->throw('Template file not set for uploading in local_upload_template');
		
	open(OUTFILE, ">$GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/sandbox/$site_id/$template_name") or
		GODOTConfig::Exception::App::CGI->throw("Unable to open file ($GODOTConfig::GODOT_SITE_TEMPLATE_DIR/sandbox/$site_id/$template_name) for uploading: $!");
		
	my $buffer;
	while (read($template_file, $buffer, 1024)) {
		print OUTFILE $buffer;
	}
	close OUTFILE;

	$self->results(["Site template uploaded: $template_name"]);
	
	param('group', $GODOTConfig::Config::GODOT_TEMPLATE_CONFIG{$template_name}->{'group'});
	return 'local_list_templates';
}

# ---------------- CSS ------------------


sub process_local_css {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	defined($self->current_site) or
		GODOTConfig::Exception::App::CGI->throw("Current site not set in local_css");
	
	my $site_id = $self->current_site->id;

	my @active_css;
	if (opendir ACTIVE_DIR, "$GODOTConfig::Config::GODOT_SITE_CSS_DIR/active/$site_id") {
		@active_css = grep !/^\./, readdir ACTIVE_DIR;   # Get all non dot files
	}

	my @sandbox_css;
	if (opendir SANDBOX_DIR, "$GODOTConfig::Config::GODOT_SITE_CSS_DIR/sandbox/$site_id") {
		@sandbox_css = grep !/^\./, readdir SANDBOX_DIR;   # Get all non dot files
	}

	$self->template->process('local_css', {'site' => $self->current_site, 'all_css' => \@GODOTConfig::Config::GODOT_CSS, 'active_css' => \@active_css, 'sandbox_css' => \@sandbox_css, 'results' => $self->results}, $self->get_append_content);

	return 'complete';
}

sub process_local_view_css {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	defined($self->current_site) or
		GODOTConfig::Exception::App::CGI->throw('Current site not set in local_view_css');
	
	my $site_id = $self->current_site->id;
	my $type = param('type') or
		GODOTConfig::Exception::App::CGI->throw('Template type not set in local_view_css');
	my $css_name = param('css') or
		GODOTConfig::Exception::App::CGI->throw('Template name not set in local_view_css');
	$self->validate_css_type($type);

	my $css;
	if (open CSS, "$GODOTConfig::Config::GODOT_SITE_CSS_DIR/$type/$site_id/$css_name") {
		while (<CSS>) { $css .= $_ };
		close CSS;
	}

	$self->template->process('local_view_css', {'css_data' => $css}, $self->get_append_content);

	return 'complete';
}


sub process_local_edit_css {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	defined($self->current_site) or
		GODOTConfig::Exception::App::CGI->throw('Current site not set in local_view_css');
	
	my $site_id = $self->current_site->id;
	my $css_name = param('css') or
		GODOTConfig::Exception::App::CGI->throw('Template name not set in local_view_css');


	my $css;
	if (-e "$GODOTConfig::Config::GODOT_SITE_CSS_DIR/sandbox/$site_id/$css_name") {
		if (open CSS, "$GODOTConfig::Config::GODOT_SITE_CSS_DIR/sandbox/$site_id/$css_name") {
			while (<CSS>) { $css .= $_ };
			close CSS;
		}
	} elsif (-e "$GODOTConfig::Config::GODOT_SITE_CSS_DIR/active/$site_id/$css_name") {
		if (open CSS, "$GODOTConfig::Config::GODOT_SITE_CSS_DIR/active/$site_id/$css_name") {
			while (<CSS>) { $css .= $_ };
			close CSS;
		}
	} else {
		if (open CSS, "$GODOTConfig::Config::GODOT_GLOBAL_CSS_DIR/$css_name") {
			while (<CSS>) { $css .= $_ };
			close CSS;
		}
	}		
		
	$self->template->process('local_edit_css', {'css_name' => $css_name, 'css_data' => $css}, $self->get_append_content);

	return 'complete';
}

sub process_local_submit_edit_css {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;
	                        
	defined($self->current_site) or
		GODOTConfig::Exception::App::CGI->throw('Current site not set in local_view_css');

	my $site_id = $self->current_site->id;
	my $css_name = param('css') or
		GODOTConfig::Exception::App::CGI->throw('Template name not set in local_view_css');

	open CSS, ">$GODOTConfig::Config::GODOT_SITE_CSS_DIR/sandbox/$site_id/$css_name" or
		GODOTConfig::Exception::App::CGI->throw("Unable to open css for writing: $!");

	print CSS param('css_data');
	close CSS;

	$self->results(["Site css saved: $css_name"]);

	return 'local_css';
}


sub process_local_delete_css {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	defined($self->current_site) or
		GODOTConfig::Exception::App::CGI->throw('Current site not set in local_delete_css');
	
	my $site_id = $self->current_site->id;
	my $css_name = param('css') or
		GODOTConfig::Exception::App::CGI->throw('Template name not set in local_delete_css');
	my $type = param('type');

	$self->validate_css_type($type);	
	
	unlink("$GODOTConfig::Config::GODOT_SITE_CSS_DIR/$type/$site_id/$css_name") or
		GODOTConfig::Exception::App::CGI->throw("Unable to delete css file: $!");

	$self->results(["Site css deleted: $css_name"]);
		
	return 'local_css';
}


sub process_local_transfer_css {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	defined($self->current_site) or
		GODOTConfig::Exception::App::CGI->throw('Current site not set in local_transfer_css');
	
	my $site_id = $self->current_site->id;
	my $css_name = param('css') or
		GODOTConfig::Exception::App::CGI->throw('Template name not set in local_transfer_css');

	# Backup any existing active css
	my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time);
	$mon++;
	$year += 1900;
	my $timestamp = "${year}-${mon}-${mday}_${hour}:${min}:${sec}";

	-e "$GODOTConfig::Config::GODOT_SITE_CSS_DIR/active/$site_id/$css_name" and
		`mv $GODOTConfig::Config::GODOT_SITE_CSS_DIR/active/$site_id/$css_name $GODOTConfig::Config::GODOT_SITE_CSS_DIR/backup/$site_id/$css_name.$timestamp`;

	# Copy sandbox css over
	`cp $GODOTConfig::Config::GODOT_SITE_CSS_DIR/sandbox/$site_id/$css_name $GODOTConfig::Config::GODOT_SITE_CSS_DIR/active/$site_id/$css_name`;

	$self->results(["Site css transfered: $css_name"]);
	
	return 'local_css';
}


sub process_local_upload_css {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	defined($self->current_site) or
		GODOTConfig::Exception::App::CGI->throw('Current site not set in local_upload_css');
	
	my $site_id = $self->current_site->id;
	my $css_name = param('css') or
		GODOTConfig::Exception::App::CGI->throw('Template name not set in local_upload_css');
	my $css_file = param('css_file') or
		GODOTConfig::Exception::App::CGI->throw('Template file not set for uploading in local_upload_css');
		
	open(OUTFILE, ">$GODOTConfig::Config::GODOT_SITE_CSS_DIR/sandbox/$site_id/$css_name") or
		GODOTConfig::Exception::App::CGI->throw("Unable to open file ($GODOTConfig::GODOT_SITE_CSS_DIR/sandbox/$site_id/$css_name) for uploading: $!");
		
	my $buffer;
	while (read($css_file, $buffer, 1024)) {
		print OUTFILE $buffer;
	}
	close OUTFILE;

	$self->results(["Site css uploaded: $css_name"]);
	
	return 'local_css';
}


# --------------- Site Administration ------------------------


sub process_local_edit_site {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;
	
	defined($self->current_site) or
		GODOTConfig::Exception::App::CGI->throw('Current site not set in local_edit_site');
		
	my @sites = GODOTConfig::DB::Sites->retrieve_all;

	$self->template->process('local_edit_site', {'site' => $self->current_site, 'sites' => \@sites}, $self->get_append_content);

	return 'complete';
}

sub process_local_submit_edit_site {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;
	
	defined($self->current_site) or
		GODOTConfig::Exception::App::CGI->throw('Current site not set in local_submit_site_admin');
	
	my $site = $self->current_site;
	$site->name(param('site_name'));
	$site->email(param('site_email'));
	$site->update;

	GODOTConfig::DB::Site_Chains->search('site' => $site->id)->delete_all;
	
	my @errors;
	foreach my $param (param()) {
		next unless $param =~ /^chain_(.+)$/;
		next if !defined(param($param)) || param($param) eq '';
		
		if (!defined(param("rank_$1")) || param("rank_$1") < 1) {
			push @errors, "Rank must be defined and cannot be less than 1";
			next;
		}
		
		my $record = { 'site' => $site->id,
		               'chain' => param($param),
		               'rank' => param("rank_$1"),
		             };
		GODOTConfig::DB::Site_Chains->create($record);
	}
	if (scalar(@errors) > 0) {
		$self->submission_errors(\@errors);
		$site->dbi_rollback;
		return 'local_edit_site';
	}

	$site->dbi_commit;

	$self->results(['Site changes saved.']);

	return 'main';
}


##
## Make sure the template/css type we're using is "active" or "sandbox" to avoid someone
## entering "/" or something like that.
##
sub validate_template_type {
	my ($self, $template_type) = @_;
	
	unless($template_type eq 'active' || $template_type eq 'sandbox') {
		GODOTConfig::Exception::App::CGI->throw("Unrecognized template type: $template_type");
	}
	
	return 1;
}

sub validate_css_type {
	my ($self, $css_type) = @_;
	
	unless($css_type eq 'active' || $css_type eq 'sandbox') {
		GODOTConfig::Exception::App::CGI->throw("Unrecognized css type: $css_type");
	}
	
	return 1;
}


# ---------------------------- Sandbox ------------------------------------

sub process_local_sandbox {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	defined($self->current_site) or
		GODOTConfig::Exception::App::CGI->throw("Current site not set in local_sandbox");
 
        use GODOT::Template;

        my %cookies = fetch CGI::Cookie;

        my %params;
        foreach my $name ($SANDBOX_OBJECT_COOKIE, $SANDBOX_OBJECT_NAME_COOKIE) {            
            $params{$name} = (defined param($name))    ? param($name) 
                           : (defined $cookies{$name}) ? $cookies{$name}->value
                           :                             '';
        }
       
        #### foreach my $cookie (keys %cookies) {
        ####     warn "____ $cookie ______", $cookies{$cookie}, "\n";
        #### }
 
        my @sandboxes = $self->sandboxes;

	$self->template->process('local_sandbox', 
                                 {
                                  'sandboxes' => \@sandboxes, 
                                  'site_id' => $self->current_site->id,
                                  'cookies' => { %params }
                                 }, 
                                 $self->get_append_content);
	return 'complete';
}

sub process_local_submit_sandbox {
    my ($self) = @_;
    report_location if $C_CGI_TRACE;

    my @errors;

    my %params;
    foreach my $name ($SANDBOX_OBJECT_COOKIE, $SANDBOX_OBJECT_NAME_COOKIE) {
        $params{$name} = trim_beg_end(param($name));
    }
    
    unless ($params{$SANDBOX_OBJECT_NAME_COOKIE} =~ m#^[a-zA-Z0-9_]*$#) {
        push @errors, "The sandbox object name should contain only letters, numbers and underscores."; 
    }

    if (scalar @errors) {
        $self->submission_errors(\@errors);
        return 'local_sandbox';
    }
    
    my @cookies;

    foreach my $name ($SANDBOX_OBJECT_COOKIE, $SANDBOX_OBJECT_NAME_COOKIE) {
        push @cookies, new CGI::Cookie('-name' => $name, '-value' => $params{$name}, '-path' => '/', '-expires' => '+24h');
    }
    $self->cookies([@cookies]);
    
    my @sandboxes = $self->sandboxes;


    $self->template->process('local_sandbox', 
                             {'sandboxes' => \@sandboxes, 'site_id' => $self->current_site->id, 'cookies' => { %params }}, 
                             $self->get_append_content);
    return 'complete';
}

1;


sub sandboxes {
    my ($self) = @_;
  
    use GODOTConfig::Config;

    opendir SANDBOX_DIR, $GODOT::Config::SANDBOX_OBJECT_DIR or
	GODOTConfig::Exception::App::CGI->throw("Unable to open frozen objects directory ($GODOT::Config::SANDBOX_OBJECT_DIR) for sandbox listing: $!");
		
    my $site_key = $self->current_site->key;
    my @sandboxes = grep !/~$/, grep /^$site_key\./o, readdir SANDBOX_DIR;
    closedir SANDBOX_DIR;

    #### debug "..sandboxes..", join("\n", @sandboxes);

    return @sandboxes;
}
