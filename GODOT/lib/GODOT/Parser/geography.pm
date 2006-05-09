package GODOT::Parser::geography;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::geography") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##

	if ($citation->is_journal() || $citation->is_book_article()) {
            # Canadian-Journal-of-Development-Studies. 1999; 1(1): 77-104 
	    if ($source =~ /^\s*([^\s]+)\s*\.(.+)$/) {
		$citation->parsed('TITLE', $1);
		my $remainder_string = $2;
		# Replace - and --
		my $title = $citation->parsed('TITLE');
		$title =~ s/([^\-])-(?!-)/$1 /g;
		$title =~ s/--/-/g;
		$citation->parsed('TITLE', $title);
	    	if ($remainder_string =~ /^\s*\d{4}\s*([\w\s\d]*)\s*;\s*([\d\w\/\-]+)\s*\(?([\d\w\/\-]*)\)?\s*:\s*([\d\w\-\/,]+)\s*$/) {
		    $citation->parsed('VOL', $2);
		    $citation->parsed('MONTH', $1);
		    $citation->parsed('ISS', $3);
	    	    $citation->parsed('PGS', $4);
		# Go for pages at least - BOOK_ARTICLES need this only usually.
	    	} elsif ($remainder_string =~ /;\s*([\d\w\-\,\/]+)\s*$/) {
	    	    $citation->parsed('PGS', $1);
	    	} else {
	    	    $citation->parsed('PUB', "$remainder_string; ");
	    	}
		my $pub = $citation->parsed('PUB');
		$pub .= $citation->pre('AD');
		$citation->parsed('PUB', $pub);
		if ($citation->pre('ED')) {
		    $citation->parsed('AUT', $citation->pre('ED'));
		}
	    } 
	} else {
		
	}
	# This database has lots of super/subscripts which have to be stripped in this weird format.
	my $title = $citation->parsed('TITLE');
	$title =~ s/<\/?(sup|inf)\.GT\.//gi;
	$citation->parsed('TITLE', $title);
	my $arttit = $citation->parsed('ARTTIT');
	$arttit =~ s/<\/?(sup|inf)\.GT\.//gi;
	$citation->parsed('ARTTIT', $arttit);


	$citation->parsed('SYSID', $citation->pre('AN'));

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::geography") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

	 if ($reqtype eq $GODOT::Constants::UNKNOWN_TYPE){
	       $reqtype = $GODOT::Constants::JOURNAL_TYPE;
	 }

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

