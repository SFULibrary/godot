package GODOT::local::CatalogueHoldings::BibCirc::MWUC;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##
use GODOT::CatalogueHoldings::BibCirc::Z3950::III;
@ISA = qw(GODOT::CatalogueHoldings::BibCirc::Z3950::III);

use GODOT::String;
use GODOT::Object;
use GODOT::CatalogueHoldings::BibCirc;
use CGI qw(:escape);

use strict;

sub holdings_from_cat_rec {
    my($self, $record, $marc) = @_;

    my $key = ($self->citation->is_journal) ? '850' : '853';

    my @fields = $marc->field($key);
    return $FALSE unless scalar @fields;

    $self->_holdings_found_if_holdings;

    foreach my $field (@fields) {
        my $string = $self->_clean_up_marc($field);
        $self->holdings($self->source, $string) unless aws($string);
    }

    return $TRUE;
}

sub _call_number_field {
    return '090';
}

sub _call_number_subfield {
    return qw(a b);

}



1;

