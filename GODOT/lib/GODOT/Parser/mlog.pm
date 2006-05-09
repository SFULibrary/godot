package GODOT::Parser::mlog;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;
use GODOT::String;

@ISA = "GODOT::Parser";


use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::mlog") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##

	if ($citation->dbase_type() eq 'erl')  {

	    if ($citation->is_journal()        # journals
		    || $citation->is_book())   # monograph and conference
	    {
		# Sidney, BC: Dept of Fisheries &;Oceans, 1995. xiii, 138p.
		# West Vancouver, BC: Environment Canada, 1993. iii, 15 p. Bibliography.
		# Ottawa: Environment Canada, 1991.viii, 11, viii, 12 p..
		# Ottawa: Environment Canada, 1990.vii, 76 p. Bibliography; Maps.
		# Edmonton: Alberta Environment, 1990. 51 p. Maps.

		my $restv = comp_ws($source);

		if ($restv =~ m#^\s*(.+),\s+(\d\d\d\d)\.\s*(.+)\s*p\..*#) {
		    $citation->parsed('TITLE', $1);
		    $citation->parsed('YEAR', $2);
		    $citation->parsed('MONTH', '');
		    my $tmpstr = $3;
		    if ($tmpstr =~ m#^\s*(\w),\s*(\d+)\s*#) {	# xiii, 138
			$citation->parsed('VOL', $1);
			$citation->parsed('ISS', '');
			$citation->parsed('PGS', $3);
		    }
		    elsif ($tmpstr =~ m#^\s*(\w),\s*(\d+),\s*\w,\s*(\d+)\s*#) {  # viii, 11, viii, 12
			$citation->parsed('VOL', $1);
			$citation->parsed('ISS', $2);
			$citation->parsed('PGS', $3);
		    }
		    elsif ($tmpstr =~ m#^\s*(\d+)\s*#) {		# 51
			$citation->parsed('VOL', '');
			$citation->parsed('ISS', '');
			$citation->parsed('PGS', $1);
		    }
		}
	    }

	    $citation->parsed('MLOG_NO', $citation->pre('MN'));    ## -microlog number
	}
	elsif ($citation->dbase_type() eq 'slri') {    

	    $citation->parsed('ARTAUT', $citation->pre('T100'));
	    my $artaut = $citation->parsed('ARTAUT');
	    if (aws($artaut)) {  $artaut .= '; '; }
	    $artaut .= $citation->pre('T110');
	    $citation->parsed('ARTAUT', $artaut);

	    $citation->parsed('ARTTIT', $citation->pre('T245'));
	    $citation->parsed('EDITION', $citation->pre('T250'));
	    $citation->parsed('FTREC', $citation->pre('T926'));

	    $citation->parsed('ISBN', $citation->pre('T020'));
	    $citation->parsed('ISSN', $citation->pre('T022'));

	    $citation->parsed('YEAR', $citation->pre('T984'));

	    if ($citation->pre('T250') =~ m#^(\d+).*?(\d+)\s+p#i) {
	       $citation->parsed('YEAR', $1);
	       $citation->parsed('PGS', $2);
	    }


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
        $citation->parsed('SYSID', $citation->pre('T035'));
        $citation->parsed('THESIS_TYPE', $citation->pre('T992'));
        $citation->parsed('TITLE', $citation->pre('T773'));
        $citation->parsed('SERIES', $citation->pre('T440'));
        if (! aws($citation->parsed('SERIES')))
        {
           if ($citation->parsed('SERIES') =~ m|^(.*?);(.*$)|)
           {
              my ($before_semi) = $1;
              my ($after_semi)  = $2;
              # remove following and trailing brackets '(', ')'
              $before_semi =~ s|^\(||;
              $after_semi  =~ s|\)$||;
              $after_semi  =~ s|^\s+||;
              $after_semi  =~ s|\s+$||;
              #
              if ($after_semi =~ m|no|)
              {
                 if ($after_semi =~ m|no.*?([\d-]+)|)
                 {
                     $citation->parsed('ISS', $1);
                 }
              }
              #
              elsif ($after_semi =~ m|#|)
              {
                 if ($after_semi =~ m|^.*?#.*?([\d-]+).*$|)
                 {
                     $citation->parsed('ISS', $1);
                 }
              }
              #
              elsif ($after_semi =~ m|^\s*?([\d-]+).*$|)
              {
                 $citation->parsed('ISS', $1);
              }
              #
              elsif ($after_semi !~ m|ISSN|i)
              {
                 $citation->parsed('REPNO', $after_semi);
              }
              #
              else
              {
                 # probably no ISS_FIELD
              }
              $citation->parsed('SERIES', $before_semi);
           }
           else
           {
              my $series = $citation->parsed('SERIES');
              $series =~ s|^\(||;
              $series =~ s|\)$||;
              $citation->parsed('SERIES', $series);
           }
        }
        if ($citation->is_tech()) {
                if ($citation->parsed('ARTTIT')) {
                        $citation->parsed('TITLE', $citation->parsed('ARTTIT'));
                        $citation->parsed('ARTTIT', "");
                }
        }

        if (($citation->is_book()) ||
            ($citation->is_conference())) {
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
        if ($citation->is_thesis()) {
                if ($citation->parsed('ARTTIT')) {
                        $citation->parsed('TITLE', $citation->parsed('ARTTIT'));
                        $citation->parsed('ARTTIT', "");
                }
                if ($citation->parsed('ARTAUT')) {
                        $citation->parsed('AUT', $citation->parsed('ARTAUT'));
                        $citation->parsed('ARTAUT', "");
                }
                if ($citation->parsed('EDITION')) {
                        $citation->parsed('EDITION', "");
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
        debug("get_req_type() in GODOT::Parser::mlog") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

	if ($citation->dbase_type() eq 'erl') {
	    if ($citation->parsed('PUBTYPE') =~ m#conference#i) {
		$reqtype = $GODOT::Constants::BOOK_TYPE;
	    }
	}
	elsif ($citation->dbase_type() eq 'slri') {
	## determine request type
	    if ($citation->pre('T008') =~ m#conference#i) {
	       $reqtype = $GODOT::Constants::CONFERENCE_TYPE;
	    }
	    elsif (($citation->pre('T008') =~ m#thesis#i) || ($citation->pre('T008') =~ m#these#i)) {
	       $reqtype = $GODOT::Constants::THESIS_TYPE;
	    }
	    elsif ((! aws($citation->pre('T440'))) && (! aws($citation->pre('T022'))))
	    {
	       $reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE;
	    }
	    else
	    {
	       $reqtype = $GODOT::Constants::BOOK_TYPE;
	    }

	}

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


sub pre_parse{
	my ($self, $citation) = @_;
	debug("pre_parse() in GODOT::Parser::mlog") if $GODOT::Config::TRACE_CALLS;

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

