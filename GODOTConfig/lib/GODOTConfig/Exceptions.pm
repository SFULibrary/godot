#
# Copyright Todd Holbrook - Simon Fraser University (2003)
#
package GODOTConfig::Exceptions;

push @ISA, 'Exporter';

@EXPORT_OK = qw(assert_ne);

use Exception::Class(
	GODOTConfig::Exception::DB => {
		description => 'database exception',
		fields => 'info' 
	},

	GODOTConfig::Exception::App => {
		description => 'application exception',
	},

	GODOTConfig::Exception::App::CGI => {
		description => 'CGI application exception',
	},

	GODOTConfig::Exception::App::CGI::Template => {
		description => 'CGI application template exception',
	},


);


##
## Asserts that a string is defined and not empty
##

sub assert_ne {
	return defined($_[0]) && $_[0] =~ /\S/;
}

1;
