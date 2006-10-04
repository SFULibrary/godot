#!/usr/local/bin/perl
##
## GODOTConfig profile cache update script.

use FindBin qw($Bin);

use lib ("$Bin/../local",  $Bin,  "$Bin/../GODOT/lib",  "$Bin/../GODOTConfig/lib");

use strict;

use Data::Dumper;
use Time::HiRes qw(gettimeofday);
use Term::ReadLine;

use Install::GODOT;
use GODOT::String;
use GODOT::Debug;
use GODOTConfig::Cache;
use GODOTConfig::Sites;

my $TRUE  = 1;
my $FALSE = 0;

my $term = new Term::ReadLine 'GODOT Profile Cache Update';

&show_introduction;

printw "Do you want to continue?";
my $input = $term->readline('[Y/n]: ');
if ($input =~ /^\s*n/i) {
    exit;
}

printw "\nUpdating site profile cache ...\n";

my @sites_from_database = GODOTConfig::Sites->site_keys;
my @cache_files;

foreach my $site (sort @sites_from_database) {

    my $cache = new GODOTConfig::Cache;
    
    unless ($cache->write_to_cache_store($site)) {
        die "failed to write ", $site, " to cache"; 
    }

    push @cache_files, $cache->filename;
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


##
## Does the user want to change the ownership or permissions of the cache files.
##

printw "\nChanging profile cache ownership and permissions ...\n";

&set_permissions([@cache_files], $term, $FALSE);





sub show_introduction {
    print "Updating the GODOT Profile File Cache\n";
    print "=====================================\n";
    printw "The public interface to GODOT uses profile cache files instead of making direct calls to the ", 
           "GODOT configuration database.\n\n",
           "This script should be used to update the profile cache ", 
           "after installing the demo profiles.\n\n"; 
    printw "It can also be used to update the cache anytime modifications ", 
           "are made to the profile database outside of the GODOT configuration tool.\n\n";
}



1;

__END__












