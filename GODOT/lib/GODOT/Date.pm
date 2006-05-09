## GODOT::Date
##
## Copyright (c) 2001, Todd Holbrook, Simon Fraser University
##
## Various string tools related to GODOT functions, including some library
## related things like ISSN/ISBN cleanups, etc.
##

package GODOT::Date;

use strict;

use vars qw(
	@ABBREV_MONTHS
	@LONG_MONTHS
	%ABBREV_TO_NUM
);

@ABBREV_MONTHS = qw( JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC );

@LONG_MONTHS = qw(
	January
	February
	March
	April
	May
	June
	July
	August
	September
	October
	November
	December
);


%ABBREV_TO_NUM = (
	'JAN' => 1,
	'FEB' => 2,
	'MAR' => 3,
	'APR' => 4,
	'MAY' => 5,
	'JUN' => 6,
	'JUL' => 7,
	'AUG' => 8,
	'SEP' => 9,
	'OCT' => 10,
	'NOV' => 11,
	'DEC' => 12
);




##-------------------------dates--------------------------------------------

sub date {
	my($mytime) = @_;

	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($mytime);

	$year = add_cent_tm($year);	   
	my($date) = sprintf("%02d:%02d:%02d  %02d/%02d/%04d",
		$hour, $min, $sec, $mday, $mon + 1, $year);

	return $date;
}

sub date_hh_mm_ss {
	my($mytime) = @_;

	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($mytime);
	$mytime = sprintf("%02d:%02d:%02d", $hour, $min, $sec);

	return $mytime;
}

sub date_yymmdd {	 
	my($mytime) = @_;

	my($sec,$min,$hour,$mday,$mon, $year,$wday,$yday,$isdst) = localtime($mytime);
	my($today) = sprintf("%02d%02d%02d", yy_from_tm($year), $mon + 1, $mday);	
	return $today;
}

sub date_yyyymmdd {	 
	my($mytime) = @_;

	my($sec,$min,$hour,$mday,$mon, $year,$wday,$yday,$isdst) = localtime($mytime);

	$year = add_cent_tm($year);	   

	my($today) = sprintf("%04d%02d%02d", $year, $mon + 1, $mday);	
	return $today;
}

sub date_yy {	 
	my($mytime) = @_;

	my($sec,$min,$hour,$mday,$mon, $year,$wday,$yday,$isdst) = localtime($mytime);
	return sprintf("%02d", yy_from_tm($year));
}

sub date_yyyy {	 
	my($mytime) = @_;

	my($sec,$min,$hour,$mday,$mon, $year,$wday,$yday,$isdst) = localtime($mytime);
	return sprintf("%04d", add_cent_tm($year));
}


sub date_yyyymm {		## yyyymm 
	my($mytime) = @_;
   
	my($sec,$min,$hour,$mday,$mon, $year,$wday,$yday,$isdst) = localtime($mytime);
	$year = add_cent_tm($year);
	
	return sprintf("%04d%02d", $year, $mon + 1); 
}

sub date_mon  {
	my($mytime) = @_;

	my($sec,$min,$hour,$mday,$mon, $year,$wday,$yday,$isdst) = localtime($mytime);
	return $ABBREV_MONTHS[$mon]; 
}

sub date_mm  {
	my($mytime) = @_;

	my($sec,$min,$hour,$mday,$mon, $year,$wday,$yday,$isdst) = localtime($mytime);
	return sprintf("%02d", $mon + 1);  
}

##
## -returns 1..7 for day of week
##
sub date_day_of_week_dd {
	my($mytime) = @_;

	my($sec,$min,$hour,$mday,$mon, $year,$wday,$yday,$isdst) = localtime($mytime);
	return sprintf("%02d", $wday + 1);  
}

sub prev_day_of_week_dd {
	my($mytime) = @_;

	my($sec,$min,$hour,$mday,$mon, $year,$wday,$yday,$isdst) = localtime($mytime);
    
	if ($wday == 0) {
		$wday = 6;
	} else {
		$wday--;
	}

	return sprintf("%02d", $wday + 1);  
}

sub date_dd  {
	my($mytime) = @_;

	my($sec,$min,$hour,$mday,$mon, $year,$wday,$yday,$isdst) = localtime($mytime);
	return sprintf("%02d", $mday);  
}

sub date_ddmmyyyy_hyphens {   ## dd-mm-yyyy 
	my($mytime) = @_;
   
	my($sec,$min,$hour,$mday,$mon, $year,$wday,$yday,$isdst) = localtime($mytime);
	$year = add_cent_tm($year);
	my($today) = sprintf("%02d-%02d-%04d", $mday, $mon + 1, $year);
	
	return $today;
}

sub date_dd_mon_yyyy  {
	my($mytime) = @_;

	my($sec,$min,$hour,$mday,$mon, $year,$wday,$yday,$isdst) = localtime($mytime);
	my($month);

	$year = add_cent_tm($year);
	$month = $ABBREV_MONTHS[$mon]; 

	return sprintf("%02d-%s-%04d", $mday, $month, $year);
}

sub yymmdd_to_dd_mon_yyyy {
	my($yymmdd) = @_;

	my($year, $month);
	$year = add_cent(substr($yymmdd, 0, 2));
	$month = $ABBREV_MONTHS[substr($yymmdd, 2, 2) - 1]; 

	return sprintf("%02d-%s-%04d", substr($yymmdd, 4, 2), $month, $year);
}

sub yyyymmdd_to_dd_mon_yyyy {
	my($yyyymmdd) = @_;

	my($month) = $ABBREV_MONTHS[substr($yyyymmdd, 4, 2) - 1]; 

	return sprintf("%02d-%s-%04d", substr($yyyymmdd, 6, 2), $month,  substr($yyyymmdd, 0, 4));
}



sub date_mm_to_month {  
	my($mm) = @_;

	return $LONG_MONTHS[$mm - 1];	 ## index starts at 0
}

sub date_mm_to_mon {
	my($mm) = @_;
  
	return $ABBREV_MONTHS[$mm - 1];	 ## index starts at 0
}

sub date_mon_to_mm {
	my($mon) = @_;
  
	$mon = uc($mon);

	return sprintf("%02d", $ABBREV_TO_NUM{$mon});	 
}

sub prev_month_mm  {
	my($mytime) = @_;

	my($mon_per_year) = 12;

	my($sec,$min,$hour,$mday,$mon, $year,$wday,$yday,$isdst) = localtime($mytime);
	my($prev_month) = 1 + ($mon + ($mon_per_year - 1)) % $mon_per_year;
	
	return sprintf("%02d", $prev_month);
}

sub prev_month_mon  {
	my($mytime) = @_;

	my($mon, $mon_per_year);

	my($prev_month) = ($mon + ($mon_per_year - 1)) % $mon_per_year;
	
	## index starts at 0
	return $ABBREV_MONTHS[prev_month_mm($mytime) - 1];
}

sub prev_month_month  {
	my($mytime) = @_;

	my($mon, $mon_per_year); 

	my($prev_month) = ($mon + ($mon_per_year - 1)) % $mon_per_year;
	## index starts at 0

	return $LONG_MONTHS[prev_month_mm($mytime) - 1];
}
	
sub prev_month_yy   {
	my($mytime) = @_;

	return substr(prev_month_yyyy($mytime), 2, 2);
}

sub prev_month_yyyy   {
	my($mytime) = @_;

	my($sec,$min,$hour,$mday,$mon, $year,$wday,$yday,$isdst) = localtime($mytime);
	$year = add_cent_tm($year);
	if ($mon == 0) { $year = $year - 1; }  ## current month is January

	return sprintf("%04d", $year);	
}

##
## (04-jan-2000 kl) - see add_cent_tm note
##
sub yy_from_tm {
	my($tm_year) = @_;

	return substr($tm_year + 1900, 2, 2); 

}

##
## (04-jan-2000 kl) - '$year' parameter returned by 'localtime' is based on 'struct tm' and 
##		      is (<year> - 1900) !!!!!  
##
sub add_cent_tm {
	my($year) = @_;

	$year += 1900; 

	return $year;
}

##
## -assumes that the '$year' parameter is the last two digits of the year 
##
sub add_cent {
	my($year) = @_;

	$year += ($year < 70) ? 2000 : 1900; 

	return $year;
}


##--------------------------------------------------------------
1;
	

1;

__END__

=head1 NAME

GODOT::Date - Collection of various date related routines for use in GODOT

=head1 SYNOPSIS

=head1 METHODS


=head1 AUTHORS / ACKNOWLEDGMENTS

Written by Todd Holbrook, based on existing GODOT code by Kristina Long and
others over the years at SFU.

=cut
