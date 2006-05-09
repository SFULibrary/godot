## GODOT::CatalogueHoldings::Config
##
## Copyright (c) 2003, Kristina Long, Simon Fraser University
##
## Various configuration variables for the CatalogueHoldings service.
##

package GODOT::CatalogueHoldings::Config;

use Exporter;
@ISA = qw( Exporter );

##
## Export variables
##

@EXPORT = qw(@SYSTEM_TYPES);

use vars qw(@SYSTEM_TYPES);


use strict;

my $FALSE = 0;
my $TRUE  = 1;



@SYSTEM_TYPES = qw(ALEPH BUCAT BRS DRA DYNIX ENDEAVOR EPIXTECH GEAC III MULTILIS NOTIS OCLC SIRSI OTHER);


1;



