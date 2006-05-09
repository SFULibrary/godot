package GODOTConfig::Cache::Config_Patr_Pickup_Choice;

use strict;

use base 'Class::Accessor';

use GODOTConfig::DB::Sites;
use GODOT::Debug;


__PACKAGE__->mk_accessors(GODOTConfig::DB::Config_Patr_Pickup_Choice->columns);


sub convert {
    my($self, $field, $config_obj) = @_;

    no strict 'refs';
    my $value = $config_obj->$field;
    use strict;

    return $value;
}



1;












