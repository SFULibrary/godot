package GODOT::RefWorks::RIS;
## 
## Originally GODOT::CitationManager::ExportFilters::RIS.
## Copyright (c) 2001, Todd Holbrook, Simon Fraser University
##
## Modified by Kristina Long for exporting citation in GODOT to RefWorks (20-apr-2005)
##
## Formats citation in GODOT::Citation object to RIS format for RefWorks import.
## 

use GODOT::Object;
use GODOT::Debug;

push @ISA, 'GODOT::Object';

use strict;

sub new {
    my ($class) = @_;

    my $self = {};
    return bless $self, $class;
}

sub export_citation {
	my ($self, $citation) = @_;
	        
 	if (!defined($citation)) {
		$self->_set_error('Error, citation reference passed into GODOT::RefWorks::RIS::export_citation is undef or not a HASH');
		return undef;
	}

	my $output;

	# Get reference type
	my $reqtype = $citation->parsed('REQTYPE');

	if ($reqtype =~ /^journal/i) {
		$output .= "TY  - JOUR\n";
		$output .= 'JF  - ' . $citation->parsed('TITLE') . "\n";
		$output .= 'T1  - ' . $citation->parsed('ARTTIT') . "\n";
	} elsif ($reqtype =~ /^book$/i) {
		$output .= "TY  - BOOK\n";
		$output .= 'T1  - ' . $citation->parsed('TITLE') . "\n";
	} elsif ($reqtype =~ /^book-article$/i || $reqtype =~ /^chapter$/i) {
		$output .= "TY  - CHAP\n";
		$output .= 'T1  - ' . $citation->parsed('ARTTIT') . "\n";
		$output .= 'BT  - ' . $citation->parsed('TITLE') . "\n";
	} elsif ($reqtype =~ /^tech/i) {
		$output .= "TY  - RPRT\n";
		$output .= 'T1  - ' . $citation->parsed('TITLE') . "\n";
	} elsif ($reqtype =~ /^thesis/i) {
		$output .= "TY  - THES\n";
		$output .= 'T1  - ' . $citation->parsed('TITLE') . "\n";
	} elsif ($reqtype =~ /^conference/i) {
		$output .= "TY  - CONF\n";
		$output .= 'T1  - ' . $citation->parsed('TITLE') . "\n";
	} elsif ($reqtype =~ /^preprint/i) {
	        $output .= "TY  - INPR\n";
        }

        $output .= 'T3  - ' . $citation->parsed('SERIES') . "\n" if defined($citation->parsed('SERIES') );


	if (defined($citation->parsed('ARTAUT'))) {
		$output .= 'AU  - ' . join("\nAU  - ", split(/\s*;\s*/, $citation->parsed('ARTAUT'))) . "\n";
		$output .= 'ED  - ' . join("\nED  - ", split(/\s*;\s*/, $citation->parsed('AUT'))) . "\n" if defined($citation->parsed('AUT'));
	} else {
		$output .= 'AU  - ' . join("\nAU  - ", split(/\s*;\s*/, $citation->parsed('AUT'))) . "\n";
	}

	$output .= 'PB  - ' . $citation->parsed('PUB') . "\n" if defined($citation->parsed('PUB'));
	$output .= 'M1  - ' . $citation->parsed('CALL_NO') . "\n" if defined($citation->parsed('CALL_NO'));
	$output .= 'M2  - ' . $citation->parsed('SYSID') . "\n" if defined($citation->parsed('SYSID'));
	$output .= 'IS  - ' . $citation->parsed('ISS') . "\n" if defined($citation->parsed('ISS'));
	$output .= 'UR  - ' . $citation->parsed('URL') . "\n" if defined($citation->parsed('URL'));

        my @notes;
        push(@notes, $citation->parsed('NOTE')) if defined $citation->parsed('NOTE');
        push(@notes, 'UMI Diss No:  ' . $citation->parsed('UMI_DISS_NO')) if defined $citation->parsed('UMI_DISS_NO');
        push(@notes, 'e-Print archive:  ' . $citation->parsed('OAI')) if defined $citation->parsed('OAI'); 
        $output .= 'N1  - ' . join('; ', @notes) . "\n" if (scalar @notes);        

	$output .= 'M3  - ' . $citation->parsed('PUBTYPE')  . "\n" if defined($citation->parsed('PUBTYPE'));

	if (defined($citation->parsed('VOL'))) {
		$output .= 'VL  - ' . $citation->parsed('VOL') . "\n";
	} elsif (defined($citation->parsed('EDITION'))) {
		$output .= 'VL  - ' . $citation->parsed('EDITION') . "\n";
	}

	my ($start_page, $end_page) = split /-/, $citation->parsed('PGS'), 2;
	$output .= "SP  - $start_page\n" if defined($start_page);
	$output .= "EP  - $end_page\n" if defined($end_page);
	
	
	my $date = $citation->parsed('YYYYMMDD');
	if ($date =~ /(\d{4})(\d{2})(\d{2})/) {
		$output .= "PY  - $1/$2/$3\n";
	} else {
		my ($year, $month, $day, $other);
		if ($citation->parsed('YEAR') =~ /\d{4}/) {
			$year = $citation->parsed('YEAR');
		} else {
			$other .= $citation->parsed('YEAR');
		}
		if ($citation->parsed('MONTH') =~ /^\d{1,2}$/) {
			$month = sprintf("%02d", int($citation->parsed('MONTH')));
		} else {
			$other .= $citation->parsed('MONTH');
		}
		if ($citation->parsed('DAY') =~ /^\d{1,2}$/) {
			$month = sprintf("%02df", int($citation->parsed('DAY')));
		} else {
			$other .= $citation->parsed('DAY');
		}
		
		$output .= "PY  - $year/$month/$day/$other\n";
	}

	if (defined($citation->parsed('ISSN'))) {
		$output .= 'SN  - ' . $citation->parsed('ISSN') . "\n";
	} elsif (defined($citation->parsed('ISBN'))) {
		$output .= 'SN  - ' . $citation->parsed('ISBN') . "\n";
	}

	return $output;
}


1;

__END__

