package GODOT::CatalogueHoldings::Source;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use Exporter;
use GODOT::Debug;
use GODOT::String;
use GODOT::Object;
use GODOT::CatalogueHoldings;
use GODOTConfig::Configuration;
use GODOTConfig::Cache;

@ISA = qw(Exporter GODOT::Object);
@EXPORT = qw();

use strict;
use vars qw($AUTOLOAD);

my @FIELDS = qw(site type source);

my @SOURCE_TYPES = qw(journal 
                      journal_detail 
                      mono 
                      mono_detail
                      same_as_dbase_journal
                      same_as_dbase_journal_detail 
                      same_as_dbase_mono 
                      same_as_dbase_mono_detail);

my @INCLUDE_PATH = ([qw(local site)],
                    [qw(local local)]);
##
## -called using class not object, so appears to need to have 'dispatch' defined explicitly for the class 
##
sub dispatch {
    my ($class, $citation, $param) = @_;

    my $site = ${$param}{'site'};    
    
    ##
    ## -for ELN-AG, ELN-AG-MONO, NEOS-OTHER, BNM-COW, BNM-NAN and BNM-POW
    ##    

    ${$param}{'site'} =~ s#\055#_#g if (defined ${$param}{'site'});

    my $obj = $class->SUPER::dispatch([@INCLUDE_PATH], $param);

    $obj->{'site'} = $site;
    $obj->set_type($citation);

    return $obj;
}

sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}

sub set_type {
    my($self, $citation) = @_; 
 
    my $type;

    if (grep {$self->site eq $_} $citation->get_dbase->source_sites) {

        if ($citation->is_journal) { $type = 'same_as_dbase_journal'; }
        else                       { $type = 'same_as_dbase_mono';    }
    }
    elsif ($citation->is_journal) {
        $type = 'journal';
    }
    else {
        $type = 'mono';
    }    
 
    return $self->{'type'} = $type;
}

##
## -return a hash of references to hashes with fields: 
##      name 
##      catalogue_source_journal 
##      catalogue_source_non_journal 
##      catalogue_source_default 
##
## -hash key is 'name'
##

sub source_info {
    my($class) = @_;


    report_time_location;
    my @sources = GODOTConfig::DB::Sites->sources;
    report_time_location;

    my %source_info;
    foreach my $item (@sources) {
	$source_info{$item->{'name'}} = $item;
    }
    
    return %source_info;
}

sub sources_to_try {
    my($class, $lenders, $citation, $detail) = @_;

    my @sources_to_try;
    foreach my $lender (@{$lenders}) {              ## -ie. list of locations that have associated holdings

        my $source = GODOT::CatalogueHoldings::Source->dispatch($citation, {'site' => $lender});
        
        unless ($source) {
            error location, ":  was unable to dispatch a source object for $lender";
            next;
        }

        my $sc = GODOTConfig::Cache->configuration_from_cache($lender);        

        unless (defined $sc) {
            error location, ":  no source information was available for $lender";
            next;
        }

        my $type = $source->type . (($detail) ? '_$detail' : ''); 

        $source->{'source'} = (naws($sc->catalogue_source_journal) && ($type eq 'journal'))  ? $sc->catalogue_source_journal 
                            : (naws($sc->catalogue_source_non_journal) && ($type eq 'mono')) ? $sc->catalogue_source_non_journal
                            : (naws($sc->catalogue_source_default))                          ? $sc->catalogue_source_default 
                            :                                                                $lender
                            ;

        push(@sources_to_try, $source);
    }
 
    return @sources_to_try;
}

1;











