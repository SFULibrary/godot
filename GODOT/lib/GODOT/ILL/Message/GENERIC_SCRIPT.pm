package GODOT::ILL::Message::GENERIC_SCRIPT;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use GODOT::Debug;
use GODOT::String;
use GODOT::Object;

use base qw(GODOT::ILL::Message);

use strict;

my $WRAP_INDENT = 10;
my $WRAP_LEN    = 66;
my $DELIM       = ':';

sub format {
    my($self, $reqno) = @_;

    my $message;

    my $date = $self->date;

    $message .= "\nREQ.NO/NO.DEM: $reqno for " . $self->patron->last_name. " (COPPUL Holdings/Requesting)\n";

    $message .= "\n\n          ILL REQUEST/DEMANDE PEB\n\n";

    $message .= $self->wrap_lf("LSB",    $self->nuc);              ##  Borrowing library
    $message .= $self->wrap_lf("LSP",    $self->lender_site);      ##  Lending library

    ##
    ## Patron info
    ##
    $message .= $self->wrap_lf("P/U",    $self->patron->last_name  . ", " .
                                         $self->patron->first_name . "/" .
                                         $self->patron->library_id);
    ##
    ##      S/E:     Patron status
    ##
    ##      ADR:     Borrowing Library address
    ##
    ## Service
    ##

    if ($self->citation->is_book || $self->citation->is_book_article || $self->citation->is_thesis)  {
        $message .= $self->wrap_lf("SER",    "LOAN/PRET");
    }
    elsif ($self->citation->is_conference)  {

        $message .= $self->wrap_lf("SER",    "CONFERENCE");
    }
    else {
        $message .= $self->wrap_lf("SER",    "PHOTOCOPY/PHOTOCOPIE");
    }

    ##
    ## Bibliographic info
    ##

    if ($self->citation->is_book || $self->citation->is_book_article) {

        $message .= $self->wrap_lf("TIT",    $self->citation->parsed('TITLE'));

        $message .= $self->wrap_lf("AUT",    $self->citation->parsed('AUT'));
        $message .= $self->wrap_lf("P/M",    $self->publisher_statement);

        $message .= $self->wrap_lf("DAT",    $self->citation->parsed('YEAR'));
        $message .= $self->wrap_lf("PAG",    $self->citation->parsed('PGS'));
        $message .= $self->wrap_lf("ART",    $self->citation->parsed('ARTTIT'));
        $message .= $self->wrap_lf("ARA",    $self->citation->parsed('ARTAUT'));

        $message .= $self->wrap_lf("SBN",    $self->citation->parsed('ISBN'));
        $message .= $self->wrap_lf("SSN",    $self->citation->parsed('ISSN'));

        $message .= $self->wrap_lf("O/A",    $self->citation->parsed('SERIES'));
    }
    elsif ($self->citation->is_conference) {
               
        $message .= $self->wrap_lf("TIT",    $self->citation->parsed('TITLE'));
        $message .= $self->wrap_lf("AUT",    $self->citation->parsed('AUT'));

        $message .= $self->wrap_lf("P/M",    $self->publisher_statement);
        $message .= $self->wrap_lf("SBN",    $self->citation->parsed('ISBN'));
        $message .= $self->wrap_lf("SSN",    $self->citation->parsed('ISSN'));

        $message .= $self->wrap_lf("DAT",    $date);

        $message .= $self->wrap_lf("O/A",    $self->citation->parsed('SERIES'));

        $message .= $self->wrap_lf("ART",    $self->citation->parsed('ARTTIT'));
        $message .= $self->wrap_lf("ARA",    $self->citation->parsed('ARTAUT'));

        $message .= $self->wrap_lf("PAG",    $self->citation->parsed('PGS'));
    }   
    elsif ($self->citation->is_journal)  {
               
        $message .= $self->wrap_lf("TIT",    $self->citation->parsed('TITLE'));

        $message .= $self->wrap_lf("VOL",    $self->citation->parsed('VOLISS'));  
        $message .= $self->wrap_lf("P/M",    $self->publisher_statement);
        $message .= $self->wrap_lf("DAT",    $date);

        $message .= $self->wrap_lf("PAG",    $self->citation->parsed('PGS'));
        $message .= $self->wrap_lf("ART",    $self->citation->parsed('ARTTIT'));
        $message .= $self->wrap_lf("ARA",    $self->citation->parsed('ARTAUT'));

        $message .= $self->wrap_lf("SBN",    $self->citation->parsed('ISBN'));
        $message .= $self->wrap_lf("SSN",    $self->citation->parsed('ISSN'));

        $message .= $self->wrap_lf("O/A",    $self->citation->parsed('SERIES'));
    }   
    elsif ($self->citation->is_tech) {
               
        $message .= $self->wrap_lf("TIT",    $self->citation->parsed('TITLE'));
        $message .= $self->wrap_lf("AUT",    $self->citation->parsed('AUT'));

        $message .= $self->wrap_lf("VOL",    $self->citation->parsed('VOLISS'));  
        $message .= $self->wrap_lf("P/M",    $self->publisher_statement);

        $message .= $self->wrap_lf("SBN",    $self->citation->parsed('ISBN'));
        $message .= $self->wrap_lf("SSN",    $self->citation->parsed('ISSN'));

        $message .= $self->wrap_lf("DAT",    $date);

        $message .= $self->wrap_lf("O/A",    $self->citation->parsed('SERIES'));

        $message .= $self->wrap_lf("ART",    $self->citation->parsed('ARTTIT'));
        $message .= $self->wrap_lf("ARA",    $self->citation->parsed('ARTAUT'));

        $message .= $self->wrap_lf("PAG",    $self->citation->parsed('PGS'));
    }   
    elsif ($self->citation->is_thesis)  {
       
        my $thesis = $self->citation->parsed('TITLE');

        if (naws($self->citation->parsed('THESIS_TYPE'))) {
            $thesis .= " (" . $self->citation->parsed('THESIS_TYPE') . ")"; 
        }

        $message .= $self->wrap_lf("TIT",    $thesis);
        $message .= $self->wrap_lf("AUT",    $self->citation->parsed('AUT'));
        $message .= $self->wrap_lf("P/M",    $self->publisher_statement);

        $message .= $self->wrap_lf("SBN",    $self->citation->parsed('ISBN'));
        $message .= $self->wrap_lf("SSN",    $self->citation->parsed('ISSN'));

        $message .= $self->wrap_lf("DAT",    $date);
    }   
    else {
        $message = '';
    }

    if ($message)  {

        $message .= $self->wrap_lf("SRC", $self->source);

	$message .= "NOT:     \n";

        $message .= $self->message_note($reqno);

   }

   return $message;
}


sub subject {
    my($self, $reqno) = @_;

    return "REQ.NO/NO.DEM: $reqno for " . $self->patron_text . " (GODOT Holdings/Requesting)";
}

sub wrap_lf {
    my($self, $labv, $strv) = @_;

    return $self->SUPER::wrap($labv, ($strv . "\n"));
}


sub transliteration  { return 'latin1'; }

sub encoding         { return 'latin1'; }


sub _delim { return $DELIM; }

sub _wrap_indent { return $WRAP_INDENT; }

sub _wrap_len { return $WRAP_LEN;  }

sub _add_leading_char { return $FALSE; }

1;
