#
# Copyright Todd Holbrook, Simon Fraser University (2003)
#

package GODOTConfig::DB::Accounts;

use GODOTConfig::DB::Accounts_Sites;

use strict;
use base 'GODOTConfig::DB::DBI';

__PACKAGE__->table('accounts');

__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
	id
	key
	name
	password

	email
	phone

	administrator

	active
	
	created
	modified
));                                                                                                        

__PACKAGE__->columns(Essential => __PACKAGE__->columns);

__PACKAGE__->sequence('accounts_id_seq');

__PACKAGE__->has_many('sites', ['GODOTConfig::DB::Accounts_Sites' => 'site'], 'account');

1;


