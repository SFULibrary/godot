package GODOT::ILL::Message::CISTI;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##


use GODOT::Debug;
use GODOT::String;
use GODOT::Object;
use GODOT::Citation;

use base qw(GODOT::ILL::Message);

my $DELIM = ':';
my $WRAP_INDENT = 22;
my $WRAP_LEN    = 66;

use strict;

sub format {
    my($self, $reqno) = @_;

    my $citation = $self->citation;

    my $message = "";

    my $date = $self->date;

    $message .= "                    LOAN AND PHOTOCOPYING REQUEST\n\n";   ## 20 spaces, for AVISO compatibility

    $message .= "DIRECT\n";

    if ($citation->is_book || $citation->is_book_article || $citation->is_thesis) { 
        $message .= "BOOK\n"; 
    }
    elsif ($citation->is_conference) {
	$message .= "CONFERENCE\n";
    }
    else  {
        $message .= "PERIODICAL\n";
    }

    $message .= $self->wrap("ACCT NO", $self->account_number);  


    $message .= $self->wrap("NO/CL", $self->patron->last_name.", ". $self->patron->first_name."/". $self->patron->library_id);
    $message .= "\n"; 

    ##
    ## bibiliographic information
    ##

    if ($citation->is_book || $citation->is_book_article) {
        $message .= $self->wrap("TITLE",           $citation->parsed('TITLE'));
	$message .= $self->wrap("AUTHOR(S)",       $citation->parsed('AUT'));
	$message .= $self->wrap("PUBLISHER",       $self->publisher_statement);
	$message .= $self->wrap("SERIES TITLE",    $citation->parsed('SERIES'));
	$message .= $self->wrap("DATE",            $citation->parsed('YEAR'));
	$message .= $self->wrap("PAGE(S)",         $citation->parsed('PGS'));
	$message .= $self->wrap("TITLE OF ART",    $citation->parsed('ARTTIT'));
	$message .= $self->wrap("AUTHOR OF ART",   $citation->parsed('ARTAUT'));
	$message .= $self->wrap("ISBN",            $citation->parsed('ISBN'));
	$message .= $self->wrap("ISSN",            $citation->parsed('ISSN'));
    }
    elsif ($citation->is_conference) {

	$message .= $self->wrap("TITLE",           $citation->parsed('TITLE'));
	$message .= $self->wrap("AUTHOR(S)",       $citation->parsed('AUT'));
	$message .= $self->wrap("PUBLISHER",       $self->publisher_statement);
	$message .= $self->wrap("SERIES TITLE",    $citation->parsed('SERIES'));
        $message .= $self->wrap("DATE",            $date);     
	$message .= $self->wrap("PAGE(S)",         $citation->parsed('PGS'));
	$message .= $self->wrap("TITLE OF ART",    $citation->parsed('ARTTIT'));
	$message .= $self->wrap("AUTHOR OF ART",   $citation->parsed('ARTAUT'));
	$message .= $self->wrap("ISBN",            $citation->parsed('ISBN'));
	$message .= $self->wrap("ISSN",            $citation->parsed('ISSN'));
    }
    elsif ($citation->is_journal) {

	$message .= $self->wrap("TITLE",           $citation->parsed('TITLE'));
	$message .= $self->wrap("PUBLISHER",       $self->publisher_statement);
	$message .= $self->wrap("SERIES TITLE",    $citation->parsed('SERIES'));
        $message .= $self->wrap("VOLUME/ISSUE",    $citation->parsed('VOLISS'));    
        $message .= $self->wrap("DATE",            $date);      
   	$message .= $self->wrap("PAGE(S)",         $citation->parsed('PGS'));
	$message .= $self->wrap("TITLE OF ART",    $citation->parsed('ARTTIT'));
	$message .= $self->wrap("AUTHOR OF ART",   $citation->parsed('ARTAUT'));
	$message .= $self->wrap("ISSN",            $citation->parsed('ISSN'));
	$message .= $self->wrap("ISBN",            $citation->parsed('ISBN'));
    }   
    elsif ($citation->is_tech) {

	$message .= $self->wrap("TITLE",           $citation->parsed('TITLE'));
	$message .= $self->wrap("AUTHOR(S)",       $citation->parsed('AUT'));
	$message .= $self->wrap("PUBLISHER",       $self->publisher_statement);
	$message .= $self->wrap("SERIES TITLE",    $citation->parsed('SERIES'));
        $message .= $self->wrap("VOLUME/ISSUE",    $citation->parsed('VOLISS'));    
        $message .= $self->wrap("DATE",            $date);     
	$message .= $self->wrap("PAGE(S)",         $citation->parsed('PGS'));
	$message .= $self->wrap("TITLE OF ART",    $citation->parsed('ARTTIT'));
	$message .= $self->wrap("AUTHOR OF ART",   $citation->parsed('ARTAUT'));
	$message .= $self->wrap("ISBN",            $citation->parsed('ISBN'));
	$message .= $self->wrap("ISSN",            $citation->parsed('ISSN'));
    }
    elsif ($citation->is_thesis) {

        my $thesis;

        if (! aws($citation->parsed('THESIS_TYPE'))) {
            $thesis = $citation->parsed('TITLE') . " (" . $citation->parsed('THESIS_TYPE') . ")"; 
        }
        else {
            $thesis = $citation->parsed('TITLE');
        }

	$message .= $self->wrap("TITLE",           $thesis);
	$message .= $self->wrap("AUTHOR(S)",       $citation->parsed('AUT'));
	$message .= $self->wrap("PUBLISHER",       $self->publisher_statement);
        $message .= $self->wrap("DATE",            $date);     
	$message .= $self->wrap("ISBN",            $citation->parsed('ISBN'));
	$message .= $self->wrap("ISSN",            $citation->parsed('ISSN'));
    }
    else {
        $message = '';
    }

    if ($message) {
                              
        $message .= $self->wrap("ORIGIN OF INFO", $self->source);
	    $message .= $self->wrap("MAX COST",       $self->max_cost);
	    $message .= $self->wrap("INSTRUCTIONS",   "Request for " . $self->nuc . ".");
        $message .= "REMARKS:\n";                                
        $message .= $self->message_note($reqno);
    }

    return $message;
}

sub subject {
    my($self, $reqno) = @_;

    return "REQ. NO. $reqno for " . $self->patron_text . " (GODOT Holdings/Requesting)";
}


sub transliteration  { return 'latin1'; }

sub encoding         { return 'latin1'; }


sub _delim { return $DELIM; }

sub _wrap_indent { return $WRAP_INDENT; }

sub _wrap_len { return $WRAP_LEN;  }


1;
