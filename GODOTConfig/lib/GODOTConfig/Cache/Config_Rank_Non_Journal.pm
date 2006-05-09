package GODOTConfig::Cache::Config_Rank_Non_Journal;

use strict;

use base 'Class::Accessor';

use GODOTConfig::DB::Sites;
use GODOT::Debug;


__PACKAGE__->mk_accessors(GODOTConfig::DB::Config_Rank_Non_Journal->columns);


sub convert {
    my($self, $field, $config_obj) = @_;

    my @convert = qw(site rank_site);

    no strict 'refs';
    my $value = (grep { $field eq $_ } @convert) ? $config_obj->$field->key : $config_obj->$field;
    use strict;

    return $value;
}




1;












