package GODOT::Parser::psyclit;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::psyclit") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##
    
        if ($citation->is_journal())  {

            ##
            ## ISSNs missing 5th char '-'
            ##
            if (length($citation->parsed('ISSN')) == 8) {
                    my $issn = substr($citation->parsed('ISSN'),0,4) . '-' .  substr($citation->parsed('ISSN'),4);
                    $citation->parsed('ISSN', $issn);
            }
         
            ##
            ## Journal-of-Economic-Psychology; 1989 Nov Vol 10(3) 343-362;
            ## Addictive-Behaviors; 1990 Vol 15(1) 89-93
            ##
            if ($source=~m#([\w-]+)\;\s*(\d+)\s*\w*\s+Vol\s+(\d+)\((\d+)\)\s*(\d+\-\d+)#) {
                $citation->parsed('ISS', $4);      
                $citation->parsed('VOL', $3);
                $citation->parsed('PGS', $5);
                my $title = $1;
                $title =~ s/-/ /g;
                $citation->parsed('TITLE', $title);
            }

            ##
            ## American-Journal-of-Drug-and-Alcohol-Abuse. 1997 Feb; Vol 23(1): 143-165
            ##
            elsif ($source=~m#([\w-]+)\.\s*(\d+)\s*[\w-]*\;\s+Vol\s+(\d+)\(([\d\w\s-]+)\):\s*([\d-]+)#)
            {
                $citation->parsed('ISS', $4);      
                $citation->parsed('VOL', $3);
                $citation->parsed('PGS', $5);
                my $title = $1;
                $title =~ s/-/ /g;
                $citation->parsed('TITLE', $title);
            }

            ##
            ##  EDRA:-Environmental-Design-Research-Association. 1979; No 10:297-306
            ##
            elsif ($source=~m#([\w-]+)\.\s*(\d+)\s*\;\s+No\s+(\d+)\s*:\s*([\d-]+)#)
            {
                $citation->parsed('VOL', $3);
                $citation->parsed('PGS', $4);
                my $title = $1;
                $title =~ s/-/ /g;
                $citation->parsed('TITLE', $title);
            }

            ##
            ## Annual-Progress-in-Child-Psychiatry-and-Child-Development. 1979 646-676
            ## Note: No volume so fake one
            ##
            elsif ($source=~m#([\w-]+)\.\s*(\d+)\s*([\d-]+)#)
            {
                $citation->parsed('VOL', '1');
                $citation->parsed('PGS', $3);
                my $title = $1;
                $title =~ s/-/ /g;
                $citation->parsed('TITLE', $title);
            }
        } elsif ($citation->is_book()) {
            $citation->parsed('TITLE', $citation->pre('TI'));
        }

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::psyclit") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##
    
        if ($citation->parsed('PUBTYPE') =~ m#journal#i) {
            $reqtype = $GODOT::Constants::JOURNAL_TYPE;
        }
        elsif ($citation->pre('DT') =~ m#journal#i) {
            $reqtype = $GODOT::Constants::JOURNAL_TYPE;
        }
        else {
            $reqtype = $GODOT::Constants::BOOK_TYPE;
        }

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

