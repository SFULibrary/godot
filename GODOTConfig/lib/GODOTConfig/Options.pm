##
## Verification and processing of option values
##
## Copyright (c) 2005, Kristina Long
##
package GODOTConfig::Options;

use Class::Accessor;
use base 'Class::Accessor';

use GODOTConfig::Config;
use GODOTConfig::DB::Sites;
use GODOTConfig::Exceptions;
use GODOTConfig::Debug;

use strict;

my $FALSE = 0;
my $TRUE  = 1;

__PACKAGE__->mk_accessors(qw(option value choices default));

sub new {
    my ($class, $option, $value) = @_;

    my $self = bless {}, $class;
    return $self->init($option, $value);
}

sub init {
    my ($self, $option, $value) = @_;

    unless (grep {$option eq $_} GODOTConfig::DB::Sites->all_config_options) { GODOTConfig::Exception::App->throw("Invalid option: $option"); }

    $self->option($option);
    $self->value($value);

    return $self;
}


#
# Check the value against the properties of the option as specified by %GODOTConfig::Config::GODOT_OPTION_CONFIG.
# (properties: required verification choices default)
#
# May change value (ie. $self->value). 
# 
# Returns false if verification fails.
# 
sub verify {
    my($self) = @_;

    my $function;
    my $option = $self->option;

    # Check for verification routine.
   
    if (defined $GODOTConfig::Config::GODOT_OPTION_CONFIG{$option}) {
        if (defined ${$GODOTConfig::Config::GODOT_OPTION_CONFIG{$option}}{'verification'}) {
	    $function = ${$GODOTConfig::Config::GODOT_OPTION_CONFIG{$option}}{'verification'};
        }
    }

    #### debug "function:  ", $function;

    return $self->$function if ($function);


    # Check that a valid value was specified.

    my @choices;

    if (defined $GODOTConfig::Config::GODOT_OPTION_CONFIG{$option}) {

        if (defined ${$GODOTConfig::Config::GODOT_OPTION_CONFIG{$option}}{'choices'}) {
	    @choices = @{${$GODOTConfig::Config::GODOT_OPTION_CONFIG{$option}}{'choices'}};
        }
    }

    if (scalar(@choices)) {
        return $FALSE unless (grep {$self->value eq $_} (@choices)); 
    }

    # !!!!!! ?????? what checking should be done for 'default' and 'required' ??????? !!!!!!!!

    return $TRUE;
}

sub boolean {
    my($self) = @_;
    
    $self->value(0) if (! defined $self->value );
    $self->value(0) if ($self->value eq '');    

    return $FALSE unless ((defined $self->value) && (grep {$self->value eq $_} (0, 1, '')));

    return $TRUE;
}


sub boolean_default_false {
    my($self) = @_;
    return $self->boolean;
}

sub boolean_default_true {
    my($self) = @_;
    return $self->boolean;
}

sub dump {
    my($self) = @_;
    use Data::Dumper;
    return Dumper($self);
}


sub choices {
    my($self) = @_;

    my @choices;

    if (defined $GODOTConfig::Config::GODOT_OPTION_CONFIG{$self->name}) {
        if (defined ${$GODOTConfig::Config::GODOT_OPTION_CONFIG{$self->name}}{'choices'}) {
	    @choices = @{${$GODOTConfig::Config::GODOT_OPTION_CONFIG{$self->name}}{'choices'}};
        }
    }
    return [ @choices ];
}

sub default {
    my($self) = @_;

    my $default;

    if (defined $GODOTConfig::Config::GODOT_OPTION_CONFIG{$self->name}) {
        if (defined ${$GODOTConfig::Config::GODOT_OPTION_CONFIG{$self->name}}{'default'}) {
	    $default = @{${$GODOTConfig::Config::GODOT_OPTION_CONFIG{$self->name}}{'default'}};
        }
        elsif (defined ${$GODOTConfig::Config::GODOT_OPTION_CONFIG{$self->name}}{'choices'}) {
            $default = ${${$GODOTConfig::Config::GODOT_OPTION_CONFIG{$self->name}}{'choices'}}[0];
        }
    }

    return $default;
}

1;



