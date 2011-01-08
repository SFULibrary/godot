package GODOT::Patron::API;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use GODOT::Constants;
use GODOT::Config;
use GODOT::Debug;
use GODOT::String;
use GODOT::Object;

use GODOT::Dispatch;

@ISA = qw(Exporter GODOT::Object);

@EXPORT = qw();

use strict;

use vars qw($AUTOLOAD);

my @FIELDS =   ('site', 
                'api',
                'api_enabled',
                'host',
                'port',
                'need_pin',
                'fine_limit',        
                'patron',                            ## points to a GODOT::Patron::Data object
                'error_message'
               );

my @INCLUDE_PATH = ([qw(local  site)], 
                    [qw(local  local)], 
                    [qw(global api)]);


sub dispatch {
    my($class, $param, $api_enabled, $phost, $zhost, $pport, $need_pin, $fine_limit) = @_;

    ${$param}{'site'} =~ s#\055#_#g if (defined ${$param}{'site'});

    #### debug location;

    my $obj = $class->SUPER::dispatch([@INCLUDE_PATH], $param);

    $obj->site(${$param}{'site'});
    $obj->api(${$param}{'api'});
  
    if (naws($phost))     { $obj->host($phost); }
    elsif (naws($zhost))  { $obj->host($zhost); }

    $obj->port($pport) unless (aws($pport));

    ##
    ## !!!!!!!!!!!!!!!! for testing only !!!!!!!!!!!!!!!!
    ##
    #### $api_enabled = $FALSE;

    $obj->api_enabled($api_enabled) if ($api_enabled eq $TRUE);
    $obj->need_pin($need_pin)       if ($need_pin eq $TRUE);
    $obj->fine_limit($fine_limit)   if (naws($fine_limit)); 

    return $obj; 
}


sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}

sub available {
    my($self) = @_;

    return ($self->api_enabled && (defined $self->host) && (defined $self->port)) ? $TRUE : $FALSE; 
}

sub get_patron {
    my($self) = @_;

    ##
    ## -return TRUE because no error has occurred, all that this means is that site is not configured to get patron info
    ##
    return $TRUE unless $self->available;

    my $message = location . ":  should not be being called.  Only API specific classes are available";
    $self->error_message($message);
    return $FALSE;
}


1;



