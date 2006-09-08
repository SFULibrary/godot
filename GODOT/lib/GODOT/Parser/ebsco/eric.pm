package GODOT::Parser::ebsco::eric;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::String;
use GODOT::Parser::ebsco;
use CGI qw/unescapeHTML/;

@ISA = "GODOT::Parser::ebsco";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::ebsco::eric") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation); 


        if ($citation->is_tech()) {
	    $citation->parsed('AUT', $citation->pre('CA'));

	    $citation->parsed('TITLE', $citation->pre('SO'));

            if ($citation->parsed('TITLE') eq '') { $citation->parsed('TITLE', $citation->pre('TI')); }


	    $citation->parsed('YYYYMMDD',  $citation->pre('MON'));

	    $citation->parsed('ISBN',      $citation->pre('ISBN')) if defined($citation->pre('ISBN'));

	    #### $citation->parsed('FTREC', $citation->pre('FT'));

        } else {
	    $self->SUPER::parse_citation($citation);
        }

        ##
        ## get rid of any pseudo ISSN, eg. 'ERIC-RIE0'
        ##        
        if ($citation->pre('ISSN') !~ /(\d{4}-?\d{3}[\dxX])/) {
	    $citation->parsed('ISSN', '');
        }

        if (naws($citation->pre('SID')))  {
	    $citation->parsed('SYSID', $citation->pre('SID'));
	    $citation->parsed('ERIC_NO', $citation->pre('SID'));
        }
        else {
	    $citation->parsed('SYSID', $citation->pre('AN'));
	    $citation->parsed('ERIC_NO', $citation->pre('AN'));
        }

        ## 
        ## (20-may-2003 kl) - ERIC Availability is not currently passed by the Ebscohost interface.
        ##
        ##                  - Only 8.5% of the documents are not available from ERIC, so we make the
        ##                    assumption that all are available (and force the availability level to '1')
        ##                    as this will cause the least errors 
        ##
        ## ERIC Availability:
        ##
        ## 1: available in paper copy and microfiche
        ## 2: available in microfiche only
        ## 3: not available from ERIC 
        ##

        my $availability_level = 1;

        if ($citation->parsed('ERIC_NO') =~ m#^ed|^ED#) {
	    $citation->parsed('ERIC_AV', $availability_level);
	}

        return $citation;
}


sub get_req_type {
    my ($self, $citation, $pubtype) = @_;
    debug("get_req_type() in GODOT::Parser::ebsco::eric") if $GODOT::Config::TRACE_CALLS;


    my $reqtype = $self->SUPER::get_req_type($citation, $pubtype);

    if (($citation->pre('SID') =~ m#^ed|^ED#) || ($citation->pre('AN') =~ m#^ed|^ED#))  {

        ##
        ## '^' is XOR
        ##

        if (($citation->pre('TI') eq '')  ^  ($citation->pre('SO') eq ''))  {
	    $reqtype = $GODOT::Constants::TECH_TYPE;
        }
    }

    return $reqtype;
}


1;

__END__

