package GODOTConfig::Cache::Sites;

use strict;

use base 'Class::Accessor';

use GODOTConfig::DB::Sites;
use GODOT::Debug;


__PACKAGE__->mk_accessors(GODOTConfig::DB::Sites->columns);

sub convert {
    my($self, $field, $config_obj) = @_;

    no strict 'refs';
    my $value = $config_obj->$field;
    use strict;

    return $value;
}



1;












