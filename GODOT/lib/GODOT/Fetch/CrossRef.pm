package GODOT::Fetch::CrossRef;
##
## Copyright (c) 2008, Kristina Long, Simon Fraser University
##
## Based on code from CUFTS written by Todd Holbrook.
##
use GODOT::Config;
use GODOT::Debug;
use GODOT::String;
use GODOT::Constants;
use GODOT::Object;

use base qw(GODOT::Fetch);

my @FIELDS = ('auth_name', 
              'auth_passwd');

use strict;


sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}

sub url {
    return 'http://doi.crossref.org/servlet/query';
}

##
## -fetch citation data from CrossRef and add to $citation
##
sub add_data {
    my($self, $citation) = @_;

    debug "add_data in GODOT::Fetch::CrossRef" if $GODOT::Config::TRACE_CALLS;

    if (aws($self->auth_name)) {
        $self->error_message('No auth_name for CrossRef lookups.');
        return $FALSE;
    }

    if (aws($self->auth_passwd)) {
        $self->error_message('No auth_passwd for CrossRef lookups.');
        return $FALSE;
    }

    if (aws($self->url)) {
        $self->error_message('No url for CrossRef lookups.');
        return $FALSE;
    }

    if (aws($citation->parsed('DOI'))) {
        debug "no doi for lookup in GODOT::Fetch::CrossRef" if $GODOT::Config::TRACE_CALLS;       
        return $TRUE;
    }

    my $doi_for_lookup   = $citation->parsed('DOI');
    my $qdata = $doi_for_lookup;
    my $qtype = 'd';

    ##--------------------
    ##
    ## -!!! for now don't worry about cache ... determine first if it is worth doing for godot fetching !!!
    ##

    ##
    ## Lookup meta-data
    ##
    my $start_time = time;

    use LWP::UserAgent;
    my $ua = LWP::UserAgent->new( 'timeout' => 20 );
    $ua->agent("AgentName/0.1 " . $ua->agent);
    
    my $request;
    $request = new HTTP::Request POST => $self->url;
    $request->content_type('application/x-www-form-urlencoded');
    my $param_string = put_query_fields({'type'    => $qtype,
                                          'usr'    => $self->auth_name,
                                          'pwd'    => $self->auth_passwd,
                                          'area'   => 'live',
                                          'format' => 'piped',
                                          'qdata'  => $qdata});
    $request->content($param_string);

    my $response = $ua->request($request);

    unless ($response->is_success) {
         debug 'CrossRef lookup failed for query ' . quote($qdata) . ' -- ' . $response->message; 
         return $TRUE;
    }

    my $returned_data = trim_beg_end( $response->content );

    debug "CrossRef returned (" . ( time - $start_time ) . " s): $returned_data\n";

    my($issn, $title, $aulast, $volume, $issue, $start_page, $year, $type, $key, $doi) = split /\|/, $returned_data;
    
    if (aws($citation->parsed('ISSN')) && naws($issn)) {
        $issn =~ /^([\dxX]{8})/ and $citation->parsed('ISSN', $1);
    }
    $citation->parsed('TITLE', $title)    if aws($citation->parsed('TITLE')) && naws($title);
    $citation->parsed('ARTAUT', $aulast)  if aws($citation->parsed('ARTAUT')) && naws($aulast);

    $citation->parsed('VOL', $volume)     if aws($citation->parsed('VOL')) && naws($volume);
    $citation->parsed('ISS', $issue)      if aws($citation->parsed('ISS')) && naws($issue);
    $citation->parsed('PGS', $start_page) if aws($citation->parsed('PGS')) && naws($start_page);

    $citation->parsed('YEAR', $year) if aws($citation->parsed('YEAR')) && ($year =~ m#^\d{4,4}$#);

    ##
    ## -not an issue for doi only lookups, but would be an issue if lookups on other citation data were added
    ##
    #### $doi =~ s/\n.+$//msx;  ## Remove everything after the first DOI
    #### $citation->parsed('DOI', $doi) if aws($citation->parsed('DOI')) and naws($doi);    
    ##

    ##
    ## -if we don't already have a req_type then set it now
    ## -is the assumption of the item being a journal article, if the doi was found in crossref, reasonable??
    ##									   
    $citation->req_type($GODOT::Constants::JOURNAL_TYPE) if $citation->is_unknown;
									   
    return $TRUE;
}

1;





