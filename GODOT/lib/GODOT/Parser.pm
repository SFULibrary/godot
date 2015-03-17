## GODOT::Parser
##
## Copyright (c) 2001, Todd Holbrook, Simon Fraser University
##
## This is the base class module for the GODOT parsers.  It contains a basic
## generic parser as well as some other subroutines commonly used by other
## parsers.  It also contains a class method meant to be used as a
## dispatcher for picking the correct specific parser to use.
##
##
package GODOT::Parser;

use Data::Dumper;

use GODOT::Constants;
use GODOT::Config;
use GODOT::Debug;
use GODOT::String;
use GODOT::Citation;

use strict;

# dispatch - tries to load a specific database parser from either the mapping
# table or a like-named module in ./Parser
# takes: $db - the database to parse
#        $database - database object  (06-feb-2002) - !!!! later can probably remove $db as param !!!!!
#        $site - site (eg. 'BVAS') 
# returns: $parser - a parser object

sub dispatch {
    my ($class, $db, $database, $site) = @_;

    debug("Dispatching database parser from GODOT::Parser for database '$db'") if $GODOT::Config::TRACE_CALLS;

    #### debug location, ":  db:\n", Dumper($db);
    #### debug location, ":  database:\n", Dumper($database);

    ##
    ## Map databases to specific parsers
    ##
    my $mapping = \%GODOT::Config::DBASE_PARSER_MAPPING;

    my $mapping_dbase_type = \%GODOT::Config::DBASE_TYPE_PARSER_MAPPING;    

    my $module;

    if (exists($mapping->{$db})) {
        ##
        ## Check the mapping above for a defined parser mapping
        ##
        $module = "GODOT::Parser::" . $mapping->{$db};

        ##
        ## (15-may-2002 kl) - added for FirstSearch openurl parser
        ##
    } 
    elsif (exists($mapping_dbase_type->{$database->dbase_type()})) {        
        warn "<<< ", $mapping_dbase_type->{$database->dbase_type()}, ">>>";
        $module = "GODOT::Parser::" . $mapping_dbase_type->{$database->dbase_type()};        
    } 
    elsif ($database->is_openurl_syntax()) {
        
        $module = "GODOT::Parser::" . 'openurl';

    } else {
        ## Attempt to load a like-named parser from the Parser
        ## directory.  If that fails, return a new object of the
        ## generic parser (this module).

        $module = "GODOT::Parser::" . $db;
    }        

    # Require uses filename rather than package name if passed a string
    (my $file = "$module.pm") =~ s/::/\//g;

    debug("GODOT::Parser::dispatch chose module: $module ($file)");

    eval {require($file)};
    if ($@ eq '') {
        return new $module $site;
    } else {
        warning("Could not load parser $module ($file) for database $db: $@") if $GODOT::Config::WARN_ON_DEFAULT_PARSER;
        return 0; 
    }
}

# new - Returns a blessed GODOT::Parser object.

sub new {
    my($class, $site) = @_;

    my $object = bless {}, $class;
    $object->{'site'} = $site;
    return $object;
}

# preparse - Does things common to almost all parsers like setting the 
# request type.  It can be overrided however for special cases.  The
# object using the parse() method should also call preparse() before hand.  


sub parse {
    my ($self, $citation) = @_;
    debug("Generic parse() in GODOT::Parser") if $GODOT::Config::TRACE_CALLS;

    $self->pre_parse($citation);

    $citation->req_type($self->pre_get_req($citation));

    unless (defined($citation->req_type())) {
        $citation->req_type($self->get_req_type($citation));
    }
    
    $self->parse_citation($citation);
    
    $self->post_parse($citation);
}

## ---pre_parse---- 
#1) To be overwritten in specific parser to perform some pre-parsing field cleanup; 
#2) does some parsing that has to be done before deciding req_type.

sub pre_parse {
    my ($self, $citation) = @_;
    debug("Generic pre_parse() in GODOT::Parser") if $GODOT::Config::TRACE_CALLS;

    if ($citation->pre('PT')) { 
        $citation->parsed('PUBTYPE', lc($citation->pre('PT')));
    } else {
        $citation->parsed('PUBTYPE', lc($citation->pre('DT')));
    }

    # Check standard ISSN fields
    foreach my $field ('IS', 'ISSN', 'SN', 'NU') {
        last if defined($citation->parsed('ISSN', GODOT::String::clean_ISSN($citation->pre($field))));
    }
}

sub post_parse {
    my ($self, $citation) = @_;
    debug("Generic post_parse() in GODOT::Parser") if $GODOT::Config::TRACE_CALLS;
    
    #### debug ('-----------------------------------------------------------------');
    #### debug Dumper($self);
    #### debug ('-----------------------------------------------------------------');
       
    ##
    ## -use info in citation (eg. pmid, doi) to find out more about citation;  
    ## -add this new data to citation object;
    ##
    use GODOT::FetchAll;
    my $fetch_all = GODOT::FetchAll->dispatch({'dispatch_site' => $self->{'site'}});        
    $fetch_all->add_data($citation);     ## -add fetched data from zero or more sources to $citation object

    my $temp = $citation->parsed('PGS');

    # remove trailing periods so periods in 'Pages VII.15-VII.23.1976. .' (from georef) do not get stripped 
    $temp =~ s#\.\s*$##; 

    # (28-mar-2002 kl) - remove leading 'pages', 'page' and abbreviations
    $temp =~ s#^\s*pages|^\s*page|^\s*pp[\.]*|^\s*p[\.]*|^\s*pgs[\.]*##;

    $citation->parsed('PGS', $temp);

    # try to fill title
    
    if (aws($citation->parsed('TITLE'))) {
        $citation->parsed('TITLE', $citation->parsed('SERIES'));
    } 

    if (aws($citation->parsed('TITLE'))) {
        $citation->parsed('TITLE', $citation->parsed('SOURCE'));
    } 

    # strip year out of pub field

    if ($citation->parsed('PUB') =~ m#(\d{4})\s*$#) {
        my $year = $1;

        # if same then strip off as it is dup info
        if ($year eq $citation->parsed('YEAR')) {
            my $temp = $citation->parsed('PUB');
            $temp =~ s#\d{4}\s*$##;
            $temp = strip_trailing_punc_ws($temp);
            $citation->parsed('PUB', $temp);
        }
    }

    ##
    ## (28-mar-2002 kl) - try to fill the MONTH field and the new DAY field if they are not already filled
    ## (28-mar-2002 kl) - check to see if month includes a date, if so parse out and put in DAY field 
    ##
    if ($citation->parsed('MONTH') =~ m#^\s*([a-zA-Z]+)\s+(\d{1,2})\s*$#)   {

        my $mon = $1;
        my $date = $2;
        $date =~ s#^0+##;
 
        if (($date > 0) && ($date <= 31)) {
            $citation->parsed('MONTH', $mon);                 
            $citation->parsed('DAY', $date); 
        }
    }

    my $yyyymmdd = $citation->parsed('YYYYMMDD');
        
    if (GODOT::String::aws($citation->parsed('MONTH')) && (length($yyyymmdd) >= 6))  {
        my $mm = substr($yyyymmdd, 4, 2);
        $citation->parsed('MONTH', GODOT::Date::date_mm_to_mon($mm)) unless ($mm == 0);
    }

    if (GODOT::String::aws($citation->parsed('DAY')) && (length($yyyymmdd) == 8))  {
        my $dd = substr($yyyymmdd, 6, 2);
        $dd =~ s#^0+##;   
        $citation->parsed('DAY', $dd) unless ($dd == 0);
    }

    if (aws($citation->parsed('YEAR'))) {       
        my $year = substr($yyyymmdd, 0, 4);
        $citation->parsed('YEAR', $year);
    }

    ##
    ## (08-dec-2006 kl) -- check that we have valid ISBN and if not try to extract one 
    ##

    if (my $isbn = valid_ISBN($citation->parsed('ISBN'))) {

        if ($isbn ne $citation->parsed('ISBN')) {
            ##
            ## -tested ISBN was not valid, but we were able to extract a valid one, so save that to ISBN field
            ##
            $citation->parsed('ISBN', $isbn);
        }
    }
    else { 
        ##         
        ## (01-jan-2006 kl ) tested ISBN was not valid and we were unable to extract a valid one, so initialize field
        ## 
        $citation->parsed('ISBN', '');
    }

    ##
    ## strip leading and trailing whitespace from the citation fields
    ##
    my $tmp_value;
    foreach my $field (@GODOT::Citation::PARSED_FIELDS) {
        $tmp_value = $citation->parsed($field);
        $tmp_value = &GODOT::String::trim_beg_end($tmp_value);
        ##
        ## (17-jan-2007 kl) - strip out NUL characters as they may be taken as end of string when data is passed to 
        ##                    other programs
        ## 
        $tmp_value =~ s#\000##g;
        ##
        ## -(17-jan-2007 kl) - what we see when an 'en-dash' is cut/paste             
        ##
        $tmp_value =~ s#\226#-#g;                 

        $citation->parsed($field, $tmp_value);
    }

    ##
    ## -final try to get a request type
    ##
    if ($citation->is_unknown) {
        my $reqtype = $self->post_get_req_type($citation);
        $citation->req_type($reqtype);

        ##
        ## -if we went from 'unknown' to 'journal article' then adjust author accordingly
        ##
        if ($citation->is_journal && aws($citation->parsed('ARTAUT'))  && naws($citation->parsed('AUT'))) {
            $citation->parsed('ARTAUT', $citation->parsed('AUT'));
            $citation->parsed('AUT', '');
        }
    }

    ##
    ## (16-mar-2015 kl) 
    ## - changed from &diss_abs_issn to &diss_abs_match for both issn and title
    ## - more change to parsed fields if match on 'dissertation abstracts' or on 'masters abstracts'
    ##              
    if (&diss_abs_issn($citation->parsed('ISSN')) || &diss_abs_title($citation->parsed('TITLE'))) {             
         $citation->req_type($GODOT::Constants::THESIS_TYPE);
         $citation->parsed('ISSN', '');
         if (naws($citation->parsed('ARTTIT'))) {   ## - assume ARTTIT contains thesis title
             $citation->parsed('NOTE', $citation->parsed('TITLE'));
             $citation->parsed('TITLE', $citation->parsed('ARTTIT'));
             $citation->parsed('ARTTIT', '');
         }
         if (naws($citation->parsed('ARTAUT'))) {                                                   ## - assume ARTAUT contains thesis author
             $citation->parsed('AUT', $citation->parsed('ARTAUT'));
             $citation->parsed('ARTAUT', '');
         }
         $citation->parsed('VOL', '');                  
         $citation->parsed('ISS', '');                  
         $citation->parsed('PGS', '');                  
    }
}

# parse_citation - Default parser, attempts to pick out common items like
# title, ISSN, etc. Takes a GODOT::Citation object and returns that object
# including the parsed fields.

sub parse_citation {
    my ($self, $citation) = @_;
    debug("Generic parse_citation() in GODOT::Parser") if $GODOT::Config::TRACE_CALLS;

    $citation->parsed('SOURCE', $citation->pre('SO'));
    if (GODOT::String::aws($citation->parsed('SOURCE')) && $citation->is_journal() ) {
        $citation->parsed('SOURCE', $citation->pre('JN'));
    }

    if ( $citation->is_thesis()  || $citation->is_book()    || $citation->is_unknown() ) {
        $citation->parsed('TITLE', $citation->pre('TI'));
        $citation->parsed('AUT', $citation->pre('AU'));
    } else {
        if (! $citation->get_dbase()->is_blank_dbase()) {
            $citation->parsed('ARTTIT', $citation->pre('TI'));
            $citation->parsed('ARTAUT', $citation->pre('AU'));
        }
    }

    $citation->parsed('YEAR', $citation->pre('PY'));
    $citation->parsed('SERIES', $citation->pre('SE')); 

    ##
    ## Check standard ISBN fields
    ##
    ## (13-nov-2006 kl) - Changed from 'clean_ISBN' to 'valid_ISBN' so check digit value gets checked.
    ##
    foreach my $field ('IB', 'ISBN', 'BN', 'SN', 'IS', 'NU') {

        if (my $isbn = valid_ISBN($citation->pre($field))) {
            $citation->parsed('ISBN', $isbn);   
            last;
        }
    }

    return $citation;
}

##
## Handles some special cases in deciding req_type
##
sub pre_get_req {
    my ($self, $citation) = @_;
    debug("Generic pre_get_req() in GODOT::Parser\n") if $GODOT::Config::TRACE_CALLS;

    my $reqtype;

    ##
    ## (16-mar-2015 kl) - commented out as calling &diss_abs_issn and &diss_abs_title in &post_parse should be sufficient
    ##               

    ##
    ## - parsed title is not yet available so no point passing to &diss_abs_match
    ##
    #### if (&diss_abs_issn($citation->parsed('ISSN'), '')) {   
    ####     $reqtype =  $GODOT::Constants::THESIS_TYPE;
    ####     $citation->parsed('ISSN', '');
    #### }
    ####

    return $reqtype;
}

# get_req_type - Attempts to determine what type of request is being parsed 
# (book, thesis, etc.).
#
# takes: $fields - A GODOT::Fields object containing the database record
# returns: a GODOT::Constants::REQ_TYPE variable 

sub get_req_type {
    my ($self, $citation, $pubtype) = @_;
    debug("Generic get_req_typ() in GODOT::Parser\n") if $GODOT::Config::TRACE_CALLS;

    my $reqtype = $GODOT::Constants::UNKNOWN_TYPE;
    $pubtype = lc($citation->parsed('PUBTYPE') or $citation->pre('PT') or $citation->pre('DT')) unless defined($pubtype);

    if ( $pubtype =~ /journal/           || 
         $pubtype eq 'article-citation'  || 
         $pubtype eq 'article'           ||
         $pubtype eq 'letter'            ||
         $pubtype =~ /editorial/         ||
         $pubtype =~ /periodical/        ||
         $pubtype =~ /book.*review/ ) {

            $reqtype = $GODOT::Constants::JOURNAL_TYPE;
        }
    elsif ( $pubtype =~ /association.*paper/  ||
        $pubtype =~ /chapter/            ||
        $pubtype =~ /book.*article/ ) {
        $reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE;
    }
    elsif ($pubtype =~ /book/ || $pubtype =~ /monograph/) {
        $reqtype =  $GODOT::Constants::BOOK_TYPE;
    }
    elsif ($pubtype =~ /dissertation/) {
        $reqtype = $GODOT::Constants::THESIS_TYPE;
    }
    return $reqtype;
}

sub run_post_get_req_type {
    return $FALSE;
}

sub post_get_req_type {
    my ($self, $citation) = @_;
    debug("Generic post_get_req_type() in GODOT::Parser") if $GODOT::Config::TRACE_CALLS;
    
    my $reqtype = $citation->req_type;
    return $reqtype unless $self->run_post_get_req_type;

    if (naws($citation->parsed('ISSN'))) {
        return $GODOT::Constants::JOURNAL_TYPE;
    }
    elsif (naws($citation->parsed('UMI_DISS_NO')) || naws($citation->parsed('THESIS_TYPE'))) {
        return $GODOT::Constants::THESIS_TYPE;
    }

    if (naws($citation->parsed('ARTTIT')) || naws($citation->parsed('ARTAUT'))) {
        return (naws($citation->parsed('VOLISS'))) ? $GODOT::Constants::JOURNAL_TYPE : $GODOT::Constants::BOOK_ARTICLE_TYPE;
    }

    return $GODOT::Constants::BOOK_TYPE;        
}


sub diss_abs_issn {
    my($issn) = @_;

    ##
    ## (16-mar-2015 kl) - account for issn containing 'x' or 'X' 
    ## 
    $issn = lc(&GODOT::String::clean_ISSN($issn, 0));
    my @lc_diss_abs_issn_arr = map { lc($_) } @GODOT::Config::DISS_ABS_ISSN_ARR;          
    my $issn_match = (scalar(grep {$issn eq $_} @lc_diss_abs_issn_arr)) ? $TRUE : $FALSE;
    #### debug location, "  issn_match:  $issn_match ($issn)";    
    return $issn_match;

}

##
## (16-mar-2015 kl) - added title match as per 27-feb-2015 sw email
##               
sub diss_abs_title {
    my($title) = @_;

    my $title_match = (($title =~ m#^dissertation abstracts#i) || ($title =~ m#^masters abstracts#i));
    #### debug location, "  title_match:  $title_match ($title)";
    return $title_match;

}

1;

__END__

=head1 NAME

GODOT::Parser - Parses GODOT citations

=head1 SYNOPSIS

$parsed_fields = $parser->parse($citation);

=head1 CLASS METHODS

=over 4

=item $parser = GODOT::Parser::dispatch($db)

Takes a database name as a string and returns the appropriate parser,
based on the GODOT::Config::DATABASE_MAPPING hash or the database 
name.  If a specific parser can't be found, GODOT::Parser is returned
as an instantiated object.

=back

=head1 INSTANCE METHODS

=over 4

=item $req_type = $parser->get_req_type($citation, $pubtype)

Takes the unparsed database fields from the GODOT::Citation object
and attempts to determine what type of request the citation is for. 
If $pubtype is defined, that is used as the publication type,
otherwise a guess at what the publication type should be is made
from the fields.  $pubtype is usually set by a subclass which is
calling the superclass for a first pass.  Returns one of the request
type constants from GODOT::Constants.

=item $parser->parse($cit)

Takes a citation object and does a variety of things common to
ALMOST all parsers.  This is generally things like setting the
request type, cleaning some fields, updating "computed" fields, etc. 
May call $parser->req_type() if the request type was not previously
set.  Calls $self->parse_citation() to do the actual database
parsing.  Normally this method is NOT overridden in sub-classes, the
parse_citation() method is though.  Returns the $cit object with
modified fields.

=item $parsed->pre_parse($cit)

This method is meant to be over-ridden in sub-classed parsing modules
and should handle early cleaning of pre fields to get rid of extra stuff
like MARC field data, etc.  It is defined as an empty method in the default
parser to avoid method call errors.

=item $parser->parse_citation($cit)

This method is NOT generally called by external objects, but is
called by parse().  This is done to logically separate very common
parsing routines into parse() and generally overridden routines into
parse_citation() to increase the amount of code we can re-use.

Updates the $cit->{'parsed'} fields based on the $cit->{'pre'}
fields and the parser details.  Returns the citation object with
modified fields.    

=back

=head1 AUTHORS / ACKNOWLEDGMENTS

Written by Todd Holbrook, based on existing GODOT code by Kristina Long and
others over the years at SFU and within COPPUL.

=cut

