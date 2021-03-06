package GODOT::ILL::Message::RELAIS;
##
## Copyright (c) 2006, Todd Holbrook, Simon Fraser University
##

use Data::Dump qw(dump);

use GODOT::Debug;
use GODOT::String;
use GODOT::Object;

use XML::Writer;
use XML::Beautify;

use base qw(GODOT::ILL::Message);

use strict;

sub godot_relais_map {
    my($self) = @_;

    return {'BibliographicInfo' => $self->bibliographic_info_map,
            'PrimaryAddress'    => $self->primary_address_map};
}

sub bibliographic_info_map {
    
    return [[ 'TITLE',   200, 'Title' ],
            [ 'AUT',     100, 'Author' ],
            [ 'SERIES',  120, 'SeriesTitle' ],
            [ 'EDITION',  20, 'Edition' ],
            [ 'ARTTIT',  120, 'ArticleTitle' ],
            [ 'ARTAUT',  120, 'ArticleAuthor' ],
            [ 'VOLISS',   50, 'VolumeIssue' ],
            [ 'PGS',      20, 'PagesRequested' ],
            [ 'ISSN',      9, 'ISSN' ],
            [ 'ISBN',     17, 'ISBN' ]];
}

sub primary_address_map {
    
    return [[ 'street',      70, 'Address1' ],
            [ 'building',   100, 'Address2' ],
            [ 'city',        40, 'City' ],
            [ 'province',    20, 'Province' ],
            [ 'postal_code', 15, 'PostalCode' ]];
}

sub format {
    my($self, $reqno) = @_;

    warn('=-=-=-= RELAIS');

    my $next_partners_max = 5;  # was 25
    my $date = $self->date;
    my $patron = $self->patron;
    my $citation = $self->citation;

    my $godot_relais_map = $self->godot_relais_map;

    if ( ! $self->valid_date ) { return ''; }

    my $xml;
    my $writer = new XML::Writer( OUTPUT => \$xml, UNSAFE => 1 );
    
    my $version = ($self->is_relais_version_2010) ? '2010.0.0.0' : '2006.0.0.0';

    $writer->startTag('AddRequest',
                      'version'   => $version,
                      'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                      'xsi:noNamespaceSchemaLocation' => $self->schema_location,
    );

    $writer->startTag('Record');

    $writer->startTag('Request');

    $writer->startTag('BibliographicInfo');
    foreach my $row ( @{ $godot_relais_map->{'BibliographicInfo'} } ) {
    	my ( $field, $size, $relais_field ) = @$row;
    	my $data = $citation->parsed($field);

    	next if aws($data);
    	
        $data = substr( $data, 0, $size );
        $writer->startTag( $relais_field );
        $writer->characters( $data );
        $writer->endTag( $relais_field );
    	
    }

    ##
    ## Get the ERIC document number in call number if available
    ##

    my $call_no = ($citation->parsed('ERIC_NO') =~ /ED/) ? $citation->parsed('ERIC_NO') : $citation->parsed('CALL_NO');

    $writer->startTag('CallNumber');
    $writer->characters( substr( $call_no, 0, 50) );
    $writer->endTag('CallNumber');

    $writer->startTag('InformationSource');
    $writer->characters( $self->source . " ($reqno)" );
    $writer->endTag('InformationSource');

    my @partners_list = $self->get_partners_list();

    if ( $self->request_type eq 'W' ) {
    	@partners_list = ();
    }
    elsif ( ( !grep { $self->request_type eq $_ } qw(D S) ) && scalar( @partners_list )) {
        unshift @partners_list, $self->nuc;
    }

    ##
    ## (29-apr-2011 kl) - version 2010 shows Location as a 'complexType'
    ##
    foreach my $site ( @partners_list ) {
        $writer->startTag('Location');
        if ($self->is_relais_version_2010) {
            $writer->startTag('SupplierCode');
            $writer->characters( $site );
            $writer->endTag('SupplierCode');
        }
        else {
            $writer->characters( $site );
        }
        $writer->endTag('Location');
    }

    $writer->endTag('BibliographicInfo');    

    $writer->startTag('PublisherInfo');

    if ( !aws( $citation->parsed('PUB') ) ) {
        $writer->startTag('Publisher');
        $writer->characters( substr( $citation->parsed('PUB'), 0, 40 ) );
        $writer->endTag('Publisher');
    }

    $writer->startTag('PublicationType');
    $writer->characters( $citation->is_journal ? 'J' : 'B' );
    $writer->endTag('PublicationType');

    if ( naws( $citation->parsed('YYYYMMDD') ) ) {
        $writer->startTag('PublicationDate');
        $writer->characters( $self->format_date( $citation->parsed("YYYYMMDD") ) );
        $writer->endTag('PublicationDate');
    }
    elsif ( naws( $citation->parsed('YEAR') ) ) {
        $writer->startTag('PublicationDate');
        $writer->characters( $citation->parsed("YEAR") );
        $writer->endTag('PublicationDate');
    }

    if ( !aws( $citation->parsed('PUB_PLACE') ) ) {
        $writer->startTag('PublicationPlace');
        $writer->characters( substr( $citation->parsed('PUB_PLACE'), 0, 40 ) );
        $writer->endTag('PublicationPlace');
    }

    $writer->endTag('PublisherInfo');

    ## 
    ## (12-sep-2012 kl) -- added so can have site specific logic for University of the Fraser Valley;
    ##
    $self->_format_request_info($writer, $patron, [ @partners_list ], $reqno);
    $writer->endTag('Request');

    $writer->startTag('PatronRecord');
    
    $writer->startTag('PatronID');
    $writer->characters( $patron->library_id );
    $writer->endTag('PatronID');
    
    $writer->startTag('PatronName');

    $writer->startTag('Surname');
    $writer->characters( $patron->last_name );
    $writer->endTag('Surname');

    $writer->startTag('FirstName');
    $writer->characters( $patron->first_name );
    $writer->endTag('FirstName');
    
    $writer->endTag('PatronName');

    $writer->startTag('LibrarySymbol');
    ##
    ## (26-nov-2006 kl) - so we can add pickup override logic for some sites (eg. SFU)
    ##
    #### $writer->characters( $self->nuc );
    ##
    $writer->characters( $self->override_sender_id );
    $writer->endTag('LibrarySymbol');

    $writer->startTag('PatronType');
    $writer->characters( $self->patron_type );
    $writer->endTag('PatronType');
    
    if ($self->_include_patron_phone || $self->_include_patron_phone_work) {
      
        $writer->startTag('ContactPhone');
        $writer->characters( $patron->phone );
        $writer->endTag('ContactPhone');

        $writer->startTag('ContactPhone');
        $writer->characters( $patron->phone_work );
        $writer->endTag('ContactPhone');
    }

    ##
    ## (17-may-2011 kl) - relais version 2010 does not like blank departments ...
    ##
    if ($self->_include_department) {
        if ((! $self->is_relais_version_2010) || (naws($patron->department))) {
            $writer->startTag('Department');
            $writer->startTag('DepartmentDescription');
            $writer->characters( $patron->department );
            $writer->endTag('DepartmentDescription');
            $writer->endTag('Department');
        }
    }

    my $has_address_data = 0;
    foreach my $row ( @{ $godot_relais_map->{'PrimaryAddress'} } ) {

    	my ( $field, $size, $relais_field ) = @$row;
        my $data = $patron->$field();
        if ( !aws($data) ) {
            $has_address_data = 1;
            last;
        }    

    }

    if ( $has_address_data ) {
        $writer->startTag('PrimaryAddress');
        foreach my $row ( @{ $godot_relais_map->{'PrimaryAddress'} } )  {

            my ( $field, $size, $relais_field, $format ) = @$row;
            my $data = $patron->$field();
            $data = $self->$format( $data ) unless aws($format);
            $data = substr( $data, 0, $size );
            $writer->startTag( $relais_field );
            $writer->characters( $data );
            $writer->endTag( $relais_field );
            
        }
        
        $writer->endTag('PrimaryAddress');
    }

    ##
    ## (22-aug-2010 kl) -- added '<BillingInformation><BillingContact><ContactPhone>' so could send patron home phone number to U of Winnipeg;
    ##                  -- they are using schema 'http://www.relais-intl.com/schema/2009.0/AddRequest.xsd' which does not allow '<PatronRecord><ContactPhone>';
    ##                  -- multiple '<BillingInformation><BillingContact><ContactPhone>' does not work so put work phone number in '<ElectronicDelivery><PhoneNumber>';
    ## 
    if (naws($patron->phone)  && $self->_include_phone_as_billing_contact_phone) {
            $writer->startTag('BillingInformation');
            $writer->startTag('BillingContact');
            $writer->startTag('ContactPhone');
            $writer->characters( $patron->phone );
            $writer->endTag('ContactPhone');
            $writer->endTag('BillingContact');
            $writer->endTag('BillingInformation');
    }

    $self->_format_electronic_delivery($writer, $patron);

    if ($self->_include_user_login) {
        $writer->startTag('UserLogin');

        $writer->startTag('LoginID');
        $writer->characters($patron->library_id);
        $writer->endTag('LoginID');

        $writer->startTag('LoginPassword');
        $writer->characters($patron->pin);
        $writer->endTag('LoginPassword');

        $writer->endTag('UserLogin');
    }

    $writer->endTag('PatronRecord');
    
    $writer->endTag('Record');
    $writer->endTag('AddRequest');

    $writer->end;


    ## 
    ## (27-oct-2010 kl) 
    ## 
    ## Have changed call below to reflect the fact that citation data is now being properly decoded on the way in and should be in perl internal format.
    ## Having said this, it is the case that the patron data may contain non-ascii data and may need decoding but currently is not.
    ## In this event, the patron data will get mangled for now .... has been put in the to do list.
    ## 
    ## Strip some low-order characters as they are not valid in XML.  Relais complains as follows:  An invalid XML character (Unicode: 0x0) was found 
    ## in the element content of the document.
    ##
    #### $xml = '<?xml version="1.0" encoding="UTF-8"?>' . latin1_to_utf8_xml($xml); 
    ####   
    $xml = '<?xml version="1.0" encoding="UTF-8"?>' . encode_for_xml($xml); 

    my $b = XML::Beautify->new();
    $b->indent_str(' ');
    $xml = $b->beautify(\$xml);

    #### debug Data::Dump::dump(split("\n", $xml));

    ##
    ## (28-apr-2011 kl) - no SOAP for relais version 2010
    ##
    unless ($self->is_relais_version_2010) {
        ##
        ## Encode XML before sending through SOAP  (<>&")
        ##
        my %encode_attribute = ('&' => '&amp;', '>' => '&gt;', '<' => '&lt;', '"' => '&quot;');
        $xml =~ s/([&<>\"])/$encode_attribute{$1}/g;

        ##
        ## Add SOAP wrapper. Tried using SOAP::Lite, but it doesn't quite work with the Relais stuff. Probably my fault.
        ##
        $xml = '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soapenv:Body><addRequest soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><param xsi:type="xsd:string">'
               . $xml
               . '</param></addRequest></soapenv:Body></soapenv:Envelope>';
    }

    return $xml;
}

sub message_url   {
    my($self) = @_;
    return $self->host;
}


##
## Format YYYYMMDD as YYYY-MM-DD
##

sub format_date {
    my ( $self, $date ) = @_;
    
    if ( $date =~ / (\d{4}) (\d{2}) (\d{2})/xsm ) {
        return sprintf("%04i-%02i-%02i", $1, $2, $3);
    }
    else {
        return undef;
    }
}


sub valid_date {
    my($self) = @_;

    use Time::Local;
    use Date::Calc qw(check_date);
    use GODOT::Date;    

    my($dd, $mm, $yyyy);

    my $string = $self->not_req_after;

    if ( $string =~ m{ (\d\d?) / (\d\d?) / (\d\d) }xsm ) {
        
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
        
        my $max_year = &GODOT::Date::date_yyyy(time) + 2;

        if ($yyyy > $max_year)  {
            $self->error_message("Need before date is too far in the future.  Use the format DD/MM/YY (eg: 31/12/00 NOT 31/12/2000).");
            return $FALSE;
        }
        
        ##
        ## Check that it is a valid date   
        ##

        unless (check_date($yyyy, $mm, $dd)) {
            $self->error_message("Need before date must be a valid date.");
            return $FALSE;
        }

        ##
        ## Check that it's not a date previous to today's date.
        ##

        if (Time::Local::timelocal(59,59,23,$dd,$mm-1,$yyyy) < time()) {
            $self->error_message("Need before date must be a future date. Use the format DD/MM/YY (eg: 31/12/00 NOT 31/12/2000).");
            return $FALSE;
        }

        $self->not_req_after( sprintf("%04i-%02i-%02i", $yyyy, $mm, $dd ) );
                
        return $TRUE;        
    }

    $self->error_message("Please enter a date in DD/MM/YY format.");
    return $FALSE;
}


sub override_sender_id {
    my($self) = @_;

    ##
    ## (26-nov-2006 kl) - library symbol logic that used to appear in format method above used 'nuc'.  
    ##                  - Is this what we want here as well?   
    ##
    #### return $self->nuc;

    return $self->sender_id;
}

sub next_partner {
    my($self, $site, $homelib) = @_;
    return $site;
}


sub transport { return 'relais'; }


##
## (10-feb-2010 kl) -- added support for ill_local_system_request_number which can be used in templates
##
sub check_http_return {
    my($self, $string) = @_;

    return $FALSE if $self->http_return_contains_error_message($string);

    if ($string =~ m#(PAT-\d+)#) {
        my $ill_local_system_request_number = $1;
        $self->ill_local_system_request_number($ill_local_system_request_number);
        return $TRUE;
    }
    return $FALSE;
}

sub http_return_contains_error_message {
    my($self, $string) = @_;

    debug '>>>>>>>>> httpd_return_contains_error_message:  ', $string;

    #### !!!!!!!!!!!!!!! here666 !!!!!!!!!!!!!!!!!!!!!!
    #### !!!!!!!!!!!!!!! are there any other places where relais logic needs to be changed because no longer getting '&lt;' version back ..... ???????????????
    ## (13-aug-2012 kl)
    ## -error messages are also being passed back as follows:
    ##  <ErrorMessage>The Patron in Request XML is not registered.  NCIP server profile STATUS ValidToDate indicate that the user is no longer active.</ErrorMessage>
    ##
    ## (04-feb-2010 kl) 
    ## -error messages are being passed back by relais as follows: 
    ##  &lt;ErrorMessage&gt;There was an Internal Error. Please contact the service provider.                                     &lt;/ErrorMessage&gt;
    ##  &lt;ErrorMessage&gt;The LoginID or Password is incorrect in Request XML.  Invalid LoginID or LoginPassword in PatronRecord&lt;/ErrorMessage&gt;
    ##
    ## -use 's' as a modifier, as this will lets '.' match newline (normally it doesn't)
    ## -use '?' for minimal matching, so we match on the first '&lt;/ErrorMessage&gt;', not the last; 
    ##
    if (($string =~ m#&lt;ErrorMessage&gt;(.+?)&lt;\/ErrorMessage&gt;#is) || 
        ($string =~ m#<ErrorMessage>(.+?)<\/ErrorMessage>#is))  {    
        my $error_message = $1;
        $self->error_message($error_message);
        return $TRUE;
    }

    return $FALSE;
}


sub get_partners_list {
    my ( $self ) = @_;

    my $homelib = $self->override_sender_id;

    my $tmp_str = $self->next_partner($self->lender_site, $homelib, $self->lender_nuc);

    my @site_arr = ($tmp_str);           ## -initialize with site that user has chosen
    my $num_next_partners = 1;

    foreach my $site (split(/\s+/, $self->holdings_site)) {

        debug "NextPartner logic:  $site";

        my $tmp_user;
        my $tmp_nuc;

        if ( $num_next_partners >= 5 ) { last; }        ## -break out of loop !!!! 

        ##
        ## -change BVAU[BVAU-KRNR] to BVAU-KRNR 
        ## -separate with commas
        ##

        if ($site =~ m#^(.+)\[(.+)\]$#)   { $tmp_nuc = $1;        $tmp_user = $2; }   ## -we want the GODOT user not the NUC
        else                              { $tmp_user = $site; }

        $tmp_user = $self->next_partner($tmp_user, $homelib, $tmp_nuc);

        ##
        ## We don't want site user has chosen in list twice
        ## Also don't want the home library in there. Changed loop flow to allow for that.
        ##

        if ($tmp_user eq $self->lender_site)     { next; }
        if ($tmp_user eq $self->nuc)             { next; }
        if ($tmp_user eq $tmp_str)               { next; }

        $num_next_partners++;

        ##
        ## Depending on transformation by next_partner method we may have duplicates (eg. all BVAU-XXX map to BVAU)
        ##

	    push(@site_arr, "$tmp_user") unless (grep { $tmp_user eq $_ } @site_arr);

    }     

    return @site_arr;
}
    

sub trim {
    my ( $self, $string ) = @_;
    
    $string =~ s/^\s+//g;
    $string =~ s/\s+$//g;
    
    return $string;
}

sub message_note   {
    my($self, $reqno, $widv, $pagv) = @_;
              
    my(@misc_arr) = $self->_message_note_fields($reqno);
    my $note;
    my @do_not_include = $self->_do_not_include;

    foreach my $list_ref (@misc_arr) {

        my($id, $value, $label) = @{$list_ref};
 
        next if (grep {$id eq $_} @do_not_include);
        next if (aws($value));

	    $note .= "$label: $value\n";
    }

    if ( length($note) > 980 ) {
    	$note = substr( $note, 0, 980 ) . ' .. ';
    }

    return $note;
}


sub schema_location {
    my($self) = @_;

    return 'http://lib-relais.lib.sfu.ca/XML/AddRequest.xsd';
}


sub transliteration  { return 'utf8'; }


sub encoding         { return 'utf8'; }

sub _format_request_info {
    my($self, $writer, $patron, $partners_list, $reqno) = @_;

    my $citation = $self->citation;
    my @partners_list = @{$partners_list};

    $writer->startTag('RequestInfo');

    $writer->startTag('ServiceType');
    $writer->characters( $citation->is_journal || $citation->is_book_article ? 'X' : 'L' );
    $writer->endTag('ServiceType');    

    $writer->startTag('ServiceLevel');
    $writer->characters( 'R' );
    $writer->endTag('ServiceLevel');    

    $writer->startTag('Notes');
    my $notes = $self->trim( $self->message_note( $reqno ) );
    foreach my $note ( split /\n/, $notes ) {
    	$writer->characters( $note );
	    $writer->raw('&#13;');
	    $writer->raw('&#10;');
    }
    $writer->endTag('Notes');

    if ($self->_include_request_type) {

        $writer->startTag('Mailbox');
        $writer->characters(
              ( grep { $self->request_type eq $_ } qw(D S) ) 
            ? 'UNMED' 
            : scalar( @partners_list ) > 0
            ? 'APPROVAL'
            : 'MED'
        );
        $writer->endTag('Mailbox');
    }

    ##
    ## -relais does not like a blank date
    ##
    if (naws($self->not_req_after())) {
        $writer->startTag('NeedByDate');
        $writer->characters( $self->not_req_after() );
        $writer->endTag('NeedByDate');    
    }

    $writer->endTag('RequestInfo');
}

sub _format_electronic_delivery {
    my($self, $writer, $patron) = @_;

    $writer->startTag('ElectronicDelivery');

    $writer->startTag('DeliveryMethod');
    $writer->characters($self->_delivery_method);
    $writer->endTag('DeliveryMethod');

    if ($self->_include_delivery_email) {
        $writer->startTag('DeliveryEmail');
        $writer->characters( $patron->email );
        $writer->endTag('DeliveryEmail');
    }

    if ($self->_include_messaging_format) {
        $writer->startTag('MessagingFormat');
        $writer->characters('T');
        $writer->endTag('MessagingFormat');
    } 

    $writer->startTag('MessagingMethod');
    $writer->characters($self->_messaging_method);
    $writer->endTag('MessagingMethod');
    
    $writer->startTag('MessagingEmail');
    $writer->characters( $patron->email );
    $writer->endTag('MessagingEmail');

    ##
    ## (22-aug-2010 kl) -- added '<ElectronicDelivery><PhoneNumber>' so could send patron work phone number to U of Winnipeg;
    ##                  -- they are using schema 'http://www.relais-intl.com/schema/2009.0/AddRequest.xsd' which does not allow '<PatronRecord><ContactPhone>';
    ##                  -- multiple '<BillingInformation><BillingContact><ContactPhone>' does not work so put work phone number in '<ElectronicDelivery><PhoneNumber>';
    ##
    if (naws($patron->phone_work)  && $self->_include_phone_as_billing_contact_phone_work) {
            $writer->startTag('PhoneNumber');
            $writer->characters( $patron->phone_work );
            $writer->endTag('PhoneNumber');
    }

    $writer->startTag('PickupLocation');
    ##
    ## (17-nov-2011 kl) -- added for Winnipeg
    ##
    #### $writer->characters( $patron->pickup );
    $writer->characters( $self->_pickup_location($patron));
    $writer->endTag('PickupLocation');

    $writer->startTag('DeliveryService');
    $writer->characters( 'Unknown' );
    $writer->endTag('DeliveryService');

    $writer->endTag('ElectronicDelivery');
}

sub _delivery_method {
    return 'P';
}

sub _messaging_method {
    return 'E';
}

sub _pickup_location {
    my($self, $patron) = @_;
    return $patron->pickup;
}

sub _message_note_fields {
    my($self, $reqno) = @_;

    return (
            ['patron_note',    $self->patron->note,                     'PATRON NOTE'],

            ##
            ## (27-oct-2008 kl) - this is included in PatronRecord.PatronType so no need (I think) to repeat here
            ##
            #### ['patron_type',    $self->patron_type,                      'PATRON TYPE'],

            ['reqno',          $reqno,                                  'REQ NO'],
            ['eric_no',        $self->citation->parsed('ERIC_NO'),      'ERIC DOC NO'],
            ['eric_av',        $self->citation->parsed('ERIC_AV'),      'ERIC AVAILABILITY'],
            ['mlog_no',        $self->citation->parsed('MLOG_NO'),      'MICROLOG NO'],

            ['umi_diss_no',    $self->citation->parsed('UMI_DISS_NO'),  'UMI DISS NO'],
            ['sysid',          $self->citation->parsed('SYSID'),        'SYSTEM NO'],

            ['patent_no',      $self->citation->parsed('PATENT_NO'),    'PATENT NO'],
            ['patentee',       $self->citation->parsed('PATENTEE'),     'PATENTEE'],
            ['patent_year',    $self->citation->parsed('PATENT_YEAR'),  'PATENT YEAR'],

            ['note',           $self->citation->parsed('NOTE'),         'CITATION NOTE'],

            ##
            ## (11-nov-2008 kl) - added as it was missing;
            ##
            ['account_number', $self->patron->account_number,           'ACCOUNT'],

            ##
            ## (27-oct-2008 kl) - added as it was not being passed in any other field; is there a better field for it??
            ##       
            ['notification',   $self->patron->notification,             'NOTIFY'],

            ['holdings_site',  $self->holdings_site,                    'SITES'],
            ['holdings',       $self->holdings,                         'HOLDINGS'],
	   );
}


sub _include_request_type {
    return $FALSE;    
}

sub _include_delivery_email {
    return $FALSE;
}

sub _include_patron_phone {
    return $FALSE;
}

sub _include_patron_phone_work {
    return $FALSE;
}

sub _include_department {
    return $FALSE;
}

sub _include_user_login {
    return $FALSE;
}

sub _include_messaging_format {
    return $FALSE;
}

sub _include_phone_as_billing_contact_phone {
    return $FALSE;
}

sub _include_phone_as_billing_contact_phone_work {
    return $FALSE;
}



1;
