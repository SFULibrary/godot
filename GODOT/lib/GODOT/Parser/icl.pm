package GODOT::Parser::icl;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::icl") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##

        if ($citation->is_journal()) {
	    if ($source =~ /^\s*\(([^)]+)\)\s+(.+)$/) {
	    	$source = $2;
	    	# Get date off the front if possible...
	    	if ($1 =~ /^\s*([\w\-\/]*)\.?\s+([\d\/\-]+)\s*$/) {
		    	$citation->parsed('MONTH', $1);
		    	$citation->parsed('YEAR', $2);
		}
		## (May 2000) 64 Ivey Business J. No. 5, 60-6
		if ($source =~ /^\s*(\d*)\s*(.+)\s+[Nn]o\.?\s+(\d+),\s+([-\d\/]+)/) {
                    $citation->parsed('VOL', $1);
		    $citation->parsed('TITLE', $2);
		    $citation->parsed('ISS', $3);
		    $citation->parsed('PGS', $4);
		    my $title= $citation->parsed('TITLE');
		    if ($title =~ s/\((.+)\)//) {
			$citation->parsed('TITLE', $title);
		    	$citation->parsed('EDITION', $1);
		    }
                }

	        ## (Mar. 1992) 2 Admin. L.R. (2d) 113-114
		## (Summer 1998) 41 Can. Pub. Admin. 239-283 
	        ## (1990) 20 Man. L.J. 227-261

	        elsif ($source =~ /^\s*(\d*)\s*(.+)\s+([-\/\d]+)/) {
                    $citation->parsed('VOL', $1);
		    $citation->parsed('TITLE', $2);
		    $citation->parsed('PGS', $3);
		    my $title = $citation->parsed('TITLE');
		    if ($title =~ s/\((.+)\)//) {
			$citation->parsed('TITLE', $title);
		    	$citation->parsed('EDITION', $1);
		    }
                }
                $citation->parsed('TITLE', $citation->pre('PN')) if $citation->pre('PN') =~ /\w/;
                my $title = $citation->parsed('TITLE');
                $title =~ s/([^-])-([^-])/$1 $2/g;
                $citation->parsed('TITLE', $title);
            }
	    ## in: Canadian Encyclopedic Digest (West. 3d), V. 11A, Title 48 (Scarborough, Ont.: Carswell), p. 48:1-48:100 .
	    elsif ($source =~ /^\s*in:\s*(.+)\s+V\.\s+([\d\w]+),\s+([Tt]itle\s*[\d\w]+)\s+\((.+)\),\s*p\.\s*([-\d:]+)\s*$/) {
                $citation->parsed('TITLE', $1);
                $citation->parsed('VOL', $2);
                $citation->parsed('ISS', $3);
                $citation->parsed('PUB', $4);
		$citation->parsed('PGS', $5);
		$citation->parsed('PGS', ('para. ' . $citation->parsed('PGS'))) if $citation->parsed('PGS') =~ /:/;
		$citation->req_type($GODOT::Constants::BOOK_ARTICLE_TYPE); ##yyua
            }
            
            ## in: Remedies: issues and perspectives / ed. by Jeffrey Berryman. (Scarborough: Thomson Professional Publishing Canada, 1991), p. 313-333
            elsif ($source =~ s#^\s*in:\s*##) {
		$citation->parsed('ARTTIT', $citation->pre('TI'));
		$citation->parsed('ARTAUT', $citation->pre('AS'));
                my $title; 
            	($title, $source) = split(/ \/ /, $source, 2);
            	$citation->parsed('TITLE', $title);
            	if ($source =~ m#^\s*(.+)\.\s+\((.+)\)\s*,\s*p\.\s*([-\d/]+)\s*$#) {
		    $citation->parsed('AUT', $1);
		    $citation->parsed('PUB', $2);
		    $citation->parsed('PGS', $3);
		}
		$citation->parsed('YYYYMMDD', $citation->pre('PD'));
            	$citation->parsed('YEAR', substr($citation->pre('PD'), 0, 4));
            	$citation->req_type($GODOT::Constants::BOOK_ARTICLE_TYPE);
	    }
	    my $title = $citation->parsed('TITLE');
	    if ($title =~ s/\((.+)\)\s*$//) {
		$citation->parsed('TITLE', $title);
		$citation->parsed('EDITION', $1);
	    }
        } elsif ($citation->is_book()) {
        	$citation->parsed('EDITION', $citation->pre('ED'));
        	$citation->parsed('PUB', $citation->pre('PU') . ' ' . $citation->pre('CY'));
		my $pub = $citation->parsed('PUB');
		$pub =~ s/\n//g;
		$citation->parsed('PUB', $pub);
        }
	my $title = $citation->parsed('TITLE');
	my $aut = $citation->parsed('AUT');
	my $edition = $citation->parsed('EDITION');
	chomp($title);
	chomp($aut);
	chomp($edition);
	$citation->parsed('TITLE', $title);
	$citation->parsed('AUT', $aut);
	$citation->parsed('EDITION', $edition);

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::icl") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

	if ($reqtype eq $GODOT::Constants::UNKNOWN_TYPE) {
	    $reqtype = $GODOT::Constants::JOURNAL_TYPE;
	}

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

