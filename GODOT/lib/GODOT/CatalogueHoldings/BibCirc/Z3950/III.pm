package GODOT::CatalogueHoldings::BibCirc::Z3950::III;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use GODOT::CatalogueHoldings::BibCirc;
@ISA = qw(GODOT::CatalogueHoldings::BibCirc);

use GODOT::String;
use GODOT::Object;
use GODOT::Debug;
use CGI qw(:escape);

use strict;

sub cat_url {
    my($self, $host) = @_;

    my $url;

    if (naws($host)) {

        if    (naws($self->isbn))   { $url =  "http://$host/search/i?" . escape($self->isbn);  }
        elsif (naws($self->issn))   { $url =  "http://$host/search/i?" . escape($self->issn);  }
        elsif (naws($self->title))  { $url =  "http://$host/search/t?" . escape($self->title); }        
    }

    return $self->_url('cat_url', $url, '');
}

sub holdings_from_cat_rec {
    my($self, $record, $marc) = @_;
    return $FALSE;
}

sub circulation_from_cat_rec {
    my($self, $record, $marc) = @_;

    return $FALSE unless defined $record->record;
    return $FALSE unless defined $record->record->{'holdingsData'};

    my $circ_item = $record->record->{'holdingsData'};

    foreach my $j (1 .. $record->record->{'num_holdingsData'}) {

        my $hr = $circ_item->[$j-1];

        my($location, $call, $status);

        foreach my $label qw(localLocation callNumber publicNote) {            
            my $value = $hr->{$label};
            $value = (defined $value) ? trim_beg_end($value) : '';

            if    ($label eq 'localLocation')  { $location = $value; }
            elsif ($label eq 'callNumber')     { $call     = $value; } 
            elsif ($label eq 'publicNote')     { $status   = $value; }    
        }

	$self->circulation($location, $call, $status);
    }

    return $TRUE;
}

1;

