package GODOT::Parser::agric;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::agric") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	##---------------Customized code goes here-------------------##

	my $source = $citation->parsed('SOURCE');

        if ($citation->is_journal())  {

            ##
            ## J-Inst-Brew. London : The Institute. Mar/Apr 1996. v. 102 (2) p. 87-91
            ##
            my ($title,$issue,$vol,$pages);
            $title = substr($source,0,index($source,"."));
            $pages = substr($source,index($source,"p.")+3);
            $vol = substr($source,index($source,"v.")+3,
                   length($source) - index($source,"p.")-3);
            $citation->parsed('ISS', $issue);      
            $citation->parsed('VOL', $vol);
            $citation->parsed('PGS', $pages);
            $citation->parsed('TITLE', $title);
        }

        elsif ($citation->is_book())  {
            $citation->parsed('TITLE', $citation->pre('TI'));
        }
        if (defined($citation->pre('UR')) && $citation->pre('UR') ne "") {
                $citation->fulltext_available(1);
        }


	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::agric") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

        # Agricola - pubtype in PT
        if ($citation->parsed('PUBTYPE') =~ m#article#i) {
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

