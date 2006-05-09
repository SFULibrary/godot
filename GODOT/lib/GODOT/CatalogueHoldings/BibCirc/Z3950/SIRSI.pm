package GODOT::CatalogueHoldings::BibCirc::Z3950::SIRSI;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##
use GODOT::CatalogueHoldings::BibCirc;
@ISA = qw(GODOT::CatalogueHoldings::BibCirc);


use Data::Dumper;
use GODOT::String;
use GODOT::Object;
use GODOT::Debug;
use CGI qw(:escape :escapeHTML);

use strict;

my @FIELDS = qw(sirsi_holdings);
 
sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}

sub sirsi_holdings {
    my($self, @rest) = @_;

    return $self->_holdings('sirsi_holdings', @rest);
}


sub _call_number_field {
    return '090';
}

sub _call_number_subfield {
    return qw(a b);

}

sub holdings_from_cat_rec {
    my($self, $record, $marc) = @_;

    my @fields = $marc->field('927');
    return $FALSE unless scalar @fields;

    #### debug "......................................";
    #### debug $self->source;
    #### debug Dumper(@fields);
    #### debug "......................................";
 
    $self->holdings_found($TRUE);

    my(@value_927_arr, @value_927_sirsi_fmt_arr);

    foreach my $field (@fields) {

        ##
        ## -Sirsi MFHL information 
        ##
        ## -is this a header record? -- ie. only has 927-a 
        ##
                   
	my $value_927_a = $self->_keep_subfields_clean_up_marc($field, ['a']);

        if ($value_927_a ne '') {

            my($value_927, $value_927_sirsi_fmt);
                       
            $value_927_sirsi_fmt = '<TR><TD NOWRAP VALIGN="TOP" ALIGN="right">';

            if ($self->_display_927_a) {
                $value_927_sirsi_fmt .= escapeHTML($value_927_a);
                $value_927           .= $value_927_a;
            }

	    $value_927_sirsi_fmt .= '</TD></TR>';

            push(@value_927_arr, [$value_927_a, $value_927]);
	    push(@value_927_sirsi_fmt_arr, [$value_927_a, $value_927_sirsi_fmt]);  
        }
        else {                      
            my $label       = $self->_keep_subfields_clean_up_marc($field, ['b']); 
            my $label_value = $self->_keep_subfields_clean_up_marc($field, ['c']);   
                                                                    
            $label = $self->_label_clean_up($label);

            my $tmp = (naws($label)) ? "$label: $label_value" : $label_value;            

            my($value_927, $value_927_sirsi_fmt);

            ($value_927_a, $value_927) = @{pop(@value_927_arr)};
            $value_927 .= "; " unless aws($value_927);
            $value_927 .= "$tmp";
            push(@value_927_arr, [$value_927_a, $value_927]);

            $label_value = $self->_label_value_clean_up($label_value);
            
            ##
            ## -save data for $BIB_CIRC_SIRSI_HOLDINGS
            ##
            $tmp = '<TR><TD></TD><TD NOWRAP VALIGN="TOP" ALIGN="right">' . escapeHTML($label) . 
                   ((&GODOT::String::naws($label)) ? ':' : '') . 
                   '</TD>' .
                   '<TD VALIGN="BOTTOM"><B>' . escapeHTML($label_value) . '</B></TD></TR>'; 
                        
            ($value_927_a, $value_927_sirsi_fmt) = @{pop(@value_927_sirsi_fmt_arr)};
            $value_927_sirsi_fmt .= $tmp;
            push(@value_927_sirsi_fmt_arr, [$value_927_a, $value_927_sirsi_fmt]);                     
        }
    }

    ##
    ## -exception logic to add holdings 
    ##

    my ($value_927_a, $value_927) = $self->_add_holdings([@value_927_arr]);
    if ($value_927 ne '') { push(@value_927_arr, [$value_927_a, $value_927]);  }  


    foreach my $value_927_ref (@value_927_arr) {

        my($value_927_a, $value_927) = @{$value_927_ref};
        $value_927 = $self->_label_value_clean_up($value_927);

        $self->holdings($value_927_a, $value_927);
    }

    foreach my $value_927_sirsi_fmt_ref (@value_927_sirsi_fmt_arr) {

        my($value_927_a, $value_927_sirsi_fmt) = @{$value_927_sirsi_fmt_ref};    
        $self->sirsi_holdings($value_927_a, "<TABLE>$value_927_sirsi_fmt</TABLE>");
    }

    return $TRUE;
}


sub circulation_from_cat_rec {
    my($self, $record, $marc) = @_;

    my @fields = $marc->field('926');
    return $FALSE unless scalar @fields;

    my $library;  

    my @reverse = reverse @fields;      ## -use copy so don't change record_hash contents

    foreach my $field (@reverse) {
    
        my $library; 
        my $location;
        my $call;    
        my $status;  
        my $copy;    
        my $material;

        foreach my $subfield  ($field->subfields) {
 
            my($code, $data) = @{$subfield};

            if    (($code eq 'a')  && ($self->_display_926_a)) { $library  = $data; }
            elsif ($code eq 'b')                               { $location = $data; } 
            elsif ($code eq 'c')                               { $call     = $data; } 
            elsif ($code eq 'd')                               { $material = $data; } 
            elsif ($code eq 'e')                               { $status   = $data; }    
            elsif ($code eq 'f')                               { $copy     = trim_beg_end($data); }    
        }

        $self->circulation((($location) ? "$library $location" : $library), 
                           $call . ' ' . (($copy ne '1') ? "c. $copy " : ''),
                           (($status) ? "DUE $status" : 'AVAILABLE'));        
    }
           
    return $TRUE;
}

sub adjust_html_incl_long {
    my($self, $html_incl_hash_ref) = @_;

    delete ${$html_incl_hash_ref}{'bib_circ_holdings'};
    ${$html_incl_hash_ref}{'bib_circ_sirsi_holdings'} = '';  
}

sub divide {
    my($self, $div) = @_;

    my $do_not_include = [qw(holdings sirsi_holdings circulation)];

    my(%hold_div_hash, %sirsi_hold_div_hash, %circ_div_hash);

    $self->divide_circulation(\%circ_div_hash);
    $self->divide_holdings(\%hold_div_hash, \%sirsi_hold_div_hash);

    ##
    ## -set $div to point to the GODOT::CatalogueHoldings::BibCirc object passed to function or, 
    ##  if the original GODOT::CatalogueHoldings::BibCirc object was split up, set it to point to the copies.
    ##

    unless (%hold_div_hash || %sirsi_hold_div_hash || %circ_div_hash) {
        ${$div}{$self->site} = $self;
        return;      
    }

    ##
    ## -original GODOT::CatalogueHoldings::BibCirc was split up, so point to the copies
    ##   

    foreach my $site (keys %hold_div_hash) {       

        unless (defined ${$div}{$site}) {
	    ${$div}{$site} = $self->duplicate($do_not_include);
            ${$div}{$site}->site($site);
        }

        foreach my $holdings (@{$hold_div_hash{$site}})  { 
            ${$div}{$site}->holdings($holdings->site, $holdings->holdings); 
        }
    }

    foreach my $site (keys %sirsi_hold_div_hash) {       

        unless (defined ${$div}{$site}) {
            ${$div}{$site} = $self->duplicate($do_not_include);
            ${$div}{$site}->site($site);
        }

        foreach my $holdings (@{$sirsi_hold_div_hash{$site}})  {          
          ${$div}{$site}->sirsi_holdings($holdings->site, $holdings->holdings); 
        }
    }

    foreach my $site (keys %circ_div_hash) {       

	unless (defined ${$div}{$site}) {
	    ${$div}{$site} = $self->duplicate($do_not_include);
            ${$div}{$site}->site($site);
        }

        foreach my $circulation (@{$circ_div_hash{$site}}) {
            ${$div}{$site}->circulation($circulation->item_location, $circulation->call_number, $circulation->status);
        }
    }
}

sub divide_holdings {
    my($self, $div, $sirsi_div) = @_;

    my($user);
    
    foreach my $field (qw(holdings sirsi_holdings)) {

        no strict 'refs';
        my @holdings = @{$self->{$field}};
	use strict;

        foreach my $ref (@holdings) {

            my $location = $ref->site;
            
            my $site = $self->location_to_site(uc(trim_beg_end($location)));    
            $ref->site($site);
     
            if ($field eq 'holdings')       { push(@{${$div}{$site}},       $ref); }  ## push on ref, not copy     
   	    if ($field eq 'sirsi_holdings') { push(@{${$sirsi_div}{$site}}, $ref); }  
        }
    }

    #### use Data::Dumper;
    #### debug "////////////////////////////////////////////////////////////////////\n",
    ####      Dumper($div),
    ####      "////////////////////////////////////////////////////////////////////\n",
    ####      Dumper($sirsi_div),
    ####      "////////////////////////////////////////////////////////////////////\n",
}


sub converted {
    my($self, $system_type) = @_;


    #### debug "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n",
    ####      $self->dump,
    ####      "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";

    my %bib_circ_hash = $self->SUPER::converted($system_type);     

    foreach my $holdings ($self->sirsi_holdings) {
        push(@{$bib_circ_hash{'bib_circ_sirsi_holdings'}}, [ $holdings->site, $holdings->holdings ]); 
    }

    #### use Data::Dumper;
    #### debug "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||\n",
    ####      Dumper(\%bib_circ_hash),
    ####      "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||\n"; 

    return %bib_circ_hash;
}

##
## (18-jan-2003 kl) - added to handle 927-b values like '$<hld_usmarc_852_v1>' (eg. for OPET)
##

sub _label_clean_up {
    my($self, $label) = @_;
    return $label;
}

sub _label_value_clean_up {
    my($self, $value) = @_;
    return $value;
}

sub _add_holdings {
    return ('', '');
}

sub _display_926_a { return $TRUE; }

sub _display_927_a { return $TRUE; }


##----------------------------------------------------------------------------------------------


