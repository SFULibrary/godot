package GODOTConfig::Cache::Config_Patr_Pickup_Choice;

use strict;

use GODOTConfig::DB::Sites;

##
## -do not import 'location' method from GODOT::Debug in order to avoid overriding 'location' method created
##  by 'Class::Accessor'
##
use GODOT::Debug qw(!location);

use base 'Class::Accessor';
__PACKAGE__->mk_accessors(GODOTConfig::DB::Config_Patr_Pickup_Choice->columns);

sub convert {
    my($self, $field, $config_obj) = @_;

    no strict 'refs';
    my $value = $config_obj->$field;
    use strict;

    return $value;
}

1;












