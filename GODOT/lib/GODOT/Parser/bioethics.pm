package GODOT::Parser::bioethics;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::bioethics") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	##---------------Customized code goes here-------------------##

        ##
        ## parsing for Bioethicsline, Cancer-CD and EMBASE Neurosciences written by Jonathan Esterhazy -  3/31/98
        ##

	my ($dt) = lc($citation->parsed('PUBTYPE'));
	my $source = $citation->parsed('SOURCE');

	if ($citation->is_book_article())  {

	    if ($dt =~ /bill/) {
		$citation->parsed('PUB', $source);
	    }

	    if ($dt =~ /law/) {
		if ($source =~ s/^\s*([^.]+)\.\s*//) {
		    $citation->parsed('TITLE', $1);
		    $citation->parsed('PUB', $source); # the rest
		}
		else {
		    $citation->parsed('PUB', $source);
		}
	    }
	    else {
		# these are analytic type

		# fix broken source field
		$source =~ s/In:\.GT.*?GT\./In:>/;
		$source =~ s/In:\.GT\./In:>/;


		# match: "<In:> editors eds. Title. Volume or edition note. Pub Place: Pub Name; Date: Pages."
		# or:    "In: editor ed. Title. Volume or edition note. Pub Place: Pub Name; Date: Pages."
		if ($source =~ /^\s*<?In:>?\s*(.*?)eds?\.([^.]+)\.\s*([^.]+)\.\s*([^:]+):\s*([^;]+);\s*([^:]+):\s*([^.]+).*$/)
		{
		    $citation->parsed('AUT', $1);
		    $citation->parsed('TITLE', "$2 $3");
		    $citation->parsed('PUB', "$4: $5; $6.");
		    $citation->parsed('PGS', $7);
		}

		# same as above, but without volume or edition note.
		elsif ($source =~ /^\s*<?In:>?\s*(.*?)eds?\.([^.]+)\.\s*([^:]+):\s*([^;]+);\s*([^:]+):\s*([^.]+).*$/)
		{
		    $citation->parsed('AUT', $1);
		    $citation->parsed('TITLE', "$2");
		    $citation->parsed('PUB', "$3: $4; $5.");
		    $citation->parsed('PGS', $6);
		}

		# same as first case, but without editor(s) names.
		elsif ($source =~ /^\s*<?In:>?\s*([^.]+)\.\s*([^.]+)\.\s*([^:]+):\s*([^;]+);\s*([^:]+):\s*([^.]+).*$/)
		{
		    $citation->parsed('TITLE', "$1 $2");
		    $citation->parsed('PUB', "$3: $4; $5.");
		    $citation->parsed('PGS', $6);
		}

		# same as above, but without volume or edition note.
		elsif ($source =~ /^\s*<?In:>?\s*([^.]+)\.\s*([^.]+)\.\s*([^:]+):\s*([^;]+);\s*([^:]+):\s*([^.]+).*$/)
		{
		    $citation->parsed('TITLE', "$1");
		    $citation->parsed('PUB', "$2: $3; $4.");
		    $citation->parsed('PGS', $5);
		}
	    }
	}

	elsif ($citation->is_book()) {
	    if ($dt =~ /unpublished/) {
		$citation->parsed('PUB', $source);
	    }
	    elsif ($source =~ /^\s*([^:]+):\s*([^;]+);\s*[^.]+\.\s*([^.]+).*$/) {
		# ignore year in source field (we've already got it)
		$citation->parsed('PUB', "$1: $2; $3.");
	    }
	}

	else { ## JOURNAL_TYPE it is.
	    if ($dt =~ /newspaper/) {
		if ($source =~ /^\s*([^.]+)\.\s*([^;]+);\s*([^.]+).*$/) {
		    $citation->parsed('TITLE', $1);
		    $citation->parsed('VOLISS', $2);
		    $citation->parsed('PGS', $3);

		    my $voliss = $citation->parsed('VOLISS'); 
		    $voliss =~ s/^\s*(\d{4})\s+//;
		    $citation->parsed('VOLISS', $voliss);
		    $citation->parsed('YEAR', $1);
		}
	    }
	    elsif ($source =~ /^([^.]+)\.\s*([^;]+);\s*([^(]+)\(([^)]+)\)\s*([^.]+).*$/) {
		$citation->parsed('TITLE', $1);
		$citation->parsed('MONTH', $2);
		$citation->parsed('VOL', $3);
		$citation->parsed('ISS', $4);
		$citation->parsed('PGS', $5);
	    }
	}



	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::bioethics") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); ##yyua

	##---------------Customized code goes here-------------------##

        my $pubtype =  lc($citation->parsed('PUBTYPE')); # so we don't need /i in matches.

	if ($pubtype =~ /analytic/ || $pubtype =~ /bill/ || $pubtype =~ /law/)  { 
	    # this type the best fit available for the laws and bills.

	    $reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE;
        }
	elsif ($pubtype =~ /monograph/ || $pubtype =~ /unpublished-document/)  {
	    $reqtype = $GODOT::Constants::BOOK_TYPE;
        }
	else {
	    $reqtype = $GODOT::Constants::JOURNAL_TYPE;
        }


	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

