package GODOTConfig::Cache;

use Class::Accessor;
use base 'Class::Accessor';

use Data::Dumper;

use GODOTConfig::Config;
use GODOTConfig::Exceptions;
use GODOTConfig::Debug;

use GODOTConfig::Cache::Sites;
use GODOTConfig::Cache::Config_Ill_Account;
use GODOTConfig::Cache::Config_Ill_Req_Form_Limit;

use GODOTConfig::Cache::Config_Patr_Department_Choice;
use GODOTConfig::Cache::Config_Patr_Paid_Choice;
use GODOTConfig::Cache::Config_Patr_Patron_Type_Choice;
use GODOTConfig::Cache::Config_Patr_Pickup_Choice;

use GODOTConfig::Cache::Config_Rank;
use GODOTConfig::Cache::Config_Rank_Non_Journal;

use GODOTConfig::Cache::Config_Request;
use GODOTConfig::Cache::Config_Request_Non_Journal;


use GODOT::String;
use GODOT::Debug;

use strict;

my $TRUE  = 1;
my $FALSE = 0;

use vars qw($AUTOLOAD);

__PACKAGE__->mk_accessors('site',                                  
                          'type',
			  GODOTConfig::DB::Sites->config_has_many,
			  GODOTConfig::DB::Sites->config_columns
                         );

##
## Class methods
##

{
    my $cache;
    my $id_to_key_map;

    sub init_cache {
        my($class) = @_;

        report_time_location;

        unless (opendir CACHE_DIR, $GODOTConfig::Config::GODOT_CONFIG_CACHE_DIR) {
            error "unable to open directory $GODOTConfig::Config::GODOT_CONFIG_CACHE_DIR:  $!";
            return undef;
        }

        my @cache_files = readdir CACHE_DIR; 
        closedir CACHE_DIR;

        use Storable qw(retrieve);

        foreach my $file (@cache_files) {

            next if (($file eq '.') || ($file eq '..'));
                     
            ##
            ## -$file needs to be a site key, eg. 'BVAS'
            ##

            $cache->{$file} = retrieve("$GODOTConfig::Config::GODOT_CONFIG_CACHE_DIR/$file"); 
        }        

        foreach my $site (keys %{$cache}) {
            my $id = $cache->{$site}->site->id;
            $id_to_key_map->{$id} = $site;
        }     

        report_time_location;
    }

    ##
    ## returns GODOTConfig::Configuration object
    ##
    sub configuration_from_cache {
        my($class, $site) = @_;

        (defined $cache->{$site}) or error "no cache found for $site";

        return $cache->{$site};
    }

    ##
    ## returns list of sites, eg. ('BVAS', 'BVASB', 'BVASS')
    ##
    sub sites_in_cache {
        my($class) = @_;
        return keys %{$cache};
    }

    sub id_to_key {
        my($class, $id) = @_;
        return $id_to_key_map->{$id};
    }

}

##
## The 'cache store' is the copy on disk which is then loaded into memory with 'init_cache'.
## Other cache routines use the copy in memory. 
##
sub sites_in_cache_store {
     my($class) = @_;

    unless (opendir CACHE_DIR, $GODOTConfig::Config::GODOT_CONFIG_CACHE_DIR) {
        error "unable to open directory $GODOTConfig::Config::GODOT_CONFIG_CACHE_DIR:  $!";
        return;
    }

    my @cache_files = grep !/^\.\.?$/, readdir CACHE_DIR;

    closedir CACHE_DIR;

    return @cache_files;
}

sub delete_from_cache_store {
    my($class, $site) = @_;

    return undef if aws($site);
   
    my $file = "$GODOTConfig::Config::GODOT_CONFIG_CACHE_DIR/$site";

    return undef if (-d $file);   ## -should never happen

    if (-e $file) {
         return undef unless (unlink "$GODOTConfig::Config::GODOT_CONFIG_CACHE_DIR/$site");        
    }
   
    debug "deleted $site from cache store"; 
    return $file;
}

##
## Object methods
##

sub new {
    my($class) = @_; 
       		
    return bless {}, $class;
}

sub write_to_cache_store {
    my($self, $site) = @_;

    my $filename = "$GODOTConfig::Config::GODOT_CONFIG_CACHE_DIR/$site";

    my $config = new GODOTConfig::Configuration($site);
    unless (defined $config) {
        error "cannot create GODOTConfig::Configuration object for $site";
        return undef;
    }

    $self->copy_from_configuration($config);

    use Storable qw(store_fd);
    use Fcntl qw(:DEFAULT :flock);

    unless (sysopen(DF, $filename, O_RDWR|O_CREAT, 0666))  {
         error "cannot open $filename:  $!";
         return undef;
    }

    unless (flock(DF, LOCK_EX)) {
        error "cannot lock $filename:  $!";
        return undef;
    }

    unless (store_fd($self, *DF)) {
        error "cannot store to $filename:  $!";
        return undef;
    }

    truncate(DF, tell(DF));
    close(DF);

    debug "wrote $site to cache store";

    return $self;
}

##
## Copy from GODOTConfig::Configuration object
##
sub copy_from_configuration  {
    my($self, $config) = @_;   

    ##
    ## Copy all scalar
    ##
    no strict 'refs';
    foreach my $field ('type', GODOTConfig::DB::Sites->config_columns) {
        $self->$field($config->$field);      
    }
    use strict;

    ##
    ## Copy lists of objects
    ##

    ##
    ## ??????????????? can we get map from GODOTConfig::DB::Sites::has_many ?????
    ##

    my %obj_mapping = ('site'                    => 'Sites',
                       'rank'                    => 'Config_Rank',
                       'rank_non_journal'        => 'Config_Rank_Non_Journal',
                       'request'                 => 'Config_Request',
                       'request_non_journal'     => 'Config_Request_Non_Journal',
                       'patr_patron_type_choice' => 'Config_Patr_Patron_Type_Choice',
                       'patr_pickup_choice'      => 'Config_Patr_Pickup_Choice',
                       'ill_req_form_limit'      => 'Config_Ill_Req_Form_Limit',
                       'patr_paid_choice'        => 'Config_Patr_Paid_Choice',
                       'ill_account'             => 'Config_Ill_Account',
                       'patr_department_choice'  => 'Config_Patr_Department_Choice');

    no strict 'refs';

    foreach my $field ('site', GODOTConfig::DB::Sites->config_has_many) {

        my @config_objs = (ref($config->$field) eq 'ARRAY') ? @{$config->$field} : ($config->$field); 

        my $config_package = "GODOTConfig::DB::$obj_mapping{$field}";
        my $cache_package  = "GODOTConfig::Cache::$obj_mapping{$field}";

        my @cache_objs; 

        foreach my $config_obj (@config_objs) {

            my $cache_obj = new $cache_package;
            foreach my $obj_field ($config_package->columns) {

		 my $value = $cache_obj->convert($obj_field, $config_obj);

                 ##
                 ## (27-mar-2006 kl) - problems using variable for method name when using Class::Accessor
                 ##                  - try $obj_field equal to 'location'
                 ## 
                 #### $cache_obj->$obj_field($value);

                 $cache_obj->set($obj_field, $value);
            }
            push @cache_objs, $cache_obj;
        } 

        if ($field eq 'site') { 
            $self->$field($cache_objs[0]); 
        }
        else  { 
            $self->$field([ @cache_objs ]); 
        }        
    }
    use strict;
}

sub rank_for_search_group {
        my($self, $search_group) = @_;

        my $rank_list = $self->rank;
        my $max_search_group = $self->max_search_group;

        my $other_group_field = $self->other_rank_search_group; 

        return $self->_rank_for_search_group($rank_list, $search_group, $max_search_group, $other_group_field);
}

sub rank_for_search_group_non_journal {
        my($self, $search_group) = @_;

        my $rank_list = $self->rank_non_journal;
        my $max_search_group = $self->max_search_group_non_journal;
        my $other_group_field = $self->other_rank_non_journal_search_group; 

        return $self->_rank_for_search_group($rank_list, $search_group, $max_search_group, $other_group_field);
}

sub _rank_for_search_group {
    my($self, $rank_list, $search_group, $max_search_group, $other_group_field) = @_;

    my @rank_arr;
    return @rank_arr unless defined $rank_list;

    ##
    ## -need to determine first if a search group is specified for any of the listed sites
    ## -if not then, consider that all sites are in group '1'
    ## -if search groups are specified for some sites, then all those that are blank will be in 
    ##  the last group specified plus 1.
    ##

    my $search_group_specified = $FALSE;

    if (scalar @{$rank_list}) {

        foreach my $obj (@{$rank_list}) {

            if ($obj->search_group >= 1) {  $search_group_specified = $TRUE; }
        }
    }
 
    if (scalar @{$rank_list}) {

        foreach my $obj (@{$rank_list}) {

            if    ($obj->search_group eq $search_group)  { 
                push(@rank_arr, $obj->rank_site); 
            }
            elsif ((aws($obj->search_group) || ($obj->search_group == 0)) && ($other_group_field eq $search_group))  { 
                push(@rank_arr, $obj->rank_site); 
            } 
            elsif (($obj->search_group < 1) && ($max_search_group eq $search_group)) { 
                push(@rank_arr, $obj->rank_site); 
            }         
        }
    }

    return @rank_arr;
}



sub auto_req_hash {
    my($self) = @_;

    my $rank_list = $self->rank;

    my %auto_req;        
    return %auto_req unless defined $rank_list;

    foreach my $obj (@{$rank_list}) {
   	$auto_req{$obj->rank_site} = $obj->auto_req;
    }
    return %auto_req;
}

sub auto_req_non_journal_hash {
    my($self) = @_;

    my $rank_list = $self->rank_non_journal;
        
    my %auto_req;
    return %auto_req unless defined $rank_list;

    foreach my $obj (@{$rank_list}) {
   	$auto_req{$obj->rank_site} = $obj->auto_req;
    }
    return %auto_req;
}

sub max_search_group  { 
    my($self) = @_;

    $self->max_group('search', @_);   
}

sub max_search_group_non_journal  { 
    my($self) = @_;

    $self->max_group_non_journal('search', @_);   
}


sub max_display_group  { 
    my($self) = @_;

    $self->max_group('display', @_);  
}

sub max_display_group_non_journal { 
    my($self) = @_;

    $self->max_group_non_journal('display', @_);  
}

sub max_group {
    my($self, $type) = @_;

    my $rank_list = $self->rank;

    my $other_field = ($type eq 'search') ? $self->other_rank_search_group : 
                                            $self->other_rank_display_group;


    return $self->_max_group($type, $rank_list, $other_field);
}

sub max_group_non_journal {
    my($self, $type) = @_;

    my $rank_list = $self->rank_non_journal;
    my $other_field = ($type eq 'search') ? $self->other_rank_non_journal_search_group : 
                                            $self->other_rank_non_journal_display_group;

    return $self->_max_group($type, $rank_list, $other_field);
}

sub _max_group {
    my($self, $type, $rank_list, $other_field) = @_;

    my $group_field;

    if    ($type eq 'search')     { $group_field = 'search_group';  }
    elsif ($type eq 'display')    { $group_field = 'display_group'; }

    my $max_group = 0;

    if ((defined $rank_list) && (scalar @{$rank_list})) {

        foreach my $obj (@{$rank_list}) {

            if ($obj->$group_field >= 1) { 

                if ($obj->$group_field > $max_group) { $max_group = $obj->$group_field; }
            }
        }
    }

    ##
    ## -default search group
    ##    
    if ($other_field > $max_group) { $max_group = $other_field; }

    $max_group++;        ## -'last group specified plus one'

    return $max_group;   
}

sub display_group {
    my($self, $display_site) = @_;

    my $rank_list = $self->rank;
    my $max_display_group = $self->max_display_group;

    my $other_group_field = $self->other_rank_display_group;

    return $self->_display_group($display_site, $rank_list, $other_group_field, $max_display_group);
}
 
sub display_group_non_journal {
    my($self, $display_site) = @_;

    my $rank_list = $self->rank_non_journal;
    my $max_display_group = $self->max_display_group_non_journal;

    my $other_group_field = $self->other_rank_non_journal_display_group;

    return $self->_display_group($display_site, $rank_list, $other_group_field, $max_display_group);
}
 
sub _display_group {
    my($self, $display_site, $rank_list, $other_group_field, $max_display_group) = @_;
    
    my $default = (naws($other_group_field)) ? $other_group_field : $max_display_group;
    $default = '' if $default == 0;     

    return $default unless defined $rank_list;

    foreach my $obj (@{$rank_list}) {

        if ($obj->rank_site eq $display_site) { 

            if (aws($obj->display_group) || ($obj->display_group == 0)) { return $default;            }
            else                                                        { return $obj->display_group; } 

        }
    }

    return $default;
}

sub search_group {
    my($self, $search_site) = @_;

    my $rank_list = $self->rank;
    my $max_search_group = $self->max_search_group;
    my $other_rank_search_group = $self->other_rank_search_group;

    my $search_group = $self->_search_group($rank_list, $other_rank_search_group, $max_search_group);

    return $search_group;
}

sub search_group_non_journal {
    my($self, $search_site) = @_;

    my $rank_list = $self->rank_non_journal;
    my $max_search_group = $self->max_search_group_non_journal;
    my $other_rank_search_group = $self->other_rank_non_journal_search_group;

    my $search_group = $self->_search_group($rank_list, $other_rank_search_group, $max_search_group);

    return $search_group;
}


sub _search_group {
    my($self, $rank_list, $other_group_field, $max_search_group) = @_;

    my $default = (naws($other_group_field)) ? $other_group_field : $max_search_group; 
    $default = '' if $default == 0;     

    return $default unless defined $rank_list;

    my $search_site = $self->site->key;

    foreach my $obj (@{$rank_list}) {

        if ($obj->rank_site eq $search_site) {             
            if (aws($obj->search_group) || ($obj->search_group == 0)) { return $default;           }
            else                                                      { return $obj->search_group; } 
        }
    }
    return $default;
}


sub name {
    my($self) = @_;

    return $self->site->key;
}

sub full_name {
    my($self) = @_;

    return $self->site->name;
}


sub account_number {
    my($self, $account_site) = @_;

    foreach my $obj (@{$self->ill_account}) {
        if ($obj->account_site eq $account_site) {
             return $obj->number;
	}
    }
}

sub patron_types {
    my($self) = @_;

    my @list;
    foreach my $obj (sort sort_by_rank @{$self->patr_patron_type_choice}) {
        push @list, $obj->type;
    }
    return @list;
}

sub departments {
    my($self) = @_;

    my @list;
    foreach my $obj (sort sort_by_rank @{$self->patr_department_choice}) {
        push @list, $obj->department;
    }
    return @list;
}

sub payment_methods {
    my($self) = @_;

    my @list;
    foreach my $obj (sort sort_by_rank @{$self->patr_paid_choice}) {
        push @list, $obj->payment_method;
    }
    return @list;
}

sub ill_req_form_message {
    my($self, $patron_type) = @_;

    foreach my $obj (sort sort_by_rank @{$self->ill_req_form_limit}) {

        if (trim_beg_end($obj->patron_type) eq trim_beg_end($patron_type)) {
            return trim_beg_end($obj->message); 
        } 
    }

    return undef;
}

sub pickup_locations {
    my($self) = @_;

    debug "---------------------";
    debug Dumper($self);
    debug "---------------------";

    my @list;
    foreach my $obj (sort sort_by_rank @{$self->patr_pickup_choice}) {
        push @list, $obj->location;
    }
    return @list;
}

sub request_types  {
    my($self) = @_;

    my %types;

    foreach my $obj (@{$self->request}) {
        $types{$obj->request_site} = $obj->type;
    }
    return %types;
}

sub request_non_journal_types {
    my($self) = @_;

    my %types;
    foreach my $obj (@{$self->request_non_journal}) {
   	$types{$obj->request_site} = $obj->type;
    }
    return %types;
}


sub sort_by_rank {
    return $a->rank <=> $b->rank;
}


sub ill_req_form_always {
    my($self) = @_;
  
    return ($self->ill_req_form eq 'T');
}

sub ill_req_form_non_journal_always {
    my($self) = @_;
  
    return ($self->ill_req_form_non_journal eq 'T');
}

sub ill_req_form_if_nothing_avail_to_request {
    my($self) = @_;
  
    return ($self->ill_req_form eq 'T_NO_REQ_AVAIL');
}

sub ill_req_form_non_journal_if_nothing_avail_to_request {
    my($self) = @_;
  
    return ($self->ill_req_form_non_journal eq 'T_NO_REQ_AVAIL');
}


1;












