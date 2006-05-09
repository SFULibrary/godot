package GODOT::Dispatch::File;

## GODOT::Dispatch::File;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use GODOT::Constants;
use GODOT::Config;
use GODOT::Debug;
use GODOT::String;
use GODOT::Object;

@ISA = qw(Exporter GODOT::Object);

@EXPORT = qw();

use strict;

use vars qw($AUTOLOAD);

my $LOCAL = 'local';
my $GLOBAL = 'global';


my @FIELDS = ('type',                ## not currently being used. In future might be be 'local' or 'global'.
              'components',          ## ref to list of strings that define the components of the file name
             );       

sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }
   
    return return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}


sub is_local {
    my($self) = @_;
    return ($self->{'type'} eq $LOCAL);
}

sub is_global {
    my($self) = @_;
    return ($self->{'type'} eq $GLOBAL);
}


1;

__END__

