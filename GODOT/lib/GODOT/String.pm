## GODOT::String
##
## Copyright (c) 2001, Todd Holbrook, Simon Fraser University
##
## Various string tools related to GODOT functions, including some library
## related things like ISSN/ISBN cleanups, etc.
##

package GODOT::String;

use CGI qw(:escape);
use GODOT::Debug;


use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(strip_dos_extended_characters 
             strip_trailing_punc_ws
             clean_ISSN 
             clean_ISBN 
             valid_ISBN
             valid_ISBN_10
             valid_ISBN_13
             convert_ISBN
             valid_ISSN_s_ok
             valid_ISSN_no_hyphen_s_ok
             normalize_marc8 
             normalize_latin1 
             latin1_to_utf8
             latin1_to_utf8_xml
             is_single_word 
             aws 
             naws 
             trim_beg_end 
             trim_end 
             comp_ws 
             quote
             all_digits 
             rep_char 
             strip_html
             strip_subfield 
             strip_white_space
             contains_white_space
             no_white_space             
             add_trailing_period 
             marc8_to_latin1 
             remove_leading_article
             keep_marc_subfield
             filter_marc_subfield
             strip_extra_leading_subfield
             rm_arr_dup_str
             put_query_fields
             put_query_fields_from_array
             uri_encode_string
             valid_email);

use strict;

my $TRUE  = 1;
my $FALSE = 0;


use vars qw(%DOS_TO_UNIX_EXTENDED);
# Conversion table from DOS extended to UNIX extended character sets.
# In DECIMAL.
%DOS_TO_UNIX_EXTENDED = (
	'128' => 199,  # C
	'129' => 252,  # u-umlat
	'130' => 233,  # e-acute
	'131' => 226,  # a-hat
	'132' => 228,  # a-umlat
	'133' => 224,  # a-grave
	'134' => 229,  # a-o
	'135' => 231,  # c
	'136' => 234,  # e-hat
	'137' => 235,  # e-umlat
	'138' => 232,  # e-grave
	'139' => 239,  # i-umlat
	'140' => 238,  # i-hat
	'141' => 236,  # i-grave
	'142' => 196,  # A-umlat
	'143' => 197,  # A-o
	'144' => 201,  # E-acute
	'145' => 230,  # ae
	'146' => 198,  # AE
	'147' => 244,  # o-hat
	'148' => 246,  # o-umlat
	'149' => 242,  # o-grave
	'150' => 251,  # u-hat
	'151' => 249,  # u-grave
	'153' => 214,  # O-umlat
	'154' => 220,  # U-umlat
	'156' => 158,  # Pound sign
	'157' => 165   # Yen??
);


my $KEEP_MARC_SUBFIELD   = 'keep_marc_subfield';
my $REMOVE_MARC_SUBFIELD = 'remove_marc_subfield';

my @STOP_WORDS = qw(& a an of and in on for the le les la de du et au der das die el);


# strip_dos_extended_characters - Changes DOS extended characters to their UNIX
# equivalents so that GODOT doesn't choke on them.

sub strip_dos_extended_characters {
	my ($string) = @_;
	$string =~ s/(%[\da-fA-F]{2})/hex(substr $&,1,2) > 127 ? ($DOS_TO_UNIX_EXTENDED{hex(substr $&,1,2)} ? "%" . uc(sprintf("%x", $DOS_TO_UNIX_EXTENDED{hex(substr $&,1,2)})) : "") : $&/ieg;
	return $string;
}


sub strip_trailing_punc_ws {
    my($string) = @_;

    $string =~ s#[\s!,:;\?\.]+$##g;
    return $string;
}


sub clean_ISSN {
	my ($string, $dash) = @_;
	
	# Remove everything that isn't a digit or Xx
	
	$string =~ tr/[0-9]xX//cd;

	if ($string =~ /^(\d{7}[\dxX])$/) {
		$string = $1;
		return substr($string,0,4) . ($dash ? '-' : '') . substr($string,4,4);
	} else {
		return undef;
	}
}

##
## (10-nov-2006 kl) clean up isbn-10 or isbn-13
##
sub clean_ISBN {
	my ($string) = @_;
	
	# Remove everything that isn't a digit or Xx
	
	$string =~ tr/0-9xX//cd;

	if ($string =~ /^(\d{9}|\d{12})([\dxX])$/) {
		return $1 . $2;
	} else {
		return undef;
	}
}

##
## (08-dec-2006 kl) - see valid_ISBN_10 comments
##
## (10-nov-2006 kl) - validate isbn-10 or isbn-13
##                  - added checksum logic for both isbn-10 and isbn-13
##                  - now allows hyphens and whitespace
##
sub valid_ISBN {
    my($string) = @_;

    my $valid_isbn;

    my @isbns = split(/\s+/, $string);

    if ($valid_isbn = valid_ISBN_10($string)) {
        return $valid_isbn;
    }
    elsif ($valid_isbn = valid_ISBN_13($string)) {
        return $valid_isbn;
    }
    ##
    ## -now try splitting on whitespace to see if we can find a valid ISBN
    ## -stop recursion with check to number of possible ISBNs 
    ## 
    elsif (scalar(@isbns) > 1) {

	foreach my $poss_isbn (@isbns) {

            if ($valid_isbn = valid_ISBN($poss_isbn)) {

	        return $valid_isbn;
            }
        }
    }

    return undef;
}

##
## (08-dec-2006 kl) - extracts a valid ISBN if possible and returns it, otherwise returns undef
##                  - previously only returned 1/0 for valid/invalid
##
sub valid_ISBN_10 {
    my($isbn) = @_;

    $isbn = clean_ISBN($isbn);       

    unless (length($isbn) == 10) { return 0; }

    use Business::ISBN;
    my $obj = Business::ISBN->new($isbn);
    
    ##
    ## (30-dec-2006 kl) - include as invalid any returns for bad country and publisher codes as these depend 
    ##                    on a valid check sum and so cannot be separated from check sum errors
    ##                  - some online isbn checkers allow bad country and publisher codes so results of such a check
    ##                    can be different
    ##

    return ($obj->is_valid eq Business::ISBN::GOOD_ISBN) ? $isbn : undef;
}

##
## (08-dec-2006 kl) - see valid_ISBN_10 comments
##
sub valid_ISBN_13 {
    my ($isbn) = @_;

    $isbn = clean_ISBN($isbn);       
    unless (length($isbn) == 13) { return 0; }

    my $chksum = chop($isbn);

    if ($chksum =~ /[xX]/){ $chksum="10";}

    my $sum = &_gen_chksum_13($isbn);

    return ($chksum == $sum) ? ($isbn . $chksum) : undef;
}


##
## Return () if the ISBN is not valid.
## Return (<incoming>) for an attempt to change a 979 isbn-13 to a isbn-10.
## Return (<incoming>, <converted>) if there is a valid isbn that can be converted.
##
sub convert_ISBN {
    my ($isbn) = @_;

    use Business::ISBN;

    $isbn =~ s#[\055\s]##g;
    $isbn = lc($isbn);

    my @isbns;

    if ((length($isbn) == 10) && valid_ISBN_10($isbn)) {

        my $obj = Business::ISBN->new($isbn);
        my $isbn13 = $obj->as_isbn13($isbn);

        push @isbns, $isbn, $isbn13;
    }
    elsif ((length($isbn) == 13) && valid_ISBN_13($isbn)) {

        if ($isbn =~ m#^(978)(\d{9}[\dx])$#) {

            my $isbn10 = $2;

            my $obj = Business::ISBN->new($isbn10);            

            $obj->fix_checksum; 

            push @isbns, $isbn, $obj->isbn; 
        }
        else {

            push @isbns, $isbn;
        }        
    }

    return @isbns;
} 


##
## (08-dec-2006 kl) - changed to match valid_ISBN
##                  - now returns valid ISSN or undef instead of 1/0
##
sub valid_ISSN_s_ok {
        my($string) = @_;

        if ($string =~ m#^[0-9]{4,4}-[0-9]{3,3}[0-9|X|S]$#i) { return $string; }
	return undef;
}

##
##  (08-dec-2006 kl) - same as valid_ISSN_s_ok
##
sub valid_ISSN_no_hyphen_s_ok {
        my($string) = @_;

        if ($string =~ m#^[0-9]{4,4}[0-9]{3,3}[0-9|X|S]$#i) { return $string; }
        return undef;
}

sub normalize_marc8 {
    my($string) = @_;
    
    return(&normalize_latin1(&marc8_to_latin1($string)));
}

sub normalize_latin1 {
        my($string) = @_;

        my(@clean);

        ##
        ## -do now before naco strips apostrophes
        ##
        $string =~ s#\'L|\'l|\'D|\'d##g;
     
        use Text::Normalize::NACO;

        my $naco = Text::Normalize::NACO->new;
        $naco->case('lower');
        $string = $naco->normalize($string);

        foreach my $i (split(/[ \t]+/, $string)) {     ## -split on whitespace

	        unless (&all_digits($i) || (grep {$i eq $_} @STOP_WORDS)) {
	        #### unless (grep {$i eq $_} @STOP_WORDS) {
                        push(@clean, $i);
                } 
        }       
        return join(' ', @clean);
}


sub latin1_to_utf8 {
    my($string) = @_;

    use Unicode::String qw(latin1 utf8);    

    my $u = latin1($string);
    return $u->utf8;    
}

sub latin1_to_utf8_xml {
    my($string) = @_;

    ## A valid XML document cannot contain ASCII characters below hexadecimal value 0x20 -- with 
    ## the exception of horizontal tab (0x9), line feed (0xA), and carriage return (0xD).

    $string =~ s#[\000-\010,\013,\014,\016-\037]##g; 

    return (latin1_to_utf8($string));
}

sub is_single_word {
        my($string) = @_;

        my $tmp = &trim_beg_end($string);
        ($tmp !~ m#\s#);
}

sub aws {
	return 1 if (!defined($_[0]) || $_[0] eq '');
	$_[0] =~ /^\s*$/;
}

sub naws {
        (! aws($_[0])); 
}

sub trim_beg_end {
      my($string) = @_;

      $string =~ s#^\s+##g;
      $string =~ s#\s+$##g;
      return $string;
}


sub trim_end {
      my($string) = @_;

      $string =~ s#\s+$##g;
      return $string;
}


##
## -compress all strings of white space into one space
##
sub comp_ws {
    my($string) = @_;

    $string =~ s#\s+# #g;
    return $string;
}

sub quote {
    my($string) = @_;

    return "'" . $string . "'";
}

sub all_digits {
    my($string) = @_;

     return ($string =~ m#^\d+$#) ? $TRUE : $FALSE; 
}



sub rep_char {
    my($char, $n) = @_;

    my $string;
    foreach (1 .. $n)  { $string .= $char; }
    return $string; 
}



sub strip_html {
    my($string) = @_;

    $string =~ s#<[^<>]+>##g;
    return $string;
}

sub strip_subfield
{
    my($field) = @_;

    ## -get rid of subfields

    $field =~ s/^.. \x1F. *//g;
    $field =~ s/^..\x1F. *//g;
    $field =~ s/\x1F.//g;

    return $field;
}

sub strip_white_space {
    my($string) = @_;

    $string =~ s#\s+##g;
    return $string;
}


sub contains_white_space {
    my($string) = @_;

    return $string =~ m#\s+#;
}

sub no_white_space {
    my($string) = @_;

    return $string !~ m#\s+#;
}


sub add_trailing_period {
    my ($string) = @_;

    if (aws($string)) { return $string; }

    unless ($string =~ m#[\.\?\!]\s*$#)   { $string .= '.'; }      ## -if no trailing punctuation, add a period
    return $string;
}


sub marc8_to_latin1 {
	my ($line) = @_;
	
	$line =~ s/(.)/sprintf ("%%%X", ord($1))/eg;

	my @orphan_chars_combined = (
		'%1B%67%61%1B%73', '%1B%67%62%1B%73', '%1B%67%63%1B%73', 
		'%1B%62%30%1B%73', '%1B%62%31%1B%73', '%1B%62%32%1B%73',
		'%1B%62%33%1B%73', '%1B%62%34%1B%73', '%1B%62%35%1B%73', 
		'%1B%62%36%1B%73', '%1B%62%37%1B%73', '%1B%62%38%1B%73',
		'%1B%62%39%1B%73', '%1B%62%28%1B%73', '%1B%62%2B%1B%73', 
		'%1B%62%29%1B%73', '%1B%70%30%1B%73', '%1B%70%31%1B%73',
		'%1B%70%32%1B%73', '%1B%70%33%1B%73', '%1B%70%34%1B%73', 
		'%1B%70%35%1B%73', '%1B%70%36%1B%73', '%1B%70%37%1B%73',
		'%1B%70%38%1B%73', '%1B%70%39%1B%73', '%1B%70%28%1B%73', 
		'%1B%70%2D%1B%73', '%1B%70%2B%1B%73', '%1B%70%29%1B%73',
		'%E0%E6', '%E1%E3', '%E1%E5', '%E1%E6', '%E1%E8', 
		'%E2%A5', '%E2%B5', '%E2%E4', '%E2%E5', '%E2%E6', 
		'%E2%E8', '%E2%EA', '%E2%F0', '%E3%E0', '%E3%E1', 
		'%E3%E2', '%E3%F2', '%E4%E3', '%E4%E6', '%E5%E4',
		'%E5%E7', '%E5%E8', '%E5%A5', '%E5%B5', '%E5%F1', 
		'%E5%F2', '%E6%F0', '%E6%F2', '%E7%E2', '%E7%F2', 
		'%E8%E4', '%E8%E5', '%E9%E8'
	);
	
	my @orphan_chars_single = (
		'%A1','%A3','%A6','%A7','%A9','%AC','%AD','%AE',
		'%AF','%B0','%B1','%B3','%B6','%B7','%B8','%BB',
		'%BC','%BD','%BE','%BF','%C1','%C2','%C4','%E0',
		'%E5','%E6','%E7','%E9','%EB','%EC','%ED','%EE',
		'%EF','%F1','%F2','%F3','%F4','%F5','%F6','%F7',
		'%F8','%F9','%FA','%FB','%FC','%FD','%FE'
	);

	my %marc8_to_latin1_combined = (
		'%1B%70%32%1B%73' => 'B2', '%1B%70%33%1B%73' => 'B3',
		'%1B%70%31%1B%73' => 'B9', '%E1%41' => 'C0',
		'%E2%41' => 'C1', '%E3%41' => 'C2', '%E4%41' => 'C3', 
		'%E8%41' => 'C4', '%EA%41' => 'C5', '%E2%43' => '43',
		'%E3%43' => '43', '%F0%43' => 'C7', '%E1%45' => 'C8', 
		'%E2%45' => 'C9', '%E3%45' => 'CA', '%E4%45' => '45',
		'%E8%45' => 'CB', '%F0%45' => '45', '%E2%47' => '47', 
		'%E3%47' => '47', '%F0%47' => '47', '%E3%48' => '48',
		'%E8%48' => '48', '%F0%48' => '48', '%E1%49' => 'CC', 
		'%E2%49' => 'CD', '%E3%49' => 'CE', '%E4%49' => '49',
		'%E8%49' => 'CF', '%E3%4A' => '4A', '%E2%4B' => '4B', 
		'%E3%4B' => '4B', '%F0%4B' => '4B', '%F2%4B' => '4B',
        	'%E2%4C' => '4C', '%E3%4C' => '4C', '%F0%4C' => '4C', 
		'%E2%4D' => '4D', '%E1%4E' => '4E', '%E2%4E' => '4E',
		'%E4%4E' => 'D1', '%F0%4E' => '4E', '%E1%4F' => 'D2', 
		'%E2%4F' => 'D3', '%E3%4F' => 'D4', '%E4%4F' => 'D5',
		'%E8%4F' => 'D6', '%E2%50' => '50', '%E2%52' => '52', 
		'%E2%53' => '53', '%E3%53' => '53', '%F0%53' => '53',
		'%F0%54' => '54', '%E1%55' => 'D9', '%E2%55' => 'DA', 
		'%E3%55' => 'DB', '%E4%55' => '55', '%E8%55' => 'DC',
		'%EA%55' => '55', '%E4%56' => '56', '%E1%57' => '57', 
		'%E2%57' => '57', '%E3%57' => '57', '%E8%57' => '57',
		'%E8%58' => '58', '%E1%59' => '59', '%E2%59' => 'DD', 
		'%E3%59' => '59', '%E4%59' => '59', '%E8%59' => '59',
		'%E2%5A' => '5A', '%E3%5A' => '5A', '%E1%61' => 'E0', 
		'%E2%61' => 'E1', '%E3%61' => 'E2', '%E4%61' => 'E3',
		'%E8%61' => 'E4', '%EA%61' => 'E5', '%E2%63' => '63', 
		'%E3%63' => '63', '%F0%63' => 'E7', '%E1%65' => 'E8',
		'%E2%65' => 'E9', '%E3%65' => 'EA', '%E4%65' => '65', 
		'%E8%65' => 'EB', '%F0%65' => '65', '%E2%67' => '67',
		'%E3%67' => '67', '%F0%67' => '67', '%E3%68' => '68', 
		'%E8%68' => '68', '%F0%68' => '68', '%E1%69' => 'EC',
		'%E2%69' => 'ED', '%E3%69' => 'EE', '%E4%69' => '69', 
		'%E8%69' => 'EF', '%E3%6A' => '6A', '%E2%6B' => '6B',
        	'%E3%6B' => '6B', '%F0%6B' => '6B', '%F2%6B' => '6B', 
		'%E2%6C' => '6C', '%E3%6C' => '6C', '%F0%6C' => '6C',
        	'%E2%6D' => '6D', '%E1%6E' => '6E', '%E2%6E' => '6E', 
		'%E4%6E' => 'F1', '%F0%6E' => '6E', '%E1%6F' => 'F2',
		'%E2%6F' => 'F3', '%E3%6F' => 'F4', '%E4%6F' => 'F5', 
		'%E8%6F' => 'F6', '%E2%70' => '70', '%E2%72' => '72',
		'%E2%73' => '73', '%E3%73' => '73', '%F0%73' => '73', 
		'%E8%74' => '74', '%F0%74' => '74', '%E1%75' => 'F9',
		'%E2%75' => 'FA', '%E3%75' => 'FB', '%E4%75' => '75', 
		'%E8%75' => 'FC', '%EA%75' => '75', '%E4%76' => '76',
		'%E1%77' => '77', '%E2%77' => '77', '%E3%77' => '77', 
		'%E8%77' => '77', '%EA%77' => '77', '%E8%78' => '78',
		'%E1%79' => '79', '%E2%79' => 'FD', '%E3%79' => '79', 
		'%E4%79' => '79', '%E8%79' => '79', '%EA%79' => '79',
		'%E8%79' => 'FF', '%E2%7A' => '7A', '%E3%7A' => '7A', 
		'%E2%A2' => '4F', '%E1%AC' => '4F', '%E2%AC' => '4F',
		'%E4%AC' => '4F', '%E1%AD' => '55', '%E2%AD' => '55', 
		'%E4%AD' => '55', '%E2%B2' => '6F', '%E1%BC' => '6F',
		'%E2%BC' => '6F', '%E4%BC' => '6F', '%E1%BD' => '75', 
		'%E2%BD' => '75', '%E4%BD' => '75'
	);
	
	my %marc8_to_latin1_single = (
		'%A2'	=> 'D8', '%A4'	=> 'DE', '%A5'	=> 'C6', 
		'%A8'	=> 'B7', '%AA'	=> 'AE', '%AB'	=> 'B1',
		'%B2'	=> 'F8', '%B4'	=> 'FE', '%B5'	=> 'E6', 
		'%B9'	=> 'A3', '%BA'	=> 'F0', '%C0'	=> 'B0',
		'%C3'	=> 'A9', '%C5'	=> 'BF', '%C6'	=> 'A1'
	);
	
	foreach my $char1 (@orphan_chars_combined) {
		$line =~ s/$char1//g;
	}
    	
    	foreach my $marc_char1 (keys (%marc8_to_latin1_combined)) {
		$line =~ s/$marc_char1/pack("C", hex($marc8_to_latin1_combined{$marc_char1}))/eg;
	}
	
	foreach my $char2 (@orphan_chars_single) {
		$line =~ s/$char2//g;
	}
	
	foreach my $marc_char2 (keys (%marc8_to_latin1_single)) {
		$line =~ s/$marc_char2/pack("C", hex($marc8_to_latin1_single{$marc_char2}))/eg;
	}
	
	$line =~ s/%([A-F0-9][A-F0-9])/pack("C", hex($1))/eg;

	return($line);
}

sub remove_leading_article {
    my($string) = @_;

    $string =~ s#^\s+##g;
    $string =~ s#^(a\s+|an\s+|the\s+|le\s+|les\s+|la\s+|l'|d'|de\s+|du\s+|au\s+|der\s+|das\s+|die\s+|el\s+)##i;
    return $string;
}


sub keep_marc_subfield {
    my($string, $subfield_arr_ref) = @_;

    return  &filter_marc_subfield($string, $subfield_arr_ref, $KEEP_MARC_SUBFIELD);
}


##
## !!!! INCLUDE INDICATOR FIELDS or function does not work as expected !!!!
## 

sub filter_marc_subfield {
    my($string, $subfield_arr_ref, $type) = @_;         

    my($new_string, $subfield_tag, $subfield_value, $keep_subfield);
    my($leading_subfield_divider, $count);

    if ($string =~ m#^\037#) { 
        $leading_subfield_divider = $TRUE; 

        ##
        ## -first item will be nul if there is a leading \037 so remove and put back later
        ##

        $string =~ s#^\037##g;                 
    }
    else { 
        $leading_subfield_divider = $FALSE;   
    }

    foreach (split(/\037/, $string)) {       
 
        $count++;

        $keep_subfield = $FALSE;

        ## 
        ## -subfield value is NOT an indicator string 
        ##

        if ( (! (($count == 1)  && ($leading_subfield_divider == $FALSE))) &&  (m#^([a-z0-9])#)) {

	     $subfield_tag = $1;
	     $subfield_value = substr($_, 1);      ## -chop off subfield tag

	     if (($type eq $KEEP_MARC_SUBFIELD) && (grep {$subfield_tag eq $_} @{$subfield_arr_ref})) { 
                 $keep_subfield = $TRUE; 
             }
             if (($type eq $REMOVE_MARC_SUBFIELD) && (! (grep {$subfield_tag eq $_} @{$subfield_arr_ref}))) { 
                 $keep_subfield = $TRUE; 
             }                     									    
        }
	else  {                               ## -indicators or incorrect marc coding ??? (ie. subfield tag ain't [a-z0-9])
	     $keep_subfield = $TRUE;

             if (m#^([A-Z])#) { error ("$0: invalid subfield tag - $1 (filter_marc_subfield)"); }
	}

        ##
        ## !!! use double quotes for the \037 !!!
        ##

	if ($keep_subfield) {

	     if (($new_string ne '') || ($leading_subfield_divider && ($count == 1)))  { $new_string .= "\037"; }    
	     $new_string .= $_;
	}
    }
    return $new_string;
}

##
## -required for BRS databases made Z39.50 accessible using BRS Zserver software
##

sub strip_extra_leading_subfield {
    my($string) = @_;

    $string =~ s#^\s*\037a ##g;

    return $string;
}


sub rm_arr_dup_str {
    my($arr_ref) = @_;

    my(%found);
    my(@new_arr);
    my($elem);
   
    foreach $elem (@{$arr_ref}) {
        if (! $found{$elem}) {
            push(@new_arr, $elem);
            $found{$elem} = 1;
	}
    }
    @{$arr_ref} = @new_arr;
    return;
}


sub put_query_fields {
    my ($ref) = @_;

    unless (ref($ref) eq 'HASH') {
        debug location, ' -- ', 'expected parameter to be a reference to a hash';
        return '';
    }

    my @arr;
    while (my($field, $value) = each %{$ref}) {
        push(@arr, uri_encode_string($field) . '=' . uri_encode_string($value));
    }

    return join('&', @arr);
}


##
## -same as above, but $ref is for an array of field/value pairs
## -allows there to be multiple occurrences of the same field name
##
sub put_query_fields_from_array {
    my ($ref) = @_;

    unless (ref($ref) eq 'ARRAY') {
        debug location, ' -- ', 'expected parameter to be a reference to an array';
        return '';
    }

    my @arr;
    foreach my $pair_ref (@{$ref}) {
        my($field, $value) = @{$pair_ref};
        push(@arr, uri_encode_string($field) . '=' . uri_encode_string($value));
    }
    return join('&', @arr);
}

##
## -using this method instead of calling CGI::escape so logic matches previous code and makes testing easier
##
sub uri_encode_string {
    my($string) = @_;
    
    $string =~ s# #+#g;
    $string =~ s#([^0-9a-zA-Z\+])#sprintf("%%%02x", ord($1))#eg;    
    return $string;
}


sub valid_email {
    my($string) = @_;

    my($tmpstr, $valid_email);
          
    ## overkill but can't hurt .....

    $tmpstr = &rm_shell_char($string);

    if ($tmpstr ne $string) { return ''; }

    if ($string =~ m#^([\w\-.]+\@[\w\-.]+)$#)  { 
        $valid_email = $1;
    }

    if ($valid_email eq $string) {  return $valid_email; }
    else                         {  return ''; }
}

sub rm_shell_char {
    my($string) = @_;

     ##
     ## get rid of shell meta chars:   &;`'\"|*?~<>^()[]{}$\n\r
     ##

     $string =~ s#[\012\015\042\044\046\047\050\051\052\073\074]##g;      
     $string =~ s#[\076\077\133\134\135\136\140\173\174\175\176]##g;      

    return $string;
}



sub _gen_chksum_13{
    my ($isbn) = @_;

    my $tb;

    for (my $i; $i<=12; $i++){
        my $tc = chop($isbn);
        my $ta = ($tc*3);
        my $tci = chop($isbn);
        $tb = $tb + $ta + $tci;
    }
    my $tg=($tb/10);

    my $tint=int($tg); 
    if ($tint==$tg) { return 0; }

    my $ts = chop($tg);
    my $tsum = (10-$ts);

    return($tsum);
}



1;

__END__

=head1 NAME

GODOT::String - Collection of various string related routines for use in GODOT

=head1 SYNOPSIS
	$clean_ISSN = GODOT::String::clean_ISSN("5143-525X");
	$clean_ISBN = GODOT::String::clean_ISBN("9-3143-3525X");

=head1 METHODS

=item B<clean_ISSN($ISSN, $dash)>
	Returns the cleaned up ISSN with or without dashes if it was valid
	(\d{7}[\dXx]).  Returns undef if the ISSN was not valid.  Does not
	check for validity based on checksums, country codes, etc.

=item B<clean_ISBN($ISBN)>
	Returns the cleaned up ISBN without dashes (this might change) if it
	was valid (\d{9}[\dXx]).  Returns undef if the ISBN was not valid.
	Does not check for validity based on checksums, country codes, etc.

=item B<aws($string)>
	Return 1 (true) if $string is either not defined, is empty, or
	consists of all white space.

=item B<aws($string)>
	Return 1 (true) if $string is either not defined, is empty, or
	consists of all white space.

=item B<naws($string)>
        The opposite of B<aws($string)>.

=item B<trim_beg_end($string)>
        Returns a string without trailing or leading white space.

=item B<comp_ws($string)>
        Compresses all instances of white space to a single blank.


=head1 AUTHORS / ACKNOWLEDGMENTS

Written by Todd Holbrook, based on existing GODOT code by Kristina Long and
others over the years at SFU.

=cut



