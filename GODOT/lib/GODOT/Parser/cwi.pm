package GODOT::Parser::cwi;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::cwi") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	##---------------Customized code goes here-------------------##

	my $source = $citation->parsed('SOURCE');

    	if ($citation->pre('RT') =~ /fulltext/i) {
           $citation->fulltext_available(1);
	}
    	if ($citation->is_journal() || $citation->is_tech()) {
		$citation->parsed('ARTTIT', $citation->pre('TI'));
		$citation->parsed('YEAR', $citation->pre('PY'));
		
		# Women in Action. Number 03, 1998; (3): 36
		if ($source =~ /^\s*(.+)\s*\.\s*(.*)\s*,\s*([\w\d\s]*)\s+\d{4}\s*;\s*([\d\w]*)\s*\(?([\d\w\-]*)\)?\s*:\s*([xvciXVCI\d,\-+]*|na)\s*\.?\s*$/) {
			$citation->parsed('TITLE', $1);
			$citation->parsed('MONTH', $3);
			$citation->parsed('VOL', $4);
			$citation->parsed('ISS', $5);
			$citation->parsed('PGS', $6);
		# Journal of Popular Film and Television.Summer 1999; 27 (2): 32
		} elsif ($source =~ /^\s*(.+)\s*\.\s*([\w\d\s]*)\s+\d{4}\s*;\s*([\d\w]*)\s*\(?([\d\w\-]*)\)?\s*:\s*([xvciXVCI\d,\-+]*|na)\s*\.?\s*$/) {
			$citation->parsed('TITLE', $1);
			$citation->parsed('MONTH', $2);
			$citation->parsed('VOL', $3);
			$citation->parsed('ISS', $4);
			$citation->parsed('PGS', $5);
		} 
		# Christian Science Monitor. July 12, 1999; 1 
		elsif ($source =~ /^\s*(.+)\s*\.\s*([\w\d\s]+)\s*,?\s+\d{4}\s*;\s*([xvciXVCI\d,\-\+]+|na)\.?\s*$/) {
			$citation->parsed('TITLE', $1);
			$citation->parsed('MONTH', $2);
			$citation->parsed('PGS', $3);
		}
		# Feminism & Nonviolence Studies. Fall 1998 
		elsif ($source =~ /^\s*(.+)\s*\.\s*([\w\d\s]+)\s*,?\s+\d{4}\s*\.?\s*$/) {
			$citation->parsed('TITLE', $1);
			$citation->parsed('MONTH', $2);
		}
		# Try for title at least
		elsif ($source =~ /^\s*(.+)\s*\.\s*[^.]+\s*\.?\s*$/) {
			$citation->parsed('TITLE', $1);
		}
    	} else {
	
    		if ($source =~ /^\s*(.+)\s*\.\s*([\d\w\s\-,]+)\s*;\s*([\dxvciXVCI,\-+]+|na)\s*\.?\s*$/) {
			$citation->parsed('TITLE', $1);
			$citation->parsed('PGS', $3);
			if ($2 =~ /^([\w\d\s]+)\s*,?\s*(\d{4})$/) {
				$citation->parsed('MONTH', $1);
			}
		}
		# Interpress Service.August 25, 1995
		elsif ($source =~ /^\s*(.+)\s*\.\s*([\d\w\s\-,]+)\s*$/) {
			$citation->parsed('TITLE', $1);
			if ($2 =~ /^([\w\d\s]+)\s*,\s*(\d{4})$/) {
				$citation->parsed('MONTH', $1);
			}
		}
		elsif ($source =~ /^\s*(.+)\s*\.\s*[^.]+$/) {
			$citation->parsed('TITLE', $1);
		}

 	}   		
	$citation->parsed('SYSID', $citation->pre('AN'));

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::cwi") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); ##yyua

	##---------------Customized code goes here-------------------##

    	if ($citation->pre('JT') =~ /(?:journal|newspaper)/i) {
    	   $reqtype = $GODOT::Constants::JOURNAL_TYPE;	
    	} else {
    	   $reqtype = $GODOT::Constants::TECH_TYPE;
    	}
    	if ($citation->pre('IS')) {
    	   $reqtype = $GODOT::Constants::JOURNAL_TYPE;
    	}

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

