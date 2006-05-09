##23-aug-2001 yyua: tested with 'arts' (http://www.lib.sfu.ca/cgi-bin/trust1.pl?arts)
##				'hssi' (http://www.lib.sfu.ca/cgi-bin/trust1.pl?hssi)
##				'socsciabs' (http://www.lib.umanitoba.ca/asp/netdoc/title.asp)

package GODOT::Parser::Wilson;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::Wilson") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##
    ##
    ## -Wilson databases (mounted on BRS, accessed via SLRI - an httpd-z39.50 gateway)
    ##
    if ($citation->dbase_type() eq 'slri') {

        if ($citation->is_journal()) {     

            $citation->parsed('TITLE', $citation->pre('SO'));
            $citation->parsed('ARTTIT', $citation->pre('TI'));  

            $citation->parsed('VOL', $citation->pre('VOL'));  
            $citation->parsed('ISS', $citation->pre('ISS'));
            $citation->parsed('PGS', $citation->pre('PG'));  

            $citation->parsed('MONTH', $citation->pre('MON'));  
            my $month = $citation->parsed('MONTH');
            $month =~ s#'\d\d\d\d##g;
            $month =~ s#'\d\d##g;
            $citation->parsed('MONTH', $month);

            $citation->parsed('ARTAUT', $citation->pre('AU'));  
        }
        elsif ($citation->is_book()) {
            $citation->parsed('TITLE', $citation->pre('TI'));  
        }

        $citation->parsed('YEAR', $citation->pre('PY')); 
        $citation->parsed('PUB', $citation->pre('PUB'));
    }
    ##
    ## -parsing added for Wilson databases (mounted on ERL) by Jonathan Esterhazy - 26/3/98
    ##
    elsif ($citation->dbase_type() eq 'erl') {

	    #Biochemistry (American Chemical Society) v 31 Dec 29 1992. p. 12885-92
	    #The Journal of Biological Chemistry v 275 no51 Dec 22 2000. p. 40148-54
	    #The Psychological Record v 51 no1 Winter 2001. p. 3-18

	    if ($source =~ /^(.*)\s+v\s+(\d+)\s*(no\d+)*\s+([\w ]+)\s+\d{4,4}.*p\.\s*([0-9-]+)/)
	    {
		    $citation->parsed('TITLE', $1);
		    $citation->parsed('VOL', $2);
		    $citation->parsed('MONTH', $4); 
		    $citation->parsed('PGS', $5);
		    if ($3) {
			my $issue = $3;
			$issue =~ s/no//g;
			$citation->parsed('ISS', $issue);
		    }
	    }

	    # match: Title. v. vol noISS Month. Day 'YY p. Pages.
	    elsif ($source =~ /^\s*([^.]+)\.\s*v\.\s*(\S+)\s*no\s*(\S+)\s*(\S+)\s*(\S+)\s*'\S+\s*p\.\s*([^.]+).*$/)
	    {
		    $citation->parsed('TITLE', $1);
		    $citation->parsed('VOL', $2);
		    $citation->parsed('ISS', $3);
		    $citation->parsed('MONTH', "$4 $5"); # "Month Day" for issue
		    $citation->parsed('PGS', $6);
	    }

	    # match: Title. v. vol Month./Month. Day 'YY p. Pages.
	    # Month could be "Month." only
	    # Pages could be "1089", "382-3", "114+", "supp 1-4", "72-4+", or "F4" etc.

	    # note that year is easily extractable, but we will use
	    # the value passed from webspirs instead (it's probably more
	    # reliable).
	    elsif ($source =~ /^\s*([^.]+)\.\s*v\.\s*(\S+)\s+(\S+)\s+(\S+)\s+'\S+\s*p\.\s*([^.]+).*$/)
	    {
		    $citation->parsed('TITLE', $1);
		    $citation->parsed('VOL', $2);
		    $citation->parsed('MONTH', $3);
		    $citation->parsed('ISS', "$3 $4"); # "Month Day" for issue
		    $citation->parsed('PGS', $5);
	    }

	    # Same as above, but without day of the month.
	    # Also catches "Title. v. vol noISS 'YY p. Pages."
	    elsif ($source =~ /^\s*([^.]+)\.\s*v\.\s*(\S+)\s*(\S+)\s*'\S+\s*p\.\s*([^.]+).*$/)
	    {
		    $citation->parsed('TITLE', $1);
		    $citation->parsed('VOL', $2);
		    $citation->parsed('MONTH', $3);
		    $citation->parsed('ISS', "$3"); # "Month" for issue
		    $citation->parsed('PGS', $4);
	    }

	    # match: Title. noISS Month 'YY p. Pages.
	    # match: Title. no ISS Month 'YY p. Pages.
	    elsif ($source =~ /^\s*([^.]+)\.\s*no\s*(\S+)\s*(\S+)\s*'\S+\s*p\.\s*([^.]+).*$/)
	    {
		    $citation->parsed('TITLE', $1);
		    $citation->parsed('VOLISS', $2);
		    $citation->parsed('MONTH', $3);
		    $citation->parsed('PGS', $4);
	    }

	    # match: "Title. Month. Day 'YY p. Pages."
	    elsif ($source =~ /^\s*([^.]+)\.\s*(\S+)\s*(\S+)\s*'\S+\s*p\.\s*([^.]+).*$/)
	    {
		    $citation->parsed('TITLE', $1);
		    $citation->parsed('VOLISS', "$2 $3"); # Month and day
		    $citation->parsed('MONTH', $2);
		    $citation->parsed('PGS', $4);
	    }
	    else { ; }
    } ## end wilson databases   ## JE 26/3/98

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::Wilson") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

	##
	## -these wilson databases only cover journals/periodicals
	##
	if ( $citation->dbase_type() eq  'erl') {   
	    $reqtype = $GODOT::Constants::JOURNAL_TYPE;
	}
	##
	## -'educ' includes monographs 
	##
	elsif ( $citation->dbase_type() eq 'slri') {

	    if ($citation->parsed('PUBTYPE') eq 'monograph') { $reqtype = $GODOT::Constants::BOOK_TYPE; }
	    else                         { $reqtype = $GODOT::Constants::JOURNAL_TYPE; }  
	}

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

