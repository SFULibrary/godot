package GODOT::Parser::ebsco;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::ebsco") if $GODOT::Config::TRACE_CALLS;

	if ($citation->is_journal()) {
	
		$citation->parsed('TITLE',  $citation->pre('SO'));
		$citation->parsed('ARTTIT', $citation->pre('TI'));
		$citation->parsed('ARTAUT', $citation->pre('CA'));
		$citation->parsed('ISSN',   $citation->pre('ISSN'));
	
		##
                ## (19-sep-2002 kl) - 'yyyymmdd' format added
                ##
		## Date types in EBSCO: mm/dd/yy, mm/dd/yyyy, yyyymmdd, Monyyyy, Mon/Monyyyy, Monyy
		##

		# mm/dd/yy and mm/dd/yyyy
		if ($citation->pre('MON') =~ m#(\d+)/(\d+)/(\d+)#) {
			$citation->parsed('YEAR',      GODOT::Date::add_cent($3));
			$citation->parsed('MONTH',     GODOT::Date::date_mm_to_mon($1));
			$citation->parsed('YYYYMMDD',  $citation->parsed('YEAR') . sprintf("%02d", $1) . sprintf("%02d", $2));

		} elsif ($citation->pre('MON') =~ m#([a-zA-Z/]+)/(\d+)#) {
			$citation->parsed('MONTH', $1);
			$citation->parsed('YEAR', GODOT::DATE::add_cent($2));

		} elsif ($citation->pre('MON') =~ /^(\d\d\d\d)(\d\d)(\d\d)$/) {

                        $citation->parsed('YYYYMMDD',  $1 . $2 . $3);
   		        $citation->parsed('YEAR', $1);
                        $citation->parsed('MONTH', GODOT::Date::date_mm_to_mon($2));

                        my $dd = $3; $dd =~ s#^0+##;
                        $citation->parsed('DAY', $dd);                        
                
		} elsif ($citation->pre('MON') =~ /^\d{6,6}$/) {
                        #
                        # parses: YYYYMM adds '01'
                        #
			$citation->parsed('YEAR',      substr($citation->pre('MON'), 0, 4));
			$citation->parsed('MONTH',     GODOT::Date::date_mm_to_mon(substr($citation->pre('MON'), 4, 6)));
			$citation->parsed('YYYYMMDD',  $citation->parsed('YEAR') . $citation->parsed('MONTH') . '01');

		} elsif ($citation->pre('MON') =~ /^\d{4,4}$/) {
			$citation->parsed('YEAR', $citation->pre('MON'));

		} else {
			warn("GODOT::Parser::ebsco: Date field for MONTH is in an unexpected format (" . 
                             $citation->pre('MON') .  
                             ")");
		}
		$citation->parsed('VOL', $citation->pre('VOL'));
		$citation->parsed('ISS', $citation->pre('ISS'));
		$citation->parsed('PGS', $citation->pre('PG'));

	} elsif ($citation->is_book() || $citation->is_book_article()) {

	        debug "arttit:  ", $citation->parsed('ARTTIT');

		if ($citation->is_book_article()) {
			$citation->parsed('TITLE', $citation->pre('SO'));
			$citation->parsed('ARTTIT', $citation->pre('TI'));
		        $citation->parsed('ARTAUT', $citation->pre('CA'));
		} else {
			$citation->parsed('TITLE', $citation->pre('SO'));
			defined($citation->parsed('TITLE')) && $citation->parsed('TITLE') or
				$citation->parsed('TITLE', $citation->pre('TI'));
		        $citation->parsed('AUT',       $citation->pre('CA'));
		}
		


		$citation->parsed('YYYYMMDD',  $citation->pre('MON'));
		$citation->parsed('ISBN',      $citation->pre('ISBN')) if defined($citation->pre('ISBN'));
		$citation->parsed('SICI',      $citation->pre('SICI')) if defined($citation->pre('SICI'));
	}
	elsif ($citation->is_thesis()) {
		$citation->parsed('TITLE',     $citation->pre('TI'));
		$citation->parsed('AUT',       $citation->pre('CA'));
		$citation->parsed('YYYYMMDD',  $citation->pre('MON'));
	}

	$citation->parsed('SYSID', $citation->pre('SID'));
	

        ##
        ## (05-sep-2003 kl) - according to a 04-sep-2003 email from Alison Galati at Ebsco
        ##                    'FT={HasFullText}' reflects the customer's local collection and 
        ##                    'T={FMT-T}' and 'P={FMT-P}' reflects whether Ebsco has full text
        ##                    for the title.   
        ##
	#### if ((lc($citation->pre('FT')) eq 'yes') || ($citation->pre('PB') eq 'P')) {

	if ((lc($citation->pre('t')) eq 'yes') || (lc($citation->pre('p')) eq 'yes')) {
		$citation->fulltext_available(1);
	}           

	return $citation;
}

sub get_req_type {
        my ($self, $citation, $pubtype) = @_;
        debug("get_req_type() in GODOT::Parser::ebsco") if $GODOT::Config::TRACE_CALLS;

	# Some ebscohost title have started including monographs... but
	# we need more fields before we can determine what type the request
	# is for.

	if ($citation->pre('ISSN')) { 
	    return $GODOT::Constants::JOURNAL_TYPE;
	} elsif ($citation->pre('ISBN')) {
                ##
                ## (18-apr-2005 kl) - PsycBooks was sending back 'TI' and 'SO' as the same for edited books 
                ##
		if (defined($citation->pre('SO')) && defined($citation->pre('TI')) && 
                   ($citation->pre('SO') ne '' && $citation->pre('TI') ne '') &&
                   ($citation->pre('SO') ne $citation->pre('TI'))) {

			return $GODOT::Constants::BOOK_ARTICLE_TYPE;
		} else {
			return $GODOT::Constants::BOOK_TYPE;
		}
	} else {
           ##
           ## (01-oct-2001 kl) - No way to tell book and book-chapters apart currently so can't
           ##                    parse them correctly. For books, the book title gets passed in
           ##                    pre('TI') which works OK.  However, for book chapters, the 
           ##                    chapter title gets passed in pre('TI') but the book title does
           ##                    not get passed at all.
           ##
           ##

	   return $GODOT::Constants::JOURNAL_TYPE;		

	}
}


1;

__END__

=head1 NAME

GODOT::Parser::ebsco - generic ebscohost databases parser


2002-09-12 - tholbroo - Fixed a number of problems with date parsing
