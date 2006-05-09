package GODOT::ILL::Message::AVISO_4;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use GODOT::Debug;
use GODOT::String;
use GODOT::Object;

use base qw(GODOT::ILL::Message);


my $WRAP_INDENT = 14;
my $WRAP_LEN    = 70;
my $DELIM       = '';

use strict;

sub format {
    my($self, $reqno) = @_;

    my($isn, $message, $thesis);

    if ($self->citation->parsed('ISSN')) { $isn = $self->citation->parsed('ISSN'); }

    if ($self->citation->parsed('ISBN')) {

        if ($isn) { $isn .= " "; }

        $isn  .= $self->citation->parsed('ISBN');
    }
        
    my $date = $self->date;

    ##
    ## added for AVISO 5.2, DB, Mar 17, 1998
    ##
 
    if ($self->citation->is_journal) {
        $message .= "\nREQUEST FOR: JOURNAL ARTICLE\n\n";
    }
    else {
        $message .= "\nREQUEST FOR: " . $self->citation->req_type . "\n\n";
    }
    ##--------------------------------------------------------

    $message .= $self->wrap("pat_name", ($self->patron->last_name . ", " . $self->patron->first_name), $TRUE);
    $message .= $self->wrap("pat_id", $self->patron->library_id, $TRUE);
    $message .= $self->wrap("pat_dept", $self->patron->department, $TRUE);
    $message .= $self->wrap("pat_cat", $self->patron->type, $TRUE);
    $message .= $self->wrap("pat_phone", $self->patron->phone, $TRUE);
    $message .= $self->wrap("pat_wphone", $self->patron->phone_work);
    $message .= $self->wrap("pat_eadd", $self->patron->email, $TRUE);
    $message .= $self->wrap("pat_street", $self->patron->street, $TRUE);
    $message .= $self->wrap("pat_city", $self->patron->city, $TRUE);
    $message .= $self->wrap("pat_prov", $self->patron->province, $TRUE);
    $message .= $self->wrap("pat_pcode", $self->patron->postal_code, $TRUE);
    $message .= $self->wrap("pat_loc", $self->patron->pickup);
    $message .= $self->wrap("ord_needby", $self->not_req_after, $TRUE);
	
    if ($self->citation->is_book) {
        $message .= $self->wrap("ord_req", "L");
        $message .= $self->wrap("ord_id", "BPIR");
        $message .= $self->wrap("ord_pages", $self->citation->parsed('PGS'));
	$message .= $self->wrap("bib_item", "B");
	$message .= $self->wrap("bib_aut1", $self->citation->parsed('AUT'));
	$message .= $self->wrap("bib_tit1", $self->citation->parsed('TITLE'));
	$message .= $self->wrap("bib_pub", $self->citation->parsed('PUB'));
	$message .= $self->wrap("bib_date", $self->citation->parsed('YEAR'));
	$message .= $self->wrap("bib_isn", $isn);
	$message .= $self->wrap("bib_ser", $self->citation->parsed('SERIES'));
    }
    elsif ($self->citation->is_book_article) {
	$message .= $self->wrap("ord_req", "X");
        $message .= $self->wrap("ord_id", "BPIR");
        $message .= $self->wrap("ord_pages", $self->citation->parsed('PGS'));
	$message .= $self->wrap("bib_item", "B");
	$message .= $self->wrap("bib_aut1", $self->citation->parsed('AUT'));
	$message .= $self->wrap("bib_aut2", $self->citation->parsed('ARTAUT'));
	$message .= $self->wrap("bib_tit1", $self->citation->parsed('TITLE'));
	$message .= $self->wrap("bib_tit2", $self->citation->parsed('ARTTIT'));
	$message .= $self->wrap("bib_pub", $self->citation->parsed('PUB'));
	$message .= $self->wrap("bib_date", $self->citation->parsed('YEAR'));
	$message .= $self->wrap("bib_isn", $isn);
	$message .= $self->wrap("bib_ser", $self->citation->parsed('SERIES'));
    }
    elsif ($self->citation->is_conference) {
	$message .= $self->wrap("ord_req", "X");
        $message .= $self->wrap("ord_id", "BPIR");
        $message .= $self->wrap("ord_pages", $self->citation->parsed('PGS'));
	$message .= $self->wrap("bib_item", "C");
	$message .= $self->wrap("bib_aut2", $self->citation->parsed('ARTAUT'));
	$message .= $self->wrap("bib_tit2", $self->citation->parsed('ARTTIT'));
	$message .= $self->wrap("bib_pub", $self->citation->parsed('PUB'));
	$message .= $self->wrap("bib_date", $date);
	$message .= $self->wrap("bib_isn", $isn);
	$message .= $self->wrap("bib_ser", $self->citation->parsed('SERIES'));
	$message .= $self->wrap("bib_aut1", $self->citation->parsed('AUT'));
	$message .= $self->wrap("bib_tit1", $self->citation->parsed('TITLE'));
    }
    elsif ($self->citation->is_journal) {
	$message .= $self->wrap("ord_req", "X");
        $message .= $self->wrap("ord_id", "BPIR");
        $message .= $self->wrap("ord_pages", $self->citation->parsed('PGS'));
	$message .= $self->wrap("bib_item", "J");
	$message .= $self->wrap("bib_aut2", $self->citation->parsed('ARTAUT'));
	$message .= $self->wrap("bib_tit2", $self->citation->parsed('ARTTIT'));
	$message .= $self->wrap("bib_pub", $self->citation->parsed('PUB'));
	$message .= $self->wrap("bib_date", $date);
	$message .= $self->wrap("bib_isn", $isn);
	$message .= $self->wrap("bib_ser", $self->citation->parsed('SERIES'));
	$message .= $self->wrap("bib_vol", $self->citation->parsed('VOLISS'));
	$message .= $self->wrap("bib_tit1", $self->citation->parsed('TITLE'));
    }
    elsif ($self->citation->is_tech) {
	$message .= $self->wrap("ord_req", "X");
        $message .= $self->wrap("ord_id", "BPIR");
        $message .= $self->wrap("ord_pages", $self->citation->parsed('PGS'));
	$message .= $self->wrap("bib_item", "R");
	$message .= $self->wrap("bib_aut2", $self->citation->parsed('ARTAUT'));
	$message .= $self->wrap("bib_tit2", $self->citation->parsed('ARTTIT'));
        $message .= $self->wrap("bib_pub", $self->citation->parsed('PUB'));
	$message .= $self->wrap("bib_date", $date);
	$message .= $self->wrap("bib_isn", $isn);
	$message .= $self->wrap("bib_ser", $self->citation->parsed('SERIES'));

	$message .= $self->wrap("bib_vol", $self->citation->parsed('VOLISS'));
	$message .= $self->wrap("bib_aut1", $self->citation->parsed('AUT'));
	$message .= $self->wrap("bib_tit1", $self->citation->parsed('TITLE'));
    }
    elsif ($self->citation->is_thesis) {
        if (naws($self->citation->parsed('THESIS_TYPE'))) {
            $thesis = $self->citation->parsed('TITLE') . " (" . $self->citation->parsed('THESIS_TYPE') . ")"; 
        }
        else {
            $thesis = $self->citation->parsed('TITLE');
        }

	$message .= $self->wrap("ord_req", "L");
        $message .= $self->wrap("ord_id", "BPIR");
	$message .= $self->wrap("bib_item", "T");
	$message .= $self->wrap("bib_aut1", $self->citation->parsed('AUT'));
	$message .= $self->wrap("bib_tit1", $thesis);
	$message .= $self->wrap("bib_pub", $self->citation->parsed('PUB'));
	$message .= $self->wrap("bib_date", $date);
	$message .= $self->wrap("bib_isn", $isn);
    }
    else {
	$message = ""; # set empty so error will be caught
    }

    if ($message) {
        $message .= $self->wrap("ord_note",  $self->source);
        $message .= trim_end($self->message_note($reqno));
    }
    ##
    ## -added for AVISO 5.2, DB, Mar 17, 1998
    ##
    $message .= "\nEOR\n";

    return ($message);

}

sub subject {
    my($self, $reqno) = @_;

    my $subj;

    if ($self->citation->is_journal) {
	$subj = "ILL JOURNAL ARTICLE Request for " . $self->patron_text; 
    }
    else {
	$subj = "ILL " . $self->citation->req_type . " Request for " . $self->patron_text;
    }

    return ($subj .  " (GODOT to " . $self->lender_site . ")");
}





sub date {
    my($self) = @_;

    my $string;

    my $day = $self->citation->parsed('DAY');
    my $month = $self->citation->parsed('MONTH');
    my $year = $self->citation->parsed('YEAR');

    if ($day ne '') { $string = "$month $day/$year"; }
    else            { $string = "$month/$year";      }

    return trim_beg_end(comp_ws($string));
}

sub wrap {
    my($self, $labv, $strv, $manv) = @_;

    return $self->SUPER::wrap($labv, ($strv . "\n"), undef, $manv);
}



sub _do_not_include {
    my($self) = @_;

    return qw(reqno not_req_after province department email pickup phone phone_work street city postal_code);
}


sub _wrap_indent { return $WRAP_INDENT; }

sub _wrap_len { return $WRAP_LEN;  }

sub _delim { return $DELIM; }


1;




