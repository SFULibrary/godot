package GODOT::ILL::Message::RSS_FORM_2;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##
use GODOT::Debug;
use GODOT::String;
use GODOT::Object;

use base qw(GODOT::ILL::Message);

use strict;

my $WRAP_INDENT = 0;
my $WRAP_LEN    = 999;


sub format {
    my($self, $reqno) = @_;

    ##
    ## -RSS fields currently not filled: HeldMediumType
    ##                                   SponsoringBody
    ##                                   SubTitle
    ##                                   NationalBibliographyNumber
    ##                                   PlaceOfPublication
    ##                                   TagName                      (- has to do with ISO protocol - can be ignored)
    ##
   
    my $next_partners_max = 5;  # was 25
    my $pre_approved_str = 'Approved';
    my $mediated_str = 'New';                                     # This isn't just mediated - All except direct.

    my $date = $self->date;

    my $patron = $self->patron;
    my $citation = $self->citation;
  
    ##
    ## -identity/direction fields
    ##
    
    my %form;

    if (grep {$self->request_type eq $_} qw(D S)) { $self->fill_field($pre_approved_str, 'SetStatus', \%form); } 
    else                                          { $self->fill_field($mediated_str, 'SetStatus', \%form); }

    ##
    ## th - This must match the RSS fields exactly!
    ##

    $self->fill_field($patron->pickup, 'Requests-Pickup', \%form);  

    ##
    ## Fix for RSS 3.1.1
    ##

    if (aws($self->sender_id)) {
        $self->error_message("No value was specified for the sender ID for user " . $self->site . "."); 
        return ''; 

    }

    my $homelib = $self->override_sender_id;

    $self->fill_field($homelib, 'HomeLib', \%form);

    if ($self->request_type ne 'W')    {           ## -if New then no NextPartners

        my $tmp_str = $self->next_partner($self->lender_site, $homelib);

        my @site_arr = ("als:$tmp_str");           ## -initialize with site that user has chosen
        my $num_next_partners = 1;

        foreach my $site (split(/\s+/, $self->holdings_site)) {

            #### debug "NextPartner logic:  $site";

            my $tmp_str2;

            if ($num_next_partners >= $next_partners_max) { last; }        ## -break out of loop !!!! 

            ##
            ## -change BVAU[BVAU-KRNR] to BVAU-KRNR 
            ## -separate with commas
            ##

            if ($site =~ m#^(.+)\[(.+)\]$#)   { $tmp_str2 = $2;    }       ## -we want the GODOT user not the NUC
            else                              { $tmp_str2 = $site; }

	    $tmp_str2 = $self->next_partner($tmp_str2, $homelib);

            ##
            ## We don't want site user has chosen in list twice
	    ## Also don't want the home library in there. Changed loop flow to allow for that.
            ##

            if ($tmp_str2 eq $self->lender_site)     { next; }

	    if ($tmp_str2 eq $self->nuc)             { next; }
	    if ($tmp_str2 eq $tmp_str)               { next; }
      
            $num_next_partners++;

            push(@site_arr, "als:$tmp_str2"); 

        }     

        $self->fill_field(join(',', @site_arr), 'NextPartners', \%form);
    }

    ##
    ## -patron fields
    ##

    $self->fill_field($patron->last_name. ", " . $patron->first_name, 'Patrons-Patron', \%form);
    $self->fill_field($patron->library_id,   'Patrons-PatronKey',        \%form);

    ##
    ## th  --- Add in mapping for parton type here (Staff/Undergraduate/Faculty/Graduate)
    ##

    $self->fill_field($self->patron_type,  'Patrons-PatronCategory',   \%form);

    ##
    ## th - fix single quote error in department field.
    ##

    my $department = $patron->department;
    $department =~ s/'/''/g;
    $self->fill_field($department, 'Patrons-PatronDepartment', \%form);

    $self->fill_field($patron->email, 'Patrons-PatronEmail',      \%form);
    $self->fill_field($self->patron_address,   'Patrons-PatronAddress',   \%form);
    $self->fill_field($self->patron_phone,     'Patrons-PatronPhone',     \%form);

    ##
    ## th - RSS will choke if the NeedBefore is not of DD/MM/YY format, so catch it now
    ## Date string contains the error message if it failed.
    ##
    my $date_str;

    unless ($self->valid_date) { return ''; }

    $self->fill_field($self->not_req_after, 'Requests-NeedBefore',   \%form);

    ##
    ## -fields for 6 diff request types + common fields
    ##
    ## th - Not sure what ItemType should be here.
    ## th - Service type seems to be 1 - Loan/2 - Copy 
    ##

    if ($citation->is_book)  {

        $self->fill_field('1', 'Requests-N-ServiceType', \%form);
    }
    elsif ($citation->is_book_article)  {

        $self->fill_field('2', 'Requests-N-ServiceType', \%form);
    }
    elsif ($citation->is_conference)  {

        $self->fill_field('1', 'Requests-N-ServiceType', \%form);
    }
    elsif ($citation->is_journal)  {

        $self->fill_field('2', 'Requests-N-ServiceType', \%form);
    }
    elsif ($citation->is_tech)  {

        $self->fill_field('1', 'Requests-N-ServiceType', \%form);
    }
    elsif ($citation->is_thesis)  {

        $self->fill_field('1', 'Requests-N-ServiceType', \%form);
    } else {
	return ('', 'No service type defined.');
    }

    ##
    ## -bibliographic fields that are used by all request types
    ##

    $self->fill_field($citation->parsed('AUT'),              'ItemId-Author',            \%form);
    $self->fill_field($citation->parsed('ARTAUT'),           'ItemId-Author of Article', \%form);
    $self->fill_field($citation->parsed('EDITION'),          'ItemId-Edition',           \%form);
    $self->fill_field($citation->parsed('PGS'),              'ItemId-Pagination',        \%form);

    if ($citation->is_journal) { $self->fill_field($date,  'ItemId-Date of Article',     \%form); }
    else                       { $self->fill_field($date,  'ItemId-Publication Date',    \%form);}

    $self->fill_field($citation->parsed('PUB'),              'ItemId-Publisher',         \%form);
    $self->fill_field($citation->parsed('SERIES'),           'ItemId-Series Title and Number', \%form);
    $self->fill_field($citation->parsed('SYSID'),            'ItemId-System Number',          \%form);

    my $title = $citation->parsed('TITLE');
    my $thesis_type = $citation->parsed('THESIS_TYPE');

    if (naws($thesis_type)) { $self->fill_field("$title ($thesis_type)", 'ItemId-Title', \%form); }
    else                    { $self->fill_field($title,                  'ItemId-Title', \%form); }

    $self->fill_field($citation->parsed('ARTTIT'),           'ItemId-Title of Article',    \%form);
    $self->fill_field($self->source . " ($reqno)", 'ItemId-Source of Information', \%form);
    $self->fill_field($citation->parsed('VOLISS'),           'ItemId-Volume/Issue',        \%form);
     
    ##
    ## Get the ERIC document number in call number if available
    ##
    if ($citation->parsed('ERIC_NO') =~ /ED/) {
        $self->fill_field($citation->parsed('ERIC_NO'),          'ItemId-Call Number',       \%form);
    } else {
        $self->fill_field($citation->parsed('CALL_NO'),          'ItemId-Call Number',       \%form);
    }
    
    $self->fill_field($citation->parsed('ISBN'),             'ItemId-ISBN', \%form);
    $self->fill_field($citation->parsed('ISSN'),             'ItemId-ISSN', \%form);

    my $ill_no_letters = $self->ill_no_letters;


    $form{'Requests-NoteFromPatron'} = ($ill_no_letters . '/ ') unless (aws($ill_no_letters));
    $form{'Requests-NoteFromPatron'} .= $self->message_note($reqno);      

    ##
    ## EXTRA STUFF PUT IN BY TODD FOR RSS 3.0!  This is static for testing anyway
    ## and may be necessary for the final release
    ##

    $self->fill_field('4','DefCon',\%form);	                 ## Used by RSS Web Form = SUBMIT
    $self->fill_field('illVerify.tpl', 'CurrentTPL', \%form);    ## Not sure, seems to work
    $self->fill_field('ENU','Language',\%form);
    $self->fill_field('TRUE','LanguageVerified',\%form);

    return put_query_fields(\%form);    
}


sub message_url   {
    my($self) = @_;
    return 'http://' . $self->host . '/cgi-bin/RSSpwsMain.pl';
}

sub message_note {
    my($self, $reqno) = @_;

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





sub valid_date {
    my($self) = @_;

    use Time::Local;
    use GODOT::Date;    

    my($dd, $mm, $yyyy);

    my $string = $self->not_req_after;

    if ($string =~ m#(\d\d?)/(\d\d?)/(\d\d)#) {
        
        $dd   = $1;         
        $mm   = $2;
        $yyyy = $3;        
        $yyyy = &GODOT::Date::add_cent($yyyy);

        $dd =~ s#^0+##g;                                   ## -don't want number interpreted as hex
        if (($dd < 1) || ($dd > 31)) {
            $self->error_message("Please enter a date in DD/MM/YY format.");
            return $FALSE;
        }


        $mm =~ s#^0+##g;                                   ## -don't want number interpreted as hex  
        if (($mm < 1) || ($mm > 12)) {
            $self->error_message("Please enter a date in DD/MM/YY format.");
            return $FALSE;
        }
        

        if ($yyyy > 2010)  {

            $self->error_message("Need before date is too far in the future.  Use the format DD/MM/YY (eg: 31/12/00 NOT 31/12/2000)");
            return $FALSE;
        }

        $self->not_req_after("$mm/$dd/$yyyy");
        
        # Check that it's not a date previous to today's date.
        
        if (Time::Local::timelocal(59,59,23,$dd,$mm-1,$yyyy) < time()) {
            $self->error_message("Need before date must be a future date.");
            return $FALSE;
        }
                
        return $TRUE;        
    }

    $self->error_message("Please enter a date in DD/MM/YY format.");
    return $FALSE;
}

sub override_sender_id {
    my($self) = @_;

    return $self->sender_id;
}

sub next_partner {
    my($self, $site, $homelib) = @_;
    return $site;
}


sub fill_field {
    my($self, $value, $rss_field, $form_ref) = @_;

    ${$form_ref}{$rss_field} = $value unless (aws($value));
}


sub transport { return 'http'; }


sub check_http_return {
    my($self, $string) = @_;

    return ($string =~ m#your request has been submitted#i);
}


sub _do_not_include {
    my($self) = @_;

    return qw(holdings_site eric_no eric_av mlog_no umi_diss_no fax type not_req_after email pickup 
              department province phone_work building street city postal_code);
}

sub _wrap_indent { return $WRAP_INDENT; }

sub _wrap_len { return $WRAP_LEN;  }


1;


