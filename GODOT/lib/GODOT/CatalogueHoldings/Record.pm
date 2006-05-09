## GODOT::CatalogueHoldings::Record
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

package GODOT::CatalogueHoldings::Record;

use Exporter;
use GODOT::Debug;
use GODOT::String;
use GODOT::CatalogueHoldings;
use GODOT::Object;


@ISA = qw(Exporter GODOT::CatalogueHoldings GODOT::Object);

use strict;

my $FALSE = 0;
my $TRUE  = 1;

my @FIELDS = ('record',                   
              '_error_message');

##
## -called using class not object, so appears to need to have 'dispatch' defined explicitly for the class 
##
sub dispatch {
    my ($class, $param)= @_;

    #### foreach my $key (keys %{$param}) { debug "in Record::dispatch: $key = ", ${$param}{$key}; }

    return $class->SUPER::dispatch($param);
}


sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}


sub error_message {
    my($self) = @_;    

    return $self->{'_error_message'};
}

1;

__END__




