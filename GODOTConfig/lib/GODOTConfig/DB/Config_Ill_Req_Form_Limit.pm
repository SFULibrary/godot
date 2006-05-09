#
# Copyright Todd Holbrook, Simon Fraser University (2003)
#
package GODOTConfig::DB::Config_Ill_Req_Form_Limit;

use strict;
use base 'GODOTConfig::DB::DBI';

__PACKAGE__->table('config_ill_req_form_limit');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
	id
	site

	rank

	patron_type
	message
));                                                                                                        

__PACKAGE__->columns(Essential => __PACKAGE__->columns);
__PACKAGE__->sequence('config_ill_req_form_limi_id_seq');


1;

