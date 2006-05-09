package GODOT::Parser::MARC;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;
use GODOT::String;

@ISA = "GODOT::Parser";


use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::MARC") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##


	$citation->parsed('ISBN', clean_ISBN(strip_subfield(keep_marc_subfield($citation->pre('T020'), [qw(a)]))));
	$citation->parsed('ISSN', clean_ISSN(strip_subfield(keep_marc_subfield($citation->pre('T022'), [qw(a)]), 1)));

        $citation->parsed('TITLE', strip_subfield(keep_marc_subfield($citation->pre('T245'), [qw(a b)]))); 
        my $title = $citation->parsed('TITLE');
        $title  =~ s#\/\s*##g;          ## -remove trailing '/'
        $citation->parsed('TITLE', $title);

        $citation->parsed('EDITION', strip_subfield(keep_marc_subfield($citation->pre('T250'), [qw(a b)]))); 

        ## -get call numbers -- try 090 then 099 
        $citation->parsed('CALL_NO', strip_subfield(keep_marc_subfield($citation->pre('T090'), [qw(a b)])));     
        if (aws($citation->parsed('CALL_NO'))) { 
            $citation->parsed('CALL_NO', strip_subfield(keep_marc_subfield($citation->pre('T099'), [qw(a)])));     
        }

        ##
        ## -use year and month from article info, if collected now later, logic will not overwrite
        ##

        if (! $citation->is_journal()) { 
            $citation->parsed('MONTH', strip_subfield(keep_marc_subfield($citation->pre('T260'), [qw(c)])));           
       
            my $tmp = substr($citation->pre('T008'), 7, 4);
            $citation->parsed('YEAR', $tmp);                              
        }
        ##
        ## marc ??? 502-a - avail at UBC ?? - need to do some processing so cleaner ???
        ##
        $citation->parsed('THESIS_TYPE', strip_subfield(keep_marc_subfield($citation->pre('LV'), [qw(c)])));   

        $citation->parsed('REPNO', strip_subfield(keep_marc_subfield($citation->pre('T027'), [qw(a)])));   

        ##
        ## marc 260 - 8.. ??? !!!!!! 
        ##
        $citation->parsed('PUB', strip_subfield(keep_marc_subfield($citation->pre('T260'), [qw(a b)])));   
        $citation->parsed('SERIES', strip_subfield(keep_marc_subfield($citation->pre('T440'), [qw(a n p h v)])));
        ##   
        ## marc 1.. and 700 !!!!!! add logic here
        ##
        $citation->parsed('AUT', strip_subfield(keep_marc_subfield($citation->pre('T100'), [qw(a b)])));        
        $citation->parsed('URL', strip_subfield(keep_marc_subfield($citation->pre('T856'), [qw(u)])));        

        if ($citation->get_dbase()->dbase() eq 'ecdb') { 
            $citation->parsed('SYSID', strip_subfield(keep_marc_subfield($citation->pre('T035'), [qw(a l)]))); 
        }
        elsif (grep {$citation->get_dbase()->dbase() eq $_} ('sfu_iii', 'cisti', 'usask')) {  

            $citation->parsed('SYSID', strip_subfield(keep_marc_subfield($citation->pre('T907'), [qw(a)]))); 

            ##
            ## -strip off '.b' and final check digit (ie. .b13904632 ===> 1390463)
            ## 
            if ($citation->get_dbase()->is_iii_database()) {
                 my $sysid = $citation->parsed('SYSID');
                 $sysid =~ s#^\.b##;
                 $sysid =~ s#\d$##;                
                 $citation->parsed('SYSID', $sysid);
            }
        }
        else { 
            $citation->parsed('SYSID', $citation->pre('T001')); 
        }

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::MARC") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##


	my $t000 = $citation->pre('T000');
	my $t008 = $citation->pre('T008');

        ##
        ## (15-may-2002 kl) - there appears to be a bug in slri whereby the '000' field is being prepended with some junk: 
        ## 
        ##                        eg. hold_tab_t000 = 1.2.840.10003.5.10&00525cas  2200181   4500 
        ##
        ##                  - need to ask Calvin on his return from vacation
        ##                  - for now just add temporary fix here
        ##

        $t000 =~ s#^[0-9\.]+&##;

        warn "t000:  $t000\n";

        my($bib_level) = substr($t000, 7, 1);        ## -Bibliographic Level (position 7 from MARC leader)     

        ##
        ## !!!! need logic to deal with t008[24-27] for 'computer file', 'cartographic material', 'mixed material', etc !!!!
        ##

        if    ($bib_level eq 'b' ||  $bib_level eq 's') { $reqtype = $GODOT::Constants::JOURNAL_TYPE;  }
        else                                            { $reqtype = $GODOT::Constants::BOOK_TYPE;     }

        if ($reqtype eq $GODOT::Constants::BOOK_TYPE) {

            my($contents) = substr($t008, 24, 4);

            if ($contents =~ /m/)   { $reqtype = $GODOT::Constants::THESIS_TYPE; }
            if ($contents =~ /x/)   { $reqtype = $GODOT::Constants::TECH_TYPE;   }

            ##
            ## -conference or meeting publication [0|1]
            ##

            if (substr($t008, 29, 1) eq '1')  { $reqtype = $GODOT::Constants::CONFERENCE_TYPE; }   

        }
        ##
        ## -if this is a union serials list, then assume all items are journals
        ##
        if (grep {$citation->get_dbase()->dbase() eq $_} ('csti', 'ecdb', 'soul')) {                   

            $reqtype = $GODOT::Constants::JOURNAL_TYPE; 
        }

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

