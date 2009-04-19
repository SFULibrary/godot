package GODOT::Parser::openurl;

use Data::Dumper;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;
use GODOT::String;

@ISA = "GODOT::Parser";

use strict;

##
## (13-mar-2009 (and earlier in month) kl) -- changes to improve OpenURL 1.0 support
##
## Some new fields are listed in %GODOT::Citation::HOLD_TAB_PARAM_MAPPINGS but are not currently
## used in parser below:
## 
##     rft.advisor
##     url_ver
##     url_ctx_fmt
##

my %RFT_VAL_FMT_TO_REQTYPE_MAP = (
    'info:ofi/fmt:kev:mtx:journal'      => $GODOT::Constants::JOURNAL_TYPE,
    'info:ofi/fmt:kev:mtx:book'         => $GODOT::Constants::BOOK_TYPE,
    'info:ofi/fmt:kev:mtx:dissertation' => $GODOT::Constants::THESIS_TYPE
); 

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::openurl") if $GODOT::Config::TRACE_CALLS;

	##---------------Customized code goes here-------------------##

        ##
	## (13-mar-2009 kl) - no need for cleanup here as GODOT::Citation::pre does not load any value that is all white space
        ##                  - also this logic does not handle fields with multiple values
        ##
	## -in case we haven't already, get rid of any leading and trailing whitespace
	##
	#### foreach (keys %GODOT::Citation::HOLD_TAB_PARAM_MAPPINGS) {
	####    $citation->pre($_, trim_beg_end($citation->pre($_)));
	#### }
        ####

        $citation->parsed('GENRE', $citation->pre('genre'));

	my $title = $citation->pre('TI') || $citation->pre('stitle');

	$citation->parsed('TITLE', $title);
	$citation->parsed('ARTTIT', $citation->pre('atitle'));
  
	$citation->parsed('SERIES', $citation->pre('series'));

	##
	## -put together the first author's name, starting with the 'better' or 'more informative' components
	##

	my($author) = $citation->pre('aulast');
	    
	if ($citation->pre('aufirst'))   {
	    if ($author ne '') { $author .= ", "; }
	    $author .= $citation->pre('aufirst');

	    if ($citation->pre('auinitm')) { $author .= " " . $citation->pre('auinitm'); }
	}
	elsif ($citation->pre('auinit'))   {
	    if ($author ne '') { $author .= ", "; }
	    $author .= $citation->pre('auinit');
	}
	elsif ($citation->pre('auinit1')) {
	    if ($author ne '') { $author .= ", "; }
	    $author .= $citation->pre('auinit1');
	}

        if ($citation->pre('ausuffix')) {
            $author .= ' ' . $citation->pre('ausuffix') if naws($author);
        }

        ##
        ## (13-mar-2009 kl) -- 'au' can occur multiple times  
        ##                  -- extract and see if more info than current author string
        ##        
        my $au_authors_list = $citation->pre_want_listref('au');

        #### debug Dumper($au_authors_list);

        ##
        ## (25-mar-2009 kl) -- it seems that citations from some sources (eg. www.isinet.com:WoK:WOS) are passed such 
        ##                     that the first author is  in the single author fields (ie. aulast, aufirst, auinit) and  
        ##                     any additional authors are passed using the au/rft.au field; 
        ##                  -- thus after checking for a duplicate, we need to prepend this author to the au/rft.au list;
        ##                  -- for now go with an exact match on author name (as opposed to a match on last name) as it is 
        ##                     better that we have a duplicate author than a missing author;
        ##
        my @au_authors = @{$au_authors_list} if defined $au_authors_list; 

        if (naws($author) && scalar(@au_authors)) {
            unshift @au_authors, $author unless (grep { lc($author) eq lc($_) } @au_authors); 
        }
        my $au_authors_statement = join('; ', @au_authors);
        $author = $au_authors_statement if length($au_authors_statement) > length($author);            

        ##
        ## organization or corportation that is the author or creator
        ##
        $author = $citation->pre('aucorp') if aws($author) && $citation->pre('aucorp');
             
	##
	## -is the author for a 'bundle' or an 'individual item' (ie. an article, book chaper, etc)
	##
        ## (08-apr-2009 kl) -- added test for 'atitle' for citations where there is no 'genre'
        ##
	if ((grep {$citation->pre('genre') eq $_} @GODOT::Config::INDIVIDUAL_ITEM_GENRE_ARR) || $citation->pre('atitle')) { 
	    $citation->parsed('ARTAUT', $author); 
	}
	else { 
	    $citation->parsed('AUT', $author); 
	}  

        ##
        ## publisher
        ##

        my $publisher = $citation->pre('pub') || $citation->pre('inst');
	$citation->parsed('PUB', $publisher);

        ##
        ## place of publication or country of publication (dissertation) or country of publication code (dissertation)
        ## 
        my $country_code_string = $citation->pre('cc') ? ('country code:  ' . $citation->pre('cc')) : '';
	my $place = $citation->pre('place') || $citation->pre('co') || $country_code_string;

        #### debug location, ":  place:  ", $place;

	$citation->parsed('PUB_PLACE', $place);

        ##
        ## (25-mar-2009 kl) -- 'rft_id' can occur multiple times  
        ##        
        my $rft_id_list = $citation->pre_want_listref('rft_id');
        my @rft_ids = @{$rft_id_list} if defined $rft_id_list;

	##
	## -standard numbers 
	##

        my $isbn_from_rft_id;
        my $issn_from_rft_id;

        foreach my $rft_id (@rft_ids) {
            if ($rft_id =~ m#^urn\:#) {          
                my($urn, $type, $value) = split(/:/, $rft_id);

                #### debug location, ":  $rft_id--$urn--$type--$value";
              
                $isbn_from_rft_id = $value if aws($isbn_from_rft_id) && $type =~ m#^isbn$#i;      ## -parse out the first isbn;
	        $issn_from_rft_id = $value if aws($issn_from_rft_id) && $type =~ m#^issn$#i;      ## -parse out the first issn;            
            }
        }
 
        my $isbn = $citation->pre('ISBN') || $isbn_from_rft_id;
	$citation->parsed('ISBN', $isbn);

	my $issn = $citation->pre('ISSN') || $issn_from_rft_id || $citation->pre('eissn');
	$citation->parsed('ISSN', clean_ISSN($issn));

	##
	## -volume and issue
	##
	my $vol = $citation->pre('VOL') || $citation->pre('part');
	$citation->parsed('VOL', $vol);

	$citation->parsed('ISS', $citation->pre('ISS'));

        ##
        ## -edition
        ##
	$citation->parsed('EDITION', $citation->pre('edition'));
        
	##
	## -figure out pages
	##
	my $pages  = $citation->pre('PG');
	my $spage  = $citation->pre('spage');
	my $epage  = $citation->pre('epage');
	my $artnum = $citation->pre('artnum');
        my $tpages = $citation->pre('tpages');

	if (aws($pages)) {
	    if ($spage && $epage) { $pages = "$spage-$epage"; }
	    elsif ($spage)        { $pages = $spage;          } 
	    elsif ($artnum)       { $pages = $artnum;         }
            elsif ((grep {$citation->pre('genre') eq $_} @GODOT::Config::BUNDLE_GENRE_ARR) && $tpages) { $pages = $tpages; }
	}
       
	$citation->parsed('PGS', $pages);

	##
	## -what date format do we have?
	##   
	my($date) = $citation->pre('date');
	my($mm);

	if (naws($date)) {
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
   
        ##
        ## $mm can be '00', so force numeric comparision instead of string comparison with '=='
        ##
	$citation->parsed('MONTH', &GODOT::Date::date_mm_to_mon($mm)) unless ($mm == 0);

	if (! $citation->parsed('MONTH')) { $citation->parsed('MONTH', $citation->pre('ssn'))};

	if (! $citation->parsed('MONTH')) {

            if ($citation->pre('quarter')) { 
	        my(%quarter_hash) = ('1' => '1st', '2' => '2nd', '3' => '3rd', '4' => '4th');
	        my $quarter = $citation->pre('quarter');
	        $citation->parsed('MONTH', "$quarter_hash{$quarter} quarter"); 
	    }
            elsif ($citation->pre('chron')) {
                $citation->parsed('MONTH', $citation->pre('chron'));
            }
	}
	
        my @id_namespaces = qw(doi pmid bibcode oai oclcnum);
	my $namespace;
        my $identifier;

        ##
        ## we are not expecting this to be multiple but might be for a poor openurl 0.1 implementation
        ## 
        my $ids_list = $citation->pre_want_listref('id');      
        my @ids = @{$ids_list} if defined $ids_list;

        foreach my $id (@ids) {
	    ($namespace, $identifier) = split(/:/, $id, 2);           
            #### debug location, ":  id -- namespace:  $namespace";
            #### debug location, ":  id -- identifier:  $identifier";
            ##
            ## only take the first value for an identifier
            ##
   	    $citation->parsed(uc($namespace), $identifier) if (grep { $namespace eq $_ } @id_namespaces) && aws($citation->parsed(uc($namespace)));
        }

        foreach my $rft_id (@rft_ids) {
	    if ($rft_id =~ m#^info\:(.+)#) {          
                my $string = $1;
	        ($namespace, $identifier) = split(/\//, $string, 2);      ## split on slash
                #### debug location, ":  rft_id -- namespace:  $namespace";
                #### debug location, ":  rft_id -- identifier:  $identifier";
      	        $citation->parsed(uc($namespace), $identifier) if (grep { $namespace eq $_ } @id_namespaces) && aws($citation->parsed(uc($namespace)));
	    }
        }

        ##
        ## (25-mar-2009 kl) -- the case of 'SICI' below is correct;  see %GODOT::Citation::HOLD_TAB_PARAM_MAPPINGS;
        ##
	$citation->parsed('SICI', $citation->pre('SICI'));
	$citation->parsed('BICI', $citation->pre('bici'));
	$citation->parsed('CODEN', $citation->pre('coden'));

        ##
        ## (10-apr-2009 kl) -- added as part of OpenURL 1.0 improvements;
        ##
        $citation->parsed('THESIS_TYPE', $citation->pre('degree'));

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
	
	my $no_title;

        my $genre = $citation->pre('genre');
        my $rft_val_fmt = $citation->pre('rft_val_fmt');	

	##
	## -'oai' specifies identifier used in Open Archives Initiative  
	##
	## -deal with case seen in 'iopp' where the genre was 'article' but no journal title was given and 
	##  article was only available through the preprint archive
	##
       
	$no_title = ((! $citation->pre('TI')) && (! $citation->pre('stitle'))) ? $TRUE : $FALSE;

        my $reqtype = $GODOT::Constants::UNKNOWN_TYPE;
     
	if ($no_title && ($citation->pre('id') =~ m#^oai:#)) { 
	    $reqtype = $GODOT::Constants::PREPRINT_TYPE; 
	} 
	elsif (($genre) && defined($GODOT::Config::GENRE_TO_REQTYPE_HASH{$genre})) {
	    $reqtype = $GODOT::Config::GENRE_TO_REQTYPE_HASH{$genre};
	}
	elsif (aws($genre) && (defined $RFT_VAL_FMT_TO_REQTYPE_MAP{$rft_val_fmt})) {
            $reqtype = $RFT_VAL_FMT_TO_REQTYPE_MAP{$rft_val_fmt};
        }
	
	##---------------Customized code ends here-------------------##

	return $reqtype;
}


sub run_post_get_req_type {
    return $TRUE;
}

1;

__END__

