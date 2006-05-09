package GODOTConfig::DB::Config_Rank_Non_Journal;

use strict;
use base 'GODOTConfig::DB::DBI';

__PACKAGE__->table('config_rank_non_journal');
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
__PACKAGE__->sequence('config_rank_non_journal_id_seq');

__PACKAGE__->has_a('site' => 'GODOTConfig::DB::Sites');
__PACKAGE__->has_a('rank_site' => 'GODOTConfig::DB::Sites');


1;

