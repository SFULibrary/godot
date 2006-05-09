package GODOT::PageElem::FormInput;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;

use GODOT::PageElem;

@ISA = "GODOT::PageElem";

my $TRUE  = 1;
my $FALSE = 0;

use strict;

my @TYPES = qw(TEXTFIELD POPUP PASSWORD RADIO DISPLAY_ONLY);


my %fields = (
    'name'     => undef,
    'label'    => undef,
    'value'    => undef,
    'type'     => undef,
    'selected' => undef,
    'choices'  => undef
);

sub new {
    my $that = shift;
    my $class = ref($that) || $that;

    return SUPER::new $class %fields;
}

sub type {
    my $self = shift;
    my $class = ref($self) || error("PageElem::FormInput::type - self is not an object");
    my $field = 'type';
   
    if (@_) { 
        my $value = shift;
        if (! grep {$value eq $_} @TYPES) { debug("PageElem::FormInput::type - not a valid value for type ($value)"); }
        return $self->{$field} = $value; 
    }
    else { 
        return $self->{$field}; 
    }
}


