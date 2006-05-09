package GODOT::ILL::Request;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use Exporter;
use GODOT::Config;
use GODOT::Debug;
use GODOT::String;
use GODOT::Object;

@ISA = qw(Exporter GODOT::Object);

@EXPORT = qw();

use strict;

my @FIELDS = ('site', 
              'type');


my @INCLUDE_PATH = ([qw(local site)],
                    [qw(local local)]);
##
## -called using class not object, so appears to need to have 'dispatch' defined explicitly for the class 
##

sub dispatch {
    my ($class, $citation, $param)= @_;

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


sub type {
    my($self, $type, @junk) = @_;

    if (naws($type)) { $self->{'type'} = $type; }

    return $self->{'type'};
}

1;
