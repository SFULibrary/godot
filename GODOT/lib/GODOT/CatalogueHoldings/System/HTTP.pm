## GODOT::CatalogueHoldings::System::HTTP
##
## Copyright (c) 2003, Kristina Long, Simon Fraser University
##

package GODOT::CatalogueHoldings::System::HTTP;


use GODOT::Object;
use GODOT::System;

@ISA = qw(GODOT::Object GODOT::System);

use strict;

##
## The System::HTTP class implements a data structure containing the following fields:
##

use strict;

my %fields = ();

sub new {
    my $that = shift;
    my $class = ref($that) || $that;

    return SUPER::new $class %fields;
}

sub uses_HTTP  {  return $TRUE; }

sub uses_Z3950 { return $FALSE; }


1;

__END__

