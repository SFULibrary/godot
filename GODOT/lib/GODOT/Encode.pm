## GODOT::Encode
##
## Copyright (c) 2010, Kristina Long, Simon Fraser University
##
## Various encoding related routines for use in GODOT.  
## Override with local copy as required.
##
## IMPORTANT:  Do not print utf8 strings in debug statements as they may cause confusion depending on your editor.  Instead use
##             Data::Dump::dump to print as escaped ascii.  Trust me.
##
package GODOT::Encode;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(decode_from_octets 
             utf8_to_latin1_transliteration);

use strict;

use Data::Dump qw(dump);
use Encode;

use GODOT::Debug;
use GODOT::String;
use GODOT::Encode::Transliteration;

my $TRUE  = 1;
my $FALSE = 0;

my $DEBUG = $FALSE;

my %map;

BEGIN {
    %map = &utf8_to_latin1_transliteration_map;
}

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
## (29-jan-2010 kl) -- started with code from Search::Tools::Transliterate by Peter Korman
## 
## Input and output are strings in perl internal format.
## Output only contains characters in latin1 range.
## 
sub utf8_to_latin1_transliteration {
    my($string) = @_;

    my $latin1;

    #### debug "--- transliteration map ---";
    #### debug dump (\%map);

    ##
    ## -don't bother unless we have non-ascii bytes in the string
    ##
    return $string if is_ascii($string);

    $DEBUG && debug "converting:  ", dump($string), "\n";

    ##
    ## -loop through perl characters 
    ## 
    while ( $string =~ m/(.)/gox ) {           
        my $char = $1;

        if ( is_latin1($char) ) {
            $DEBUG && debug "is_latin1:  ", dump($char);
            $latin1 .= $char;
        }
        elsif (exists $map{$char}) {
            $DEBUG && debug 'transliterate:  ', dump($char), ' => ', dump($map{$char});
            $latin1 .= $map{$char};
        }
        else {
            $DEBUG && debug "not in map:  ", dump($char);
            $latin1 .= ' ';
        }
    }

    return $latin1;
}




1;

__END__




