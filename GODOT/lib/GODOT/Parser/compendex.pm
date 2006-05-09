package GODOT::Parser::compendex;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;

@ISA = "GODOT::Parser";

use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::compendex") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	##---------------Customized code goes here-------------------##

	my $source = $citation->parsed('SOURCE');

        #
        # Extract Page Information
        #
        if ($source =~ m#^(.+)(?:\.|\,)\s*p\s*(\S+)\s*.*#) {
            $citation->parsed('PGS', $2);
            $source = $1;
        }
        elsif ($source =~ m#^(.+)(?:\.|\,)\s*(\d+)\s*pp?#) {
            $citation->parsed('PGS', $2);
            $source = $1;
        }
        #
        # Extract Volume/Issue Information
        #
        if ($source =~ m#^(.+)\.\s*(n\s*\S+)(?:\,|\.|\s)(/Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec/i\S*)(?:\,|\.|\s)\s*\d\d\d\d.*#) {
            #
            # n3, May-June 1996
            #
            $citation->parsed('TITLE', $1);
            $citation->parsed('VOL', $2);
            $citation->parsed('MONTH', $3);
        }
        elsif ($source =~ m#^(.+)\.\s*v\s*(.+)\s*(n\s*\S*\s*pt\s*\S*)\s*(/Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec/i\S*)\s*\d*(?:\,|\.|\s)\s*\d\d\d\d#) {
            #
            # v 12 n 34 pt 1234 May 1, 1996
            # v 12 n 34 pt 1234 May 1 1996
            #
            $citation->parsed('TITLE', $1);
            $citation->parsed('VOL', $2." ".$3);
            $citation->parsed('MONTH', $4);
        }
        elsif ($source =~ m#^(.+)\.\s*v\s*(.+)\s*(n\s*\S+),\s*\S*\s*(/Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec/i\S*)\s*\d*(?:\,|\.|\s)\s*\d\d\d\d\.*#) {
            # 
            # ...v 47 n2267, -2282 Apr 15 1997
            #
            $citation->parsed('TITLE', $1);
            $citation->parsed('VOL', $2." ".$3);
            $citation->parsed('MONTH', $4);
        }
        elsif ($source =~ m#^(.+)\.\s*v\s*(.+)\s*(n\s+\S+)\s*(\S*)\s*\d*(?:\,|\.|\s)\s*\d\d\d\d\.*#) {
            #
            # v 446 n1927, Aug 8 1994
            #
            $citation->parsed('TITLE', $1);
            $citation->parsed('VOL', $2." ".$3);
            $citation->parsed('MONTH', $4);
        }
        elsif ($source =~ m#^(.+)\.\s*v\s*(.+)\,\s*(\S+)\s*\d\d\d\d\.#) {
            #
            # v 1306, Oct 1997
            #
            $citation->parsed('TITLE', $1);
            $citation->parsed('VOL', $2);
            $citation->parsed('MONTH', $3);
        }
        elsif ($source =~ m#^(.+)\.\s*v\s*(.+)(?:\,|\s)\s*\d\d\d\d[,\s*,\w]*#) {
            #
            # v 1234, 1996
            # v CR12 1996
            # v 1 1996,,96TH8185
            #
            $citation->parsed('TITLE', $1);
            $citation->parsed('VOL', $2);
        }
        elsif ($source =~ m#^(.+)\.\s*(n.+),\s+\S*\s*(/Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec/i\S*)?\s*\d\d\d\d?#) {
            #
            # ...n 1123, 3 Nov 1994
            # ...n FC96-2691, 996
            #
            $citation->parsed('TITLE', $1);
            $citation->parsed('VOL', $2);
            $citation->parsed('MONTH', $3);
        }
        elsif ($source =~ m#^(.+)\.\s*(n.+),?\s+\d\d\d\d?#) {
            #
            # n 123 1997
            #
            $citation->parsed('TITLE', $1);
            $citation->parsed('VOL', $2);
        }
        elsif ($source =~ m#^(.+)\.\s*\d\d\d\d.*#) {
            #
            # 1996, ...
            #
            $citation->parsed('TITLE', $1);
        }
        my $vol = $citation->parsed('VOL');
        $vol =~ s#,$##;
        $citation->parsed('VOL', $vol);

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::compendex") if $GODOT::Config::TRACE_CALLS;

	#my $reqtype = $self->SUPER::get_req_type($citation); ##yyua
	my $reqtype;

	##---------------Customized code goes here-------------------##

        $reqtype = $GODOT::Constants::JOURNAL_TYPE;

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

