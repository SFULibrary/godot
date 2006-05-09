package GODOT::Page;

## GODOT::Page
##
## Copyright (c) 2002, Kristina Long, Simon Fraser University
##

use GODOT::Constants;
use GODOT::Config;
use GODOT::Debug;
use GODOT::String;

use strict;

##
## -????? should these be in Constants.pm instead ????
##

use vars qw($ILL_FORM_COMP
            $INSTRUCTIONS_COMP          

            $LINK_TEMPLATE_COMP

            $CITATION_COMP
            $ERIC_COLL_COMP             
            $MLOG_COLL_COMP             

            $HOLDINGS_RESULT_COMP
            $LINK_COMP                  
            $LINK_FROM_CAT_COMP

            $PREPRINT_COMP
            $AUTO_REQ_COMP
            $CITATION_MANAGER_COMP

            $SHOW_ALL_COMP
            $SEARCH_ALL_COMP
            $ANOTHER_SCRNO_COMP);

$INSTRUCTIONS_COMP           = 'instructions_comp';
$LINK_TEMPLATE_COMP          = 'link_template_comp';
$CITATION_COMP               = 'citation_comp';
$LINK_COMP                   = 'link_comp';
$LINK_FROM_CAT_COMP          = 'link_from_cat_comp';  
$ERIC_COLL_COMP              = 'eric_coll_comp';
$MLOG_COLL_COMP              = 'mlog_coll_comp';
$PREPRINT_COMP               = 'preprint_comp';
$HOLDINGS_RESULT_COMP        = 'holdings_result_comp';
$ILL_FORM_COMP               = 'ill_form_comp';
$AUTO_REQ_COMP               = 'auto_requesting_comp';
$CITATION_MANAGER_COMP       = 'citation_manager_comp';
$SHOW_ALL_COMP               = 'show_all_comp';
$SEARCH_ALL_COMP             = 'search_all_comp';
$ANOTHER_SCRNO_COMP          = 'another_scrno_comp';


use vars qw($TRIED_NO_HOLDINGS $NOT_TRIED);

$TRIED_NO_HOLDINGS        = 'tried_no_holdings';
$NOT_TRIED                = 'not_tried';


use vars qw($AUTOLOAD);

my %fields = (
    'scrno'               => undef,
    'title'               => undef,
    'user'                => undef,
    'user_full_name'      => undef,
    'remote_host'         => undef,
    'form_url'            => undef,
    'form_input'          => undef,
    'hidden_fields'       => undef,
    'session_id'          => undef,

    'search_messages'         => undef,
    'messages'                => undef,
    'your_library_has_warning'=> undef,
    'instructions'            => undef,
    'citation_is_complete'    => undef,
    'has_get_link'            => undef,
    'has_request_link'        => undef,
    'has_check_link'          => undef,
    'has_auto_req_link'       => undef,
    'has_hidden_record'       => undef,

    'ill_request_type'        => undef,            ## eg. 'S' (retrieval), 'D' (direct), 'N' (new), etc.
    'records'                 => undef,
    'buttons'                 => undef,    
    'template_vars'           => undef,

    'local'                   => undef
);

sub new {
    my $that = shift;
    my $class = ref($that) || $that;

    my $fields_ref = (@_) ? {@_} : \%fields;

    my $self = {
        '_permitted' => $fields_ref,
        %{$fields_ref}
    };

    bless $self, $class;
    return $self;
}

##
## -parameter is a reference to an array of one or more form input elements 
##
sub form_input {
    my $self = shift;    
    my $class = ref($self) || error("Page::form_input - self is not an object");

    my $form_input_ref = shift;    
 
    my $field = 'form_input';

    if (ref($form_input_ref)  &&  @{$form_input_ref}) { push(@{$self->{$field}}, @{$form_input_ref}); }

    if (defined $self->{$field}) { return $self->{$field}; }    
    else                         { return [];                 }  
} 

##
## -parameter is a reference to an array of one or more records 
##
sub records {
    my $self = shift;    
    my $class = ref($self) || error("Page::records - self is not an object");
    my $record_ref = shift;    
 
    my $field = 'records';

    if (ref($record_ref)  &&  @{$record_ref}) { push(@{$self->{$field}}, @{$record_ref}); }

    if (defined $self->{$field}) { return $self->{$field}; }    
    else                         { return [];                 }  
} 

sub buttons {
    my $self = shift;    
    my $class = ref($self) || error("Page::buttons - self is not an object");
    my $button_ref = shift;    
 
    my $field = 'buttons';

    if (ref($button_ref)  &&  @{$button_ref}) { push(@{$self->{$field}}, @{$button_ref}); }

    if (defined $self->{$field}) { return $self->{$field}; }    
    else                         { return [];                 }  
} 


sub messages {
    my $self = shift;    
    my $class = ref($self) || error("Page::messages - self is not an object");
    my $message_ref = shift;    
 
    my $field = 'messages';

    if (ref($message_ref)  &&  @{$message_ref}) { push(@{$self->{$field}}, @{$message_ref}); }

    if (defined $self->{$field}) { return $self->{$field}; }    
    else                         { return [];                 }  
} 

##
## -returns an array of records
## -if no type is passed then return all records in page object
## -return them in the order listed in @type_arr
##
sub records_of_type {
    my $self = shift;    
    my $class = ref($self) || error("Page::records_of_type - self is not an object");
    my @type_arr = @_;    

    my @record_arr;

    if (! @{$self->records()}) { return []; }

    if (! @type_arr) { return $self->records();  }

    foreach my $type (@type_arr) {

        foreach my $record (@{$self->records()}) {

            if ($record->type() eq $type) {

                push(@record_arr, $record);
            }            
        }
    }

    return [ @record_arr ];
}


sub link_records             { my $self = shift;  $self->records_of_type($LINK_COMP); }

sub link_from_cat_records    { my $self = shift;  $self->records_of_type($LINK_FROM_CAT_COMP); }

sub preprint_records         { my $self = shift;  $self->records_of_type($PREPRINT_COMP); }

sub holdings_records         { my $self = shift;  $self->records_of_type($HOLDINGS_RESULT_COMP); }

sub search_all_records       { my $self = shift;  $self->records_of_type($SEARCH_ALL_COMP);}

sub show_all_records         { my $self = shift;  $self->records_of_type($SHOW_ALL_COMP);}

sub another_scrno_records    { my $self = shift;  $self->records_of_type($ANOTHER_SCRNO_COMP);}

sub auto_req_records         { my $self = shift;  $self->records_of_type($AUTO_REQ_COMP); }

sub ill_form_records         { my $self = shift;  $self->records_of_type($ILL_FORM_COMP); }

sub citation_manager_records { my $self = shift;  $self->records_of_type($CITATION_MANAGER_COMP);}



sub tried_no_holdings_records   { my $self = shift;  $self->records_of_type($TRIED_NO_HOLDINGS); }

sub not_tried_records           { my $self = shift;  $self->records_of_type($NOT_TRIED); }



sub format {
    my($self, $screen, $citation, $config) = @_;

    my $user = $config->site->key;
    
    my $template;

    my %main_layout_hash = ('citation'         => $citation,
                            'page'             => $self,
                            'screen'           => $screen);

    $self->template_vars( { %main_layout_hash } );

    use GODOT::Template;
    $template = new GODOT::Template {'name'  => 'main_layout', 'site'  => $user, 'config' => $config};

    return  $template->format(\%main_layout_hash);
}


sub has_get_link      { my($self) = shift;  $self->boolean('has_get_link', @_); }

sub has_request_link  { my($self) = shift;  $self->boolean('has_request_link', @_); }

sub has_check_link    { my($self) = shift;  $self->boolean('has_check_link', @_); }

sub has_auto_req_link { my($self) = shift;  $self->boolean('has_auto_req_link', @_); }

sub has_hidden_record { my($self) = shift;  $self->boolean('has_hidden_record', @_); }

sub is_local_ill_request_type {
    my($self) = shift;

    return (grep {$self->{'ill_request_type'} eq $_} qw(W M S)) ? $TRUE : $FALSE; 
}


sub boolean {
    my $self = shift;
    my $class = ref($self) || error("Page::AUTOLOAD - self is not an object");
    my $field = shift;    

    $field =~ s/.*://;               ## -strip fully qualified part
   
    unless (exists $self->{_permitted}->{$field}) {
	error "Page::AUTOLOAD - '$field' is an invalid field for an object of class $class";
    }    

    if (@_) { return $self->{$field} = ($self->{$field} || shift) ? $TRUE : $FALSE; }
    else    { return $self->{$field}; }	      
}


sub AUTOLOAD {
    my $self = shift;
    my $class = ref($self) || error("Page::AUTOLOAD - self is not an object");
    my $field = $AUTOLOAD;    

    $field =~ s/.*://;               ## -strip fully qualified part
   
    unless (exists $self->{_permitted}->{$field}) {
	error "Page::AUTOLOAD - '$field' is an invalid field for an object of class $class";
    }    

    if (@_) { return $self->{$field} = shift; }
    else    { return $self->{$field}; }	      
}

##
## !!!!!!!!!!!!!!!!!! do we need this, does it need to do anymore ?????????????
##

sub DESTROY {
    my $self = shift;
    #### warn "DESTROYING $self";
}



1;

__END__



