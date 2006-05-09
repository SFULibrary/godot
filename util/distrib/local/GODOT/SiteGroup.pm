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

    if ($self->group eq 'OTHER')             { return ();                            }
    elsif ($self->group eq 'ELN')            { return qw(ELN COPPUL_AND_ELN);        }
    elsif ($self->group eq 'COPPUL')         { return qw(COPPUL COPPUL_AND_ELN);     }
    elsif ($self->group eq 'COPPUL_AND_ELN') { return qw(COPPUL_AND_ELN COPPUL ELN); } 

    return ($self->group);
}

1;


