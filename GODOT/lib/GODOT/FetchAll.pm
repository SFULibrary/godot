package GODOT::FetchAll;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##
use GODOT::Config;
use GODOT::Debug;
use GODOT::String;
use GODOT::Object;
use GODOT::Fetch;

use base qw(GODOT::Object);

use strict;

my @FIELDS = ('dispatch_site');

my @INCLUDE_PATH = ([qw(local dispatch_site)],
                    [qw(local)],
                    [qw(global)]);
##
## -called using class not object, so appears to need to have 'dispatch' defined explicitly for the class 
##
sub dispatch {
    my ($class, $param)= @_;

    my $dispatch_site = ${$param}{'dispatch_site'};    
    
    ${$param}{'dispatch_site'} =~ s#\055#_#g if (defined ${$param}{'dispatch_site'});       ## -for ELN-AG, ELN-AG-MONO, NEOS-OTHER, BNM-COW, BNM-NAN and BNM-POW

    my $obj = $class->SUPER::dispatch([@INCLUDE_PATH], $param);
    $obj->{'dispatch_site'} = $dispatch_site;

    return $obj;
}

sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}


sub add_data {
    my($self, $citation) = @_;

    ##
    ## !!! is this the right place for this or should we be passing a GODOTConfig::Cache object in from hold_tab.cgi?? 
    ##
    use GODOTConfig::Cache;
    my $config = GODOTConfig::Cache->configuration_from_cache($self->dispatch_site);

    unless (defined $config) {
        error location, ':  no configuration information was available for ' . quote($self->dispatch_site);
        return;
    }

    ##
    ## !!! -for now, only try a fetch if we have the associated identifier
    ## !!! -later can add logic to do lookups based on other citation data -- see CrossRef.pm in CUFTS
    ##

    if ($config->crossref_doi_query) {
        my $fetch_crossref = GODOT::Fetch->dispatch({'type' => 'CrossRef', 'dispatch_site' => $self->dispatch_site});        
        $fetch_crossref->auth_name($config->crossref_id);
        $fetch_crossref->auth_passwd($config->crossref_password);
        unless ($fetch_crossref->add_data($citation)) {
            error $fetch_crossref->error_message;
        }
    }

    if ($config->pubmed_pmid_query) {
        my $fetch_pubmed = GODOT::Fetch->dispatch({'type' => 'PubMed', 'dispatch_site' => $self->dispatch_site});        
        unless ($fetch_pubmed->add_data($citation)) {
            error $fetch_pubmed->error_message;
        }
    }
}


1;



