#
# Copyright Todd Holbrook, Simon Fraser University (2003)
#

package GODOTConfig::DB::Site_Chains;

use strict;
use base 'GODOTConfig::DB::DBI';

__PACKAGE__->table('site_chains');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
	id

	site
	rank
	chain
));                                                                                                        

__PACKAGE__->columns(Essential => __PACKAGE__->columns);
__PACKAGE__->sequence('site_chains_id_seq');

__PACKAGE__->has_a('site' => 'GODOTConfig::DB::Sites');
__PACKAGE__->has_a('chain' => 'GODOTConfig::DB::Sites');


1;

