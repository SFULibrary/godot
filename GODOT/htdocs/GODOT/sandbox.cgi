use Data::Dumper;

use GODOTConfig::Config;
use GODOT::Config;
use GODOTConfig::Configuration;
use CGI qw(:standard);

use GODOTConfig::DB::Sites;
use GODOTConfig::Exceptions;
use GODOT::Debug;

use strict;

my $site = GODOTConfig::DB::Sites->retrieve(param('site_id'));
my $site_key = $site->key;
my $sandbox = param('sandbox');

##
## For now, use configuration object linked to database instead of GODOTConfig::Cache object
##
my $configuration = new GODOTConfig::Configuration($site_key, 'sandbox');

my $frozen_object_file = "$GODOT::Config::SANDBOX_OBJECT_DIR/$sandbox";

unless (-e $frozen_object_file)  {
    print error_screen("Unable to find sandbox frozen object: $frozen_object_file");
    exit;
}

unless (open FROZEN, $frozen_object_file)  {
    print error_screen("Unable to open sandbox frozen object: $frozen_object_file: $!");
    exit;
}

my $frozen_data;
while (<FROZEN>) {
	$frozen_data .= $_;
}
close FROZEN;
	
##
## cleanup
##
	
$frozen_data =~ s/^=====+\n?$//gm;

{	
	use GODOT::Template;
	use GODOT::Page;
	use GODOT::PageElem::Record;
	use GODOT::Database;
	use GODOT::Citation;
	use GODOT::CUFTS;

	my $VAR1;
	eval $frozen_data;

	$VAR1->{'page'}->template_vars->{'page'} = $VAR1->{'page'};

        debug join("\n", $configuration->template_include_path);
       
	my $template = new Template({'INCLUDE_PATH' => [$configuration->template_include_path], 
                                     'PRE_CHOMP'    => 1,
                                     'POST_CHOMP'   => 1,
                                     'VARIABLES'    => {'config' => $configuration}});

	print header();
	my $output;
	$template->process('main_layout', $VAR1->{'page'}->template_vars, \$output);

	print $output;
}

sub error_screen {
    my($error) = @_;

    return header . start_html . $error . end_html;
}




1;

