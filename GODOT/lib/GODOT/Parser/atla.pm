package GODOT::Parser::atla;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";


use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::atla") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	##---------------Customized code goes here-------------------##

	my $source = $citation->parsed('SOURCE');

        if ($citation->is_journal())  {

            $citation->parsed('TITLE', $citation->pre('JN'));

	    ##Examples: 
	    # 'Ostkirchlichen-Studien. 49, no 1 (Ap 2000), p. 31-54..'
	    # 'Archiv-fur-Reformationsgeschichte. 75 (1984), p. 176-193..'

	    if ($source =~ /^.*\.\s+[^0-9]*(\d+)[\s,]*([Nn]o){0,1}\s*([0-9-]*)\s+\((\w*)\s*\d{4,4}\),\s+p\.\s+([0-9,-]*)/) {
	       $citation->parsed('VOL', $1);
	       $citation->parsed('ISS', $3);
	       $citation->parsed('MONTH', $4);
	       $citation->parsed('PGS', $5);
	    }
	}
	## Examples:
	# 'In: Annual review of women in world religions, vol 5, The. Albany : State Univ of New York Pr, 1999. p. 206-228.'
	# 'In: Zeit und Stunde. Munich : Maander Verlag, 1985. p. 235-255.'
	elsif ($citation->is_book_article()) {
	    $source = $citation->pre('PB');
	    if ($source =~ /^In:\s+(.+)\..+:\s+(.+),\s+(\d{4,4})\.\s+p\.\s+([0-9-]+)\./) {
	       $citation->parsed('TITLE', $1);
	       $citation->parsed('PUB', $2);
	       $citation->parsed('PGS', $4);
	    }
	    else {
	       warning 'atla DB: source matching failed!';
	    }
	}
	elsif ($citation->is_book() ) {
	#SUPER does the job.
	}
	    
	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::atla") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

        if ($citation->pre('PT') eq 'Journal-article' || $citation->pre('PT') eq 'Book-Review') { 
	    $reqtype = $GODOT::Constants::JOURNAL_TYPE; 
	}
        elsif ($citation->pre('PT') eq 'Book' ) { 
	    $reqtype = $GODOT::Constants::BOOK_TYPE; 
	}
	elsif ($citation->pre('PT') eq 'Essay') {
	    $reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE;
	}
        else {
	    warning 'atla database got new publication type!'; 
	}

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

