##
## Copyright (c) 2004, Kristina Long, Simon Fraser University
##
package GODOT::CGI;

use CGI qw(:escapeHTML :escape :cookie);

use GODOT::Constants;
use GODOT::Config;

use GODOT::Debug;
use GODOT::String;

use GODOT::Object;
@ISA = qw(Exporter GODOT::Object);

@EXPORT = qw();

use strict;

use vars qw($AUTOLOAD);

my $TRUE  = 1;
my $FALSE = 0;


##
## -need logic to check that the correct types of values are being saved to the fields
##

my @FIELDS = ('prev_screen', 
              'session',
              'action', 
              'header_printed',
              'skipped_main_no_holdings',
              'skipped_main_auto_req',
              'citation_result', 
              'citation_message',
              'error_message',

              'result',
              'new_screen',
              'subroutine_name',
              'subroutine',
              'redirect', 
              'config_cache');              

my %STATE_MAPPING = (
    ##           
    ## <screen>.<action>  => <screen subroutine>
    ## 
    "no_screen_screen.start_action"                     => 'main_holdings_screen',

    "main_holdings_screen.main_holdings_action"         => 'main_holdings_screen',
    "main_holdings_screen.article_form_action"          => 'article_form_screen', 
    "main_holdings_screen.check_patron_db_action"       => 'check_patron_screen',
    "main_holdings_screen.password_action"              => 'password_screen',
    "main_holdings_screen.request_form_action"          => 'request_screen',
    "main_holdings_screen.warning_action"               => 'warning_screen', 
    "main_holdings_screen.catalogue_action"             => 'catalogue_screen',
    "main_holdings_screen.catalogue_interface_action"   => 'catalogue_interface_screen',
    "main_holdings_screen.request_info_action"          => 'request_info_screen',

    "article_form_screen.check_patron_db_action"        => 'check_patron_screen',
    "article_form_screen.password_action"               => 'password_screen',
    "article_form_screen.request_form_action"           => 'request_screen',
 
    "catalogue_screen.article_form_action"              => 'article_form_screen',
    "catalogue_screen.check_patron_db_action"           => 'check_patron_screen',   
    "catalogue_screen.password_action"                  => 'password_screen',     
    "catalogue_screen.request_form_action"              => 'request_screen', 
    "catalogue_screen.warning_action"                   => 'warning_screen',      
    "catalogue_screen.catalogue_action"                 => 'catalogue_screen',    

    "check_patron_screen.request_form_action"           => 'request_screen', 

    "password_screen.request_form_action"               => 'request_screen', 
    "password_screen.check_patron_db_action"            => 'check_patron_screen', 

    "request_form_screen.request_send_action"           => 'request_screen',   

    "request_input_error_screen.request_return_action"  => 'request_screen',   
    "request_input_error_screen.request_cancel_action"  => 'request_screen',   

    "request_confirmation_screen.request_accept_action" => 'request_screen',   
    "request_confirmation_screen.request_cancel_action" => 'request_screen',

    "warning_screen.request_info_action"                => 'request_info_screen',  
    "warning_screen.article_form_action"                => 'article_form_screen', 
    "warning_screen.check_patron_db_action"             => 'check_patron_screen',  
    "warning_screen.password_action"                    => 'password_screen',     
    "warning_screen.request_form_action"                => 'request_screen', 
);



##------------------------------------------------------------------------------------------------


sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    my $obj = $class->SUPER::new([@FIELDS, @{$fields}], $values);
    $obj->{'config_cache'} = {};
    return $obj;
}

sub screen {
    my($self, $page, $config, $citation) = @_;

    ##
    ## -all screen subroutines return an action (to indicate that another screen function needs to be run), 
    ##  $TRUE on success or $FALSE on failure
    ##

    $self->{'result'} = &{$self->{'subroutine'}}($self, $page, $config, $citation);
}

##
## -if state is not defined (or other error) then return 0 in result, else return 1
##
sub get_state {
    my($self, $config, $citation) = @_;

    unless (grep {$self->{'prev_screen'} eq $_} (keys %GODOT::Constants::SCREENS)) { 
        error location, " - invalid screen (", $self->{'prev_screen'}, ")";
        $self->{'result'} = $FALSE;
        return $FALSE; 
    }

    my $state_key = "$self->{'prev_screen'}.$self->{'action'}";
    
    #### debug &CGI::remote_host(), " state_key:  $state_key";

    unless (defined($STATE_MAPPING{$state_key}))  { 
        $self->{'result'} = $FALSE;
        return $FALSE;
    }

    $self->{'subroutine_name'}  = $STATE_MAPPING{$state_key};

    ##
    ## -conditional stuff that cannot be expressed in state table above
    ## 

    #### debug "<citation_result:  $self->{'citation_result'}>\n";

    if (grep {$self->{'prev_screen'} eq $_} qw(article_form_screen)) {
    
        if  ($self->{'citation_result'} eq 'citn_need_article_info') { 
            $self->{'subroutine_name'} = 'article_form_screen';
        }
    }

    if ($self->{'citation_result'} eq 'citn_failure') {

            $self->{'subroutine_name'} = 'error_screen';       

            $self->{'error_message'} = (&GODOT::String::naws($self->{'citation_message'})) ? 
                                       $self->{'citation_message'} : 
                                       "Failed on citation check after main holdings screen ($self->{'citation_result'}).";  
    }

    $self->{'result'} = $TRUE;
    return $TRUE;
}


1;



