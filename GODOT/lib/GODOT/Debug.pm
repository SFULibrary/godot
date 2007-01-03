## GODOT::Debug
##
## Copyright (c) 2001, Todd Holbrook, Simon Fraser University
##
## Contains various commands for exporting which handle debug, warning, error
## messages, etc.  Prints to STDERR, might be modified to send to a log file.
##

package GODOT::Debug;

use Exporter ();
@ISA = qw( Exporter );
@EXPORT = qw(
	debug
	error
	warning
	send_admin_email
	report_location
        report_time_location
        location
        log_message_to_file
);

@EXPORT_OK = qw(
	debug
	error
	warning
	report_location
        report_time_location
        location
        log_message_to_file
);

use GODOT::Config;
use CGI qw(:standard);
use Time::HiRes qw(gettimeofday tv_interval);
use strict;



BEGIN {
    my $time = gettimeofday;
    sub report_time_location {
	my ($pack1, $file1, $line1, $subname1, $hasargs1, $wantarray1) = caller(1);
	my ($pack0, $file0, $line0, $subname0, $hasargs0, $wantarray0) = caller();

        my $delta = tv_interval([$time]);
        if ($delta < 0.0001) { $delta = 0; }  
        return unless ($delta >= 0.1);

        print STDERR "Delta [line $line0] [pid $$]: ", $delta, ' in ', $subname1, "\n";
        $time = gettimeofday;
    }
}


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
	my ($pack, $file, $line, $subname, $hasargs, $wantarray) = caller(1);
	print STDERR "Trace: $subname\n";
}

sub location {
	my ($pack, $file, $line, $subname, $hasargs, $wantarray) = caller(1);
	return $subname;
}


sub send_admin_email {
    my($maillist, $message) = @_; 
    local(*SENDMAIL);
    my($subject);   

    $subject = "Message from GODOT"; 
    my($sendmail) = '/usr/lib/sendmail -t -n';
    $message = "\n\nremote_host: " . &CGI::remote_host  . "\n\nreferer: " . &CGI::referer . "\n\n" . $message;
    open (SENDMAIL, "| $sendmail") || return;
    print SENDMAIL <<End_of_Message;
From: 
To: $GODOT::Config::MAILLIST_HASH{$maillist}
Reply-To:
Subject: $subject

$message
End_of_Message

    close(SENDMAIL);
}

##
## -useful for comparing structures/objects of production and development copies
##
sub log_message_to_file {
    my($name, $message) = @_;

    use CGI qw(:remote_host :server_port);
    return unless (remote_host() eq 'hs72260.lib.sfu.ca');

    my $filename = "/tmp/$name." . server_port();

    use FileHandle;
    my $fh = new FileHandle;
    $fh->open("> $filename") || return;
    print $fh $message, "\n";
    $fh->close;  
}




1;

__END__

=head1 NAME

GODOT::Debug - Debug routines for the GODOT system

=head1 METHODS

=over 4

=item debug($message)

=item warning($message)

=item error($message)

All these routines write I<$message> to STDERR.

=item send_admin_email($maillist, $message)

Sends I<$message> by email to the mailing list specified by
I<$maillist>. Possible values for I<$maillist> include:
'parser' for parser admin and 'godot' for GODOT admin.

=back

=head1 AUTHORS / ACKNOWLEDGMENTS

Written by Todd Holbrook, based on existing GODOT code by Kristina Long and
others over the years at SFU.

=cut
