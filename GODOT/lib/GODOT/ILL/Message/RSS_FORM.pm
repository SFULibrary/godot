package GODOT::ILL::Message::RSS_FORM;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use GODOT::Debug;
use GODOT::String;
use GODOT::Object;

use base qw(GODOT::ILL::Message);

my $WRAP_INDENT = 0;
my $WRAP_LEN    = 999;

use strict;

sub format {
    my($self, $reqno) = @_;

    ##
    ## -RSS fields currently not filled: HeldMediumType
    ##                                   SponsoringBody
    ##                                   SubTitle
    ##                                   NationalBibliographyNumber
    ##                                   TagName                      (- has to do with ISO protocol - can be ignored)
    ##
    ##
    my $next_partners_max = 25;
    my $pre_approved_str = 'AddNewPreApproved';

    my $date = $self->date;
 	
    my $citation = $self->citation;
    my $patron = $self->patron;
		  
    ##
    ## -identity/direction fields
    ##
    my %form;

    if ($self->request_type ne 'M') { $self->fill_field($pre_approved_str, 'SetStatus', \%form); }

    $self->fill_field($patron->pickup, 'Pickup', \%form);  

    if ($self->request_type ne 'W')    {    ## -if New then no NextPartners

        my $tmp_str;

        my @site_arr = $self->lender_site;            ## -initialize with site that user has chosen
        my $num_next_partners = 1;

        foreach my $site (split(/\s+/, $self->holdings_site)) {

            if ($num_next_partners >= $next_partners_max) { last; }       ## -break out of loop !!!! 

            ##
            ## -change BVAU[BVAU-KRNR] to BVAU-KRNR 
            ## -separate with commas
            ##
            if ($site =~ m#^(.+)\[(.+)\]$#)   { $tmp_str = $2;    }       ## -we want the GODOT user not the NUC
            else                              { $tmp_str = $site; }
            ##
            ## -we don't want site user has chosen in list twice
            ##
            if ($tmp_str ne $self->lender_site) { 
                $num_next_partners++;
                push(@site_arr, $tmp_str); 
            }
        }     

        $self->fill_field(join(',', @site_arr), 'NextPartners', \%form);
    }

    ##
    ## -patron fields
    ##
    $self->fill_field($patron->last_name . ",   " . $patron->first_name, 'PatronName', \%form);
    $self->fill_field($patron->library_id,   'PatronKey',        \%form);
    $self->fill_field($patron->type,  'PatronCategory',   \%form);
    ##
    ## th - fix single quote error in department field
    ##
    my $department = $patron->department;
    $department =~ s/'/''/g;
    $self->fill_field($department,   'PatronDepartment', \%form);

    ##
    ## (28-sep-1999) - changed from 'PatronEMail' to 'PatronEmail'
    ##
    $self->fill_field($patron->email,          'PatronEmail',     \%form);
    $self->fill_field($self->patron_address,   'PatronAddress',   \%form);
    $self->fill_field($self->patron_phone,     'PatronPhone',     \%form);

    $self->fill_field($self->not_req_after, 'NeedBeforeStr',   \%form);

    ##
    ## -fields for 6 diff request types + common fields
    ##

    if ($citation->is_book)  {
        $self->fill_field('1', 'ItemType', \%form);
        $self->fill_field('1', 'ServiceType', \%form);
    }
    elsif ($citation->is_book_article)  {
        $self->fill_field('1', 'ItemType', \%form);
        $self->fill_field('2', 'ServiceType', \%form);
    }
    elsif ($citation->is_conference)  {
        $self->fill_field('1', 'ItemType', \%form);
        $self->fill_field('1', 'ServiceType', \%form);
    }
    elsif ($citation->is_journal)  {
        $self->fill_field('2', 'ItemType', \%form);
        $self->fill_field('2', 'ServiceType', \%form);
    }
    elsif ($citation->is_tech)  {
        $self->fill_field('1', 'ItemType', \%form);
        $self->fill_field('1', 'ServiceType', \%form);
    }
    elsif ($citation->is_thesis)  {
        $self->fill_field('1', 'ItemType', \%form);
        $self->fill_field('1', 'ServiceType', \%form);
    }
    else {
        $self->error_message('unexpected request type');
        return '';
    }

    ##
    ## -bibliographic fields that are used by all request types
    ##

    $self->fill_field($self->ill_no_letters, 'AdditionalNoLetters', \%form);

    $self->fill_field($citation->parsed('AUT'),              'Author',            \%form);
    $self->fill_field($citation->parsed('ARTAUT'),           'AuthorOfArticle',   \%form);
    $self->fill_field($citation->parsed('EDITION'),          'Edition',           \%form);
    $self->fill_field($citation->parsed('PGS'),              'Pagination',        \%form);

    if ($citation->is_journal) { $self->fill_field($date,  'PublicationDateOfComponent',   \%form); }
    else                       { $self->fill_field($date,  'PublicationDate',   \%form);}

    $self->fill_field($citation->parsed('PUB'),              'Publisher',          \%form);
    $self->fill_field($citation->parsed('PUB_PLACE'),        'PlaceOfPublication', \%form);

    $self->fill_field($citation->parsed('SERIES'),           'SeriesTitleNumber', \%form);
    $self->fill_field($citation->parsed('SYSID'),            'SystemNo',          \%form);

    if (naws($citation->parsed('THESIS_TYPE'))) {
        $self->fill_field($citation->parsed('TITLE'). " (" . $citation->parsed('THESIS_TYPE') . ")", 'Title', \%form); 
    }
    else {
        $self->fill_field($citation->parsed('TITLE'),      'Title', \%form); 
    }

    $self->fill_field($citation->parsed('ARTTIT'),           'TitleOfArticle',    \%form);

    $self->fill_field($self->source, 'VerificationReferenceSource', \%form);

    $self->fill_field($citation->parsed('VOLISS'),           'VolumeIssue',       \%form);
    $self->fill_field($citation->parsed('CALL_NO'),          'CallNumber',       \%form);

    $self->fill_field($citation->parsed('ISBN'),             'ISBN', \%form);
    $self->fill_field($citation->parsed('ISSN'),             'ISSN', \%form);

    ##
    ## -note field(s)
    ##

    $form{'NoteFromPatron'} = $self->message_note($reqno);      

    return put_query_fields(\%form);
}

sub message_url {
    my($self) = @_;
    return 'http://' . $self->host . '/DLL~ISC17';
}




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
    my $string = $self->SUPER::message_note($reqno);
    my $data_len = $max_len - length($trunc_note);

    if (length($string) > $data_len)  { $string = substr($string, 0, $data_len) . $trunc_note; }

    ##
    ## -make RSS display look better....
    ##
    $string =~ s#\n#\\\\#g;                              ## -so wrap works for both RSS_FORM and ISO_EMAIL formats

    return $string;
}


sub fill_field {
    my($self, $value, $rss_field, $form_ref) = @_;

    ${$form_ref}{$rss_field} = $value unless (aws($value));
}

sub check_http_return {
    my($self, $string) = @_;

    return ($string =~ m#your request has been submitted#i);
}



sub transport { return 'http'; }


sub _do_not_include {
    my($self) = @_;

    return qw(holdings_site eric_no eric_av mlog_no umi_diss_no fax type not_req_after email pickup 
              department province phone_work building street city postal_code);
}


sub _wrap_indent { return $WRAP_INDENT; }

sub _wrap_len { return $WRAP_LEN;  }



1;
