#
# Copyright Todd Holbrook, Simon Fraser University (2003)
#
package GODOTConfig::DB::Config_Patr_Department_Choice;

use strict;
use base 'GODOTConfig::DB::DBI';

__PACKAGE__->table('config_patr_department_choice');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
	id
	site

	rank

        department
));                                                                                                        

__PACKAGE__->columns(Essential => __PACKAGE__->columns);
__PACKAGE__->sequence('config_patr_department_c_id_seq');


1;

