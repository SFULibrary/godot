package GODOT::ILL::Message::RELAIS;

##
## Copyright (c) 2006, Todd Holbrook, Simon Fraser University
##

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
            [ 'ISBN',     17, 'ISBN' ],
            [ 'CALL_NO',  50, 'CallNumber' ]];
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

    if ( !$self->valid_date ) { return ''; }

    my $xml;
    my $writer = new XML::Writer( OUTPUT => \$xml, UNSAFE => 1 );
    
    $writer->startTag('AddRequest',
                      'version'   => '2006.0.0.0',
                      'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                      'xsi:noNamespaceSchemaLocation' => 'http://ollie.lib.sfu.ca/~tholbroo/AddRequest.xsd',
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
    
    foreach my $site ( @partners_list ) {
        $writer->startTag('Location');
        $writer->characters( $site );
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


    $writer->endTag('PublisherInfo');


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


    $writer->startTag('NeedByDate');
    $writer->characters( $self->not_req_after() );
    $writer->endTag('NeedByDate');    

    $writer->endTag('RequestInfo');

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

    if ($self->_include_department) {
        $writer->startTag('Department');
        $writer->startTag('DepartmentDescription');
        $writer->characters( $patron->department );
        $writer->endTag('DepartmentDescription');
        $writer->endTag('Department');
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
           
            ##
            ## (03-oct-2006 kl) - remove this check for whitespace in order to solve the problem with Relais not accepting the
            ##                    case where PrimaryAddress.Address1 is not passed, but a filled PrimaryAddress.Address2
            ##                    is passed. If this breaks something else, may have to make this a special case.
            ##

            #### next if aws($data);            
            #### if ( !aws($format) ) {
            ####        $data = $self->$format( $data );
            #### }
            
            $data = $self->$format( $data );

            $data = substr( $data, 0, $size );
            $writer->startTag( $relais_field );
            $writer->characters( $data );
            $writer->endTag( $relais_field );
            
        }
        
        $writer->endTag('PrimaryAddress');
    }

    $writer->startTag('ElectronicDelivery');

    $writer->startTag('DeliveryMethod');
    $writer->characters('P');
    $writer->endTag('DeliveryMethod');

    if ($self->_include_delivery_email) {
        $writer->startTag('DeliveryEmail');
        $writer->characters( $patron->email );
        $writer->endTag('DeliveryEmail');
    }

    $writer->startTag('MessagingMethod');
    $writer->characters('E');
    $writer->endTag('MessagingMethod');
    
    $writer->startTag('MessagingEmail');
    $writer->characters( $patron->email );
    $writer->endTag('MessagingEmail');

    $writer->startTag('PickupLocation');
    $writer->characters( $patron->pickup );
    $writer->endTag('PickupLocation');

    $writer->startTag('DeliveryService');
    $writer->characters( 'Unknown' );
    $writer->endTag('DeliveryService');
   
    $writer->endTag('ElectronicDelivery');

    $writer->endTag('PatronRecord');
    
    $writer->endTag('Record');
    $writer->endTag('AddRequest');

    $writer->end;


    ##
    ## (16-jan-2006 kl) - both XML::Beautify and Relais fail on extended ascii so we need to convert to UTF8;
    ##                  - extended ascii was showing up in unexpected places as a result of a problem with cutting 
    ##                    and pasting HTML containing '&#8211;' which results in '\226' in godot; also showing up
    ##                    for accents;
    ##                  - also strip some low-order characters as they are not valid in XML.  Relais complains 
    ##                    as follows:  An invalid XML character (Unicode: 0x0) was found in the element content of 
    ##                    the document.
    ##
   
    $xml = '<?xml version="1.0" encoding="UTF-8"?>' . latin1_to_utf8_xml($xml); 

    my $b = XML::Beautify->new();
    $b->indent_str(' ');
    $xml = $b->beautify(\$xml);

    print STDERR $xml;

    print STDERR "\n\n-=-=-=- RESPONSE -=-=-=-=\n\n";

    # Encode XML before sending through SOAP  (<>&")

    my %encode_attribute = ('&' => '&amp;', '>' => '&gt;', '<' => '&lt;', '"' => '&quot;' );
    $xml =~ s/([&<>\"])/$encode_attribute{$1}/g;

    # Add SOAP wrapper.. Tried using SOAP::Lite, but it doesn't quite work with the Relais stuff. Probably my fault.
    
    $xml =   '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><soapenv:Body><addRequest soapenv:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><param xsi:type="xsd:string">'
           . $xml
           . '</param></addRequest></soapenv:Body></soapenv:Envelope>';

#    return undef;
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
        
        if ($yyyy > 2010)  {

            $self->error_message("Need before date is too far in the future.  Use the format DD/MM/YY (eg: 31/12/00 NOT 31/12/2000)");
            return $FALSE;
        }
        
        # Check that it's not a date previous to today's date.
        
        if (Time::Local::timelocal(59,59,23,$dd,$mm-1,$yyyy) < time()) {
            $self->error_message("Need before date must be a future date.");
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


sub check_http_return {
    my($self, $string) = @_;

    return ($string =~ m#PAT-\d+#);
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

sub _message_note_fields {
    my($self, $reqno) = @_;

    return (
            ['patron_note',    $self->patron->note,                     'PATRON NOTE'],

            ##
            ## (03-oct-2006 kl) - this is included in PatronRecord.PatronType so no need (I think) to repeat here
            ##
            ['patron_type',    $self->patron_type,                      'PATRON TYPE'],

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

1;
