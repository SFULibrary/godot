##
## Copyright (c) 2001, Todd Holbrook
##
## Contains various commands for exporting which handle debug, warning, error
## messages, etc.  Prints to STDERR, might be modified to send to a log file.
##

package GODOTConfig::Debug;

use Exporter ();
@ISA = qw( Exporter );
@EXPORT = qw(
	debug
	error
	warning
	send_admin_email
	report_location
);

@EXPORT_OK = qw(
	debug
	error
	warning
	report_location
);

use CGI qw(:standard);
use strict;

sub debug {
	print STDERR (join '', 'Debug: ', @_, "\n");
}

sub warning {
	print STDERR (join '', 'Warning: ', @_, "\n");
}

sub error {
	print STDERR (join '', 'Error: ', @_, "\n");
}

sub report_location {
	my ($pack, $file, $link, $subname, $hasargs, $wantarray) = caller(1);
	print STDERR "Trace: $subname\n";
}




##
## (01-jul-2010 kl) comment out instead as no longer being used; 
## (01-jul-2010 kl) switched to using GODOT::Email;
##
#### sub send_admin_email {
####    my($to, $message) = @_; 
####
####    use GODOT::Email;
####
####    $subject = "Message from GODOT (debug)"; 
####    $message = "\n\nremote_host: " . &CGI::remote_host  . "\n\nreferer: " . &CGI::referer . "\n\n" . $message;
####
####    send_email('', '', $to, $subject, $message);
#### }
####

1;

__END__

=head1 NAME

GODOTConfig::Debug - Debug routines for the GODOT system

=head1 METHODS

=over 4

=item debug($message)

=item warning($message)

=item error($message)

All these routines write I<$message> to STDERR.

=item send_admin_email($maillist, $message)

Sends I<$message> by email to the recipients specified by
I<$to>.


=back

=cut
