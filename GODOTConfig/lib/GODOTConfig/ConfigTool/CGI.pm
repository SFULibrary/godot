## GODOTConfig::ConfigTool::CGI
##
## Copyright Todd Holbrook - Simon Fraser University (2003)
##

package GODOTConfig::ConfigTool::CGI;

use Class::Accessor;
use base qw(Class::Accessor);

use GODOTConfig::Debug;
use GODOTConfig::Config;
use GODOTConfig::Exceptions qw(assert_ne);

# Load up the individual parts of the CGI module

use GODOTConfig::ConfigTool::CGI::Config;
use GODOTConfig::ConfigTool::CGI::admin;
use GODOTConfig::ConfigTool::CGI::general;
use GODOTConfig::ConfigTool::CGI::local;
use GODOTConfig::ConfigTool::CGI::local_configuration;

# Load the DB modules

use GODOTConfig::DB::DBI;
use GODOTConfig::DB::Accounts;
use GODOTConfig::DB::Sites;
use GODOTConfig::DB::Site_Chains;

# Load other supporting modules

use Text::Template;

use Template;
use Template::Stash;

use Apache::Session::File;
use CGI::Cookie;
use CGI qw(:standard :cgi-lib);

use URI::Escape;

use Data::Dumper;

use strict;

__PACKAGE__->mk_accessors(qw(session account_key account_id account current_site session_dir 
                             installation_name http_header sidebar http_footer base_template_dir page_heading_image 
                             content submission_errors results onload template css last_state cookies));


$Template::Stash::SCALAR_OPS->{'not_empty'} = sub { my $x = shift; return(defined($x) && $x ne '') };

# Add substr() to the Template::Toolkit stash.
$Template::Stash::SCALAR_OPS->{'substr'} = sub { my ($scalar, $offset, $length) = @_; return defined($length) ? substr($scalar, $offset, $length) : substr($scalar, $offset); };

# Add (n)in() to the Template::Toolkit stash. It's like grep for lists (non-regexp)
$Template::Stash::LIST_OPS->{'in'} = sub { my ($array, $val) = @_; return((grep {$_ eq $val} @$array) ? 1 : 0) };
$Template::Stash::LIST_OPS->{'nin'} = sub { my ($array, $val) = @_; return((grep {$_ == $val} @$array) ? 1 : 0) };


##
## new - Creates a new GODOTConfig::ConfigTool::CGI object.  Makes a new database
##       connection from either the passed in database string or the
##       information in Config
##
## Returns: GODOTConfig::ConfigTool::CGI object on success
##

sub new {
	my ($class, $database_connect) = @_;
	report_location if $C_CGI_TRACE;

	# Override the current Class::DBI settings if they're specified in the .cgi file

	if (defined($database_connect)) {
		GODOTConfig::DB::DBI->set_db('Main', @$database_connect);
	}

	return(bless {}, $class);
}


##
## handler - Main control loop for processing pages.  This handles
##           determining the state, setting up objects and sessions, and
##           running the appropriate processing routines and returns the
##           final (complete) text for the web page for display.
##
## Returns: String containing web page for display including HTML headers on
##          success, undef on failure.
##

sub handler {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;
	
	# Set the state based on params - usually to deal with buttons being pushed
	# that can't set the param('state') variable directly due to limits with HTML
	# forms...
	
	my $state = $self->get_state_from_params() ||
	            param('state');

	# Try to establish session.  If no session, check for login variables
	if (!defined($self->session($self->get_session()))) {
		warn("GODOT: Error creating account session, returning to login for account.");
		return $self->build_page('logout');	
	}

	# Setup the account information unless in a state which should not NOT do a login
	# State is set again from params() because they may have been set
        # based on success of authentication.
	eval {
		if (!defined($state) || !grep {$_ eq $state} ('login', 'mail_password', 'logout')) {
			$state = $self->setup_account($state);
		}
	};
	if ($@) {
		$self->set_error($@);
		$state = 'error';
	}

	use Template::Constants qw(:debug );

	$self->template(new Template({'INCLUDE_PATH' => (defined($self->base_template_dir) ? 
                                                        $self->base_template_dir : 
                                                        $GODOTConfig::Config::GODOT_CONFIG_TOOL_BASE_TEMPLATE_DIR), 
                                      'DEBUG_ALL' => 1}));

	my $output;
	eval {
		$output = $self->build_page($state);
	};

	if ($@) {
		my $error = $@;
		eval {
			$self->set_error($error);
			$output = $self->build_page($error);
		};
		if ($@) {
			if (ref($@) =~ /^GODOTConfig::Exception/) {
				$@->rethrow();
			} else {
				die($@);
			}
		}
	}

	return $output;
}		     

##
## setup_account - Checks for login information and attempts to
##                 authetication user.
##
## Returns: State string
##

sub setup_account {
	my ($self, $state) = @_;	
	report_location if $C_CGI_TRACE;

	# Check for login key/password pair first, if not check to see if
	# there's a stored session with a account_id already.  Fall back to login
	# screen if neither are available.
 
	if (defined(param('login_account_key')) && param('login_account_key') ne '') {
		$self->account_key(param('login_account_key'));
		my @accounts = GODOTConfig::DB::Accounts->search('key' => $self->account_key());

		if (scalar(@accounts) == 0) {
			# No matching account for error 1 - build special page
			return 'unknown_account';
		}

		my $account = shift @accounts;

		# Do authentication which is a password check at this point
		if ($self->check_password($account->password, param('login_password'))) { 
			$self->account_id($account->id);
			$self->session()->{'account_id'} = $self->account_id();  # Save account_id in session
			$self->account($account);

			my @sites = $account->sites;
			if (scalar(@sites) == 1) {
				$self->current_site($sites[0]);
				$self->session()->{'current_site_id'} = $sites[0]->id;
			}
		} else {
			return 'authentication_failed';
		}
	} elsif (defined($self->session()->{'account_id'}) && $self->session()->{'account_id'} > 0) {

		# Get a account object from the database but don't bother verifying
		# the login since it should be safe in the session
		
		$self->account_id($self->session()->{'account_id'});
		$self->account(GODOTConfig::DB::Accounts->retrieve($self->account_id()))
			or GODOTConfig::Exception::App::CGI->throw('Error retrieving account id "' . $self->account_id . '" which was defined in a session.  Possible corruption of session data has occured.');

		if (defined($self->session()->{'current_site_id'})) {
			$self->current_site(GODOTConfig::DB::Sites->retrieve($self->session()->{'current_site_id'})) or
				GODOTConfig::Exception::App::CGI->throw('Error retrieving site id"' . $self->session()->{'current_site_id'} . '" which was defined in a session.');
		}
	} else {
		return 'login';
	}

	return($state);
}



##
## check_password - Checks the password passed in against the password in the Account record.  If
##                  encrypted passwords are being used, the password is encrypted first.
##
## Returns: 1 on good password, 0 on bad password, undef on failure.
##

sub check_password {
	my ($self, $password_crypted, $password_check) = @_;
	report_location if $C_CGI_TRACE;
	
	$password_check = '' if !defined($password_check);
	
	# Check for no password first... fail.  Nobody should have a blank password.
	if (!defined($password_crypted) || $password_crypted eq '') {
		return 0;
	}

	# This could be changed to call back to the GODOT object to centralize crypt stuff

	$password_check = crypt($password_check, $password_crypted);
	return $password_check eq $password_crypted ? 1 : 0;	
}



##
## get_session - Tries to retrieve a session key from client side cookies
##               and retrieve it from the local session store.  If there is no
##               session, one is created.
##
##               $C_CGI_SESSION_TYPE (set in Config.pm) should contain a
##               string like 'Apache::Session::File' - the session module to
##               use.  $C_CGI_SESSION_CONFIG is a hash of configuration info to
##               pass into the session setup.
##
## Returns: Reference to the session hash on success, undef on failure.
##

sub get_session {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	my $base_dir = defined($self->session_dir) ? $self->session_dir : $GODOTConfig::Config::GODOT_CONFIG_TOOL_SESSION_DIR;
	if (!defined($base_dir)) {
		warn("Error, badly configured system, no session directory set.");
		return undef;
	}
	$base_dir .= '/' unless $base_dir =~ m#/$#;

	my $installation_name = defined($self->installation_name) ? $self->installation_name : $C_CGI_INSTALLATION_NAME;
	if (!defined($installation_name)) {
		warn("Error, badly configured system, no installation name set.");
		return undef;
	}

	my $session_config_hash = $C_CGI_SESSION_CONFIG;
	defined($session_config_hash) or
		$session_config_hash = {
			'Directory' => $base_dir,
			'LockDirectory' => $base_dir . '/lock',
		};
	
	my $session_id;
	my %cookies = fetch CGI::Cookie;
	if (defined($cookies{'GODOT_SESSION_ID'}) && defined($cookies{'GODOT_SESSION_ID'}->value()) && $cookies{'GODOT_SESSION_ID'}->value() =~ /^\w+$/) {
		$session_id = $cookies{'GODOT_SESSION_ID'}->value();
		debug("Got session cookie: $session_id") if $C_CGI_DEBUG;
	}

	my %session;
	eval { tie %session, $C_CGI_SESSION_TYPE, $session_id, $session_config_hash; };
	if ($@ =~ /Object does not exist in the data store/) {
		eval { tie %session, $C_CGI_SESSION_TYPE, undef, $session_config_hash; };
	}
	if ($@) {
		warn("Error creating session: $@");
		return undef;
	}

	# Double check we haven't got another system's session

	if (!defined($session{'installation_name'})) {
		$session{'installation_name'} = $self->installation_name();
	} else {
		if ($session{'installation_name'} ne $self->installation_name()) {
			warn("Error, badly configured system, installation name in cookies does not match.");
			return undef;
		}
	}

	return \%session;
}






##
## build_page - does the actual work of building the web page and returns
##              the text of the page for output.
##
## Returns: complete web page including headers/body on sucess, undef on failure
##

sub build_page {
	my ($self, $state) = @_;
	report_location if $C_CGI_TRACE;

	$state ||= 'main';  # Default state if not set

	$self->content('');  # Clear content, removes a warning and is a good idea anyway
	my @submission_errors;

	# Loop and dispatch handlers based on the current state.
	
	while ($state ne 'complete' && $state ne 'pass-through') {
		$self->last_state($state);
		# Process submission errors

		if (defined($self->submission_errors) && scalar(@{$self->submission_errors}) > 0) {
			push @submission_errors, @{$self->submission_errors};
		}
		# Attempt to dispatch (use eval in case the process_$state has not been defined yet)
		
		my $method = "process_$state";
		debug("Attempting to process state: $state") if $C_CGI_DEBUG;
		eval { no strict 'refs'; $state = $self->$method(); use strict 'refs'; };
		if ($@) {
			$state = $self->return_error("Error running state processing method: $method:", $@);
		}
	}

	my $output;
	if ($state eq 'complete') {

		# Assign defaults for each page section not explicitly handled in the state loop above

		$self->http_header($self->default_http_header()) unless defined($self->http_header());
		$self->sidebar($self->default_sidebar()) unless defined($self->sidebar());
		$self->http_footer($self->default_http_footer()) unless defined($self->http_footer());
	
		$output = $self->http_header();

                #### debug ">>>>>>>>>>>>>>> ", join('--', @submission_errors);

		my $hash = { 'page_heading_image' => $self->page_heading_image(),
                             'sidebar' => $self->sidebar(),
                             'errors' => \@submission_errors,
                             'page_content' => $self->content(),
                             'url' => url(-relative=>1) };

		$hash->{'account_name'} = $self->account->name if defined($self->account);
		$hash->{'current_site'} = $self->current_site->name if defined($self->current_site);

		$self->template->process('main_layout', $hash, \$output) ||
			GODOTConfig::Exception::App::CGI::Template->throw($self->template->error);
		
		$output .= $self->http_footer();

	} elsif ($state eq 'pass-through') {
		$output = $self->http_header() . $self->content();
	} else {
		error("Error, entered invalid 'finishing' state: $state");
		return undef;
	}
	             
	return \$output;			
}


##
## process_error - Displays any error messages stored in $self->{'err'}.
##
## Returns: next state to enter: 'complete' on success, 'error' on error
##

sub process_error {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	my $content = h2("Error in GODOT");
	foreach my $err (@{$self->{'err'}}) {
		$content .= ref($err) ? $err->error() : $err;
		$content .= '<BR>';
	}	

	$self->content($content);

	return 'complete';
}


##
## process_login - Displays the account login screen, including a site choice
##                 if a site has not been selected already.
##
## Returns: next state to enter: 'complete' on success, 'error' on error
##

sub process_login {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->sidebar('');

	$self->template->process('login', {}, $self->get_append_content);
	$self->page_heading_image('title_login.jpg');

	return 'complete';
}

##
## process_logout - Logs a account out by clearing the session cookies and
##                  returning to the 'login' state.  Sets the $http_header
##                  variable to include the modified cookie.
##
## Returns: next state to enter: 'login' on success, 'error' on error
##

sub process_logout {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->remove_session();
		
	return 'login';
}



##
## proces_main - Displays the main screen which may have things like alerts,
##               etc.
## 
## Returns: next state to enter: 'login' on success, 'error' on error
##

sub process_main {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;
	
	$self->template->process('main', {}, $self->get_append_content);
	$self->page_heading_image('title_home.jpg');

	return 'complete';
}


##
## process_authentication_failed - Displays the failed login screen caused
##                                 by an incorrect password where the account
##                                 key exists.  If encrypted passwords are
##                                 NOT being used, the option to mail your
##                                 password is included.
##
## Returns: next state to enter: 'complete' on success, 'error' on error
##

sub process_authentication_failed {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->template->process('authentication_failed', {'account_key' => $self->account_key}, $self->get_append_content);

	return 'login';
}


##
## process_unknown_account_key - Displays the failed login screen caused by a account key which is unknown.
##
## Returns: next state to enter: 'complete' on success, 'error' on error
##

sub process_unknown_account {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	$self->template->process('unknown_account', {'account_key' => $self->account_key}, $self->get_append_content);

	return 'login';
}



##
## default_http_header - Produces HTTP headers which do MAY rely on there being
##                       a current site or account.
##
##
## Returns: String containing HTTP headers on success, undef on failure.
##

sub default_http_header {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;


	my @cookies;
	if (defined($self->session())) {
		push @cookies, new CGI::Cookie('-name' => 'GODOT_SESSION_ID', '-value' => $self->session()->{'_session_id'}, '-path' => '/');
	} else {
		# Logout/Login state normally
                push @cookies, new CGI::Cookie('-name' => 'GODOT_SESSION_ID', '-value' => '', '-path' => '/', '-expires' => '-1Y');
	}

        
        if (defined $self->cookies) {
            foreach my $cookie (@{$self->cookies}) {
	        push @cookies, $cookie;
            }
        }       

	#### my $http_header .= header('-cookies'=> [ @cookies ]);
        ##
        ## Display page in utf-8. (Andrew Sokolov of Saint-Petersburg State University Scientific Library)
        ##
        my $http_header .= header('-cookies'=> [ @cookies ], '-CHARSET' => 'UTF-8');

	my $style = {'-SRC' => [$C_CGI_CSS]};
	$self->css and
                push @{$style->{'-SRC'}}, $C_CGI_CSS_DIR . $self->css;

	-e $C_CGI_CSS_DIR . $self->last_state . '.css' and
		push @{$style->{'-SRC'}}, $C_CGI_CSS_DIR . $self->last_state . '.css';
		
	$http_header .= start_html({'-TITLE' => 'GODOT Configuration Tool',
	                            '-STYLE' => $style,
	                            '-SCRIPT' => {'-LANGUAGE' => 'JavaScript', '-src' => $C_CGI_JAVASCRIPT},
	                            '-META' => {'-KEYWORDS' => 'GODOT configuration todd holbrook',
	                                        '-DESCRIPTION' => 'GODOT Configuration',
	                                       },
	                            '-LEFTMARGIN' => 0,
	                            '-RIGHTMARGIN' => 0,
	                            '-TOPMARGIN' => 0,
	                            '-MARGINWIDTH' => 0,
	                            '-MARGINHEIGHT' => 0,
	                            '-ONLOAD' => $self->onload || '',
	                });

	return $http_header;
}

##
## default_http_footer - Produces HTTP footers which do MAY rely on there being
##                       a current site or account.
##
##
## Returns: String containing HTTP footers on success, undef on failure.
##

sub default_http_footer {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	return end_html();
}


##
## Default template routines.
##


sub default_sidebar {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;

	my $url = url(-relative=>1);
	my @menu = ();

	if (defined($self->account())) {
		push @menu, ['Home', "$url?state=main", 'main'];

		if ($self->current_site) {
			push @menu, ['Sandbox', "$url?state=local_sandbox", 'local_sandbox'];
			push @menu, ['Configuration', "$url?state=local_configuration", 'local_configuration'];
			push @menu, ['Templates', "$url?state=local_templates", 'local_templates'];
			push @menu, ['Style Sheets', "$url?state=local_css", 'local_css'];
		}

		my @sites = $self->account()->sites;
		if (scalar(@sites) > 1 || $self->account->administrator) {
			push @menu, ['Change Site', "$url?state=general_change_site", 'change_site'];
		}

		if ($self->account->administrator) {
			push @menu, ['Global Templates', "$url?state=global_templates", 'global_templates'];
			push @menu, ['Global Style Sheets', "$url?state=global_css", 'global_css'];
			push @menu, ['System Administration', "$url?state=admin_menu", 'system_administration'];
		}

		if (defined($self->current_site)) {
			push @menu, ['Site Administration', "$url?state=local_edit_site", 'site_administration'];
		}
		push @menu, ['Account Administration', "$url?state=local_edit_account", 'account_administration'];
		push @menu, ['Logout', "$url?state=logout", 'logout'];
	}

	my $menu;
	$self->template->process('sidebar', {'menu' => \@menu}, \$menu);

	return $menu;
}


##
## get_state_from_params - Attempt to get the state and any extra CGI parameters encoded in a "state_..."
##                         parameter.  This is to allow extra information to be passed through from a button
##                         without resorting to multiple forms or hidden field tricks.
##
## Side Effects: May set param() variables if they're found encoded in the "state_..." parameter
##
## Returns: State as a string if state parameter found, undef otherwise
##

sub get_state_from_params {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;
	
	foreach my $param (param()) {
#		debug("get_state_from_params: $param = " . param($param));
		next unless $param =~ /^state_([^\.]+)/;  # No \. because of image links getting .x/.y names.  Doh

		my ($state, @params) = split /!/, $1;
		
		foreach my $param (@params) {
			my ($field, $value) = split /:/, $param;
			param($field, $value);
		}

		debug("Found special state parameter: $param: " . param($param)) if $C_CGI_DEBUG;
		
		return $state;
	}
	return undef;

}


                        

##
## return_error - Pushes an error onto the internal error stack ($self->{'err'}) and returns the
##                string "error", which if returned from a state processing subroutine (process_*), 
##                should then call the process_error subroutine to display the error(s) nicely.
##
## Returns: 'error' as a string
##

sub return_error {
	shift->set_error(@_);
	return 'error';
}	

sub set_error {
	my ($self) = shift;
	report_location if $C_CGI_TRACE;

	my $error_string;
	foreach my $err (@_) {
		$error_string .= $err;
		if (ref($err)) {
			warn("\n-------error trace------------\n" . $err->trace->as_string . "\n----------------------------\n") if $err->can('trace');
		}
	}
	push @{$self->{'err'}}, $error_string;
	error($error_string);

	return 1;
}



##
## __quote_values - Used by templates to quote strings which will be in VALUE="" fields
##
## Returns: String
##

sub __quote_values {
	my ($string) = @_;

	if (defined($string) && $string ne '') {
		$string =~ s{&}{&amp;}gso;
		$string =~ s{<}{&lt;}gso;
		$string =~ s{>}{&gt;}gso;
		$string =~ s{"}{&quot;}gso;  #"
		$string =~ s{\012}{&#10;}gso;
		$string =~ s{\015}{&#13;}gso;
	} else {
		$string = '';
	}
	
	return $string;
}


##
## __popup_menu - Shortcut used by templates to display popup menus
##
## Returns: String
##

sub __popup_menu {
	my ($list_ref, $id_method, $label_method, $name, $default, $class, $include_blank) = @_;
	
	GODOTConfig::Exception::App::CGI->throw('No list of records passed into __popup_menu') unless defined($list_ref) && ref($list_ref) eq 'ARRAY';
	GODOTConfig::Exception::App::CGI->throw('No id method passed into __popup_menu') unless defined($id_method);
	GODOTConfig::Exception::App::CGI->throw('No label method passed into __popup_menu') unless defined($label_method);
	GODOTConfig::Exception::App::CGI->throw('No name passed into __popup_menu') unless defined($name);

	my @values;
	my %labels;
	foreach my $item (@$list_ref) {
		push @values, $item->$id_method;
		$labels{$item->$id_method} = $item->$label_method
	}	
	if ($include_blank) {
		unshift @values, '';
		$labels{''} = '';
	}

	return popup_menu(-name => $name, -default => $default, -class => $class, -values => \@values, -labels => \%labels);
}

sub remove_session {
	my ($self) = @_;
	
	# Must untie and delete a session at logout to remove it from server storage
	
	if (defined($self->session())) {
		untie($self->{'__session'});
		delete($self->{'__session'});	
	}
	
	return 1;
}
                                                               	
sub append_content {
	my ($self, $content) = @_;
	
	return $self->content($self->content . $content);
}

##
## Returns a closure to pass to templates for appending to the content variable
##

sub get_append_content {
	my $self = $_[0];
	return sub { my $y = shift; $self->append_content($y); };
}

##
## Returns a closure to pass to templates for setting the content variable
##

sub get_content {
	my $self = $_[0];
	return sub { my $y = shift; $self->content($y); };
}


1;

__END__


=head1 NAME

GODOTConfig::ConfigTool::CGI - produces web pages, forms, etc, for maintenance screens

=back

=head1 AUTHORS / ACKNOWLEDGMENTS

Written by Todd Holbrook (tholbroo@sfu.ca)

=back

=cut
