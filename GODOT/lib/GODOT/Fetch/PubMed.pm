package GODOT::Fetch::PubMed;
##
## Copyright (c) 2008, Kristina Long, Simon Fraser University
##
## Based on code from CUFTS written by Todd Holbrook.
##
## Documentation (28-mar-2009 kl -- is this the right document?) on the fields used in 
## the returned XML can be found at:
##     
##     http://www.nlm.nih.gov/bsd/licensee/elements_descriptions.html
## 
use base qw(GODOT::Fetch);

use strict;

use HTTP::Request::Common;
use XML::DOM;
use Data::Dumper;
use Encode;           

use GODOT::Config;
use GODOT::Debug;
use GODOT::String;
use GODOT::Constants;
use GODOT::Object;


my $month_lookup = {
    'jan' => '01',
    'feb' => '02',
    'mar' => '03',
    'apr' => '04',
    'may' => '05',
    'jun' => '06',
    'jul' => '07',
    'aug' => '08',
    'sep' => '09',
    'oct' => '10',
    'nov' => '11',
    'dec' => '12',
};

sub url {
    my($self) = @_;

    return 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi';
}


sub add_data {
    my($self, $citation) = @_;

    debug "add_data in GODOT::Fetch::PubMed" if $GODOT::Config::TRACE_CALLS;
	
    my $pmid_for_lookup = $citation->parsed('PMID');
    return $TRUE if aws($pmid_for_lookup);
	
    ##
    ## Lookup meta-data
    ##
    my $start_time = time;

    use LWP::UserAgent;
    my $ua = LWP::UserAgent->new( 'timeout' => 10 );
    $ua->agent("AgentName/0.1 " . $ua->agent);
    
    my $request;
    $request = new HTTP::Request POST => $self->url;
    $request->content_type('application/x-www-form-urlencoded');
    my $param_string = put_query_fields({ 'db'   => 'pubmed', 
                                          'id'   => $pmid_for_lookup, 
                                          'mode' => 'xml',
    		                          'tool' => 'CUFTS' });
    $request->content($param_string);
    my $response = $ua->request($request);

    unless ($response->is_success) {
         debug 'PubMed lookup failed for pmid ' . quote($pmid_for_lookup) . ' -- ' . $response->message; 
         return $FALSE;
    }

    my $returned_data = trim_beg_end($response->content);

    debug "PubMed lookup returned in " . (time - $start_time) . " seconds\n";
    debug $returned_data;
    	
    my $data = parse_pubmed_data($returned_data);
    	
    foreach my $field (qw(TITLE ARTTIT ARTAUT ISSN VOL ISS PGS YYYYMMDD YEAR DAY DOI)) {

        debug "$field:  ", $data->{$field};

    	if (aws($citation->parsed($field)) && naws($data->{$field}) ) {
    	    #### $citation->parsed($field, $data->{$field});
            ##
            ## Andrew Sokolov of Saint-Petersburg State University Scientific Library
            ##
   	    $citation->parsed($field, Encode::encode_utf8($data->{$field}));
    	}
    }
	
    return $TRUE;
}

sub parse_pubmed_data {
    my($input) = @_;

    ##
    ## -see http://www.webreference.com/programming/perl/comments/v.910/2.html
    ## 
    if ($[ < 5.008) { use utf8; }

    my $data = {};

    my $parser = XML::DOM::Parser->new;
    my $doc = $parser->parse($input);

    my $articles = $doc->getElementsByTagName('PubmedArticle');

    if ( $articles->getLength == 0 ) {
        # No results
    } else {
        if ( $articles->getLength > 1 ) {
            warn "Multiple articles returned for PMID.  Processing first one only.";
        }
        my $article = $articles->item(0);

        ##
        ## -change each to separate eval as otherwise a missing field will mean statements coming after will not get run
        ##
        eval { $data->{ARTTIT} = trim_beg_end(($article->getElementsByTagName('ArticleTitle')->item(0)->getChildNodes)[0]->getNodeValue()); };
        eval { $data->{TITLE} = trim_beg_end(($article->getElementsByTagName('Title')->item(0)->getChildNodes)[0]->getNodeValue());         };
        eval { $data->{VOL} = trim_beg_end(($article->getElementsByTagName('Volume')->item(0)->getChildNodes)[0]->getNodeValue());          };
        eval { $data->{ISS} = trim_beg_end(($article->getElementsByTagName('Issue')->item(0)->getChildNodes)[0]->getNodeValue());           };
       
        my $pubdate = $article->getElementsByTagName('PubDate')->item(0);

        my $month;

        eval { $data->{YEAR} = trim_beg_end(($pubdate->getElementsByTagName('Year')->item(0)->getChildNodes)[0]->getNodeValue() );          };
        eval { $month = trim_beg_end(($pubdate->getElementsByTagName('Month')->item(0)->getChildNodes)[0]->getNodeValue() );                };
        eval { $data->{DAY} = trim_beg_end(($pubdate->getElementsByTagName('Day')->item(0)->getChildNodes)[0]->getNodeValue() );            };

        my $mm = (($month =~ /^\d\d?$/) && ($month <= 1) && ($month >= 12)) ? $month : $month_lookup->{lc($month)};

        if ( $data->{YEAR} =~ /^\d{4}$/ ) {
            my $yyyymmdd = $data->{YEAR};

            if ($mm =~ /^\d\d?$/) {
                $yyyymmdd .= $mm;

                if ($data->{DAY} =~ /^\d\d?$/) {
                    $yyyymmdd .= $data->{DAY};
                }
                else {
                    $yyyymmdd .= '00';
                }
      	        $data->{YYYYMMDD} = $yyyymmdd; 
            }
        }

	my $spage;
	my $epage;
	my $pages;

        eval { $spage = trim_beg_end(($article->getElementsByTagName('StartPage')->item(0)->getChildNodes)[0]->getNodeValue()); };
        eval { $epage = trim_beg_end(($article->getElementsByTagName('EndPage')->item(0)->getChildNodes)[0]->getNodeValue());   };

        if (aws($spage)) {
            eval { $pages = trim_beg_end(($article->getElementsByTagName('MedlinePgn')->item(0)->getChildNodes)[0]->getNodeValue());  };
        }

        if (naws($pages) && $pages =~ /^ (\d+) - (\d+) $/xsm ) {
            $spage = $1;
            $epage = $2;

            ##
            ## Change page ranges 1123-33 into 1123 and 1133
            ##
            my $length = length($spage) - length($epage);
            if ($length > 0) {
                $epage = substr($spage, 0, $length) . $epage;
            }
  
            $pages = "$spage-$epage";
        }   

	if (aws($pages) && naws($spage)) {
            $pages = $spage . (naws($epage) ? "-$epage" : '');
        }

	$data->{PGS} = $pages;

        my $issn_nodes = $article->getElementsByTagName('ISSN');
        my $n          = $issn_nodes->getLength;

        foreach my $i ( 0 .. $n - 1 ) {
            my $issn = $issn_nodes->item($i);
            my $attr = $issn->getAttribute('IssnType');

            my $issn_string;
            eval { 
                $issn_string = trim_beg_end(($issn->getChildNodes)[0]->getNodeValue()); 
            };
            if ($issn_string =~ /^ (\d{4}) -? (\d{3}[\dxX]) $/xsm ) {
                $issn_string = "$1$2";
                $data->{ISSN} ||= $issn_string;            
            }
        }

        ##
        ## (06-apr-2009 kl) -- extract doi from <ArticleIdList>
        ##
        ## <ArticleIdList>
        ##    <ArticleId IdType="pii">PCN1792</ArticleId>
        ##    <ArticleId IdType="doi">10.1111/j.1440-1819.2008.01792.x</ArticleId>
        ##    <ArticleId IdType="pubmed">18588585</ArticleId>
        ## </ArticleIdList>
        ##
        my $article_id_lists = $article->getElementsByTagName('ArticleIdList');

        unless ( $article_id_lists->getLength == 0) {
            if ( $article_id_lists->getLength > 1) { warn "Multiple identifier lists returned for PMID.  Processing first one only."; }
            my $article_id_list = $article_id_lists->item(0);

            my $doi;                
            for my $article_id ($article_id_list->getElementsByTagName('ArticleId')) {

                if ($article_id->getAttribute('IdType') eq 'doi') { 
                    eval { $doi = trim_beg_end(($article_id->getChildNodes)[0]->getNodeValue); };      
                    $data->{DOI} = $doi unless aws($doi);
                    last;   ## -assume there will only be one doi
	        }
            }
	}

        ##
        ## (28-mar-2009 kl) -- extract authors from <AuthorList>
        ##
        ## from http://www.nlm.nih.gov/bsd/licensee/elements_descriptions.html:
        ##
        ## USE OF LISTS AND ATTRIBUTE "CompleteYN"
        ## Three of the elements (<AuthorList>, <GrantList>, and <DataBankList>) use "lists" with the 
        ## corresponding attribute of 'CompleteYN". 'Y', meaning Yes, represents that NLM has entered 
        ## all list items that appear in the published journal article. 'N', meaning No, represents that NLM 
        ## has not entered all list items that appear in the published journal article. The latter case 
        ## (incomplete list) occurs on records created during periods of time when NLM policy was to enter 
        ## fewer than all items that qualified. NLM recommends the following when encountering 'N' for 
        ## the element lists:
        ## 
        ## <AuthorList> when attribute = N, then supply the literal "et al." after last author name
        ##               

        my @statement_authors;
        my $author_lists = $article->getElementsByTagName('AuthorList');

        unless ( $author_lists->getLength == 0) {

            if ( $author_lists->getLength > 1) {  warn "Multiple author lists returned for PMID.  Processing first one only."; }

            my $author_list = $author_lists->item(0);
            my $is_complete_author_list = ($author_list->getAttribute('CompleteYN') eq 'Y') ? $TRUE : $FALSE; 

            for my $author ($author_list->getElementsByTagName('Author')) {
                my ($last_name, $fore_name, $suffix, $collective_name);
                
                if ($author->getAttribute('ValidYN') eq 'Y') { 
             
                    eval { $last_name = trim_beg_end($author->getElementsByTagName('LastName')->item(0)->getFirstChild->getNodeValue); };
                    eval { $fore_name = trim_beg_end($author->getElementsByTagName('ForeName')->item(0)->getFirstChild->getNodeValue); };
                    eval { $suffix = trim_beg_end($author->getElementsByTagName('Suffix')->item(0)->getFirstChild->getNodeValue); };

                    my $full_name = $last_name;
                    $full_name .= ", $fore_name $suffix" unless aws($fore_name) && aws($suffix);
                    $full_name = trim_beg_end($full_name);

                    ##
                    ## -assumes there would never be both a personal and collective name in the same <Author> element
                    ##
                    if (aws($full_name)) {
                        eval { $collective_name = trim_beg_end($author->getElementsByTagName('CollectiveName')->item(0)->getFirstChild->getNodeValue); };
                        $full_name = trim_beg_end($collective_name);
                    }

                    push @statement_authors, $full_name unless aws($full_name); 
	        }
            }

            push @statement_authors, 'et al.' if (scalar @statement_authors) && (! $is_complete_author_list);

            ##
            ## -assume all fetch records are for a contribution not an item
            ## 
            $data->{ARTAUT} = join('; ', @statement_authors);              
        }
    }
    return $data;
}

1;


