package GODOT::SiteGroup;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use GODOT::Debug;
use GODOT::String;

use base qw(GODOT::Object);

use strict;

my @FIELDS = ('group');

sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}


sub groups {
    my($self) = @_;

    if ($self->group eq 'OTHER') { return (); }
    return ($self->group);
}


1;


