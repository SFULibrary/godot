package GODOT::CatalogueHoldings::BibCirc;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use Exporter;
use GODOT::Debug;
use GODOT::String;
use GODOT::Object;
use GODOT::CatalogueHoldings;

@ISA = qw(Exporter GODOT::CatalogueHoldings GODOT::Object);
@EXPORT = qw($INDICATOR_INDENT);

use strict;
use vars qw($INDICATOR_INDENT);

$INDICATOR_INDENT = 3;


my $MARC_ISBN_FIELD               = '020';
my $MARC_ISSN_FIELD               = '022';
my $MARC_TITLE_FIELD              = '245';


my $NUC_BRANCH_DELIM = '.';

my @FIELDS = ('user_site',          ## -single - end user site 
              'site',               ## -single - site to which holdings belong
              'source',             ## -single - source of bib/circ info         
                                    ##
              'title',              ## -multiple
              'marc_title',         ## -multiple
              'call_number',        ## -multiple
              'issn',               ## -multiple
              'isbn',               ## -multiple
                                    ##
              'collection',         ## -multiple - fiche collection holdings statements (eg. ERIC, Microlog)
                                    ##
              'cat_url',            ## -multiple - URL(s) to get to this item via web interface
              'bib_url',            ## -multiple - URL(s) found in bib record (ie. 856 field values)
                                    ##
              'holdings',           ## -multiple - holdings summary statements
              'circulation',        ## -multiple - circulation information
              'note',               ## -multiple - notes - temporarily using for DRA circ info....
                                    ##
              'citation',           ## -single (incoming citation)
              'search_type',        ## 
              'holdings_found'      ## -single 
             );


##
## -called using class not object, so appears to need to have 'dispatch' defined explicitly for the class 
##
sub dispatch {
    my ($class, $param)= @_;

    ##
    ## -for ELN-AG, ELN-AG-MONO, NEOS-OTHER, BNM-COW, BNM-NAN and BNM-POW
    ##

    ${$param}{'site'} =~ s#\055#_#g if (defined ${$param}{'site'});

    return $class->SUPER::dispatch($param);
}

sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}

sub title {
    my($self) = shift;
    $self->_multiple('title', @_);
}

sub marc_title {
    my($self) = shift;
    $self->_multiple('marc_title', @_);
}

sub call_number {
    my($self) = shift;
    $self->_multiple('call_number', @_);
}

sub issn {
    my($self) = shift;
    $self->_multiple('issn', @_);
}

sub isbn {
    my($self) = shift;
    $self->_multiple('isbn', @_);
}


##
## usage:
##
## @collections = $bibcirc->collection 
## @collections = $bibcirc->collection('ERIC') - returns a list of collection pairs for ERIC
## @collections = $bibcirc->collection('ERIC', <text>) - adds collection pair for ERIC
## 
## where each element of @collections is a GODOT::CatalogueHoldings::Collection object
##

sub collection  {
    my ($self, $type, $text) = @_;

    use GODOT::CatalogueHoldings::Collection;
    my @arr;

    unless (($type eq '') ||  GODOT::CatalogueHoldings::Collection->ok_type($type)) {

        debug("GODOT::CatalogueHoldings::BibCirc::Collection was passed an invalid type");
        return ();
    }

    if ($text)  {

        my $collection = new GODOT::CatalogueHoldings::Collection;

        unless ($collection) {
            debug("GODOT::CatalogueHoldings::BibCirc::Collection was unable to create a new collection object");
            return ();
        }

        unless ($collection->type($type) && $collection->text($text)) {
            return ();       
        }

        push(@{$self->{'collection'}}, $collection);
        my @arr = @{$self->{'collection'}};        
    }
    else {
        
        if ($type) {

            foreach my $collection (@{$self->{'collection'}}) {
                if ($collection->type eq $type) { push(@arr, $collection); }
            }
        }
        else {
            my @arr = @{$self->{'collection'}} if defined $self->{'collection'};
        }
    } 
    return @arr;
}


##
## usage:
##
## @urls = $bibcirc->cat_url;
## @urls = $bibcirc->cat_url($url, $text);
##
## where each element of @urls is a GODOT::CatalogueHoldings::URL object
##

sub cat_url  {
    my($self, $url, $text) = @_;    
    return $self->_url('cat_url', $url, $text);
}


sub bib_url  {
    my($self, $url, $text) = @_;    

    return $self->_url('bib_url', $url, $text);
}

sub holdings {
    my($self, @rest) = @_;

    return $self->_holdings('holdings', @rest);
}


##
## usage:
##
## @circulation = $bibcirc->circulation;
## @circulation = $bibcirc->circulation($location, $callno, $status);
##
## where each element of @circulation is a GODOT::CatalogueHoldings::Circulation object
##
sub circulation  {
    my ($self, $location, $callno, $status) = @_;

    if (($callno || $status ) && (GODOT::String::aws($location))) {

	debug("CatalogueHoldings::BibCirc::circulation: no location was passed");
        return ();
    }
   
    my $circ_location = $self->_circulation_location($location);

    use GODOT::CatalogueHoldings::Circulation;

    if (GODOT::String::naws($circ_location)) { 

        my $obj = new GODOT::CatalogueHoldings::Circulation;

        ##
        ## -define $callno and $circ_location as otherwise there will be problems with the returns of the GODOT::Circulation methods
        ##

        unless (defined $callno) { $callno = ''; }
        unless (defined $status) { $status = ''; }

        unless ((defined $obj->item_location($circ_location)) && 
                (defined $obj->call_number($callno)) && 
                (defined $obj->status($status)))              { return (); }

        push(@{$self->{'circulation'}}, $obj); 
    }

    return ((defined $self->{'circulation'}) ? @{$self->{'circulation'}} : ());
}

##
## usage:
## 
## @notes = $bibcirc->note;
## @notes = $bibcirc->note($note);
##
## where each element of @notes is a string
##

sub note  {
    my ($self, $note) = @_;

    use GODOT::CatalogueHoldings::Note;

    if (GODOT::String::naws($note)) {

        if (ref $note) {

            debug("CatalogueHoldings::BibCirc::Note: note passed was not a scalar");
            return ();
        }

        my $obj = new GODOT::CatalogueHoldings::Note;

        $obj->note($note);

        push(@{$self->{'note'}}, $obj);
    }

    return (defined $self->{'note'}) ? @{$self->{'note'}} : ();
}

##
## Extract values from catalogue record.
##

sub holdings_format {
    my($self, $db_config, $record) = @_;  

    my $user        = $db_config->name;
    my $system_type = $db_config->system_type;

    $self->source($db_config->name);
   
    report_time_location;

    if (defined $record) {
         
        $self->values_from_cat_rec($record);

        ##
        ## Default behaviour is to assume holdings if, for instance, only a title has been found, so 
        ## include 'holdings are available' phrase if we have not any actual holdings or circulation 
        ## records. 
        ##

        $self->default_holdings('Holdings are available.');
    }
    else { 
        debug location, ":  bibliographic record not defined";
    }

    #### debug "///////////////////////////////////////////////";
    #### debug $self->dump;
    #### debug "///////////////////////////////////////////////";

    report_time_location;    

    ##
    ## (23-jul-2001 kl) - if we are looking for holdings, not 856 links, then throw out record if no holdings/circ info
    ##

    if (($self->search_type eq 'holdings') && ($self->citation->is_journal)) {

        unless ((scalar $self->holdings || scalar $self->circulation))  {

           $self->empty;
        }
    }
}


sub url_link_format  {
    my($self, $db_config, $record) = @_;   

    return unless defined($record);   ## this should not happen
    my $user = $db_config->name;
    $self->source($user);
    $self->site($user);         ## -assume for now they are the same (ie. $user)

    my $bib = $record->bibliographic;
    use MARC::Record;
    my $rec = MARC::Record->new_from_usmarc($bib->rawdata());
    unless (defined $rec) {
        debug location, ":  bibliographic record not defined";
        return; 
    }

    ##
    ##
    ## -for now just take first _good_ ISBN 
    ##
    my $isbn;
    foreach my $field ($rec->field($MARC_ISBN_FIELD)) {
        foreach my $subfield ($field->subfields) {
            next unless defined $subfield;
            my($code, $data) = @{$subfield};

            if (clean_ISBN($data)) {
                $isbn = $data; 
                last;
            }
        } 
    }
 
    my $issn;   
    foreach my $field ($rec->field($MARC_ISSN_FIELD)) {
        foreach my $subfield ($field->subfields) {
            next unless defined $subfield;
            my($code, $data) = @{$subfield};           

            if (clean_ISSN($data)) {
                $issn = $data; 
                last;
            }
        }
    }

    my $title;
    my $marc_title;
    foreach my $field ($rec->field($MARC_TITLE_FIELD)) {
        $marc_title = $field; 
        foreach my $subfield ($field->subfields) {
            next unless defined $subfield;
            my $code;
            ($code, $title) = @{$subfield};
            next unless $code eq 'a';
            $title =~ s#/\s*$##;;
            last;
        }
        last;
    }

    $self->issn($issn);
    $self->isbn($isbn);
    $self->title($title);
    $self->marc_title($marc_title);
    $self->cat_url($db_config->zhost);
}


sub values_from_cat_rec {
    my($self, $record) = @_;
  
    my @field_names = $self->_fields_to_get_from_cat_rec;

    use MARC::Record;
    my $marc = MARC::Record->new_from_usmarc($record->bibliographic->rawdata());

    foreach my $field_name (@field_names) {    
        my $func = $field_name . '_from_cat_rec';
	no strict 'refs';
        $self->$func($record, $marc);
        use strict;
    }
}


sub titles_from_cat_rec {
    my($self, $record, $marc) = @_;

    my @fields = $marc->field('245');
    return $FALSE unless scalar @fields;

    $self->_holdings_found_if_title;

    foreach my $field (@fields) {
        $self->marc_title($field);
        my $string = $self->_clean_up_marc($field); 
        $self->title($string) unless aws($string);
    }
    return $TRUE;
}



sub call_number_from_cat_rec {
    my($self, $record, $marc) = @_;

    my @fields = $marc->field($self->_call_number_field);
 
    return $FALSE unless scalar @fields;

    foreach my $field (@fields) {
	my $string = $self->_keep_subfields_clean_up_marc($field, [$self->_call_number_subfield]);
        $self->call_number($string) unless aws($string);
    }

    return $TRUE;
}

sub isbn_from_cat_rec {
    my($self, $record, $marc) = @_;

    my @fields = $marc->field('020');
    return $FALSE unless scalar @fields;
   
    foreach my $field (@fields) {
        my $string = $self->_clean_up_marc($field);
        $self->isbn($string) unless aws($string);;
    }

    return $TRUE;
}

sub issn_from_cat_rec {
    my($self, $record, $marc) = @_;

    my @fields = $marc->field('022');
 
    return $FALSE unless scalar @fields;
   
    foreach my $field (@fields) {
        my $string = $self->_clean_up_marc($field);
        $self->issn($string) unless aws($string);
    }

    return $TRUE;
}

sub bib_url_from_cat_rec {
    my($self, $record, $marc) = @_;
    
    my @fields = $marc->field('856');
    return $FALSE unless scalar @fields;

    my $url_text_subfield = $self->_url_text_subfield;

    foreach my $field (@fields) {

        my $url      =  $self->_keep_subfields_clean_up_marc($field, ['u']);
        my $url_text =  $self->_keep_subfields_clean_up_marc($field, [$url_text_subfield]);  

        $self->bib_url($url, $url_text) unless aws($url);
    }

    return $TRUE;
}

sub holdings_from_cat_rec {
    my($self, $record, $marc) = @_;

    my @fields = $marc->field('9XX');
    return $FALSE unless scalar @fields;

    $self->_holdings_found_if_holdings;

    foreach my $field (@fields) {
        my $string = $self->_clean_up_marc($field);
        $self->holdings($self->source, $string) unless aws($string);
    }

    return $TRUE;
}


sub union_holdings_from_cat_rec {
    my($self, $record, $marc) = @_;

    my @fields = $marc->field('852');
    return $FALSE unless scalar @fields;

    my @holdings_nuc_subfields     = qw(a);                                    ## -nuc
    my @holdings_text_subfields    = $self->_union_holdings_text_subfields;    ## -holdings

    foreach my $field (@fields) {

        my @subfield_arr = $field->subfields;

        my $nuc = '';
        my $site = '';              
        my $holdings = '';       

        foreach my $subfield  ($field->subfields) {
                
            my($code, $data) = @{$subfield};
           
	    $data = $self->_union_holdings_subfield_processing($data);
                
            if (grep {$code eq $_} @holdings_text_subfields) {
                $holdings .= " $data";                          ## -there may be multiple 949-a in same 949 field
            }
            elsif (grep {$code eq $_} @holdings_nuc_subfields) {
                $nuc = $data;
            }
        }

        ##
        ## -$nuc may not be actual NUC, but could instead be a more readable location code (eg. YORK)
        ##

        ##            
        ## -use "\036" to separate fields, "\035" to separate 852 field instances
        ##            
        $nuc      =~ s#[\036\035]##g;
        $site     =~ s#[\036\035]##g;
        $holdings =~ s#[\036\035]##g;

        $nuc  = trim_beg_end($nuc);     ## this must be exact 
        $site = trim_beg_end($site);    ## this must be exact 

        $holdings = $self->_adjust_holdings($holdings);

        if (naws($holdings) && naws($nuc)) {

            $nuc = ($nuc . $NUC_BRANCH_DELIM . $site) if ($site ne '');    ## -make a pseudo-nuc
            $self->holdings($nuc, $holdings) unless aws($holdings);
        }  
    }

    return $TRUE;
}


sub circulation_from_cat_rec {
    my($self, $record, $marc) = @_;

    return $FALSE;
}


sub default_holdings {
    my($self, $text) = @_;

    if ($self->holdings_found && (! $self->holdings) && (! $self->circulation)) {
        $self->holdings($self->source, $text);
    }
}



sub skip_circ_location { return $FALSE; }


sub adjust_html_incl {
    ## do nothing
}


sub adjust_html_incl_long {
    ## do nothing
}


sub call_number_text {
    return '';
}


sub converted {
    my($self, $system_type) = @_;

    my %bib_circ_hash;     

    $bib_circ_hash{'bib_circ_db'}        = $self->source if (defined $self->source);
    $bib_circ_hash{'bib_circ_db_system'} = $system_type;
    $bib_circ_hash{'bib_circ_user'}      = $self->site if (defined $self->site);

    $bib_circ_hash{'bib_circ_title'}      = [ $self->title ] if (defined $self->title);
    $bib_circ_hash{'bib_circ_marc_title'} = [ $self->marc_title ] if (defined $self->marc_title);
    $bib_circ_hash{'bib_circ_issn'}       = [ $self->issn ] if (defined $self->issn);
    $bib_circ_hash{'bib_circ_isbn'}       = [ $self->isbn ] if (defined $self->isbn);
    $bib_circ_hash{'bib_circ_call_no'}    = [ $self->call_number ] if defined ($self->call_number);

    foreach my $collection ($self->collection) {
        if ($collection->type eq 'ERIC')     { push(@{$bib_circ_hash{'bib_circ_eric_coll'}}, $collection->text); } 
        if ($collection->type eq 'MICROLOG') { push(@{$bib_circ_hash{'bib_circ_mlog_coll'}}, $collection->text); } 
    }

    foreach my $url ($self->cat_url) {
        push(@{$bib_circ_hash{'bib_circ_cat_url'}}, $url->url); 
    }

    foreach my $url ($self->bib_url) {
        push(@{$bib_circ_hash{'bib_circ_bib_url'}}, [ $url->text, $url->url ]); 
    }

    foreach my $holdings ($self->holdings) {
        push(@{$bib_circ_hash{'bib_circ_holdings'}}, [ $holdings->site, $holdings->holdings ]); 
    }

    foreach my $circ ($self->circulation) {
        push(@{$bib_circ_hash{'bib_circ_circ'}}, [ $circ->item_location, $circ->call_number, $circ->status ]); 
    }

    foreach my $note ($self->note) {
        push(@{$bib_circ_hash{'bib_circ_note'}}, $note->text); 
    }

    #### use Data::Dumper;
    #### debug "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";
    #### debug Dumper(%bib_circ_hash);
    #### debug "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||";

    return %bib_circ_hash;
}


sub location_to_site {
    my($self, $location) = @_;

    my %map = $self->_location_to_site_map;

    ##
    ## -if map is empty
    ##
    #### return $location unless (scalar (keys %map));
    ##
    ## -if map is empty then return the source of the holdings
    ##
    return $self->source unless (scalar (keys %map));

    ##
    ## -If we have a map, but can't find a location then ignore.  Must be a new location.
    ##
    my $site = (defined $map{$location}) ? $map{$location} : '';

    return $site;
}

sub circ_location_to_site {
    my($self, $location) = @_;

    return $self->site;
}

##
## -input  - one GODOT::CatalogueHoldings::BibCirc object  
## -output - $div_hash{<user>} = <GODOT::CatalogueHoldings::BibCirc object> 
##
## -this process may involve dividing up one GODOT::CatalogueHoldings::BibCirc object into multiple instances,
##  with the appropriate bib and circ info being distributed between the various instances
##
sub divide {
    my($self, $div) = @_;

    my $do_not_include = [qw(holdings circulation)];

    my(%hold_div_hash, %circ_div_hash);

    $self->divide_circulation(\%circ_div_hash);
    $self->divide_holdings(\%hold_div_hash);

    ##
    ## -set $div to point to the GODOT::CatalogueHoldings::BibCirc object passed to function or, 
    ##  if the original GODOT::CatalogueHoldings::BibCirc object was split up, set it to point to the copies.
    ##

    unless (%hold_div_hash || %circ_div_hash) {
        ${$div}{$self->site} = $self;
        return;      
    }

    ##
    ## -original GODOT::CatalogueHoldings::BibCirc was split up, so point to the copies
    ##   

    foreach my $site (keys %hold_div_hash) {       ## -go through holdings info  

      	unless (defined ${$div}{$site}) {
	    ${$div}{$site} = $self->duplicate($do_not_include);
            ${$div}{$site}->site($site);
        }

        foreach my $holdings (@{$hold_div_hash{$site}})  { 
            ${$div}{$site}->holdings($holdings->site, $holdings->holdings); 
        }
    }

    foreach my $site (keys %circ_div_hash) {       ## -now do for circ info 

      	unless (defined ${$div}{$site}) {
	    ${$div}{$site} = $self->duplicate($do_not_include);
            ${$div}{$site}->site($site);
        }

        use Data::Dumper;
        #### debug "////////////////////////////////////////////////////////////////////\n",
        ####      Dumper(${$div}{$site}),
        ####      "////////////////////////////////////////////////////////////////////\n";

        foreach my $circulation (@{$circ_div_hash{$site}}) {
            ${$div}{$site}->circulation($circulation->item_location, $circulation->call_number, $circulation->status);
        }
    }
}


##
## -depending on the source, holdings may need to be divided up (ex. BVAS, BVASB and BVASS)
## -if this is done, then the hash ref $div will be filled
##
## -also, the holdings info in the BibCirc object (ie. $self) may get changed
##
sub divide_holdings {
    my($self, $div) = @_;

    foreach my $ref ($self->holdings) {

        my $location = $ref->site;
            
        my $site = $self->location_to_site(uc(trim_beg_end($location)));    

        ##
        ## (17-jun-2005 kl)
        ##
        unless (aws($site)) {
            $ref->site($site);
            push(@{${$div}{$site}}, $ref);  ## push on ref, not copy     
        }
    }
}

##
## -purpose of routine is to fill $div if circ data is for two different sites
##
sub divide_circulation { 
   my($self, $div) = @_;

   my $site = $self->site;

   foreach my $circulation ($self->circulation) {

       my $location = $circulation->item_location;
       my $call     = $circulation->call_number;
       my $status   = $circulation->status;
              
       my $circ_user = $self->circ_location_to_site($location);

       push(@{${$div}{$circ_user}}, $circulation);     ## add reference not copy 
   }
}

##
## -for now we are only duplicating the first level (ie. both the original and the duplicate will 
##  point to same cat_url and bib_url lists)
##
sub duplicate {
    my($self, $do_not_include) = @_;

    my $class = ref $self;
    my $copy = new $class;

    foreach my $field (@{$self->{'_permitted'}}) {

        next if (grep {$field eq $_} @{$do_not_include});
        $copy->{$field} = $self->{$field};            
    }   

    return $copy;
}




##
## usage:
##
## @holdings = $bibcirc->holdings;
## @holdings = $bibcirc->holdings($site, $holdings_statement);
##
## where each element of @holdings is a GODOT::CatalogueHoldings::Holdings object
##
## !!!!!!!!! $type needs to be the second parameter as $site and $holdings may be blank !!!!!!!!
##
sub _holdings  {
    my($self, $type, $site, $holdings) = @_;

    $site     = trim_beg_end($site);
    $holdings = trim_beg_end($holdings);

    if ($holdings && (! $site)) {
	debug(location, ": holdings statement was passed, but site was not");
        return ();
    }

    if ($site && (! $holdings)) {
	debug(location, ": site was passed, but holdings statement was not");
        return ();
    }

    use GODOT::CatalogueHoldings::Holdings;

    if ($holdings) {

        my $obj = new GODOT::CatalogueHoldings::Holdings;

        unless ((defined $obj->site($site)) && (defined $obj->holdings($holdings))) { return (); }

        push(@{$self->{$type}}, $obj);
    } 

    return (defined $self->{$type}) ? @{$self->{$type}} : ();
}


sub _location_to_site_map {
    return ();
}


sub _multiple {
    my $self = shift;
    my $field = shift;

    if (@_) { push(@{$self->{$field}}, @_); }
 
    if (defined $self->{$field}) {  return @{$self->{$field}}; }
    else                         {  return ();                 }
}


sub _url {
    my ($self, $type, $url, $text) = @_;
    
    use GODOT::CatalogueHoldings::URL;
    
    if (GODOT::String::aws($url)) {

        if (GODOT::String::naws($text)) {

            debug "GODOT::CatalogueHoldings::BibCirc::$type was passed text but no URL";
 	    return ();
        }
    }
    else { 

        my $obj = new GODOT::CatalogueHoldings::URL;

        unless ((defined $obj->url($url)) && (defined $obj->text($text))) { return (); }

        push(@{$self->{$type}}, $obj);

    }

    my @result = (defined $self->{$type}) ? @{$self->{$type}} : ();

    # use Data::Dumper;
    # debug "<<<_____________________________>>>";
    # debug Dumper(@result);
    # debug "<<<_____________________________>>>"; 

    return @result;
}


sub _call_number_field {
    return '099';
}

sub _call_number_subfield {
    return qw(a b);

}

sub _fields_to_get_from_cat_rec {
    return qw(titles call_number isbn issn bib_url holdings circulation);
}


sub _union_holdings_text_subfields {
    return ();
}

sub _union_holdings_subfield_processing {
    my($self, $subfield) = @_;
    return $subfield;
}

sub _url_text_subfield { return 'z'; }

sub _clean_up_marc {
    my($self, $field) = @_;

    my @string;

    foreach my $subfield ($field->subfields) {
        my($code, $data) = @{$subfield};
        push @string, $data;
    }

    return trim_beg_end(join(' ', @string));
}

sub _keep_subfields_clean_up_marc {
    my($self, $field, $keep_subfields) = @_;
  
    my @string;

    foreach my $subfield ($field->subfields) {
        my($code, $data) = @{$subfield};
        if (grep {$code eq $_} @{$keep_subfields}) {            
	    push @string, $data;
        }
    }

    return trim_beg_end(join(' ', @string));
}

sub _holdings_found_if_title {
    my($self) = @_;
    $self->holdings_found($TRUE);  
}

sub _holdings_found_if_holdings {
    my($self) = @_;
    $self->holdings_found($TRUE);
}


sub _adjust_holdings {
    my($self, $string) = @_;
    return $string;
}


sub _circulation_location {
    my($self, $location) = @_;
    return $location;
}


1;

__END__



