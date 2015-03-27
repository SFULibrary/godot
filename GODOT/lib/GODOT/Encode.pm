## GODOT::Encode
##
## Copyright (c) 2010, Kristina Long, Simon Fraser University
##
## This file, GODOT::Encode, is for encoding related routines that you may need to override with a local copy for non-english languages.
## Use GODOT::String for encoding related routines that you are unlikely to need to override.
## See GODOT::Normalize for routines that you will likely want to override for non-english languages.
##
## IMPORTANT:  Do not print utf8 strings in debug statements as they may cause confusion depending on your editor.  
##             Instead use Data::Dump::dump or Data::Dumper::Dumper to print as escaped ascii.  Trust me.
##
package GODOT::Encode;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(decode_from_octets 
             encode_catalogue_search_term
             bib_record_detect_encoding
             leader_09_for_encoding
             decode_marc_record_field_clone
             link_template_field);
use strict;

use Data::Dump qw(dump);
use Data::Dumper;
use Encode;
use MARC::Record;
use MARC::Field;
use MARC::Charset qw(marc8_to_utf8);

use GODOT::Debug;
use GODOT::String;
use GODOT::Encode::Transliteration;

my $TRUE  = 1;
my $FALSE = 0;

my $BLANK = ' ';

sub decode_from_octets {
    my($octets) = @_;

    #### report_location;

    my $string;
    my $error;

    eval {  $string = decode_utf8($octets, Encode::FB_CROAK);  };
    $error = $@;
    #### debug location_plus, "utf8:  $error";  
    #### debug location_plus, "string:  $string";
        
    ##
    ## -if there is an error then assume it is because this is not valid utf8 encoding and the encoding is either windows-1252 or iso-8859-1
    ## -since iso-8859-1 is a subset of windows-1252 decode from 'cp1252'
    ##
    if ($error) {
        eval { $string = decode('cp1252', $octets, Encode::FB_CROAK);  }; 
        $error = $@; 
        #### debug location_plus, "cp1252:  $error";  

        if ($error) { 
            ##
            ## -with Encode::FB_DEFAULT substitution characters will be put in place of the malformed character
            ## -(19-sep-2012 kl) was failing with 'Wide character in subroutine entry at /usr/lib/perl5/5.8.5/i386-linux-thread-multi/Encode.pm line 164'
            ##  so add an eval;  if decode fails then $string will be empty;
            ##
            eval { $string = decode('cp1252', $octets, Encode::FB_DEFAULT); };
            $error = $@;
            #### debug location_plus, 'error after decode with Encode::FB_DEFAULT:  ',  $error;  
            #### debug location_plus, 'string after decode with Encode::FB_DEFAULT:  ',  $string;  
        }
    }

    return $string;
}

##
## (25-mar-2010 kl) - first pass  ... system differences should likely be handled elsewhere.
## 
sub encode_catalogue_search_term {
    my($string, $system_type, $title_index_includes_non_ascii) = @_;

    #### report_location;
 
    ##
    ## -seems that many of the coppul/eln catalogues do not return records when search terms contain utf8 characters;
    ## -not clear whether this is because of limitations with their z39.50 servers or because they are not indexing utf8 version of titles;
    ## -am assuming that catalogues that are mostly non-english records will handle utf8 search terms or perhaps they are using other character sets??;
    ## -adjust this routine to match the way the catalogues you want to search are configured;
    ##
    if ($title_index_includes_non_ascii) {
        ##
        ## -indexes utf8 characters as escaped ascii using the form {u<code point>} (eg. e-acute is '{u00e9}') 
        ##
        $string = ($system_type eq 'III') ? curly_brace_utf8_escape_format($string) : GODOT::String::encode_string('utf8', $string);     
    }    
    else {
        ##
        ## -utf8 to ascii transliteration 
        ##
        $string = utf8_to_ascii_transliteration($string);
    }

    return $string;
}

##
## (21-oct-2010 kl)
## - fix leader-9 so that it matches actual encoding 
## - does not try encodings other than utf8 or marc8
## - in future, add logic that is more like that found in koha C4::Charset::MarcToUTF8Record as it considers other character encodings 
##   such as latin1 and iso-5426.  It also differentiates between marc21 and unimarc.  As well, it takes care of the case where the encoding cannot 
##   be determined or has errors.
##
sub bib_record_detect_encoding {
    my($rawdata) = @_;   

    #### debug location;
    #### debug '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~';
    #### debug Data::Dump::dump($rawdata);
    #### debug '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~';
    
    my $encoding;
    my $try_to_read = $FALSE;

    if (is_utf8_octets($rawdata)) {
        #### debug location_plus, 'is_utf8';
        $encoding = 'utf8';
        $try_to_read = $TRUE;
    }
    elsif ((is_marc8_octets($rawdata)) && (has_common_marc8_sequences($rawdata))) {
        #### debug location_plus, 'is_marc8';
        $encoding = 'marc8';
        $try_to_read = $TRUE;
    }
    elsif (is_latin1_or_marc_delim($rawdata)) {
        #### debug location_plus, 'is_latin1';
        $encoding = 'latin1';
        $try_to_read = $TRUE;
    }
    else {
        $encoding = 'unknown';

        ####
        #### debug location_plus, "none of utf8, marc8 or latin1 encoding\n";       
        #### debug '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~';
        #### my @fields = split("\036", $rawdata);
        #### foreach my $field (@fields) {
        ####    foreach my $subfield (split("\037", $field)) {
        ####        debug Data::Dump::dump($subfield);
        ####    }
        #### }
        #### debug '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~';
        ####
    }    

    return ($encoding, $try_to_read);
}

##
## (23-oct-2010 kl) -- currently encoding may be 'utf8', 'marc8' or 'latin1'
##                  -- if encoding is 'latin1' then set leader-9 to blank as otherwise utf8 decoding logic will complain
##
sub leader_09_for_encoding {
    my($encoding) = @_;

    my $new_leader_09 = ($encoding eq 'utf8') ? 'a' : $BLANK;
}

##
## (23-oct-2010 kl) 
## - latin1 will easily pass for marc8 when testing with  MARC::Charset::marc8_to_utf8 so add this further test
## - code below is language specific -- current code should work ok for french and other similar languages;
##
sub has_common_marc8_sequences {
    my($octets) = @_;

    return ($octets =~ m#[\xe1-\xe3][aeiouAEIOU]|\xf0[cC]#) ? $TRUE : $FALSE;
}

## 
## (23-oct-2010 kl) -- add logic to take into account the guessed encoding which may be neither utf8 nor marc8
## (11-apr-2010 kl) -- convert MARC::Field to utf8
## 
## Field must not be a control field (ie. > 009).
## !!!! Below will cause problems if any MARC::Field or MARC::Record logic is used that assumes data is still encoded.  However this should be ok for now for our purposes. !!!
##
sub decode_marc_record_field_clone {
    my($marc, $field, $encoding) = @_;

    #### report_location;

    unless (ref $marc eq 'MARC::Record') {        
        debug '$marc is not a MARC::Record';
        return undef;
    }

    unless (ref $field eq 'MARC::Field') {        
        debug '$field is not a MARC::Field';
        return undef;
    }

    if ($field->is_control_field) {
        debug '$field is a control field but subroutine was expecting a non-control field';
        return undef;
    }

    my $leader_09 = substr($marc->leader, 9, 1);
    debug "leader-09 value is invalid ($leader_09)" unless (grep { $leader_09 eq $_ } ($BLANK, 'a'));

    ## 
    ## (22-oct-2010 kl) -- decode based on $encoding
    ## (11-oct-2010 kl) -- change '%subfields_utf8' from a hash to a list so that order of subfields is preserved 
    ##
    my @subfields_utf8;
    foreach my $subfield ($field->subfields) {
        my($code, $data) = @{$subfield};        
        
        #### debug location_plus, Data::Dump::dump($data);

        ## (23-oct-2010)
        ## If marc record was encoded in utf8 the $bib_record_object data will be in perl internal format.
        ## If marc record was encoded in marc8 the $bib_record_oject data will still be encoded in marc8.
        ##
        ## (22-oct-2010) -- Encode::marc8_to_utf8 outputs decoded utf8 (ie. perl internal format).
        ##
        my $decoded_data;
        if ($encoding eq 'utf8') {
	        $decoded_data = $data;
        }
        elsif ($encoding eq 'marc8') {
	        $decoded_data = marc8_to_utf8($data, 'ignore-errors');    ## -marc8_to_utf8 outputs the perl internal format
        }
        elsif ($encoding eq 'latin1') {
            $decoded_data = decode("iso-8859-1", $data, Encode::FB_DEFAULT);
        }
        else {
            debug location_plus, "unexpected encoding ($encoding)";
            return undef;
        }

        #### debug location_plus, Data::Dump::dump($decoded_data), " -- is_utf8:  ", utf8::is_utf8($decoded_data);

        push @subfields_utf8, $code => $decoded_data;
    }
        
    my $field_utf8 = MARC::Field->new($field->tag, $field->indicator(1), $field->indicator(2), @subfields_utf8);
    return $field_utf8;
 }


##
## (26-jun-2010 kl)
## Refworks and citation manager links use ancient GODOT_ORIG/link_template.pm logic which really needs to be replaced
## with GODOT::Citation::openurl or GODOT::Citation::openurl_latin1.  For now add quick fix and change 
## to 'latin1 with transliteration'.  The utf8 is an issue for citation manager.  May be an issue for refworks but not
## sure yet, however they use the same code for link generation so go to latin1 for both.
##
sub link_template_field {
    my($string) = @_;

    return encode_string('latin1', transliterate_string('latin1', $string));
}



1;

__END__




