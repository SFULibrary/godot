package GODOT::Parser::cei;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;
use GODOT::String;

@ISA = "GODOT::Parser";


use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::cei") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##

       if ($citation->is_journal()) {
           #
           # -match: AGATE, v.9(2) Fall, 1995 pg 33-42.
           #         Revue des sciences de l'education, v.22(1) 1996 pg 189-190            
           #         Canadian Journal for the Study of Adult Education, V.6 no 2: November 1992.pg 65-67.
           #
           if ($source =~ m#^(.+)\s*,\s*(.+)\s*\((.+)\).*\s*,\s*\d\d\d\d.*\s*pg(.+).\s*#) {
               $citation->parsed('TITLE', $1);
               $citation->parsed('VOL', $2);
               $citation->parsed('ISS', $3);
               $citation->parsed('PGS', $4);
           } elsif ($source =~ m#^(.+)\s*,\s*(.+)\s*\((.+)\).*\s*\d\d\d\d.*\s*pg(.+).\s*#) {
               $citation->parsed('TITLE', $1);
               $citation->parsed('VOL', $2);
               $citation->parsed('ISS', $3);
               $citation->parsed('PGS', $4);
           } elsif ($source =~ m#^(.+)\s*,\s*V.(.+)\s*:\s*.*\s*\d\d\d\d.*\s*pg(.+).\s*#) {
               $citation->parsed('TITLE', $1);
               $citation->parsed('VOLISS', $2);
               $citation->parsed('PGS', $3);
           }
           my $vol = $citation->parsed('VOL');
           $vol =~ s#v.##g; 
           $citation->parsed('VOL', $vol);
       }
       if ($citation->is_book()) {
           if ($source =~ m#^(.+)\s*,\s*\d\d\d\d.\s*#) {
               $citation->parsed('PUB', $1);
           } else {
               $citation->parsed('PUB', trim_beg_end($source));
           }
       }
       if ($citation->is_thesis()) {
           $citation->parsed('NOTE', $citation->pre('AS'));
       }

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::cei") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

        if ($citation->parsed('PUBTYPE') =~ m#thesis#) { $reqtype = $GODOT::Constants::THESIS_TYPE; }

        if ($citation->parsed('PUBTYPE') =~ m#announcement# ||
            $citation->parsed('PUBTYPE') =~ m#guideline#    ||
            $citation->parsed('PUBTYPE') =~ m#research#     ||
            $citation->parsed('PUBTYPE') =~ m#document#     ||
            $citation->parsed('PUBTYPE') =~ m#report#       ||
            $citation->parsed('PUBTYPE') =~ m#conference#) {

            $reqtype = $GODOT::Constants::BOOK_TYPE;
        }

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

