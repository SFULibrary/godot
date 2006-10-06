#!/usr/local/bin/perl
##
## GODOT installation script.
##
## -m    check for required modules and then exit without installing GODOT
##
##
use strict;

use FindBin qw($Bin);
use lib ("$Bin/../GODOT/lib", "$Bin/../GODOTConfig/lib");

use DBI;
use CGI qw(:escape);

use Install::GODOT;
use Install::GODOTConfig;
use GODOT::String;
use GODOT::Debug;

use Term::ReadLine;

use Template;
use Template::Stash;

my $VERSION = '2.0.0';

my $TRUE  = 1;
my $FALSE = 0;

my $DISTRIB_DIR = 'util/distrib';


my @FILE_SUBSET = qw(util/install.pl
                     GODOT_ORIG/hold_tab.pm
                     GODOT/lib/GODOT/Authentication.pm
                     GODOT/lib/GODOT/CatalogueHoldings.pm
		     GODOT/htdocs/GODOT/hold_tab.cgi
                     GODOT/templates/main_holdings_screen
                     GODOTConfig/templates/main
                     GODOTConfig/lib/GODOTConfig/AdvancedConfig.pm);

my $SFU_GODOT_URL = 'http://godot.lib.sfu.ca:7888/godot/hold_tab.cgi';

my $no_DBI = 0;
my $no_psql = 0;

my @MODULES = qw(Apache::DBI
                 Apache::Session::File
                 Carp 
                 CGI 
                 CGI::Cookie 
                 Class::Accessor 
                 Class::Data::Inheritable 
                 Class::DBI 
                 Class::DBI::AbstractSearch 
	         Class::DBI::Iterator
                 Class::DBI::Query
                 Class::DBI::Relationship                  
	         Data::Dumper
	         Data::Dump
                 DBI
                 Error
                 Exception::Class 
                 Exception::Class::DBI 
                 Exporter
	         File::Basename
                 FileHandle
                 LWP::UserAgent
	         MARC::Record
                 Net::Z3950
                 Parallel::ForkManager
                 POSIX
                 Socket
                 SQL::Abstract 
                 Template
	         Template::Constants
	         Template::Stash
                 Text::Normalize::NACO
                 Text::Striphigh
                 Text::Template
                 Time::HiRes
                 Time::Local              
                 URI::Escape
                 URI::URL);   


$Template::Stash::SCALAR_OPS->{'escapeHTML'} = sub { 
    my $x = shift; 
    return escapeHTML($x);
};

$Template::Stash::SCALAR_OPS->{'escape'} = sub { 
    my $x = shift; 
    return escape($x);
};

$Template::Stash::HASH_OPS->{'format'} = sub { 
    return _format_citation(@_);
};

$Template::Stash::HASH_OPS->{'url'} = sub { 
    return _url_for_citation(@_);
};


##
## Sets up ownership, etc.
##

my $term = new Term::ReadLine 'GODOT Installation';
if (grep {$_ eq '-m'} @ARGV) {
        my $mod_perl_version = &mod_perl_version;
	check_modules($mod_perl_version, [ @MODULES ]);
	print "\n\n";
	exit;
}


##
##  Introduction
##

show_introduction();

##
## Configuration tests... 
##
##     Is DBI and PostgreSQL installed? 
##     Is yaz installed? 
##

printw("\nChecking for necessary tools.\n");

unless (check_DBI()) {
	diew "** DBI or DBD::Pg not found. You can continue with installation, but testing for an existing database will not be possible. It is recommended that you abort the installation here and install DBI\nwith DBD::Pg before continuing. Continue?";
}

unless (check_psql()) {
	diew "** 'psql' or 'createdb' was not found in the current path.\nThis installation script uses the PostgreSQL command\nline tools to set up the database. You can continue without them and install the database yourself\nlater, but it is recommended that you abort the installation here and install PostgreSQL or fix the path.\nContinue?\n";
}

unless (check_yaz()) {
        diew "** The YAZ tool Z39.50 programmers' toolkit is required.  YAZ may be downloaded freely at http://http://www.indexdata.com/yaz/.\n";

}



my $mod_perl_version = &mod_perl_version;

exit unless &check_modules($mod_perl_version, [ @MODULES ]);

printw "Finished preliminary checks.\n\n";
 

##
## Initial directory setup
##

# Get base directory - ignore whatever is in the config file and use the current working dir as a start.
# If it's not the current directory, copy all files there.

chomp(my $cwd = `pwd`);

verify_cwd($cwd);

printw "Current working directory is: $cwd\n";

printw "Into what directory do you want to install GODOT?\n";

my $default_base_dir = (naws($ENV{'GODOT_ROOT_DIR'})) ? $ENV{'GODOT_ROOT_DIR'} : $cwd;

my $input = $term->readline("[$default_base_dir]: ");

my $base_dir;
if (defined($input) && $input =~ /\S/) {
	$base_dir = $input;
} else {
	$base_dir = $default_base_dir;
}

printw "\nInstalling GODOT in: $base_dir\n";

unless ($base_dir eq $cwd) {
	printw "Do you want to copy the GODOT tree to $base_dir?";
	my $input = $term->readline('[Y/n]: ');
	unless ($input =~ /^\s*n/i) {
	    copy_files($base_dir);
	}
}

##
## Load config file and ask for changes. 
##

chdir $base_dir;

my @dirs;


##
## debug-1
##
#### goto _debug;

printw "Next we need to install two packages -- GODOT and GODOTConfig.\n\n";

##
## For GODOT package.
## 

print "\n--- Installing the GODOT package ---";

my $godot_config = &write_config_for_GODOT;
@dirs = &Install::GODOT::directories_to_write($godot_config);
foreach my $dir (@dirs) { &make_dir($dir); }              
&set_permissions([@dirs], $term, $TRUE);
my $web_dir = &setup_web_tree($godot_config, 'GODOT', $ENV{'GODOT_CGI_DIR'});

##
## For GODOTConfig package.
##

print "\n--- Installing the GODOTConfig package ---";

my $godotconfig_config = &write_config_for_GODOTConfig($godot_config);
@dirs = &Install::GODOTConfig::directories_to_write($godotconfig_config);
foreach my $dir (@dirs) { &make_dir($dir); }
&set_permissions([@dirs], $term, $TRUE);
my $config_web_dir = &setup_web_tree($godotconfig_config, 'GODOTConfig', $ENV{'GODOT_CONFIG_CGI_DIR'});

##
## Write godot_httpd.conf file 
##

&create_apache_config_modperl($godot_config, $godotconfig_config, $web_dir, $config_web_dir, $mod_perl_version);	


##
## Demo data and files
##

&site_specific($godot_config, $godotconfig_config);

_debug:

##
## Web pages for testing your installation.
##

&installation_test_pages($godot_config);

printw "\n\nATTENTION:  You are not done yet!  Please run\n\n    perl util/install_db.pl\n\nto set up the configuration profile database and optionally to install demo profile data.\n\nYou may want to run the database install as a different user (ie. postgres) depending on the postgres rights of the current user.\n\n";




##---------------------------------------------------------------------------------------------
##
## show_introduction - Welcome to GODOT, show information, ask to continue
##

sub show_introduction {
    print "Configuring GODOT\n";
    print "=================\n";
}

##
## check_DBI - Checks whether DBI and DBD::Pg are installed
##

sub check_DBI {
    print "DBI installed... ";
    my $dbi = 0;
    my $dbd = 0;
	
    eval { require DBI; };
    if ($@) {
     	print "no.\n";
    } else {
	print "yes.\n";
	$dbi = 1;
    }

    print "DBD::Pg installed... ";
    eval { require DBD::Pg; };
    if ($@) {
	print "no.\n";
    } else {
	print "yes.\n";
	$dbd = 1;
    }

    return ($dbi && $dbd);
}

##
## check_psql - Checks whether PostgreSQL tools are available
##

sub check_psql {
    my $psql = 0;

    print "PostgreSQL tools available... ";

    my $psql_check = `psql --help`;
    if ($psql_check =~ /PostgreSQL/) {
        $psql = 1;
    } 	

    $psql_check = `createdb --help`;
    if ($psql_check =~ /PostgreSQL/) {
	$psql = 1;
    } 	

    print $psql ? "yes.\n" : "no.\n";

    return $psql;
}

##
## check_yaz - Checks whether YAZ is installed
##

sub check_yaz {

    print "YAZ tools available...\n";

    ##
    ## - hung on yaz-client check; use 'which' instead?
    ##
    #### my $yaz_client_check = (`yaz-client` =~ /Z>/);
    #### print "    yaz-client:  ", (($yaz_client_check) ? 'yes' : 'no'), "\n";

    my $yaz_config_check = (`yaz-config --version` =~ /^\d+\.\d+/);
    print "    yaz-config:  ", (($yaz_config_check) ? 'yes' : 'no'), "\n";
    
    #### return ($yaz_client_check && $yaz_config_check);
    return $yaz_config_check;
}

##
## verify_cwd - Checks for various GODOT directories and files to be reasonably sure
##              the script is running from the correct directory.
##

sub verify_cwd {
    my $cwd = shift;
	
    foreach my $file (@FILE_SUBSET) {
	unless (-e "$cwd/$file") {
            diew "*** Installation script run from the wrong directory, or this is an incomplete GODOT package.\n*** ", 
                 "Could not locate file '$file'.\n";
        }
    }
}



sub mod_perl_version {

    my $version;

    foreach my $iter (1 .. 3) {
        printw "Which version of mod_perl are you using (1 or 2)?";
        my $input = $term->readline('[2]: ');

        $input = '2' if aws($input);

        if ($input =~ /^\s*[1|2]\s*$/) {
            $version = $input;
            last;
        }

        printw "You must either enter '1' or '2'." unless $iter == 3;          
    }
    
    unless ($version) {
        diew "*** Unable to continue without a mod_perl version ***\n";
    }

    return $version;
}


##
## copy_files - Copies the installation tree to its installation destination
##

sub copy_files {
    my $destination = shift;

    unless (-d $destination) {
	    print "Creating directory $destination ... ";
	    unless (mkdir $destination) {
                my $res = $!; 
                print "failed", (naws($res) ? " ($res)." : "."), "\n";                 
                exit; 
            }
	    print "done.\n";
    }
   
    print "Copying files to $destination ... ";
    `cp -r * $destination`;
    printw "done.\n";
}


sub write_config_for_GODOT {

    return &write_config('GODOT',
                         $base_dir,
                         $Install::GODOT::CONFIG_FILE, 
                         $Install::GODOT::HEADER,
                         \@Install::GODOT::CONFIG_VARS,
                         \%Install::GODOT::CONFIG_VARS_DESC, 
                         \%Install::GODOT::DEFAULT_VALUES);
}

sub write_config_for_GODOTConfig {

    return &write_config('GODOTConfig',
                         $base_dir,
                         $Install::GODOTConfig::CONFIG_FILE,
                         $Install::GODOTConfig::HEADER, 
                         \@Install::GODOTConfig::CONFIG_VARS, 
                         \%Install::GODOTConfig::CONFIG_VARS_DESC, 
                         \%Install::GODOTConfig::DEFAULT_VALUES);
}

sub write_config {
    my($package_name, $base_dir, $config_file, $header, $config_vars, $config_vars_desc, $default_values) = @_;

    printw "\n\nWe will now customize $config_file for the $package_name package.\n\n";

    eval { require $config_file };
    if ($@) { diew "unable to execute $config_file file: $@"; }

    my $config;

    no strict 'refs';
    foreach my $name (@{$config_vars}) {
        my $tmp = 'GODOT::Config::' . $name;
        $config->{$name} = ${$tmp}; 
    }
    use strict;

    ##
    ## -make backup and indicate that this has been done
    ##
    my $config_file_full = $base_dir . "/$package_name/lib/" . $config_file; 
    my $backup = "$config_file_full.backup";

    printw "Making a backup copy of $config_file_full in $backup.\n";

    if (-e $backup)  {
	printw "A copy of $backup already exists. Proceed?";
        my $input = $term->readline('[y/N]: ');
        exit unless $input =~ /^\s*y/i;
    } 

    my $res = `cp '$config_file_full' $backup`; 
    printw "$res\n", "\n" if ($res);

    ##
    ## -prompt for new values
    ##

    my $use_current;
    printw "Do you want to use the current or the installation values as the default?";
    $input = $term->readline('[C/i]: ');
    $use_current = $TRUE unless ($input =~ /^\s*i/i);

    print "\n";

    foreach my $name (@{$config_vars}) {

        my $desc = "$config_vars_desc->{$name}";

        my $default;
        if ($use_current) {
            $default = $config->{$name};
        }
        elsif (defined $default_values->{$name}) {
            $default = eval "\"$default_values->{$name}\"";
            diew "$@\n" if $@;
        }

        my $default_string = " [$default]" if defined $default;
       
        my $input = $term->readline("$desc$default_string: ");
        if ((defined $default) && ($input eq '')) {
            $config->{$name} = $default;
        }
        else {
            $config->{$name} = $input;
        }
        print "\n";
    }

    print "\n";

    ##
    ## -write new config file
    ##
    
    printw "Updating the configuration file with the new settings ...";

    my $maxlen;

    foreach my $name (@{$config_vars}) {
        if (length($name) > $maxlen) { $maxlen = length($name); }
    }

    open CONFIG, "> $config_file_full"  or diew "Unable to open configuration file for writing: $!";
	
    print CONFIG "$header\n", "use strict;\n\n", "use vars qw(\n";

    my $version_var = 'VERSION';

    foreach my $name ($version_var, @{$config_vars}) {
        print CONFIG "    \$$name\n";
    }

    print CONFIG ");\n\n";

    foreach my $name ($version_var, @{$config_vars}) {
        my $tmp = '%-' . $maxlen  . 's';
        my $value = ($tmp eq $version_var) ? $VERSION : $config->{$name};

        printf CONFIG "\$$tmp = '%s';\n", $name, $value;
    }
    
    print CONFIG "\n1;\n";
 
    close CONFIG;

    printw "Done";

    return $config;
}
	

sub make_dir {
    my($newdir) = @_;

    my @dirs = split('/', $newdir);
    my $path;

    foreach my $dir (@dirs) {

        next unless ($dir =~ m#\S#);

	my $full_dir = "$path/$dir";

	#### print $full_dir, "\n";

	unless (-d $full_dir) {
	    my $res = mkdir $full_dir;
	    unless ($res) { printw "creation of '$full_dir' failed:  $!\n"; }
	}

	$path = $full_dir;
    }
}



sub setup_web_tree {
    my ($config, $package, $cgi_dir) = @_;
      
    my $basedir = "$config->{'GODOT_ROOT'}/$package";

    printw "\nConfiguring the web tree ...\n";
	
    printw "\nEnter the full path for where the GODOT CGI files will be located.\n", 
           "It should be under the web tree, and the directory must be able to execute CGI scripts:\n";

    my $input;

    while ($input eq '' || -d $input || -e $input) {

	$input = $term->readline("[$cgi_dir]: ");        
        $input = $cgi_dir if aws($input);

	if (-d $input) {
	    printw "\nThe directory you just specified already exists. Please specify a directory that does not already exist. It will be symlinked from the GODOT installation." .
                   "Please delete the existing directory or enter a new directory which does not exist:\n";
        }
	elsif (-e $input) {
	    printw "\nThere is already a file with that directory name. Please specify a directory that does not already exist. It will be symlinked from the GODOT installation." .
                   "Please delete the existing file or enter a new directory which does not exist:\n";
        }
    }

    $input =~ s#/$##;
    my $web_dir = $input;
    (my $dir = $web_dir) =~ s#/[^/]+$##;
	
    unless (-d $dir) {
	print "Creating directory for link... ";
	my $result = `mkdir -p $dir 2>&1`;
	if ($result =~ /^mkdir:\scannot/) {
	    diew "Unable to create directory:\n$result\n";
	}
	print "done.\n";
    }

    my $cmd = "ln -s $basedir/htdocs/$package/ $web_dir 2>&1";

    printw "Linking into web tree:", 
 
    my $result = `$cmd`;
    if ($result =~ /ln:\s+(.+)$/) {
	printw "\n$1\nUnable to create link into web tree.  You will need to do this manually.\n";
    }
    else {
        printw "done\n";
    }	

    return $web_dir;
}

sub create_apache_config_modperl {
    my ($config, $config_config, $web_dir, $config_web_dir, $mod_perl_version) = @_;
	
    my $httpd_conf = "$config->{'GODOT_ROOT'}/util/godot_httpd.conf";
    my $startup    = "$config->{'GODOT_ROOT'}/util/startup.pl";

    my @dirs = @Install::GODOT::INCLUDE_DIRS;

    my @include = ( map { "$config->{'GODOT_ROOT'}/$_" }        @Install::GODOT::INCLUDE_DIRS, 
                    map { "$config_config->{'GODOT_ROOT'}/$_" } @Install::GODOTConfig::INCLUDE_DIRS );
  

    my $use_lib_qw = '    use lib qw';
    my $indent     = "\n              ";    

    my $include = join($indent, @include);

    my $perl_module  = ($mod_perl_version eq '1') ? 'Apache::Registry' : 'ModPerl::Registry';
    my $perl_handler = ($mod_perl_version eq '1') ? 'PerlHandler Apache::Registry' : 'PerlResponseHandler ModPerl::Registry';
    my $perl_header_option = ($mod_perl_version eq '1') ? 'PerlSendHeader off' : 'PerlOptions -ParseHeaders'; 

    open CONF, "> $httpd_conf" or diew "Unable to open $httpd_conf file for writing: $!";
  	
    print CONF <<EOF;

<Perl>
$use_lib_qw\[$include\];
</Perl>

PerlRequire $startup   

PerlModule $perl_module

<Directory $web_dir>
        <Files *.cgi>
                SetHandler perl-script
                $perl_handler
                Options ExecCGI
                $perl_header_option
        </Files>
</Directory>

<Directory $config_web_dir>
        <Files *.cgi>
                SetHandler perl-script
                $perl_handler
                Options ExecCGI
                $perl_header_option
        </Files>
</Directory>

EOF

    close CONF;

    boxw "The file '$httpd_conf' has been created. Copy the following line into your Apache config file:\n\n" . 
         "    Include $httpd_conf";
}


sub site_specific {
    my($godot_config, $godotconfig_config) = @_;

    my $input;

    printw "Site specific data/logic is handled in four ways:\n\n",  
           "    1) site profiles stored in a Postgres database\n       (install later with 'perl util/install_db.pl')\n",
           "    2) site specific templates\n",  
           "    3) site specific CSS files\n",
           "    4) site specific modules located in '$godot_config->{'GODOT_ROOT'}/local'\n\n",
           "The site specific profiles, templates and CSS files are managed by the configuration tool.\n";


    #### printw "Directory installation complete. Would you like to install the database?\n";
    #### $input = $term->readline("[Y/n]: ");
    #### unless ($input =~ /^\s*n/i) { &database_setup($godotconfig_config, 'GODOTConfig') unless ($input =~ /^\s*n/i) };

    printw "\nWould you like demo data for the site specific templates, CSS files and modules to be installed?";
    $input = $term->readline('[Y/n]: ');

    unless ($input =~ /^\s*n/i) {

        my $site_template_dir = $godotconfig_config->{'GODOT_SITE_TEMPLATE_DIR'};
        printw "Copying site specific templates to $site_template_dir.\n";
        if (-d $site_template_dir) { print `cp -R $DISTRIB_DIR/GODOTConfig/site_templates/active $site_template_dir`; }
        else                       { printw "Directory '$site_template_dir' does not exist.\n";    }

        my $site_css_dir = $godotconfig_config->{'GODOT_SITE_CSS_DIR'};
        printw "Copying site specific CSS files to $site_css_dir.\n";
        if (-d $site_css_dir) { print `cp -R $DISTRIB_DIR/GODOT/htdocs/GODOT/css/active $site_css_dir`; }
        else                  { printw "Directory '$site_css_dir' does not exist.\n";    }

        printw "Copying site specific modules to 'local'.\n";
        if (-d 'local') { print `cp -R $DISTRIB_DIR/local .`; } 
        else            { printw "Directory 'local' does not exist.\n"; }
    }
}

##
## Check for all the modules GODOT uses.
##

sub check_modules {
    my ($mod_perl_version, $modules) = @_;

    my @modules = (($mod_perl_version eq '1') ? 'Apache::Registry' : 'ModPerl::Registry', @{$modules});

    printw "\nGODOT needs a number of Perl modules to work...\n";

    my @not_found;
    my $missing = 0;
    foreach my $module (sort @modules) {
        print "Checking for module $module... ";
	if (check_module($module)) {
	    print "found\n";
	} else {
	    print "not found\n";
	    $missing++;
            push @not_found, $module;
	}
    }
    if ($missing == 0) {
	printw "Great, you seem to have everything necessary!\n";
    } else {
	print "\nYou're missing $missing modules:\n\n    ", 
	      join("\n    ", @not_found), "\n",
              "\nPlease use CPAN to install them.\nYou can use $0 -m to check for the modules again.\n";
    }

    return ! $missing;
}


sub check_module {
    my ($module) = @_;

    $module =~ s#::#/#g;
    $module .= '.pm';
	
    eval { require $module };
    return $@ =~ /Can't\slocate/ ? 0 : 1;
}

##
## Generate pages for testing links to GODOT and testing the GODOT config tool from the 
## following templates:
##
##    * GODOT/htdocs/GODOT/index.atml
##    * GODOT/htdocs/GODOT/example_citations.atml
##    * GODOT/htdocs/GODOT/citation_form.atml
##    * GODOT/htdocs/GODOT/citation_data.atml (data for example_citations.atml)
##
sub installation_test_pages {
    my($config) = @_;    

    ##
    ## debug-1
    ##
    #### my $template_dir = "/home/kristina/godot/util/distrib/GODOT/htdocs/GODOT";
    #### my $file_dir     = "/home/kristina/godot/GODOT/htdocs/GODOT"; 

    my $template_dir = "$config->{'GODOT_ROOT'}/util/distrib/GODOT/htdocs/GODOT";
    my $file_dir     = "$config->{'GODOT_ROOT'}/GODOT/htdocs/GODOT"; 

    my $prompt;

    $prompt = "\nEnter the URL which will run the GODOT package 'hold_tab.cgi' script:\n"; 
    printw $prompt;

    my $public_url = $term->readline('[' . $ENV{'GODOT_URL'}  . ']: ');

    my $max = 3;
    foreach my $iter (1 .. 3) {
        $public_url = $ENV{'GODOT_URL'} if aws($public_url);       
        if (aws($public_url)) {
            printw "You did not enter a URL.  Without a URL, you will have to edit the 'Installation Test Pages' manually.\n\n";
	    printw $prompt unless ($iter == $max);
        }
    }
    
    $prompt = "\nEnter the URL which will run the GODOTConfig package 'config.cgi' script:\n"; 
    printw $prompt;

    my $config_url = $term->readline('[' . $ENV{'GODOT_CONFIG_URL'}  . ']: ');

    foreach my $iter (1 .. 3) {
        $config_url = $ENV{'GODOT_CONFIG_URL'} if aws($config_url);
        if (aws($config_url)) {
            printw "You did not enter a URL.  Without a URL, you will have to edit the 'Installation Test Pages' manually.\n\n";
	    printw $prompt unless ($iter == $max);
        }
    }

    &page($config, $template_dir, 'index.atml', "$file_dir/index.html", $public_url, $config_url, 
          {'config_url' => $config_url});

    &page($config, $template_dir, 'example_citations.atml', "$file_dir/example_citations.html", $public_url, $config_url, 
          {'sfu_godot_url'   => $SFU_GODOT_URL,
           'local_godot_url' => $public_url, 
           'sid'             => 'SAMPLE:InstallTesting'});

    &page($config, $template_dir, 'citation_form.atml', "$file_dir/citation_form.html", $public_url, $config_url, 
          {'local_godot_url' => $public_url, 
           'sid'             => 'SAMPLE:InstallTesting'});
 
    (my $index_url = $public_url) =~ s#hold_tab\.cgi$#index.html#;
    
    boxw "The Installation Test Page should be found at\n\n    $index_url";
}

sub page {
    my($config, $template_dir, $template_file, $file, $public_url, $config_url, $vars) = @_;

    my $template = new Template({'INCLUDE_PATH' => $template_dir, 
                                 'PRE_CHOMP'    => 1,
			         'POST_CHOMP'   => 1,
			         'VARIABLES'    => $vars
                               });
    my $text;
 
    $template->process($template_file, {}, \$text);

    if ($template->error) { diew "Failed to process template '$template_dir/$template_file' (" . $template->error . ")"; }

    my $fh = new FileHandle "> $file";
    unless (defined $fh) { diew "Unable to open $file for writing."; }
    print $fh $text;
    $fh->close;

    return $text;
}

sub _format_citation {
    my($citation_ref) = shift;
    my %citation = %{$citation_ref}; 

    my $is_article = naws($citation{'atitle'});

    my @first_line;
    my @second_line;

    if ($is_article) {
        push @first_line, $citation{'atitle'};
        push @second_line, $citation{'title'};
    }
    else {
        push @first_line, $citation{'title'};
    }

    my $author = $citation{'aulast'};
    $author .= (naws($citation{'aufirst'})) ? ", $citation{'aufirst'} $citation{'auinit'}" : '';

    push @second_line, _format_field('author', $author);

    foreach my $field qw(issn isbn volume issue date) {
        push @second_line, _format_field($field, $citation{$field});
    }

    my $pages =  _format_field('pages', $citation{'pages'}) || 
                 _format_field('pages', $citation{'spage'} . ((naws($citation{'epage'})) ? '-' : '') . $citation{'epage'}) ||
	         _format_field('page', $citation{'epage'});

    push @second_line, $pages;
    
    my @lines;
    push @lines, join(', ', grep {naws($_)} @first_line);
    push @lines, join(', ', grep {naws($_)} @second_line);
    
    return join('<BR>', grep {naws($_)} @lines);
}

sub _format_field {
    my($label, $value) = @_;

    return '' if aws($value);

    return "<B>$label</B>" . ':  ' . $value;
}

sub _url_for_citation {
    my($citation_ref) = shift;

    my %citation = %{$citation_ref};

    my @fields;

    foreach my $field (keys %citation) {
        push @fields, "$field=" . CGI::escape($citation{$field});
    }

    return join('&', @fields);
};


1;

__END__









