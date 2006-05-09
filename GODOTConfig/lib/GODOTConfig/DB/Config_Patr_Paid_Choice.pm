#
# Copyright Todd Holbrook, Simon Fraser University (2003)
#
package GODOTConfig::DB::Config_Patr_Paid_Choice;

use strict;
use base 'GODOTConfig::DB::DBI';

__PACKAGE__->table('config_patr_paid_choice');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
	id
	site

	rank

        payment_method
        input_box
));                                                                                                        

__PACKAGE__->columns(Essential => __PACKAGE__->columns);
__PACKAGE__->sequence('config_patr_paid_choice_id_seq');


1;

