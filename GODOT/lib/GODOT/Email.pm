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
@EXPORT = qw(send_email
             send_email_encoded
);

use strict;
use Encode;
use Data::Dump qw(dump);
use GODOT::Config;
use GODOT::Debug;
use GODOT::String;
use GODOT::Encode::Transliteration;

my $TRUE = 1;
my $FALSE = 0;

my $MAX_BODY_LINE_LENGTH = 900;

my @TRANSLITERATION_TYPES = qw(utf8 latin1 ascii);
my @ENCODING_TYPES = qw(utf8 latin1 ascii);


sub send_email {
    my($sender_name, $sender_email, $email, $subject, $message) = @_; 

    return send_email_encoded($sender_name, $sender_email, $email, $subject, $message, 'utf8', 'utf8');
}

##
## (30-oct-2010 kl) -- added $transliteration parameter
## (24-oct-2010 kl) -- added $encoding parameter
##                  -- for now, fail if header data is non-ascii;
## (01-jul-2010 kl) -- added logic for utf8 in both headers and body;
## (30-oct-2008 kl) -- added for use in GODOT::local::ILL::Message::RELAIS::SRU so that they could have an email in addition to soap message to relais;
##
sub send_email_encoded {
    my($sender_name, $sender_email, $email, $subject, $message, $transliteration, $encoding) = @_; 

    unless (grep {$transliteration eq $_} @TRANSLITERATION_TYPES) {
        debug location_plus, "Unexpected requested transliteration -- $transliteration\n";
        return $FALSE;
    }

    unless (grep {$encoding eq $_} @ENCODING_TYPES) {
        debug location_plus, "Unexpected requested encoding -- $encoding\n";
        return $FALSE;
    }

    ##
    ## (30-oct-2010) -- pass both parameters for now but ignore transliteration ...
    ##
    unless ($transliteration eq $encoding) {
        debug location_plus, "Transliteration ($transliteration) and encoding ($encoding) do not match.\n";
        return $FALSE;
    }

    if (aws($email)) {
        debug "No email address given for message from '$sender_email', with subject '$subject'";
        return $FALSE;
    }

    my $header_not_ascii = (grep { not_ascii($_) } ($sender_name, $sender_email, $email, $subject)) ? $TRUE : $FALSE;
    if ($header_not_ascii) {
        debug "Header data has non-ascii characters.  This case is not currently handled.";
        return $FALSE;
    }

    ####
    #### if ($header_not_ascii) {
    ####    $header_from = encode_utf8_encode_mimeq($header_from);
    ####    $header_to = encode_utf8_encode_mimeq($header_to);
    ####    $header_reply_to = encode_utf8_encode_mimeq($header_reply_to);
    ####    $header_subject = encode_utf8_encode_mimeq($header_subject); 
    #### }
    ####

    my $header_from = "$sender_name <$sender_email>";    
    my $header_to = $email; 
    my $header_reply_to = $sender_email;
    my $header_subject = $subject;

    my $body = $message;
    my $body_not_ascii = not_ascii($body) ? $TRUE : $FALSE;

    if ($encoding eq 'utf8') {
        $body = GODOT::String::encode_string('utf8', $body);
    }    
    elsif ($encoding eq 'latin1') {
        if ($body_not_ascii) {      
            debug location_plus, 'transliterating to latin1'; 
            $body = GODOT::String::encode_string('latin1', transliterate_string_preserve_linefeed('latin1', $body));
        }
    }
    elsif ($encoding eq 'ascii') {
        if ($body_not_ascii) {      
            debug location_plus, 'transliterating to ascii'; 
            $body = transliterate_string_preserve_linefeed('ascii', $body);
        }    
    }
    else {
        debug location_plus, 'we should not be here';
        return $FALSE;
    }

    my $content_type;
    my $content_transfer_encoding;

    ##
    ## Not expecting really long lines.
    ##
    foreach my $line (split("\n", $body)) {
        #### debug location_plus, 'line length is ', length($line);
        if (length($line) > $MAX_BODY_LINE_LENGTH) {
            debug location_plus, "line contained in body of message is greater than $MAX_BODY_LINE_LENGTH\n";
            debug Data::Dump::dump($line);
            return $FALSE;
        }
    }
    
    ##
    ## ???? replace 'Content-Transfer-Encoding:  8bit' with 'Content-Transfer-Encoding:  quoted-printable' for messages with lines > 1000 characters ???
    ##
    if ($encoding eq 'utf8') {
        $content_type = "\nContent-type: text/plain; charset=UTF-8\n";
        $content_transfer_encoding = "Content-Transfer-Encoding:  8bit";
    }
    elsif ($encoding eq 'latin1') {
        $content_type = "\nContent-type: text/plain; charset=iso-8859-1\n";
        $content_transfer_encoding = "Content-Transfer-Encoding:  8bit";
    }
    
    my $complete_message .=<<"End_of_Message"; 
From: $header_from
To: $header_to
Reply-To: $header_reply_to
Subject: $header_subject$content_type$content_transfer_encoding

$body
End_of_Message

    debug location;
    #### debug '------------------------------------------------------';
    #### foreach my $line (split("\n", $complete_message)) {
    ####    debug Data::Dump::dump($line);
    #### }
    #### debug '------------------------------------------------------';

    use FileHandle;
    my $fh = new FileHandle "| $GODOT::Config::SENDMAIL";

    unless (defined $fh) {
        print "Could not open mail program for message from '$sender_email', to '$email', with subject '$subject'";
        return $FALSE;
    }

    print $fh $complete_message;

    $fh->close;
}

1;

__END__

