#!/usr/local/bin/perl

use FindBin qw($Bin);

use lib ("$Bin/../local",  $Bin,  "$Bin/../GODOT/lib",  "$Bin/../GODOTConfig/lib");

use strict;

use Data::Dumper;
use Time::HiRes qw(gettimeofday);
use GODOT::Debug;
use GODOTConfig::Configuration;
use GODOTConfig::Cache;
use GODOTConfig::Sites;

my @sites_from_database = GODOTConfig::Sites->site_keys;

foreach my $site (sort @sites_from_database) {

    my $cache = new GODOTConfig::Cache;
    
    unless ($cache->write_to_cache_store($site)) {
        die "failed to write ", $site, " to cache"; 
    }
}

##
## -delete any sites in the cache that no longer exist in the database
##

my @sites_in_cache_store = GODOTConfig::Cache->sites_in_cache_store;

die 'no sites in cache store' unless scalar @sites_in_cache_store;

foreach my $site_in_store (@sites_in_cache_store) {

  unless (grep { $site_in_store eq $_ } @sites_from_database) {

      GODOTConfig::Cache->delete_from_cache_store($site_in_store); 
  } 

}
