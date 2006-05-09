package glog;

require hold_tab;

use GODOT::String;

use strict;

my @CITN_LOG_ARR  = ('_ht_reqtype', 
                     '_ht_title', 
                     '_ht_issn', 
                     '_ht_isbn', 
                     '_ht_arttit');
 
my @CITN_LOG_2_ARR = ('_ht_vol',
                      '_ht_iss',
                      '_ht_year',
                      '_ht_month',
                      '_ht_day',
                      '_ht_pgs');

my @TRANS_LOG_ARR = ('hold_tab_branch', 
                     'hold_tab_dbase', 
                     'hold_tab_msg_addr', 
                     'hold_tab_reqno');

##
## ===> fill this in with whatever matches what is used in your ill module
##

my @PATRON_LOG_ARR = ('PATR_LAST_NAME_FIELD', 
                      'PATR_FIRST_NAME_FIELD',
                      'PATR_LIBRARY_ID_FIELD', 
                      'PATR_PATRON_TYPE_FIELD',
                      'PATR_PATRON_EMAIL_FIELD'
                     );

##------------------------------------------------------------------------------
##
## -ill request logging module
## -save in format suitable for loading into excel
##
## -rules that excel appears to use for comma delimited format are
##
##      1. all double quotes are doubled   (ie.  " ---> "")
##      2. all fields that have double quotes or commas in them are double quoted
##         (ie.   She said "hello, there"  --->  "She said ""hello, there"""      
##

sub ill_log {
    my($log_file, $ill_fields_ref) = @_;

    local(*FP);
    my $item;    

    my $delim = "\t";

    if (! open(FP, ">> $log_file")) {
        &glib::send_admin_email("$0: unable to open $log_file");
        return;
    }

    print FP  &timestamp, $delim;

    my @arr = (@TRANS_LOG_ARR, @CITN_LOG_ARR, @PATRON_LOG_ARR);

    foreach $item (@arr) { 
       print FP &fmt_field(${$ill_fields_ref}{$item}), $delim;
    }

    print FP $$, $delim;        ## -added process id to help debug merged requests problem.....

    my $subscript = 0;

    foreach $item (@CITN_LOG_2_ARR) { 

        print FP &fmt_field(${$ill_fields_ref}{$item});

        ##
        ## -no trailing delimiter  
        ##
        if ($subscript != $#CITN_LOG_2_ARR) { print FP $delim; }   

        $subscript++; 
    }

    print FP "\n";
     
    close(FP);
}

##
## -remove tabs and any other whitespace
##

sub fmt_field {
    my($string) = @_;

    return &GODOT::String::trim_beg_end(&GODOT::String::comp_ws($string));
}

sub timestamp {

     my @timearray = localtime(time);
     my $timestamp = sprintf ("%04d%02d%02d %02d:%02d:%02d", 
                              $timearray[5]+1900, 
                              $timearray[4]+1, 
                              $timearray[3], 
                              $timearray[2], 
                              $timearray[1], 
                              $timearray[0]);
     return $timestamp;
}

##-----------------------------------------------------------------------

