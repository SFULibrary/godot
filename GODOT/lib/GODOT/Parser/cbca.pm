package GODOT::Parser::cbca;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;
use GODOT::String;

@ISA = "GODOT::Parser";



use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::cbca") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	##---------------Customized code goes here-------------------##

	my $source = $citation->parsed('SOURCE');

	if ($citation->dbase_type() eq 'erl')  {

	    if (! aws($source))  {

		if ($citation->is_book()) {
		    my $title = $citation->parsed('TITLE');
		    $title =~ s/^\(?(.*)\s*\/\/\s*[Bb]ook\s*\)?\s*$/$1/;
		    $citation->parsed('TITLE', $title);
		    my $pub = $source;
		    $pub =~ s/^(.*)\s*,\s*\d{2,4}\s*\.?$/$1/;
		    $citation->parsed('PUB', $pub);
		} else {
		    my $title;
		    ($title) = split(/,/,$source,2);
		    $citation->parsed('TITLE', $title);

		    my $yearIn2digits = substr($citation->parsed('YEAR'),2,2);

		    my $year = $citation->parsed('YEAR');
		    if ($source =~ m#\s+(\S*)(\s+\d+){0,1},\s+$year#)  {
			$citation->parsed('MONTH', $1);
		    }

		    elsif ($source =~ m#\s+(\S+)(\s[\d\/]+)?\'$yearIn2digits#)  {

			$citation->parsed('MONTH', $1);
			##
			## CBCA Fulltext reference uses these acronyms for month names ###
			##

			my $month = $citation->parsed('MONTH');
			$month =~ s#D#December#; 
			$month =~ s#N#November#;
			$month =~ s#O#October#;
			$month =~ s#S(?!pr|um)#September#;
			$month =~ s#Ag#August#;
			$month =~ s#Jl#July#;
			$month =~ s#Je#June#;
			$month =~ s#My#May#;
			$month =~ s#Ap#April#;
			$month =~ s#Mr#March#;
			$month =~ s#F(?!al)#February#;
			$month =~ s#Ja#January#;
			$month =~ s#Spr(?!ing)#Spring#;
			$month =~ s#Summ?(?!er)#Summer#;
			$month =~ s#Fal(?!l)#Fall#;
			$month =~ s#Wint?(?!er)#Winter#;
			$citation->parsed('MONTH', $month);
		    }
		  
		    if ($source =~ m#v\.([\055\d]+(\([\s\w\055]+\))*).*#)  {
			$citation->parsed('VOLISS', $1);						        
		    }

		    if ($source =~ m#pg (\S+)\.#)  {
			$citation->parsed('PGS', $1);
		    }
	
		    if ($citation->parsed('VOLISS') =~ m#([\055\d]+)\s*\(([\s\w\055]+)\)#)  {

			$citation->parsed('VOL', $1);
			$citation->parsed('ISS', $2);
		    }	
		}
	    }
	}
	##
	## (16-sept-1998 kl) - added parsing for CBCA linking from SLRI
	##
	elsif ($citation->dbase_type() eq 'slri') {  

	    #### (008 020 022 027 035 100 110 245 250 260 440 773 775 852 926 920 979 984 988 992)   

	    $citation->parsed('ARTAUT', $citation->pre('T100'));
	    my $artaut = $citation->parsed('ARTAUT');
	    if (aws($artaut)) {  
		$artaut .= '; ';
	    }	
	    $artaut .= $citation->pre('T110');
	    $citation->parsed('ARTAUT', $artaut);

	    $citation->parsed('ARTTIT', $citation->pre('T245')); 
	    $citation->parsed('EDITION', $citation->pre('T250')); 

	    if ($citation->pre('T926') eq 'Fulltext') {  $citation->fulltext_available(1); }

	    $citation->parsed('ISBN', $citation->pre('T020')); 
	    $citation->parsed('ISSN', $citation->pre('T022')); 

	    $citation->parsed('YEAR', $citation->pre('T984')); 

	    ##  volume, issue, month, pages logic
	    ##  !!!!????? use pd=920 to get ddmmyy for month ??? or do we want text ????
	
	    $citation->parsed('MONTH', $citation->pre('T775'));      ## -default  

	    ## !!!!! -for now handle these through default above
	    ## 
	    ## My 28'98
	    ## 1979 pg 265-83
	    ## [1980?]
	    ## Jan 22, 1981
	    ##

	    ##
	    ## v.71(9) My 29'98 pg 74-79 
	    ## v.11 Spring 1981 pg 64-76
	    ##
	    if ($citation->pre('T775') =~ m#^\s*v.(.+)\s*\((.+)\)\s+(.+)\s+pg\s+(.+)$#) { 

		$citation->parsed('VOL', $1);
		$citation->parsed('ISS', $2);
		$citation->parsed('MONTH', $3);
		
		$citation->parsed('PGS', $4);     
	    }
	    ##
	    ## My 30/Je 1'98 pg 31   
	    ## My 29'98 pg A16
	    ##
	    elsif ($citation->pre('T775') =~ m#^\s*(.+)\s+pg\s+(.+)$#) {
		$citation->parsed('MONTH', $1);
		$citation->parsed('PGS', $2);     
	    }
	    ##
	    ## (439) My 25'98
	    ##
	    elsif ($citation->pre('T775') =~ m#^\s*\((.+)\)\s+(.+)$#) {      
		$citation->parsed('ISS', $1);
		$citation->parsed('MONTH', $2);
	    }

	    $citation->parsed('MLOG_NO', $citation->pre('T852')); 
	    ##
	    ## !!!! -add cy=988 later 
	    ##
	    $citation->parsed('PUB', $citation->pre('T260')); 
	    $citation->parsed('REPNO', $citation->pre('T027')); 
	    $citation->parsed('SERIES', $citation->pre('T440')); 
	    $citation->parsed('SYSID', $citation->pre('T035')); 
	    $citation->parsed('THESIS_TYPE', $citation->pre('T992')); 
	    $citation->parsed('TITLE', $citation->pre('T773')); 
	    
	    if ($citation->is_tech()) {
		    if ($citation->parsed('ARTTIT')) {
			    $citation->parsed('TITLE', $citation->parsed('ARTTIT'));
			    $citation->parsed('ARTTIT', "");
		    }
	    }

	    if ($citation->is_book()) {
		$citation->parsed('TITLE', $citation->parsed('ARTTIT'));
		$citation->parsed('ARTTIT', "");
		my $title = $citation->parsed('TITLE');
		$title =~ s/^\((.*)\)$/$1/;
		$title =~ s/^(.*)\s*\([Bb]ook\)$/$1/;
		$citation->parsed('TITLE', $title);
		$citation->parsed('AUT', $citation->parsed('ARTAUT'));
		$citation->parsed('ARTAUT', "");
		# Fix the screwy "Author. (Title)" format that is used occasionally.
		if ($citation->parsed('TITLE') =~ m/^(.*)\.\s*\((.*)\)\s*$/) {
			if ($1 eq $citation->parsed('AUT')) {
			    $citation->parsed('TITLE', $2);
		    }
		}
	    }
	    my $arttit = $citation->parsed('ARTTIT');
	    $arttit =~ s/^\[(.*)\]$/$1/;
	    $citation->parsed('ARTTIT', $arttit);
	}


	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::cbca") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

	if ($citation->parsed('ISSN') eq "") {
	    if ($citation->parsed('ISBN') ne "") {
		    $reqtype = $GODOT::Constants::BOOK_TYPE;
	    } else {
		if ( ($citation->pre('T773') =~ /\w/) || ($citation->pre('SO') =~ /\w/)) {
		    $reqtype = $GODOT::Constants::JOURNAL_TYPE;
		} else {
		    $reqtype = $GODOT::Constants::TECH_TYPE;
		}
	    }
	}

	##---------------Customized code ends here-------------------##

	return $reqtype;
}

sub pre_parse{
	my ($self, $citation) = @_;
	debug("pre_parse() in GODOT::Parser::cbca") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::pre_parse($citation); 

	if ($citation->dbase_type() eq 'slri') {  
	    my ($tmpstr, $key);
	    foreach $key (keys %GODOT::Citation::HOLD_TAB_PARAM_MAPPINGS) {
		$tmpstr = $citation->pre($key);
		$tmpstr = strip_subfield($tmpstr);
		$citation->pre($key, $tmpstr);
	    }
	}
}

1;

__END__

