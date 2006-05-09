package GODOT::Authentication;
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

my @FIELDS = ('site');

sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}

##
## Determine identity:
##     1) hidden or URL field
##     2) use default site
##
sub get_site {
    my($self, $site_param) = @_;

    my $site = (naws($site_param)) ? $site_param : $GODOT::Config::DEFAULT_SITE; 

    #### debug '__________ here we are in default get_site';

    return $self->site($site);
}


1;
