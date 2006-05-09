#
# Copyright Todd Holbrook, Simon Fraser University (2003)
#

package GODOTConfig::DB::Accounts_Sites;

use strict;
use base 'GODOTConfig::DB::DBI';

__PACKAGE__->table('accounts_sites');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
	id

	account
	site
		
	created
	modified
));                                                                                                        

__PACKAGE__->columns(Essential => __PACKAGE__->columns);
__PACKAGE__->sequence('accounts_sites_id_seq');

__PACKAGE__->has_a('account' => 'GODOTConfig::DB::Accounts');
__PACKAGE__->has_a('site' => 'GODOTConfig::DB::Sites');


1;

