package GODOT::Parser::socio;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;
use GODOT::String;

@ISA = "GODOT::Parser";


use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::socio") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##
	
	if ($citation->is_journal()) {
		my ($title, $restv) = split(/;/, $source);

		# Parse out translations, take the first assuming it's english...
		$title =~ s#^(.+?)\s+/\s+.+$#$1#;
		$citation->parsed('TITLE', $title);
		
		
		$restv =~ s#[\.;]+##g;    ## remove trailing punctuation
		
		my ($year, $vol, $iss, $month, $pgs) = split(/,/, $restv);
		
		$citation->parsed('YEAR', trim_beg_end($year));
		$citation->parsed('VOL', trim_beg_end($vol));
		$citation->parsed('ISS', trim_beg_end($iss));
		$citation->parsed('MONTH', trim_beg_end($month));
		$citation->parsed('PGS', trim_beg_end($pgs));
		
		##
		## 1996, 8, 2-3, 133-146  (must specify trailing whitespace or there will be overlap with above)
		##
		if ($restv =~ m#(\d\d\d\d),\s*([\d\055]+),\s*([\d\055]+),\s*([\d\055]+)\s*$#) {
			$citation->parsed('YEAR', $1);
			$citation->parsed('VOL', $2);
			$citation->parsed('ISS', $3);
			$citation->parsed('MONTH', '');
			$citation->parsed('PGS', $4);
		}
		##
		## 1996, 10, 51-68.;
		##
		elsif ($restv =~ m#(\d\d\d\d),\s*([\d\055]+),\s*([\d\055]+)\s*$#) {
			$citation->parsed('YEAR', $1);
			$citation->parsed('VOL', $2);
			$citation->parsed('ISS', '');
			$citation->parsed('MONTH', '');
			$citation->parsed('PGS', $3);
		}
		
		##
		## 1996, 546, July, 9-21.;
		##
		elsif ($restv =~ m#(\d\d\d\d),\s*([\d\055]+),\s*([a-z\055]+),\s*([\d\055]+)\s*$#i) {
			$citation->parsed('YEAR', $1);
			$citation->parsed('VOL', $2);
			$citation->parsed('ISS', '');
			$citation->parsed('MONTH', $3);
			$citation->parsed('PGS', $4);
		}
	} elsif ($citation->is_book() || $citation->is_book_article()) {

		if ($citation->is_book())  {
			$citation->parsed('TITLE', $citation->pre('TI')) unless aws($citation->pre('TI'));
			$citation->parsed('AUT', $citation->pre('AU'));
			$citation->parsed('ARTTIT', '');
			$citation->parsed('ARTAUT', '');
		}
		
		if ($citation->parsed('PUBTYPE') =~ m#association-paper#i) {
			$citation->parsed('TITLE', "Association Paper");
			$source = $citation->pre('AS');
		} elsif ($citation->parsed('PUBTYPE') =~ m#book-chapter-abstract#i) {
			$citation->parsed('TITLE', trim_beg_end($citation->pre('PB')));
			my $title = $citation->parsed('TITLE');
			$title =~ s#^chpt in ##i;
			$citation->parsed('TITLE', $title);
		}
		
		$citation->parsed('PUB', trim_beg_end($source));
	}
	
	if ($citation->is_thesis()) {
		$citation->parsed('NOTE', trim_beg_end($source));
	}
        
	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::socio") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##
	
	if ($citation->parsed('PUBTYPE') =~ m#book-chapter-abstract#) {
		$reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE;
	}

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

