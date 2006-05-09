package GODOTConfig::Sites;

use Class::Accessor;
use base 'Class::Accessor';

use GODOTConfig::Config;
use GODOTConfig::Exceptions;
use GODOTConfig::DB::Sites;
use GODOTConfig::DB::Site_Chains;
use GODOTConfig::DB::Site_Config;
use GODOTConfig::Debug;
use GODOT::String;
use GODOT::Debug;

use strict;


sub site_keys {
    my($class) = @_;

    my @sites;

    my @obj = GODOTConfig::DB::Sites->retrieve_all;

    foreach my $obj (@obj) {
        push @sites, $obj->key;
    }

    return @sites;
}

1;












