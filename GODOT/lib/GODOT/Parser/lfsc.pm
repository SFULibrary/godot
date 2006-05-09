package GODOT::Parser::lfsc;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";


use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::lfsc") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	##---------------Customized code goes here-------------------##

	my $source = $citation->parsed('SOURCE');

        if ($citation->is_journal())  {

	    #Nature 2001 vol. 411, no. 6839, pp. 801-805
	    #Toxicology 1999 vol. 139, no. 1-2, pp. 119-127
	    #Ecological-Modelling [Ecol.-Model.] 1999 vol. 123, no. 1, pp. 29-40
	    #J.-BIOCHEM. 1981. vol. 90, no. 3, pp. 889-892

	    if ($source =~ /^(.*)\s+\d{4,4}\.*\s+vol\.\s+([\d-]+)\,\s+no\.\s+([\d-]+)\,\s+pp\.\s+([\d-]+)/) {
	       $citation->parsed('TITLE', $1);
	       $citation->parsed('VOL', $2);
	       $citation->parsed('ISS', $3);
	       $citation->parsed('PGS', $4);
	    }

	    #AIDS 2000 vol. 14, p. S136

	    elsif ($source =~ /^(.*)\s+\d{4,4}\.*\s+vol\.\s+([\d-]+)\,\s+p{1,2}\.\s+([\d-S]+)/) {
	       $citation->parsed('TITLE', $1);
	       $citation->parsed('VOL', $2);
	       $citation->parsed('PGS', $3);
	    }
	    else {
	       print STDERR "Warning: lsfc journal parsing failed!\n"; 
	    }
	}

	#The-Birds-of-North-America PHILADELPHIA,-PA-USA Academy-of-Natural-Sciences 1999 no. 400, 16 pp
	#HOMING-AND-STRAYING-IN-SALMON. Heggberget-T.G.-ed. 1994 vol. 25, no. 2 Suppl. pp. 31-44
	#ni,-R.;Nagabhushanam,-R.-eds. 1991. pp. 387-391
	#PARASITE-ANTIGENS.-TOWARD-NEW-STRATEGIES-FOR-VACCINES. Pearson,-T.W.-ed. 1986. vol. 7 pp. 317-402
	#DELAYED-NEUROTOXICITY. Cranmer,-J.M.;Hixson,-E.J.-eds. 1982. vol. 3, no. 4, pp. 315-320 pp. 53-58

	elsif ($citation->is_book_article()) {
	    my ($title, $aut, $vol, $iss, $pgs);

	    if ($source =~ /^([^\s]+)\s+/){
		$title = $1;
		$title =~ s/-/ /g;
		$citation->parsed('TITLE', $title);
	    }
	    if ($source =~ /\s+([\w.\-;,]+)eds{0,1}\.\s+/){
		$aut = $1;
		$aut =~ s/-/ /g;
		$citation->parsed('AUT', $aut);
	    }
	    if ($source =~ /\s+vol\.\s+([\d-]+)/){
		$vol = $1;
		$citation->parsed('VOL', $vol);
	    }
	    if ($source =~ /\s+no\.\s+([\d-]+)/){
		$iss = $1;
		$citation->parsed('ISS', $iss);
	    }
	    if ($source =~ /\s+pp\.\s+([\d-]+)/ || $source =~ /\s+([\d-]+)\s+pp/){
		$pgs = $1;
		$citation->parsed('PGS', $pgs);
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
        debug("get_req_type() in GODOT::Parser::lfsc") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

        if ($citation->pre('PT') =~ /Journal-Article/) { 
	    $reqtype = $GODOT::Constants::JOURNAL_TYPE; 
	}
        elsif ($citation->pre('PT') =~ /Book/ ) { 
	    $reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE;
	}
        else {
	    print STDERR "Warning: lfsc: get_req_type: unrecognized type\n";
	}

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

