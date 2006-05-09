#
# Copyright Todd Holbrook, Simon Fraser University (2003)
#
package GODOTConfig::DB::Config_Patr_Pickup_Choice;

use strict;
use base 'GODOTConfig::DB::DBI';

__PACKAGE__->table('config_patr_pickup_choice');
__PACKAGE__->columns(Primary => 'id');

__PACKAGE__->columns(All => qw(
	id
	site
	rank
        location
));                                                                                                        

__PACKAGE__->columns(Essential => __PACKAGE__->columns);
__PACKAGE__->sequence('config_patr_pickup_choic_id_seq');


1;

