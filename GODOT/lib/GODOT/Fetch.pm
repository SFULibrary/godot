package GODOT::Fetch;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##
use GODOT::Config;
use GODOT::Debug;
use GODOT::String;
use GODOT::Object;

use base qw(GODOT::Object);

use strict;

my @FIELDS = ('dispatch_site', 
              'error_message');

my @INCLUDE_PATH = ([qw(local  type  dispatch_site)],
                    [qw(local  type)],
                    [qw(global type)]);

##
## -called using class not object, so appears to need to have 'dispatch' defined explicitly for the class 
##
sub dispatch {
    my ($class, $param)= @_;

    my $dispatch_site = ${$param}{'dispatch_site'};    
    
    ${$param}{'dispatch_site'} =~ s#\055#_#g if (defined ${$param}{'dispatch_site'});       ## -for ELN-AG, ELN-AG-MONO, NEOS-OTHER, BNM-COW, BNM-NAN and BNM-POW

    #### debug 'dispatch_site:  ', $dispatch_site;
    #### debug 'type:  ', ${$param}{'type'};

    my $obj = $class->SUPER::dispatch([@INCLUDE_PATH], $param);
    $obj->{'dispatch_site'} = $dispatch_site;
    $obj->{'type'} = ${$param}{'type'};

    return $obj;
}

sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}

1;



