package GODOT::Parser::inspec;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::inspec") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##

        if ($citation->is_journal()) {
            my $pos = index($source,".");
            my $title = substr($source,0,$pos);
            $citation->parsed('TITLE', $title);
            my $pos2 = index($source,";",$pos+1);
            my $vol = substr($source,$pos+1,$pos2-$pos-1);
            $citation->parsed('VOLISS', $vol);
            my $pos3 = index($source,";",$pos2+1);
            my $pages = substr($source,$pos3+1);
            $pages =~ s#p|\.##g;
            $citation->parsed('PGS', $pages);
        }
        if ($citation->is_book()) {
        }
        if ($citation->is_thesis()) {
        }

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::inspec") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

