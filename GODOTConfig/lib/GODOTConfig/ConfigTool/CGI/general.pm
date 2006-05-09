## GODOTConfig::ConfigTool::CGI::general
##
## Routines for general things like changing current site, etc.
##
## Copyright (c) 1997-2003, Todd Holbrook
##

package GODOTConfig::ConfigTool::CGI;

use GODOTConfig::ConfigTool::CGI::Config;
use GODOTConfig::Debug;

use strict;

sub process_general_change_site {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	my @sites_list;
	if ($self->account->administrator) {
		@sites_list = GODOTConfig::DB::Sites->retrieve_all;
	} else {
		@sites_list = $self->account->sites;
	}

	my $hash = {
		'current_site' => $self->current_site,
		'sites' => \@sites_list,
	};

	$self->template->process('change_site', $hash, $self->get_append_content);	
	$self->page_heading_image('title_change_current_site.jpg');
	
	return 'complete';
}

sub process_general_submit_change_site {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	my $chosen_site = param('change_current_site') or
		GODOTConfig::Exception::App::CGI->throw("No site id found in process_general_submit_change_site");
	
	my @sites_list;
	if ($self->account->administrator) {
		@sites_list = GODOTConfig::DB::Sites->retrieve_all;
	} else {
		@sites_list = $self->account->sites;
	}

	@sites_list = grep {$_->id == $chosen_site} @sites_list;
	if (scalar(@sites_list) == 1) {
		$self->current_site($sites_list[0]);
		$self->session->{'current_site_id'} = $sites_list[0]->id;
	} else {	
		GODOTConfig::Exception::App::CGI->throw("You do not have permission to change settings for this site.");
	}

	return 'main';
}


sub process_show_help {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;
	
	my $help_template = param('template');
	defined($help_template) && $help_template ne '' or
		GODOTConfig::Exception::App::CGI->throw("No help template defined in show_help");
	
	my $template = $self->template->process($help_template, {}, $self->get_append_content);

	$self->page_heading_image('title_help.jpg');
	$self->sidebar('');

        #### !!!!!!!!!!!! change these !!!!!!!!!!!
	# $self->page_header('');
	# $self->footer('');

	$self->onload('window.resizeTo(window.screen.availWidth/2, window.screen.availWidth/2)');

	return 'complete';
}

	
1;
