#
# Copyright Todd Holbrook, Simon Fraser University (2003)
#
package GODOTConfig::DB::Config_Patr_Patron_Type_Choice;

use strict;
use base 'GODOTConfig::DB::DBI';

__PACKAGE__->table('config_patr_patron_type_choice');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
	id
	site

	rank

        type
));                                                                                                        

__PACKAGE__->columns(Essential => __PACKAGE__->columns);
__PACKAGE__->sequence('config_patr_patron_type__id_seq');


1;

