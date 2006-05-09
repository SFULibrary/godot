## GODOTConfig::ConfigTool::CGI::local_configuration
##
## Configuration details
##
## Copyright (c) 1997-2003, Todd Holbrook
##

package GODOTConfig::ConfigTool::CGI;

use GODOTConfig::ConfigTool::CGI::Config;
use GODOTConfig::Config;
use GODOTConfig::Options;
use GODOTConfig::Debug;

use strict;

sub process_local_configuration {
 	my ($self) = @_;
 	report_location if $C_CGI_TRACE;
	
	defined($self->current_site) or GODOTConfig::Exception::App::CGI->throw("Current site not set in local_configuration");

	$self->template->process('local_configuration', {}, $self->get_append_content);

	return 'complete';
}


# ------------------------ Generic --------------------------------

sub process_local_configuration_options {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;
	
	defined($self->current_site) or GODOTConfig::Exception::App::CGI->throw("Current site not set.");
        defined(param('section')) or GODOTConfig::Exception::App::CGI->throw("Section not specified.");
 
	my @all_sites = GODOTConfig::DB::Sites->retrieve_all;
	
        while ( my($option_name, $option_config) =  each %GODOTConfig::Config::GODOT_OPTION_CONFIG ) {

                if (defined $option_config->{'type'} && $option_config->{'type'} eq 'LIST') {

                        my $init_func = '_' . $option_name . '_init_string';
                        
                        no strict 'refs';
      	                my $current_init_string = $self->$init_func;
                        use strict;

	                if ($current_init_string ne '') {
		                $current_init_string = "init_array('$option_name', ${current_init_string});";
	                }

	                # Set onload with array setup and initializations
                                              
                        my $num_choices = scalar @{$option_config->{'choices'}};
                        my $required = join(',', (0 .. $num_choices - 1));

	                $self->onload($self->onload . "create_array('mainform', '${option_name}', ${num_choices}, '${required}', '0'); ${current_init_string}");
		}
        }


	$self->template->process('local_configuration_options', 
                                 {'site'          => $self->current_site,                                  
                                  'all_sites'     => [ @all_sites ], 
                                  'section'       => param('section'), 
                                  'option_config' => {%GODOTConfig::Config::GODOT_OPTION_CONFIG}
                                 }, 
                                 $self->get_append_content);





	return 'complete';
}

sub process_local_submit_configuration_options {
	my ($self) = @_;
	report_location if $C_CGI_TRACE;
	
	defined($self->current_site) or GODOTConfig::Exception::App::CGI->throw("Current site not set.");

        my @options = param('local_configuration_option_list');
        scalar(@options) or GODOTConfig::Exception::App::CGI->throw("No options specified.");

        my @allowed_options = GODOTConfig::DB::Sites->all_config_options;

        foreach my $option_name (@options) {

	        my $option_config = $GODOTConfig::Config::GODOT_OPTION_CONFIG{$option_name};

                if ((defined $option_config) && (defined $option_config->{'type'}) && ($option_config->{'type'} eq 'LIST'))   {
                     
                        my $db_package = "GODOTConfig::DB::Config_" . join('_', map { "\u$_" } split('_', $option_name));

	                $db_package->delete('site' => $self->current_site->id);

	                my $count = 0;
	                while (defined(my $value = param("${option_name}_value_${count}"))) {

 		                my @values = split /\|/, $value;
  
                                my $record_func = '_' . $option_name . '_record';
                                        
                                no strict 'refs';
      	                        my $record = $self->$record_func($count, \@values);
                                use strict;

                                use Data::Dumper;
                                                                                          		                
		                $db_package->create($record) or GODOTConfig::Exception::App::CGI->throw("Unable to create config_${option_name} record.");

		                $count++;
	                }
                        
	                GODOTConfig::DB::DBI->dbi_commit;
                }
                else {
                        my $param = 'config_' . $option_name;

                        unless (grep {$option_name eq $_} @allowed_options) { next; }
            
                        my $option = new GODOTConfig::Options($option_name, param($param));

                        unless ($option->verify) {
			        my $param_str = (defined param($param)) ? param($param) : '';
	                        GODOTConfig::Exception::App::CGI->throw("Invalid value ($param_str) for option ($option_name).");
                        }

                        $self->current_site->$option_name($option->value);

          	        $self->current_site->update;
	                $self->current_site->dbi_commit;
 	        }
        }
	     
        ## Save to cache
        
        use GODOTConfig::Cache;
        my $cache = new GODOTConfig::Cache;
        my $key = $self->current_site->key;
        $cache->write_to_cache_store($key) or GODOTConfig::Exception::App::CGI->throw("Unable to write site " . $key . " to cache.");

	return 'local_configuration';
}

#
#  _<option>_init_string and _<option>_record functions 
#

#
# For 'rank' option.
#

sub _rank_init_string {
    my($self) = @_;
    my @current_htr;

    foreach my $elem ($self->current_site->rank) {
 
        my $display_group = ($elem->display_group) ? $elem->display_group : '';
        my $search_group  = ($elem->search_group)  ? $elem->search_group : '';

	push @current_htr, "'" . $elem->rank_site->key . "'";		
	push @current_htr, "'" . $display_group . "'";		
	push @current_htr, "'" . $search_group . "'";		
	push @current_htr, "'" . ($elem->auto_req ? 'show' : '') . "'";
    }

    #### debug "----------------------------------------------------------";
    #### debug join('-', @current_htr), "\n";
    #### debug "----------------------------------------------------------";


    return join(',', @current_htr);
}


sub _rank_record {
    my($self, $count, $values) = @_;

    my @holdings_sites = GODOTConfig::DB::Sites->search('key' => ${$values}[0]);
    my $holdings_site = $holdings_sites[0] or GODOTConfig::Exception::App::CGI->throw("Unable to find site for key: ${$values}[0]");

    return {'site'           => int($self->current_site->id),
	    'rank'           => $count,
	    'rank_site'      => int($holdings_site->id),
	    'display_group'  => (${$values}[1] ? int(${$values}[1]) : 0),
	    'search_group'   => (${$values}[2] ? int(${$values}[2]) : 0),
	    'auto_req'       => ((${$values}[3] eq 'show') ? 't' : 'f')
           };
}

#
# For 'rank_non_journal' option.
#

sub _rank_non_journal_init_string {
    my($self) = @_;
    my @current_htr;

    foreach my $elem ($self->current_site->rank_non_journal) {
 
	my $display_group = ($elem->display_group) ? $elem->display_group : '';
        my $search_group  = ($elem->search_group)  ? $elem->search_group : '';

	push @current_htr, "'" . $elem->rank_site->key . "'";		
	push @current_htr, "'" . $display_group . "'";		
	push @current_htr, "'" . $search_group . "'";		
	push @current_htr, "'" . ($elem->auto_req ? 'show' : '') . "'";
    }
    return join(',', @current_htr);
}

sub _rank_non_journal_record {
    my($self, $count, $values) = @_; 
    return $self->_rank_record($count, $values);
}


#
# For 'request' option.
#

sub _request_init_string {
    my($self) = @_;

    my @current_htr;

    foreach my $elem ($self->current_site->request) {
 
	push @current_htr, "'" . $elem->request_site->key . "'";		
	push @current_htr, "'" . $elem->type . "'";		
    }
    return join(',', @current_htr);
}


sub _request_record {
    my($self, $count, $values) = @_;

    my @holdings_sites = GODOTConfig::DB::Sites->search('key' => ${$values}[0]);
    my $holdings_site = $holdings_sites[0] or GODOTConfig::Exception::App::CGI->throw("Unable to find site for key: ${$values}[0]");

    return { 'site'           => int($self->current_site->id),
	     'rank'           => $count,
	     'request_site'   => int($holdings_site->id),
	     'type'           => ${$values}[1],
           };
		
}


#
# For 'request_non_journal' option.
#

sub _request_non_journal_init_string {
    my($self) = @_;

    my @current_htr;

    foreach my $elem ($self->current_site->request_non_journal) {
 
	push @current_htr, "'" . $elem->request_site->key . "'";		
	push @current_htr, "'" . $elem->type . "'";		
    }
    return join(',', @current_htr);
}


sub _request_non_journal_record {
    my($self, $count, $values) = @_; 
    return $self->_request_record($count, $values);
}

#
# For 'patr_patron_type_choice' option.
#

sub _patr_patron_type_choice_init_string {
    my($self) = @_;

    my @current_htr;

    foreach my $elem ($self->current_site->patr_patron_type_choice) {
 	push @current_htr, "'" . $elem->type . "'";		
    }
    return join(',', @current_htr);
}

sub _patr_patron_type_choice_record {
    my($self, $count, $values) = @_;

    return { 'site'           => int($self->current_site->id),
	     'rank'           => $count,
	     'type'           => ${$values}[0],
           };
}


#
# For 'patr_pickup_choice' option.
#

sub _patr_pickup_choice_init_string {
    my($self) = @_;

    my @current_htr;

    foreach my $elem ($self->current_site->patr_pickup_choice) {
 	push @current_htr, "'" . $elem->location . "'";		
    }
    return join(',', @current_htr);
}

sub _patr_pickup_choice_record {
    my($self, $count, $values) = @_;

    return { 'site'           => int($self->current_site->id),
	     'rank'           => $count,
	     'location'       => ${$values}[0],
           };
}

#
# For 'patr_department_choice' option.
#

sub _patr_department_choice_init_string {
    my($self) = @_;

    my @current_htr;

    foreach my $elem ($self->current_site->patr_department_choice) {
 	push @current_htr, "'" . $elem->department . "'";		
    }
    return join(',', @current_htr);
}

sub _patr_department_choice_record {
    my($self, $count, $values) = @_;

    return { 'site'           => int($self->current_site->id),
	     'rank'           => $count,
	     'department'     => ${$values}[0],
           };
}

#
# For 'patr_paid_choice' option.
#

sub _patr_paid_choice_init_string {
    my($self) = @_;

    my @current_htr;

    foreach my $elem ($self->current_site->patr_paid_choice) {
 	push @current_htr, "'" . $elem->payment_method . "'";
        push @current_htr, "'" . ($elem->input_box ? 't' : '') . "'";
    }
    return join(',', @current_htr);
}

sub _patr_paid_choice_record {
    my($self, $count, $values) = @_;

    return { 'site'           => int($self->current_site->id),
	     'rank'           => $count,
	     'payment_method' => ${$values}[0],
             'input_box'      => ((${$values}[1] eq 't') ? 't' : 'f')
           };
}

#
# For 'ill_req_form_limit' option.
#

sub _ill_req_form_limit_init_string {
    my($self) = @_;

    my @current_htr;

    foreach my $elem ($self->current_site->ill_req_form_limit) {
 	push @current_htr, "'" . $elem->patron_type . "'";
        push @current_htr, "'" . $elem->message . "'";
    }
    return join(',', @current_htr);
}

sub _ill_req_form_limit_record {
    my($self, $count, $values) = @_;

    return { 'site'        => int($self->current_site->id),
	     'rank'        => $count,
	     'patron_type' => ${$values}[0],
	     'message'     => ${$values}[1],
           };
}


#
# For 'ill_account' option.
#

sub _ill_account_init_string {
    my($self) = @_;

    my @current_htr;

    foreach my $elem ($self->current_site->ill_account) {
 	push @current_htr, "'" . $elem->account_site->key . "'";
        push @current_htr, "'" . $elem->number . "'";
    }
    return join(',', @current_htr);
}

sub _ill_account_record {
    my($self, $count, $values) = @_;

    my @account_sites = GODOTConfig::DB::Sites->search('key' => ${$values}[0]);
    my $account_site  = $account_sites[0] or GODOTConfig::Exception::App::CGI->throw("Unable to find site for key: ${$values}[0]");

    return { 'site'        => int($self->current_site->id),
	     'rank'        => $count,
	     'account_site'=> int($account_site->id),
	     'number'      => ${$values}[1],
           };
}




1;












