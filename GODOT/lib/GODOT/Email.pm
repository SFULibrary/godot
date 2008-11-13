## GODOT::Email
##
## Copyright (c) 2008, Kristina Long, Simon Fraser University
##
## Contains subroutines related to email.  
## Existing modules need to be changed to use these subroutines instead of current inline code.
##

package GODOT::Email;

use Exporter ();
@ISA = qw( Exporter );
@EXPORT = qw(
        send_email
);

@EXPORT_OK = qw(
        send_email
);

use GODOT::Config;
use GODOT::Debug;
use GODOT::String;
use strict;

##
## (30-oct-2008 kl) -- added for use in GODOT::local::ILL::Message::RELAIS::SRU so that 
##                     they could have an email in addition to soap message to relais;
##
sub send_email {
    my($sender_name, $sender_email, $email, $subject, $message) = @_; 

    if (aws($email)) {
        debug "No email address given for message from '$sender_email', with subject '$subject'";
        return;
    }

    use FileHandle;
    my $fh = new FileHandle "| $GODOT::Config::SENDMAIL";

    unless (defined $fh) {
        debug "Could not open mail program for message from '$sender_email', to '$email', with subject '$subject'";
        return;
    }

    print $fh <<End_of_Message;
From: $sender_name <$sender_email>
To: $email
Reply-To: $sender_email
Subject: $subject

$message
End_of_Message

    $fh->close;
}

1;

__END__

=head1 NAME

GODOT::Email - Email routines for the GODOT system

=head1 METHODS

=over 4

=back

=head1 AUTHORS / ACKNOWLEDGMENTS

=cut
