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
             marc_record_field_to_utf8);
use strict;

use Data::Dump qw(dump);
use Data::Dumper;
use Encode;
use MARC::Record;
use MARC::Field;
use MARC::Charset;

use GODOT::Debug;
use GODOT::String;
use GODOT::Encode::Transliteration;

my $TRUE  = 1;
my $FALSE = 0;
my $BLANK = '';

sub decode_from_octets {
    my($octets) = @_;

    my $string;
    my $error;

    eval {  $string = decode_utf8($octets, Encode::FB_CROAK);  };
    $error = $@;

    #### debug "decode_from_octets -- utf8:  $error";  
        
    ##
    ## -if there is an error then assume it is because this is not valid utf8 encoding and the encoding is either windows-1252 or iso-8859-1
    ## -since iso-8859-1 is a subset of windows-1252 decode from 'cp1252'
    ##
    if ($error) {
        eval { $string = decode('cp1252', $octets, Encode::FB_CROAK);  }; 
        $error = $@; 
        if ($error) { $string = decode('cp1252', $octets, Encode::FB_DEFAULT); }   ## -with Encode::FB_DEFAULT substitution characters will be put in place of the malformed character
    }

    return $string;
}

##
## (25-mar-2010 kl) - first pass  ... system differences should likely be handled elsewhere.
## 
sub encode_catalogue_search_term {
    my($string, $system_type) = @_;

    debug 'before -- encode_catalogue_search_term:  ', Dumper($string), "\n";

    ##
    ## -seems that many of the coppul/eln catalogues do not return records when search terms contain utf8 characters;
    ## -not clear whether this is because of limitations with their z39.50 servers or because they are not indexing utf8 version of titles;
    ## -am assuming that catalogues that are mostly non-english records will handle utf8 search terms or perhaps they are using other character sets??
    ## -adjust this routine to match they way the catalogues you want to search are configured
    ##
    
    if ($system_type eq 'ENDEAVOR') {
        $string = encode_utf8($string);
    }
    elsif ($system_type eq 'III') {
        ##
        ## -indexes utf8 characters as escaped ascii using the form {u<code point>}.  
        ## -for instance an e-acute would be '{u00e9}' 
        ##
        $string = curly_brace_utf8_escape_format($string);      
    }
    else {
        ##
        ## -utf8 to ascii transliteration 
        ##
        $string = utf8_to_ascii_transliteration($string);
    }

    debug 'after -- encode_catalogue_search_term:  ', dump($string), "\n";  

    return $string;
}


## 
## (11-apr-2010 kl) -- convert MARC::Field to utf8
## 
## Field must not be a control field (ie. > 009).
##
sub marc_record_field_to_utf8 {
    my($marc, $field) = @_;

    unless (ref $marc eq 'MARC::Record') {        
        debug '$marc is not a MARC::Record';
        return undef;
    }

    if ($field->is_control_field) {
        debug '$field is a control field but subroutine was expecting a non-control field';
        return undef;
    }

    my $leader_09 = substr($marc->leader, 9, 1);
    debug "leader-09 value is invalid ($leader_09)" unless grep { $leader_09 eq $_ } ($BLANK, 'a');

    MARC::Charset->ignore_errors(1);

    my %subfields_utf8;
    foreach my $subfield ($field->subfields) {
        my($code, $data) = @{$subfield};
	$data = marc8_to_utf8($data) if ($leader_09 eq $BLANK);
        $subfields_utf8{$code} = $data;
    }
        
    my $field_utf8 = MARC::Field->new($field->tab, $field->indicator(1), $field->indicator(2), %subfields_utf8);
    return $field_utf8;

}



1;

__END__




