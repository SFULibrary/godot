package GODOT::CatalogueHoldings::BibCirc::Z3950::ALEPH;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use GODOT::CatalogueHoldings::BibCirc;
@ISA = qw(GODOT::CatalogueHoldings::BibCirc);

use Data::Dumper;

use GODOT::String;
use GODOT::Object;
use GODOT::Debug;
use CGI qw(:escape);

use strict;

##
## return a list of GODOT::CatalogueHoldings::URL objects
##
sub cat_url {
    my($self, $host) = @_;

    my $url_root = "http://$host" . ((naws($self->cat_url_port)) ? ':' : '') . $self->cat_url_port . '/F?func=find-b&find_code=';
    my $url;

    unless (aws($host)) {

        if    (naws($self->isbn))   { 
            $url = $self->cat_url_isbn_index . '&request=' . escape($self->isbn);
        }
        elsif (naws($self->issn))   { 
            $url = $self->cat_url_issn_index . '&request=' . escape($self->issn);
        }
        elsif (naws($self->title))  { 
            $url = $self->cat_url_title_index . '&request=' . escape(remove_leading_article($self->title)) . '&adjacent=Y';
        }

        $url = ($url_root . $url) if naws($url);        
    }

    return $self->_url('cat_url', $url, '');
}

##
## -holdings are extracted in 'circulation_from_cat_rec' below
##
sub holdings_from_cat_rec {
    my($self, $record, $marc) = @_;

    return $FALSE;
}


sub circulation_from_cat_rec {
    my($self, $record, $marc) = @_;

    ##
    ## -make sure we are getting what we expect, ie. a reference to a Net::Z3950::Record::OPAC object
    ## -when Okanagan (and perhaps others) have a problem we are getting back a reference to a
    ##  Net::Z3950::Record::SUTRS object
    ##

    return '' unless ref($record->record) eq 'Net::Z3950::Record::OPAC';

    ##
    ## -circ/item data
    ##

    my $circ_item = $record->record->{'holdingsData'};

    foreach my $j (1 .. $record->record->{'num_holdingsData'}) {

        my $hr = $circ_item->[$j-1];

        my($location, $shelving_location, $hacd_enum_and_chron, $call, $public_note);

        foreach my $label qw(shelvingLocation localLocation enumAndChron publicNote callNumber) {
            my $value = &_value($hr->{$label});
            next if aws($value);
   
            if ($label eq 'localLocation')   { 
                $location = $value; 
            }
            elsif ($label eq 'shelvingLocation')   { 
                $shelving_location = $value; 
            }
            elsif ($label eq 'enumAndChron') { 
                $hacd_enum_and_chron = $self->_hacd_enum_and_chron_cleanup($value); 
                $hacd_enum_and_chron =~ s#\037[a-z1-9]##g;                       
                $hacd_enum_and_chron =~ s#\036$##g;
            }
            elsif ($label eq 'publicNote')   { 
                $public_note = $value; 
            }
            elsif ($label eq 'callNumber') {
                $call = $value;
	    }
        }

        my @volumes;

        my $vols = $hr->{'volumes'};
        my $n = scalar @{$vols};
        foreach my $i (1 .. $n) {
            my $vol = $vols->[$i-1];
            my($enumeration, $chronology);
            foreach my $label qw(enumeration chronology) {
                my $value = &_value($vol->{$label});  
                next if aws($value);
                if ($label eq 'enumeration')   { $enumeration = $value; }
                elsif ($label eq 'chronology') { $chronology  = $value; }
            }

            $chronology =~ s#^\s*\(##g;
            $chronology =~ s#\)\s*$##g;

            push @volumes, (($enumeration) ? "$enumeration " : '') . (($chronology) ? "($chronology)" : '');
        }

        #### my $vol_str = join('; ', @volumes);

	my $vol_str = $self->_opac_volume_text if scalar(@volumes); 

        my $hacd_text = $self->_opac_holdings_and_circ_data_text;
        my $skip_hacd_enum_and_chron = $self->_skip_hacd_enum_and_chron;

        my $holdings_stmt = 
            $self->_call_number_for_statement($call) .
            (($location ne '') ? "Location: $location; " : '')  . 
            (((! $skip_hacd_enum_and_chron) && ($hacd_enum_and_chron ne '')) ? ($hacd_text . "$hacd_enum_and_chron; ") : '') .
            $vol_str . 
            ((naws($public_note)) ? $public_note : '');

            
        $holdings_stmt =~ s#;\s*$##;                                  ## -remove trailing semicolon, if there is one              

        ##
        ## (08-sep-2004 kl) - changed so that multi branch sites would work (eg. UBC)
        ##
        $self->holdings($self->_site($location), $holdings_stmt);

        my $cd = $hr->{'circulationData'};
        $n = scalar @{$cd};
        foreach my $i (1 .. $n) {
            my $cr = $cd->[$i-1];
            my($available_now, $availability_date, $status, $enum_and_chron);

            ##
            ## (17-mar-2005 kl) - include both correct and typo version of 'availabilityDate' as standard has a typo in it 
            ##
            foreach my $label qw(availableNow availablityDate availabilityDate enumAndChron) {
                my $value = &_value($cr->{$label});
                next if aws($value);

                if (($label eq 'availableNow') && ($value eq '1')) {
                    $available_now = $TRUE;
                }
		elsif (grep {$label eq $_} qw(availablityDate availabilityDate)) {
		    $availability_date = $value;
		}
		elsif ($label eq 'enumAndChron') {
                    $enum_and_chron = $value;
		}
            }

            $status = ($available_now) ? $availability_date : "DUE $availability_date";

            my $is_call = naws($call);
            my $is_eacs = naws($enum_and_chron);

            my $call_str  = ($is_call) ?  "$call" : '';
            $call_str    .= ($is_call && $is_eacs) ? "; " : ''; 
            $call_str    .= ($is_eacs) ? $enum_and_chron : '';
 
            $self->circulation($shelving_location, $call_str, $status); 
        }
    }
}

sub _value {
    my($value) = @_;

    return ((defined $value) ? $value : '');
}

sub _skip_hacd_enum_and_chron { return $FALSE; }

sub _call_number_for_statement { 
    my($self, $call) = @_;
    
    return '';
}

sub _site {
    my($self, $location) = @_;

    return $self->site;
}

sub _opac_volume_text {
    my($self) = @_;
    return '';
}

sub _opac_holdings_and_circ_data_text {
    my($self) = @_;
    return '';
}

sub _hacd_enum_and_chron_cleanup {
    my($self, $string) = @_;

    ##
    ## -strip off leading 0
    ##
    $string =~ s#^\s*0\s*##;
    return $string;
}


sub cat_url_port {
    my($self) = @_;
    return '';
}

sub cat_url_isbn_index {
    my($self) = @_;
    return 'ISBN';
}

sub cat_url_issn_index {
    my($self) = @_;
    return 'ISSN';
}

sub cat_url_title_index {
    my($self) = @_;
    return 'WTI';
}

