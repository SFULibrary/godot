## GODOT::Normalize
##
## Copyright (c) 2010, Kristina Long, Simon Fraser University
##
## This file, GODOT::Normalize, is for text normalization related routines that you may need to override with a local copy for non-english languages.
## Use GODOT::String for text normalization related routines that you are unlikely to need to override.
##
## IMPORTANT:  Do not print utf8 strings in debug statements as they may cause confusion depending on your editor.  Instead use
##             Data::Dump::dump to print as escaped ascii.  Trust me.
##
package GODOT::Normalize;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(normalize_for_catalogue_match
             normalize_for_catalogue_match_leader);
use strict;

use Data::Dumper;
use Data::Dump;
use MARC::Charset qw(marc8_to_utf8);
use Encode;

use GODOT::Debug;
use GODOT::String;
use GODOT::Encode;

my $TRUE  = 1;
my $FALSE = 0;

my $BLANK = ' ';

##
## (25-mar-2010 kl) -- used by GODOT::CatalogueHoldings::Record::Z3950::good_match
##
## Input and output are strings in perl internal format.
##
sub normalize_for_catalogue_match {
    my($string) = @_;

    my $normalized = &normalize($string);
    #### debug location_plus, Data::Dump::dump($normalized);
    return $normalized;

    
}

##
## (22-oct-2010 kl) -- no need for this logic -- by the time we get around to using the data, it has already been decoded
##
## (25-mar-2010 kl) -- leader offset 9 in marc21 has two values so normalize accordingly
##
##                     <space> - MARC-8
##                           a - UCS/Unicode
##
#### sub normalize_for_catalogue_match_leader {
####    my($string, $leader) = @_;
####
####    #### report_location;
####
####    my $leader_09 = substr($leader, 9, 1);
####
####    debug "leader-09 value is invalid ($leader_09)" unless (grep { $leader_09 eq $_ } ($BLANK, 'a'));
####
####    if ($leader_09 eq $BLANK) {
####        $string = marc8_to_utf8($string, 'ignore-errors');
####    }
####    return &normalize($string);
#### }
####
####

1;

__END__

