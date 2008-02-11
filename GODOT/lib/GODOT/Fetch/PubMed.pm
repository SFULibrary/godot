package GODOT::Fetch::PubMed;
##
## Copyright (c) 2008, Kristina Long, Simon Fraser University
##
## Based on code from CUFTS written by Todd Holbrook.
##
use base qw(GODOT::Fetch);

use strict;

use HTTP::Request::Common;
use XML::DOM;
use Data::Dumper;

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
    	
    foreach my $field (qw(TITLE ARTTIT ISSN VOL ISS PGS YYYYMMDD YEAR DAY)) {

        debug "$field:  ", $data->{$field};

    	if (aws($citation->parsed($field)) && naws($data->{$field}) ) {
    	    $citation->parsed($field, $data->{$field});
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
    }
    return $data;
}

1;
