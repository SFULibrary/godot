package GODOT::Parser::llba;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::llba") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##

        if ($citation->is_journal()) {

	    $citation->parsed('PUB', $citation->pre('CP'));

	    # Get title out
	    my $title;
	    ($title, $source) = split(/;/, $source, 2);
	    $citation->parsed('TITLE', $title);

	    # Get year out and throw it away
	    (undef, $source) = split(/,/, $source, 2);

	    ## Foundations-of-Language; 1974, 11 (2), 281-285..
	    if ($source =~ /^\s*(\d+)\s*\((\d+\-?\d*)\),\s*(?:([-A-Za-z]+),\s*)?(\d+\-\d+)\s*/) {
                $citation->parsed('VOL', $1);
                $citation->parsed('ISS', $2);
		$citation->parsed('MONTH', $3);
		$citation->parsed('PGS', $4);
            }

            ## Scandinavian-Journal-of-Psychology; 2000, 41, 1, Mar, 41-48.
            ## Lingue-del-Mondo; 1989, 54, 4-5, July-Oct, 308-311.
	    ## Linguistische-Berichte; 1973, 27, 1-7.
	    ## Revista-de-Documentacao-de-Estudos-em-Linguistica-Teorica-e-Aplicada-(D.E.L.T.A.); 1999, 15, special issue, 257-290.
	    ## Homme; 2000, 153, Jan-Mar, 153-164.
	    ## Journal-of-Linguistic-Anthropology; 1999, 9, 1-2, June-Dec, 1-276.

	    elsif ($source =~ /^\s*(\d+),\s*(?:(\d+\-?\d*),\s*)?(?:([-A-Za-z]+),\s*)?(\d+\-\d+)/) {
                $citation->parsed('VOL', $1);
                $citation->parsed('ISS', $2);
		$citation->parsed('MONTH', $3);
		$citation->parsed('PGS', $4);
            }
        } elsif ($citation->is_book_article()) {
	    $citation->parsed('ARTTIT', $citation->pre('TI'));
            $citation->parsed('ARTAUT', $citation->pre('AU'));

	    # Chpt in ON CONDITIONALS AGAIN, Athanasiadou, Angeliki, & Dirven, Rene [Eds], Amsterdam: John Benjamins, 1997, pp 323-354
	    if ($citation->pre('PB') =~ /^\s*Chpt\sin\s*([-A-Z,:&()\s0-9]+),\s*([A-Za-z][a-z].+\[Eds?\]),\s*(.+),\s*\d{4},\s*pp\s*(\d+\-?\d*)/) {
		    $citation->parsed('AUT', $2);
	    	    $citation->parsed('TITLE', $1);
	            $citation->parsed('PGS', $4);
        	    $citation->parsed('PUB', $3);
	    } else {
		my ($title, $pgs);
	    	($title, $pgs) = split(/pp\s*/, $citation->pre('PB'), 2);
	    	$citation->parsed('TITLE', $title);
	    	$citation->parsed('PGS', $pgs);
	    }	    
    	}

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::llba") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##
        if ($citation->parsed('PUBTYPE') =~ /book-chapter/) {
                $reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE;
        } elsif ($citation->parsed('PUBTYPE') =~ /association-paper/ ) {
                $reqtype = $GODOT::Constants::TECH_TYPE;
        } elsif ($citation->parsed('PUBTYPE') =~ /dissertation/){
                $reqtype = $GODOT::Constants::THESIS_TYPE;
        }

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

