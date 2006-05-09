package clink;

use CGI qw(-no_xhtml :standard);      

use GODOT::CUFTS;
use GODOT::String;
use GODOT::Debug;

use strict;

my $TRUE  = 1;
my $FALSE = 0;

my %SERVICE_TEXT = (

    'database'             => 'Check the <B>database</B> for a link to the article online',
    'journal'              => 'Check the <B>journal</B> for a link to the article online',
    'table of contents'    => 'Check the <B>list of articles</B> for a link to article online',
    'fulltext'             => '<B>Article</B> may be available online'
);


##-----------------------------------------------------------------------------------------------------------
##                                      misc-func
##-----------------------------------------------------------------------------------------------------------

sub coverage_text {
    my($ft_start_date, $ft_end_date, $ft_start_volume, $ft_end_volume) = @_;    

    my($string);

    if ($ft_start_date || $ft_start_volume) {   $string .= "Available for ";   }

    if ($ft_start_date) { 

        $string .= " $ft_start_date to " . (($ft_end_date) ? $ft_end_date : "the present");
    }
   
    if ($ft_start_date && $ft_start_volume) {   $string .= " and  for ";  }         

    if ($ft_start_volume) { 

        $string .= "volumes $ft_start_volume to " . (($ft_end_volume) ? $ft_end_volume : "the present");
    }

    if ($string eq '') {
        
        if ($ft_end_date || $ft_end_volume) { $string .= "Available up to "; }

        $string .= ($ft_end_date) ? $ft_end_date : $ft_end_volume;  
    }

    if ($string ne '') { $string .= "."; }
 
    $string;
}


sub view_text {
    my($service, $result) = @_;

    my $text;
    my $title = GODOT::String::trim_beg_end($result->title);

    if (($service->name eq 'fulltext') && ($title)) {

        $text = '<B>Article</B> (' . $title  .  ') may be available online';
    }
    else {

        $text = $SERVICE_TEXT{$service->name};
    }

    #### return '<FONT COLOR="RED">' . $text . '</FONT>';
    return $text;
}


sub fmt_display_name {
    my($fmt) = @_;


    return '';
    #### $FMT_DISPLAY_HASH{$fmt};                                                                                                 
}


##---------------------------------------------------------------------------------------------------------------------------
##
## -query CUFTS fulltext server
## 
## -returns a GODOT::CUFTS::Search object
## 

sub cufts_server_query {
    my($config, $assoc_sites, $is_bccampus) = @_;

    my(%field_hash);
    my($start_page, $auth_last, $auth_first, $junk, $field_str, $ft_server_url, $issn, $isbn, $exact_title); 

    ($start_page, $junk) = split(/[,\055]/, param($gconst::PGS_FIELD), 2);
    ($auth_last, $junk)  = split(/[,\055;]/, param($gconst::ARTAUT_FIELD), 2);      
    ($junk, $auth_first) = split(/[,\055]/, param($gconst::ARTAUT_FIELD), 2);      

    $start_page = trim_beg_end($start_page);
    $auth_last  = trim_beg_end($auth_last);
    $auth_first = trim_beg_end($auth_first);


    $issn = param($gconst::ISSN_FIELD);         ## (23-mar-2000 kl) - make sure ISSN is in 9999-9999 format
    $issn =~ s#[\055\s]##g;
    $issn = clean_ISSN($issn, $TRUE);

    $isbn = param($gconst::ISBN_FIELD);
    $isbn =~ s#[\055\s]##g;

    $exact_title = param($gconst::TITLE_FIELD);


    ##
    ## -need date in YYYY-MM-DD, YYYY-MM or YYYY format
    ##
    
    my $date;

    #### open TODD, '>>/tmp/todd1';
    #### print TODD "!!!! $exact_title YYYYMMDD_FIELD: " . param($gconst::YYYYMMDD_FIELD) . "\n";

    if (param($gconst::YYYYMMDD_FIELD) =~ m#^\d{8,8}$#) {

	#### print TODD '!!!! Using YYYYMMDD_FIELD: ' . param($gconst::YYYYMMDD_FIELD) . "\n";

        $date = substr(param($gconst::YYYYMMDD_FIELD), 0, 4) . '-' . 
                substr(param($gconst::YYYYMMDD_FIELD), 4, 2) . '-' . 
                substr(param($gconst::YYYYMMDD_FIELD), 6, 2);        
    }
    elsif (param($gconst::YEAR_FIELD) =~ m#^\d{4,4}$#) {
        $date = param($gconst::YEAR_FIELD);

	if (param($gconst::MONTH_FIELD) =~ m#^\d{1,2}$#) {
		$date .= '-' . param($gconst::MONTH_FIELD);
		
		if (param($gconst::DAY_FIELD) =~ m#^\d{1,2}$#) {
			$date .= '-' . param($gconst::DAY_FIELD);
		}
	}
    }

    #### close TODD;


    ##
    ## -create url for cufts server
    ##
    ## -commented out 'authLast' and 'authFirst' as it is hard to extract them with any reliability
    ##
    ## -!!!!!!!!!!!!!!!!!!!!!!!!!!!! future change - assign genre dynamically !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ##

    %field_hash = ('genre'      => 'article',

                   'title'      => trim_beg_end($exact_title),
                   'issn'       => trim_beg_end($issn),
                   'isbn'       => trim_beg_end($isbn),

                   'atitle'     => trim_beg_end(param($gconst::ARTTIT_FIELD)),
                   'volume'     => trim_beg_end(param($gconst::VOL_FIELD)),
                   'issue'      => trim_beg_end(param($gconst::ISS_FIELD)),
                   'spage'      => trim_beg_end($start_page),
                   'sici'       => trim_beg_end(param($gconst::SICI_FIELD)),

                   'date'       => $date                                                                                     
                  );


    #### foreach (keys %field_hash) { debug "$_ = $field_hash{$_}"; }

    my $citation = new GODOT::CUFTS::Citation;

    foreach my $field (keys %field_hash) { $citation->$field($field_hash{$field}); }


    use GODOT::CUFTS::Site;

    my $tmp = naws($config->link_name) ? $config->link_name : $config->name;

    my $site = new GODOT::CUFTS::Site { 'site' => [ $tmp ], 
                                        'assoc_sites' => [ $assoc_sites ],
                                        'is_bccampus' => [ $is_bccampus ]};


    #### debug "++++++++++++++++++++++ is_bccampus:  $is_bccampus";
    #### debug "------------------";
    #### debug $site->tagged; 
    #### debug "------------------";;

    my $search = new GODOT::CUFTS::Search { 'citation'    => [ $citation ], 
                                            'site'        => [ $site ] };

    #### debug "\n----------------------------------------------------\n",
    ####       $search->tagged,
    ####       "\n----------------------------------------------------\n";

    $search->search;

    #### if (! $search->result) {
    ####    debug "\n--- result ---:  ", $search->error_message, "\n\n";
    #### }
    #### else {
    ####    debug "\n----------------------------------------------------\n",
    ####           $search->tagged,
    #### 	  "\n----------------------------------------------------\n";
    #### }

    return $search;
}

##-----------------------------------------------------------------------------------------------------------

1;




