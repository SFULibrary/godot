#
# Copyright Todd Holbrook, Simon Fraser University (2003)
#
package GODOTConfig::DB::Config_Rank;

use strict;
use base 'GODOTConfig::DB::DBI';

__PACKAGE__->table('config_rank');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
	id

	site

	rank
	rank_site
	display_group
	search_group
	auto_req
));                                                                                                        

__PACKAGE__->columns(Essential => __PACKAGE__->columns);
__PACKAGE__->sequence('config_rank_id_seq');

__PACKAGE__->has_a('site' => 'GODOTConfig::DB::Sites');
__PACKAGE__->has_a('rank_site' => 'GODOTConfig::DB::Sites');


1;

