package GODOT::ILL::Message::III;
##
## Copyright (c) 2007, Kristina Long, Simon Fraser University
##
use Data::Dump qw(dump);

use GODOT::Debug;
use GODOT::String;
use GODOT::Object;
use GODOT::Constants;
use GODOT::Encode::Transliteration;

use base qw(GODOT::ILL::Message);

use strict;

my $WRAP_INDENT = 0;
my $WRAP_LEN    = 999;

##
## (02-nov-2010 kl) -- appears that field order may be important for godot-to-iii ill messaging;
##
my @FORM_FIELD_ORDER = qw(main0 main1 publ0 publ1 publ2 publ3 publ4 main3 info0 info1 info2 main5 needby_Month needby_Day needby_Year email0 extpatid extpatpw name barcode subill);

sub format {
    my($self, $reqno) = @_;

    my $date = $self->date;

    my $patron = $self->patron;
    my $citation = $self->citation;
  
    my %form;

    $self->fill_field('SUBMIT THIS REQUEST', 'subill', \%form);

    ##
    ## (05-nov-2010 kl) -- Method has_separate_auth_step added for Lethbridge when they moved to an integrated login.  
    ##
    unless ($self->has_separate_auth_step) {
        ##
        ## -patron fields
        ##
        ## (20-aug-2007 kl) - added for ALU for their LDAP authentication which is implemented using III's 'External Patron Verification' product
        ##
        my $extpatid = $self->extpatid;
        my $extpatpw = $self->extpatpw;

        if ($self->external_patron_verification && naws($extpatid) && naws($extpatpw)) {
            $self->fill_field($extpatid, 'extpatid', \%form);
            $self->fill_field($extpatpw, 'extpatpw', \%form);    
        }
        else {
            $self->fill_field($patron->last_name . ", " . $patron->first_name, 'name', \%form);
            $self->fill_field($patron->library_id, 'barcode', \%form);
        }
    }

    ##
    ## Check that 'cancel if not filled by' date is valid and in format DD/MM/YY.
    ## Date string contains the error message if it failed.
    ##
    unless ($self->valid_date) { return ''; }
   
    $self->fill_field($patron->email, 'info2', \%form);

    ##
    ## -added per email from Rumi Graham 04-mar-2008
    ##
    my($dd, $mm, $yy) = split('/', $self->not_req_after);
    $self->fill_field($dd,  'needby_Day',   \%form);
    $self->fill_field($mm,  'needby_Month', \%form);
    $self->fill_field($yy,  'needby_Year',  \%form);
    $self->fill_field('-1', 'main5',        \%form);

    my $pub_date = join(', ', $self->publisher_statement, $date);

    my $title = naws($citation->parsed('TITLE')) ? $citation->parsed('TITLE') : 'Title not available.';

    if ($citation->is_book || $citation->is_tech) {
        $self->fill_field($citation->parsed('AUT'),   'main0', \%form);

        $self->fill_field($title, 'main1', \%form);

        $self->fill_field($self->publisher_statement,   'publ1', \%form);
        $self->fill_field($date,                      'publ2', \%form);
    }
    elsif ($citation->is_book_article)  {
        $self->fill_field($citation->parsed('ARTAUT'), 'main0', \%form);

        my $article_title = naws($citation->parsed('ARTTIT')) ? $citation->parsed('ARTTIT') : 'Article title not available.' ;
        $self->fill_field($article_title, 'main1', \%form);
      
        $self->fill_field($title,  'publ0', \%form);

        $self->fill_field($citation->parsed('AUT'),    'publ1', \%form);
        $self->fill_field($citation->parsed('PGS'),    'publ2', \%form);

        $self->fill_field($pub_date,                   'publ3', \%form);
    }
    elsif ($citation->is_conference)  {

        $self->fill_field($title,  'main1', \%form);

        $self->fill_field($citation->parsed('ARTTIT'), 'publ2', \%form);
        $self->fill_field($citation->parsed('ARTAUT'), 'publ3', \%form);
        $self->fill_field($pub_date,                   'publ1', \%form);
    }
    elsif ($citation->is_journal)  {
        $self->fill_field($citation->parsed('ARTAUT'), 'main0', \%form);

        my $article_title = naws($citation->parsed('ARTTIT')) ? $citation->parsed('ARTTIT') : 'Article title not available.' ;
        $self->fill_field($article_title, 'main1', \%form);

        $self->fill_field($title,  'publ0', \%form);

        if (naws($citation->parsed('VOL')) && naws($citation->parsed('ISS'))) {
            $self->fill_field($citation->parsed('VOL'),    'publ1', \%form);
            $self->fill_field($citation->parsed('ISS'),    'publ2', \%form);
        }
        else {
            $self->fill_field($citation->parsed('VOLISS'),    'publ1', \%form);
        }

        $self->fill_field($citation->parsed('PGS'),    'publ4', \%form);
        $self->fill_field($date,                       'publ3', \%form);
    }
    elsif ($citation->is_thesis)  {
        $self->fill_field($citation->parsed('AUT'),         'main0', \%form);
        $self->fill_field($title,                           'main1', \%form);
        $self->fill_field($self->publisher_statement,       'publ0', \%form);
        $self->fill_field($citation->parsed('THESIS_TYPE'), 'publ1', \%form);
        $self->fill_field($date,                            'publ2', \%form);

    } else {
	return ('', 'Unexpected request type (', $citation->req_type, ').');
    }

    ##
    ## -added per email from Rumi Graham 04-mar-2008
    ##
    $self->fill_field($citation->parsed('ISBN'),   'info1', \%form);
    $self->fill_field($citation->parsed('ISSN'),   'info1', \%form);

    $self->fill_field($self->source . " ($reqno)", 'main3', \%form);
    $self->fill_field($self->message_note,         'info0', \%form);

    #### debug "----------------------------------------------";
    #### debug location_plus;
    #### foreach my $field (sort keys %form) {
    ####     debug "$field = ", Data::Dump::dump($form{$field});
    #### }
    #### debug "----------------------------------------------";

    ##
    ## (02-nov-2010 kl) 
    ## Seems that the III ILL input form processing likes fields to be passed in an order that is the same (or similar?) to the order used on their input forms.
    ## Current thought is that sending authentication related fields (eg. name, barcode, extpatid and extpatpw) at the beginning of the parameter list produces
    ## the 'Unable to run request for http://darius.uleth.ca/illj~S1 (Moved Permanently)' type message.
    ## 
    my @form = $self->order_fields({ %form });
          
    ##
    ## (27-oct-2010 kl) -- find out what encoding should be used
    ##
    return put_query_fields_from_array([@form], $self->encoding);
}

sub message_url   {
    my($self) = @_;

    my $citation = $self->citation;
    my $form_type = ($citation->is_journal)       ? 'j' 
                  : ($citation->is_book_article)  ? 'c'
                  : ($citation->is_thesis)        ? 'd'
		          : ($citation->is_conference)    ? 'p'
                  : ($citation->is_book)          ? 'b'
                  : ($citation->is_tech)          ? 'b'
		          :                                 '';

    unless ($form_type) { return ('', 'Unexpected request type.'); }

    return 'http://' . $self->host . '/ill' . $form_type;
}

sub message_note {
    my($self, $reqno) = @_;

    my $max_len = 1000;              ## ????????????? are there any length restrictions ??????????????
    my $trunc_note = '....';

    my $string = $self->SUPER::message_note($reqno);
    my $data_len = $max_len - length($trunc_note);

    if (length($string) > $data_len)  { $string = substr($string, 0, $data_len) . $trunc_note; }

    return $string;
}


sub _message_note_fields {
    my($self, $reqno) = @_;

    return (['holdings_site',  $self->holdings_site,                    'SITES'],

            ['title',          $self->citation->parsed('TITLE'),        'TITLE'],
            ['arttit',         $self->citation->parsed('ARTTIT'),       'ARTICLE TITLE'],
            ['series',         $self->citation->parsed('SERIES'),       'SERIES'],
            ['aut',            $self->citation->parsed('AUT'),          'AUTHOR'],
            ['artaut',         $self->citation->parsed('ARTAUT'),       'ARTICLE AUTHOR'],
            ['pub',            $self->publisher_statement,              'PUBLISHER'],
            ['voliss',         $self->citation->parsed('VOLISS'),       'VOLUME/ISSUE'],
            ['pgs',            $self->citation->parsed('PGS'),          'PAGES'],
            ['edition',        $self->citation->parsed('EDITION'),      'EDITION'],
            ['thesis_type',    $self->citation->parsed('THESIS_TYPE'),  'THESIS TYPE'],

            ['call_no',        $self->citation->parsed('CALL_NO'),      'CALL NO'],

            ['eric_no',        $self->citation->parsed('ERIC_NO'),      'ERIC DOC NO'],
            ['eric_av',        $self->citation->parsed('ERIC_AV'),      'ERIC AVAILABILITY'],
            ['mlog_no',        $self->citation->parsed('MLOG_NO'),      'MICROLOG NO'],
            ['umi_diss_no',    $self->citation->parsed('UMI_DISS_NO'),  'UMI DISS NO'],
            ['sysid',          $self->citation->parsed('SYSID'),        'SYSTEM NO'],
            ['repno',          $self->citation->parsed('REPNO'),        'REPORT NO'],
            ['repno',          $self->citation->parsed('OCLCNUM'),      'OCLC NO'],

            ['patent_no',      $self->citation->parsed('PATENT_NO'),    'PATENT NO'],
            ['patentee',       $self->citation->parsed('PATENTEE'),     'PATENTEE'],
            ['patent_year',    $self->citation->parsed('PATENT_YEAR'),  'PATENT YEAR'],

            ['doi',            $self->citation->parsed('DOI'),          'DOI'],
            ['pmid',           $self->citation->parsed('PMID'),         'PMID'],
            ['bibcode',        $self->citation->parsed('BIBCODE'),      'BIB CODE'],
            ['oai',            $self->citation->parsed('OAI'),          'OAI'],
            ['sici',           $self->citation->parsed('SICI'),         'SICI'],

            ['fax',            $self->fax,                              'FAX NO'],
            ['note',           $self->citation->parsed('NOTE'),         'CITATION NOTE'],

            ['patron_note',    $self->patron->note,                     'PATRON NOTE'],
            ['pickup',         $self->patron->pickup,                   'PICKUP LOCATION'],
            ['rush_req',       $self->rush_req,                         'RUSH'],
            ['payment_method', $self->patron->payment_method,           'PAY METHOD'],
            ['account_number', $self->patron->account_number,           'ACCOUNT'],
            ['notification',   $self->patron->notification,             'NOTIFY'],
            ['type',           $self->patron->type,                     'TYPE'],
            ['not_req_after',  $self->not_req_after,                    'NOT REQ AFTER'],

            ['department',     $self->patron->department,               'DEPARTMENT'],
            ['province',       $self->patron->province,                 'PROVINCE'],
            ['phone',          $self->patron->phone,                    'PHONE'],
            ['phone_work',     $self->patron->phone_work,               'PHONE WORK'],
            ['building',       $self->patron->building,                 'BUILDING'],
            ['street',         $self->patron->street,                   'STREET'],
            ['city',           $self->patron->city,                     'CITY'],
            ['postal_code',    $self->patron->postal_code,              'POSTAL CODE'],

            ['holdings',       $self->holdings,                         'HOLDINGS']
	   );
}

sub valid_date {
    my($self) = @_;

    use Time::Local;
    use GODOT::Date;    

    my($dd, $mm, $yyyy);
    my $string = $self->not_req_after;

    if ($string =~ m#^\s*(\d\d)/(\d\d)/(\d\d)\s*$#) {
        
        $dd   = $1;         
        $mm   = $2;
        $yyyy = $3;        
        $yyyy = &GODOT::Date::add_cent($yyyy);
	

        if (($dd < 1) || ($dd > 31)) {
            $self->error_message("Please enter a date in DD/MM/YY format.");
            return $FALSE;
        }

        if (($mm < 1) || ($mm > 12)) {
            $self->error_message("Please enter a date in DD/MM/YY format.");
            return $FALSE;
        }
        
        if ($yyyy > 2010)  {
            $self->error_message("Need before date is too far in the future.  Use the format DD/MM/YY (eg: 31/12/00 NOT 31/12/2000)");
            return $FALSE;
        }

        $self->not_req_after("$dd/$mm/$yyyy");
        
        ##
        ## Check that it's not a date previous to today's date.
        ##        
        if (Time::Local::timelocal(59,59,23,$dd,$mm-1,$yyyy) < time()) {
            $self->error_message("Need before date must be a future date.");
            return $FALSE;
        }               
        return $TRUE;        
    }

    $self->error_message("Please enter a date in DD/MM/YY format.");
    return $FALSE;
}

sub fill_field {
    my($self, $value, $rss_field, $form_ref) = @_;

    my $transliterated_value = transliterate_string($self->transliteration, $value);
    ${$form_ref}{$rss_field} = $transliterated_value unless (aws($transliterated_value));
}

sub transport { return 'http'; }

sub transliteration  { return 'latin1'; }

sub encoding         { return 'latin1'; }

   
##
## (02-nov-2010 kl)
## -input is reference to hash containing field/value pairs;
## -output is array of field/value pairs; 
##
sub order_fields {
    my($self, $form_ref) = @_;

    my @form;
    ##
    ## -make a copy so as not to modify the original
    ##
    my %remaining = %{$form_ref};        

    foreach my $field ($self->form_field_order) {
        if (defined($remaining{$field} && naws($remaining{$field}))) {
            push @form, [ $field, $remaining{$field} ];
            delete $remaining{$field};
        }
    }

    ##
    ## -put any remaining field/value pairs at the end
    ##    
    foreach my $field (keys %remaining) {
        push @form, [ $field, $remaining{$field} ] unless aws($remaining{$field});        
    }

    return @form;
}

sub form_field_order {  return @FORM_FIELD_ORDER;  }

sub check_http_return {
    my($self, $string) = @_;

    if ($string =~ m#sorry,\s+the\s+information\s+you\s+submitted\s+was\s+invalid.\s+please\s+try\s+again#i) {
        $self->error_message("There was a problem submitting your ILL request.  Possible reason is an invalid name or barcode.");
        return $FALSE;
    }
    elsif ($string =~ m#not\s+enough\s+information#i) {
        $self->error_message("There was a problem submitting your ILL request.  Required information is missing.");
        return $FALSE;       
    }
    else {
        return ($string =~ m#your request has been sent to the library#i);
    }
}

sub has_separate_auth_step {
    my($self) = @_;
    return $FALSE;
}

sub external_patron_verification {
    my($self) = @_;
    return $FALSE;
}

sub extpatid {
    my($self) = @_;
    return '';
}

sub extpatpw {
    my($self) = @_;
    return '';
}

sub _do_not_include {
    my($self) = @_;

    my $citation = $self->citation;

    my @list = ($citation->is_book || $citation->is_tech) ? qw(aut title pub)
             : ($citation->is_book_article)               ? qw(artaut arttit title aut pgs pub)
             : ($citation->is_conference)                 ? qw(title arttit artaut art)      
             : ($citation->is_journal)                    ? qw(artaut arttit title voliss pgs) 
             : ($citation->is_thesis)                     ? qw(aut title pub thesis_type)
             :                                              qw();          


    push @list, 'not_req_after';

    return @list;
}

sub _wrap_indent { return $WRAP_INDENT; }

sub _wrap_len { return $WRAP_LEN;  }


1;


