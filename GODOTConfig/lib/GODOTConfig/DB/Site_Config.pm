#
# Copyright Todd Holbrook, Simon Fraser University (2003)
#

package GODOTConfig::DB::Site_Config;

use GODOTConfig::DB::Sites;

use strict;
use base 'GODOTConfig::DB::DBI';


__PACKAGE__->table('site_config');

__PACKAGE__->columns(Primary => 'id');

__PACKAGE__->columns(All => qw(
	id

	site
	config_group
	field
	value
	created
	modified
));                                                                                                        

__PACKAGE__->columns(Essential => __PACKAGE__->columns);


__PACKAGE__->sequence('site_config_id_seq');

__PACKAGE__->has_a('site' => 'GODOTConfig::DB::Sites');


1;
