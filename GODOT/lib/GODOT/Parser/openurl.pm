package GODOT::Parser::openurl;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;
use GODOT::String;

@ISA = "GODOT::Parser";


use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::openurl") if $GODOT::Config::TRACE_CALLS;

        ##
        ## (12-mar-2002 kl) - removed as none of the mappings apply to this parser
        ##
	#### $self->SUPER::parse_citation($citation);
        ##        

	##---------------Customized code goes here-------------------##

	##
	## -in case we haven't already, get rid of any leading and trailing whitespace
	##

	foreach (keys %GODOT::Citation::HOLD_TAB_PARAM_MAPPINGS) {
	    $citation->pre($_, trim_beg_end($citation->pre($_)));
	}


        $citation->parsed('GENRE', $citation->pre('genre'));


	my $title = ($citation->pre('TI') ne '') ? $citation->pre('TI') : $citation->pre('stitle');

	$citation->parsed('TITLE', $title);
	$citation->parsed('ARTTIT', $citation->pre('atitle'));

	##
	## -put together the first author's name, starting with the 'better' or 'more informative' components
	##

	my($author) = $citation->pre('aulast');
	    
	if ($citation->pre('aufirst') ne '')   {
	    if ($author ne '') { $author .= ", "; }
	    $author .= $citation->pre('aufirst');

	    if ($citation->pre('auinitm') ne '' ) { $author .= " " . $citation->pre('auinitm'); }
	}
	elsif ($citation->pre('auinit'))   {
	    if ($author ne '') { $author .= ", "; }
	    $author .= $citation->pre('auinit');
	}
	elsif ($citation->pre('auinit1')) {
	    if ($author ne '') { $author .= ", "; }
	    $author .= $citation->pre('auinit1');
	}

	##
	## -is the author for a 'bundle' or an 'individual item' (ie. an article, book chaper, etc)
	##

	if (grep {$citation->pre('genre') eq $_} @GODOT::Config::INDIVIDUAL_ITEM_GENRE_ARR)  { 
	    $citation->parsed('ARTAUT', $author); 
	}
	else { 
	    $citation->parsed('AUT', $author); 
	}  

	##
	## -standard numbers 
	##
	my $issn = ($citation->pre('ISSN') ne '') ? $citation->pre('ISSN') : $citation->pre('eissn');
	$citation->parsed('ISSN', clean_ISSN($issn));


	$citation->parsed('ISBN', $citation->pre('ISBN'));

	##
	## -volume and issue
	##

	my $vol = ($citation->pre('VOL') ne '') ? $citation->pre('VOL') : $citation->pre('part');
	$citation->parsed('VOL', $vol);

	$citation->parsed('ISS', $citation->pre('ISS'));

	##
	## -figure out pages
	##

	my($pages)  = $citation->pre('PG');
	my($spage)  = $citation->pre('spage');
	my($epage)  = $citation->pre('epage');
	my($artnum) = $citation->pre('artnum');

	if ($pages eq '') {
	    if ($spage && $epage) { $pages = "$spage-$epage"; }
	    elsif ($spage)        { $pages = $spage;          } 
	    elsif ($artnum)       { $pages = $artnum;         }       
	}
       
	$citation->parsed('PGS', $pages);

	##
	## -what date format do we have?
	##   
	my($date) = $citation->pre('date');
	my($mm);

	if ($date ne '') {
	    if ($date =~ m#(\d\d\d\d)\055(\d\d)\055(\d\d)#) {                ## YYYY-MM-DD
		$citation->parsed('YEAR', $1);   
		$citation->parsed('YYYYMMDD', "$1$2$3");
		$mm = $2;
	    }
	    elsif ($date =~ m#(\d\d\d\d)\055(\d\d)#) {                       ## YYYY-MM    
		$citation->parsed('YEAR', $1);   
		$mm = $2; 
	    }
	    elsif ($date =~ m#(\d\d\d\d)#) {                                 ## YYYY  
		$citation->parsed('YEAR', $1);   
	    }
	}

	##
	## -don't pass blank to &GODOT::Date::date_mm_to_mon or will get 'DEC' -- need to fix date_mm_to_mon !!!!!
	##

	if ($mm) { $citation->parsed('MONTH', &GODOT::Date::date_mm_to_mon($mm)); }

	if (! $citation->parsed('MONTH')) { $citation->parsed('MONTH', $citation->pre('ssn'))};
	##
	## -do we want to put numeric quarter in month field???? 
	## -possible confusion????
	## -add new quarter field ????
	##

	if ((! $citation->parsed('MONTH')) && $citation->pre('quarter')) { 
	    my(%quarter_hash) = ('1' => '1st', '2' => '2nd', '3' => '3rd', '4' => '4th');
	    my $quarter = $citation->pre('quarter');

	    $citation->parsed('MONTH', "$quarter_hash{$quarter} quarter"); 
	}
	
	##
	## !!!!! -still need to map OpenURL 'id', 'pid', 'coden', and 'bici' !!!!!!
	##    

	if ($citation->pre('id'))  {   
	    my($namespace, $identifier) = split(/:/, $citation->pre('id'), 2);
	    $citation->parsed(uc($namespace), $identifier);
	}

	$citation->parsed('SICI', $citation->pre('SICI'));

	if ($citation->is_thesis()) {
		if ($citation->parsed('TITLE') =~ /abstracts/i && $citation->parsed('ARTTIT') =~ /\S/) {
			$citation->parsed('NOTE', $citation->parsed('NOTE') . $citation->parsed('TITLE'));
			$citation->parsed('TITLE', $citation->parsed('ARTTIT'));
			$citation->parsed('ARTTIT', '');
			$citation->parsed('VOL', '');
			$citation->parsed('ISS', '');
			$citation->parsed('PGS', '');
			$citation->parsed('ISSN', '');
		}		
	}




	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::openurl") if $GODOT::Config::TRACE_CALLS;

	##---------------Customized code goes here-------------------##
	
	my($reqtype, $no_title);

        my($genre) = $citation->pre('genre');
	
	##
	## -'oai' specifies identifier used in Open Archives Initiative  
	##
	## -deal with case seen in 'iopp' where the genre was 'article' but no journal title was given and 
	##  article was only available through the preprint archive
	##
       
	$no_title = (aws($citation->pre('TI')) && aws($citation->pre('stitle'))) ? $TRUE : $FALSE;
     
	if ($no_title && ($citation->pre('id') =~ m#^oai:#)) { 
	    $reqtype = $GODOT::Constants::PREPRINT_TYPE; 
	} 
	elsif (($genre) && defined($GODOT::Config::GENRE_TO_REQTYPE_HASH{$genre})) {
	    $reqtype = $GODOT::Config::GENRE_TO_REQTYPE_HASH{$genre};
	}
	else {
            $reqtype = $GODOT::Constants::UNKNOWN_TYPE;
        }

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

