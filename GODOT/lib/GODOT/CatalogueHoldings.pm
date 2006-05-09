package GODOT::CatalogueHoldings;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use GODOT::Constants;
use GODOT::Config;
use GODOT::Debug;
use GODOT::String;
use GODOT::Object;

use GODOT::Dispatch;

@ISA = qw(Exporter GODOT::Object);

@EXPORT = qw();

use strict;

use vars qw($AUTOLOAD);

my $DEFAULT_PROTOCOL = 'Z3950';

my @FIELDS = qw(site system protocol);

my @INCLUDE_PATH = ([qw(local site)], 
                    [qw(local local)], 
                    [qw(global protocol system)], 
                    [qw(global protocol)]);
sub dispatch {
    my($class, $param) = @_;

    unless (defined ${$param}{'protocol'}) { ${$param}{'protocol'} = $DEFAULT_PROTOCOL; }

    my $site = ${$param}{'site'};
    ##
    ## -for ELN-AG, ELN-AG-MONO, NEOS-OTHER, BNM-COW, BNM-NAN and BNM-POW
    ##
    ${$param}{'site'} =~ s#\055#_#g if (defined ${$param}{'site'});

    my $obj = $class->SUPER::dispatch([@INCLUDE_PATH], $param);
    $obj->{'site'} = $site;
    return $obj;
}


sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}


sub link_from_cat_sites {
    my($self, $link_from_cat_site) = @_;

    my @arr;
    push(@arr, (naws($link_from_cat_site) ? $link_from_cat_site : $self->site));
    return @arr;
}


1;



