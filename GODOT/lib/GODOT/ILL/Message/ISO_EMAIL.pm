package GODOT::ILL::Message::ISO_EMAIL;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##
## Not actual ISO protocol.  
## Instead, this message format is based on ISO messages and is for use with the RSS ILL system.
##

use GODOT::Debug;
use GODOT::String;
use GODOT::Object;

use base qw(GODOT::ILL::Message);

use strict;

sub format {
    my($self, $reqno) = @_;

    ##
    ## -currently not sending info for citation fields:   :SEND_PlaceOfPublication
    ##                                                    :SEND_MediumCharacteristics
    ##                                                    :SEND_NationalBibliographyNo
    ##                                                    :SEND_SubTitle
    ##

    my $message;

    my $date = $self->date;

    use GODOT::ILL::Site;

    my $borrower = GODOT::ILL::Site->dispatch({'site' => $self->site}); 
    $borrower->nuc($self->nuc);

    my $borrowing_site = $borrower->borrowing_site; 

    my $citation = $self->citation;
    my $patron = $self->patron;

    my $ref_id = "$borrowing_site---$reqno---1---";

    ##
    ## -fill those fields...order may matter....
    ##
    $message .= 'ISO-10161-ILL-1';    
    $message .= $self->_format_field('1',                                     ':SEND_ILL-APDU-Type');
    $message .= $self->_format_field('0',                                     ':SEND_ILL-APDU-SubType');
    $message .= $self->_format_field('0',                                     ':SEND_ILL-Message-Flavor');
    $message .= $self->_format_field($ref_id,                                 ':SEND_ILL-ReferenceId');      

    $message .= $self->_format_field($citation->parsed('AUT'),                ':SEND_Author');


    if (naws($citation->parsed('THESIS_TYPE'))) {
        $message .= $self->_format_field($citation->parsed('TITLE') . " \(" . $citation->parsed('THESIS_TYPE') . "\)", 
                                         ':SEND_Title'); 
    }
    else {
        $message .= $self->_format_field($citation->parsed('TITLE'), ':SEND_Title'); 
    }

    if ($citation->is_journal) { 
        $message .= $self->_format_field($date,   ':SEND_PublicationDateOfComponent'); 
    }
    else  { 
        $message .= $self->_format_field($date,   ':SEND_PublicationDate');
    }

    $message .= $self->_format_field($citation->parsed('EDITION'),            ':SEND_Edition');
    $message .= $self->_format_field('',                                      ':SEND_PlaceOfPublication');
    $message .= $self->_format_field($citation->parsed('PUB'),                ':SEND_Publisher');
    $message .= $self->_format_field($citation->parsed('SERIES'),             ':SEND_SeriesTitleNumber');
    $message .= $self->_format_field($citation->parsed('CALL_NO'),            ':SEND_CallNumber');
    $message .= $self->_format_field($citation->parsed('ISSN'),               ':SEND_ISSN');
    $message .= $self->_format_field($citation->parsed('ISBN'),               ':SEND_ISBN');
    $message .= $self->_format_field($citation->parsed('ARTTIT'),             ':SEND_TitleOfArticle');
    $message .= $self->_format_field($citation->parsed('ARTAUT'),             ':SEND_AuthorOfArticle');
    $message .= $self->_format_field($citation->parsed('PGS'),                ':SEND_Pagination');
    $message .= $self->_format_field($citation->parsed('VOLISS'),             ':SEND_VolumeIssue');
    $message .= $self->_format_field('1',                                     ':SEND_WillPayFee');

    if ($citation->is_journal || $citation->is_book_article) {
        $message .= $self->_format_field('2',                                 ':SEND_ServiceType');
    }
    else {
        $message .= $self->_format_field('1',                                 ':SEND_ServiceType'); 
    }

    $message .= $self->_format_field('',                                      ':SEND_PendingNote');
    $message .= $self->_format_field('',                                      ':SEND_MaxCostMonetaryValue');
    $message .= $self->_format_field('0',                                     ':SEND_PlaceOnHold');
    $message .= $self->_format_field('1',                                     ':SEND_TransactionType');
    $message .= $self->_format_field('0',                                     ':SEND_HeldMediumType');
    $message .= $self->_format_field($borrowing_site,                         ':SEND_RequesterId');
    $message .= $self->_format_field($self->lender_site,                      ':SEND_ResponderId');


    $message .= $self->_format_field($self->not_req_after,                        ':SEND_NeedBefore');
    $message .= $self->_format_field($citation->parsed('SYSID') . " \\\\ $reqno", ':SEND_SystemNo');
    $message .= $self->_format_field('',                                          ':SEND_DeliveryService');

    if ($citation->is_journal) {
        $message .= $self->_format_field('2',                                 ':SEND_ItemType');
    }
    else {
        $message .= $self->_format_field('1',                                 ':SEND_ItemType'); 
    }

    $message .= $self->_format_field('',                                      ':SEND_SponsoringBody');
    $message .= $self->_format_field('',                                      ':SEND_RequesterDeliveryAddress');
    $message .= $self->_format_field('',                                      ':SEND_RequesterBillAddress');
    $message .= $self->_format_field('',                                      ':SEND_MediumCharacteristics');
    $message .= $self->_format_field('',                                      ':SEND_NationalBibliographyNo');
    $message .= $self->_format_field($self->source,                           ':SEND_VerificationReferenceSource');
    $message .= $self->_format_field('',                                      ':SEND_CopyrightCompliance');    
    $message .= $self->_format_field('',                                      ':SEND_MaxCostCurrencyCode');    
    $message .= $self->_format_field('1',                                     ':SEND_TransactionQualifier');
    $message .= $self->_format_field($reqno,                                  ':SEND_TransactionGroupQualifier');
    $message .= $self->_format_field('0',                                     ':SEND_ReciprocalAgreement');
    $message .= $self->_format_field('-1',                                    ':SEND_CanSendReceived');  
    $message .= $self->_format_field('-1',                                    ':SEND_CanSendReturned');
    $message .= $self->_format_field('2',                                     ':SEND_RequesterShipped');
    $message .= $self->_format_field('2',                                     ':SEND_RequesterCheckedIn');
    $message .= $self->_format_field('2',                                     ':SEND_StatusId');
    $message .= $self->_format_field($self->email,                            ':SEND_TargetAddressEx');
    $message .= $self->_format_field(($patron->last_name . ',   ' . $patron->first_name), ':SEND_PatronName');
    $message .= $self->_format_field($patron->library_id,                     ':SEND_PatronKey');
    $message .= $self->_format_field($patron->type,                           ':SEND_PatronCategory');

    ##
    ## -these fields (patron address, dept, note, phone, pickup and email) do not get output by RSS 
    ##  when it sends a message in ISO format, so we don't know what the correct tags are...assuming there are any
    ##

    $message .= $self->_format_field($patron->department,                     ':SEND_PatronDepartment');

    ##
    ## (28-sep-1999) - commented out as it is not part of protocol - see email (28-sep-1999) from Graeme  
    ##
    $message .= $self->_format_field($patron->email,                          ':SEND_PatronEmail');

    $message .= $self->_format_field($self->patron_address,                   ':SEND_PatronAddress');
    $message .= $self->_format_field($self->patron_phone,                     ':SEND_PatronPhone');
    $message .= $self->_format_field($self->message_note($reqno),             ':SEND_NoteFromPatron');   

    $message .= $self->_format_field('',                                      ':SEND_Us'); 
    $message .= $self->_format_field(0,                                       ':SEND_TargetPort'); 
    $message .= $self->_format_field('',                                      ':SEND_SubTitle'); 

    $message .= $self->_format_field($self->ill_no_letters,                   ':SEND_AdditionalNoLetters');

    $message .= $self->_format_field('',                                      ':SEND_SenderAddressEx'); 

    $message .= $self->_format_field('3',                                     ':SEND_TargetEncoding');
    $message .= $self->_format_field('3',                                     ':SEND_SenderEncoding');
    $message .= $self->_format_field('0',                                     ':SEND_HasAuthExtension');
    $message .= $self->_format_field('1',                                     ':SEND_ResponsePromptID0');
    $message .= $self->_format_field('2',                                     ':SEND_ResponsePromptID1');
    $message .= $self->_format_field('0',                                     ':SEND_ResponsePromptID2');
    $message .= $self->_format_field('',                                      ':SEND_ResponsePromptResponse0');
    $message .= $self->_format_field('',                                      ':SEND_ResponsePromptResponse1');
    $message .= $self->_format_field($borrowing_site,                         ':SEND_SenderSysId');
    $message .= $self->_format_field($self->lender_site,                      ':SEND_TargetSysId');
    $message .= $self->_format_field('1',                                     ':SEND_$HasIPIGExtension');
    $message .= $self->_format_field($borrowing_site,                         ':SEND_$SenderAlias');
    $message .= $self->_format_field($self->lender_site,                      ':SEND_$TargetAlias');

    return ($message);
}


sub subject {
    my($self, $reqno) = @_;

    return "ILL Message";

}

##here-21-jul-2005

sub message_note {
    my($self, $reqno) = @_;

    my $wrap_indent = 0;
    my $wrap_len    = 999;
    #### my $max_len = 999;      ## -RSS said 1000 but this appears to break RSS Workstation software so go down to 250
    my $max_len = 249; 
    my $trunc_note = '....';

    ##
    ## -this ends up being put in the RSS NoteFromPatron field which has a max of 1000 characters
    ##
    my $string = $self->SUPER::message_note($reqno, $wrap_indent, $wrap_len);
    my $data_len = $max_len - length($trunc_note);

    if (length($string) > $data_len)  { $string = substr($string, 0, $data_len) . $trunc_note; }

    ##
    ## -make RSS display look better....
    ##
    $string =~ s#\n#\\\\#g;                              ## -so wrap works for both RSS_FORM and ISO_EMAIL formats

    return $string;
}

sub _do_not_include {
    my($self) = @_;

    return qw(holdings_site eric_no eric_av mlog_no umi_diss_no fax type not_req_after email pickup 
              department province phone_work building street city postal_code);
}

sub _format_field  {
    my($self, $value, $label) = @_;

    my $wrap_indent = $self->_field_indent($label);
    my $wrap_len    = 85;

    ##
    ## -5th parameter indicates that field is mandatory -- ie. print field label even if value is blank
    ##
    return $self->wrap("$label:", $value, '', $TRUE, $wrap_indent, $wrap_len);    
}

sub _field_indent {
    my($self, $label) = @_;

    my($label_indent) = length($label) + 2;
    my($indent) = 21;

    if ($label_indent > $indent) { $indent = $label_indent; }

    return $indent;
}


1;




