#
# Copyright Todd Holbrook, Simon Fraser University (2003)
#
package GODOTConfig::DB::Config_Ill_Account;

use strict;
use base 'GODOTConfig::DB::DBI';

__PACKAGE__->table('config_ill_account');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
	id
	site

	rank

	account_site
	number
));                                                                                                        

__PACKAGE__->columns(Essential => __PACKAGE__->columns);
__PACKAGE__->sequence('config_ill_account_id_seq');

__PACKAGE__->has_a('site' => 'GODOTConfig::DB::Sites');
__PACKAGE__->has_a('account_site' => 'GODOTConfig::DB::Sites');


1;

