package GODOTConfig::Cache::Config_Ill_Req_Form_Limit;

use strict;

use base 'Class::Accessor';

use GODOTConfig::DB::Sites;
use GODOT::Debug;


__PACKAGE__->mk_accessors(GODOTConfig::DB::Config_Ill_Req_Form_Limit->columns);


sub convert {
    my($self, $field, $config_obj) = @_;

    no strict 'refs';
    my $value = $config_obj->$field;
    use strict;

    return $value;
}



1;












