package GODOT::Patron::Data::III_HTTP;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use GODOT::Debug;
use GODOT::String;
use GODOT::Object;
use GODOT::Dispatch;

@ISA = qw(Exporter GODOT::Patron::Data);

use strict;

my @FIELDS = qw(expiry_date
                mblock
                money_owed
                hlodues
                block_until);

sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}

