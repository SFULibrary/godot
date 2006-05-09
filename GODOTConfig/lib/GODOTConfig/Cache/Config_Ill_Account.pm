package GODOTConfig::Cache::Config_Ill_Account;

use strict;

use base 'Class::Accessor';

use GODOTConfig::DB::Sites;
use GODOT::Debug;


__PACKAGE__->mk_accessors(GODOTConfig::DB::Config_Ill_Account->columns);


sub convert {
    my($self, $field, $config_obj) = @_;

    my @convert = qw(site account_site);

    no strict 'refs';
    my $value = (grep { $field eq $_ } @convert) ? $config_obj->$field->key : $config_obj->$field;
    use strict;

    return $value;
}


1;












