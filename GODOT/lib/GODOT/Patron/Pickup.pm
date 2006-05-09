package GODOT::Patron::Pickup;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##
use GODOT::Debug;
use GODOT::String;
use GODOT::Object;
use GODOT::Dispatch;

@ISA = qw(Exporter GODOT::Object);

use strict;
use vars qw($AUTOLOAD);

my @FIELDS = ('site',
              'lender_site',
              'patron',             ## GODOT::ILL::Patron
              'citation',           ## GODOT::ILL::Citation
              'locations',          ## ref to list of locations
              'request_type');        


my @INCLUDE_PATH = ([qw(local site)], 
                    [qw(local local)], 
                    [qw(global)]);

sub dispatch {
    my($class, $param) = @_;

    my $site = ${$param}{'site'};
    ${$param}{'site'} =~ s#\055#_#g if (defined ${$param}{'site'});

    my $obj = $class->SUPER::dispatch([@INCLUDE_PATH], $param);
    $obj->{'site'} =  $site;
    return $obj;
}

sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}

sub available_locations {
    my($self) = @_;

    return @{$self->locations};
}


1;

















