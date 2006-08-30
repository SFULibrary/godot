#
# Copyright Todd Holbrook, Simon Fraser University (2003)
#
package GODOTConfig::DB::Config_Request_Non_Journal;

use strict;
use base 'GODOTConfig::DB::DBI';

__PACKAGE__->table('config_request_non_journal');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw(
	id
	site

        rank 

	request_site
	type
));                                                                                                        

__PACKAGE__->columns(Essential => __PACKAGE__->columns);
__PACKAGE__->sequence('config_request_non_journal_id_seq');

__PACKAGE__->has_a('site' => 'GODOTConfig::DB::Sites');
__PACKAGE__->has_a('request_site' => 'GODOTConfig::DB::Sites');


1;

