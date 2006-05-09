package GODOT::Parser::crim;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;
use GODOT::String;

@ISA = "GODOT::Parser";


use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::crim") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	##---------------Customized code goes here-------------------##

	my $source = $citation->parsed('SOURCE');

        $citation->parsed('REPNO', "Rutgers University document number: " . $citation->pre('AN'));
        if ($citation->is_journal())  {

            my $comma1v = index($source,",");
            my $comma2v = index($source,",",$comma1v + 1);
            my $comma3v = index($source,",",$comma2v + 1);

            my $title =  trim_beg_end(substr($source,0,$comma1v));
            $title =~ s/([^\-])-([^\-])/$1 $2/g;    # Get rid of -s   
            $citation->parsed('TITLE', $title);
            $citation->parsed('VOL', trim_beg_end(substr($source,$comma1v + 1, $comma3v - ($comma1v + 1))));
            $citation->parsed('MONTH', " ");
            $citation->parsed('PGS', trim_beg_end(substr($source, $comma3v + 1,length($source) - ($comma3v - 1))));

            ##
            ## ex. 18, (4)
            ##

            if ($citation->parsed('VOL') =~ m#(\w+),\s*\((\w+)\)#i)  {
                $citation->parsed('VOL', $1);
                $citation->parsed('ISS', $2);
            }
        } elsif ($citation->is_book_article()) {
            $citation->parsed('ARTTIT', $citation->pre('TI'));
            $citation->parsed('ARTAUT', $citation->pre('AU'));
            ## The format is not stable enough to 100% parse, but make a good attempt: (TH)
            ## There are also a number of database entry errors which do not follow any of the
            ## parsing methods.  If something can't be matched, dump the whole BK field into  
            ## the title.

            # Try for a TITLE : PUBLISHER : PAGES parse
            if ($citation->pre('BK') =~ /^\s*(.+)\s*:\s*([^:]+)\s*[,:]\s*(?:[pP\.]*)\s*([\s\d\-]+)\s*\.*$/) {
                $citation->parsed('PUB', $2);
                $citation->parsed('PGS', $3);
                $citation->parsed('TITLE', $1);
                #Try to strip off annoying city/state/country codes.
                if ($citation->parsed('TITLE') =~ /^\s*(.*)\s*[\.,]+\s*(?:[\w\s]+)\s*,\s*(?:[\s\w]+)\s*$/) {
                    $citation->parsed('TITLE', $1);
                } elsif ($citation->parsed('TITLE') =~ /^\s*(.*)\s*\.?,\s*(?:[\s\w]+)\s*$/) {
                    $citation->parsed('TITLE', $1);
                }
                #Try to get an editor or author out, too
                if ($citation->parsed('TITLE') =~ /^(.*?),\s*(?:edited\sby|by)\s*(.*)$/) {
                    $citation->parsed('TITLE', $1);
                    $citation->parsed('AUT', $2);  
                }
            # Nope, try for pages at least
            } elsif ($citation->pre('BK') =~ /^\s*(.+)\s*:\s*(?:[pP\.]*)\s*([\s\d\-]+)/) {
                $citation->parsed('PGS', $2);
                $citation->parsed('TITLE', $1);
            } else {
            # Could not parse anything useful :(
                $citation->parsed('TITLE', $citation->pre('BK'));
            }
        }

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::crim") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); ##yyua

	##---------------Customized code goes here-------------------##

        if (! aws($citation->pre('JN'))) { $reqtype = $GODOT::Constants::JOURNAL_TYPE; }
        elsif (! aws($citation->pre('BK'))) { $reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE; }
        else {$reqtype = $GODOT::Constants::BOOK_TYPE;}

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

