package GODOT::local::CatalogueHoldings::BibCirc::AEU;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##
use GODOT::CatalogueHoldings::BibCirc::Z3950::SIRSI;
@ISA = qw(GODOT::CatalogueHoldings::BibCirc::Z3950::SIRSI);

use GODOT::String;
use GODOT::Object;
use GODOT::Debug;
use GODOT::CatalogueHoldings::BibCirc;
use CGI qw(:escape);

use strict;

sub holdings_from_cat_rec {
    my($self, $record, $marc) = @_;

    my @fields = $marc->field('9XX');
    return $FALSE unless scalar @fields;

    $self->_holdings_found_if_holdings;

    foreach my $field (@fields) {
        my $string;
        if ($field->tag eq '950') { $string = $self->_keep_subfields_clean_up_marc($field, ['a']); } 
        $self->holdings($self->source, $string) unless aws($string);
    }

    return $TRUE;
}

sub _url_text_subfield { return '3'; }

sub _label_clean_up {
    my($self, $label) = @_;

    if ($label =~ m#^\s*\$<.+>\s*$#) { $label = ''; }
    return $label;
}

sub _location_to_site_map {

    my %map = ( 
        'AGINTERNET'   => 'NEOS-OTHER',
        'AGL_CAP'      => 'NEOS-OTHER',
        'AGL_COM'      => 'NEOS-OTHER',
        'AGL_GWL'      => 'NEOS-OTHER',
        'AGL_LB'       => 'NEOS-OTHER',
        'AGL_MNC'      => 'NEOS-OTHER',
        'AGL_NCC'      => 'NEOS-OTHER',
        'AGL_NPP'      => 'NEOS-OTHER',
        'AGL_SSP'      => 'NEOS-OTHER',
        'AGL_TPN'      => 'NEOS-OTHER',
        'ARC_CALG'     => 'NEOS-OTHER',
        'ARC_C-FER'    => 'NEOS-OTHER',
        'ARC_DEVON'    => 'NEOS-OTHER',
        'ARC_MW'       => 'NEOS-OTHER',
        'ARC_VEG'      => 'NEOS-OTHER',
        'AUGUSTANA'    => 'NEOS-OTHER',
        'CARITAS_GN'   => 'NEOS-OTHER', 
        'CARITAS_MH'   => 'NEOS-OTHER',
        'CH_RAH'       => 'NEOS-OTHER',
        'CHGLENROSE'   => 'NEOS-OTHER',
        'CONCORDIA'    => 'AEC',
        'CROSS'        => 'NEOS-OTHER',
        'CUC'          => 'NEOS-OTHER',
        'EUB_AGS'      => 'NEOS-OTHER',
        'FAIRVIEW'     => 'NEOS-OTHER',
        'FAIRVIEWNR'   => 'NEOS-OTHER',
        'FAIRVIEWPR'   => 'NEOS-OTHER',
        'GPRC'         => 'NEOS-OTHER',
        'GR_MACEWAN'   => 'NEOS-OTHER',
        'JUSTICE_CA'   => 'NEOS-OTHER',
        'KINGS'        => 'NEOS-OTHER',
        'NEWMAN'       => 'NEOS-OTHER',
        'OLDS'         => 'NEOS-OTHER',
        'OLDS_OCCI'    => 'NEOS-OTHER',
        'RED_DEER_C'   => 'ARDC',
        'TAYLOR'       => 'NEOS-OTHER',
        'UAARCHIVES'   => 'AEU', 
        'UABARD'       => 'AEU',
        'UABSJ'        => 'AEU',
        'UABUSINESS'   => 'AEU',
        'UAEDUC'       => 'AEU',
        'UAHLTHSC'     => 'AEU',
        'UAHSS'        => 'AEU', 
        'UAINTERNET'   => 'AEU',
        'UALAW'        => 'AEU', 
        'UAMATH'       => 'AEU',
        'UAPHYSC'      => 'AEU',
        'UASCITECH'    => 'AEU', 
        'UASJC'        => 'AEU',
        'UASPCOLL'     => 'AEU',
        'UATECHSERV'   => 'AEU'               
    );

    return %map;
}


sub _call_number_field {
    return '090';
}

sub _call_number_subfield {
    return qw(a);

}



1;
