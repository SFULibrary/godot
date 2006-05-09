package GODOT::PageElem::Instructions;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;

use GODOT::String;

use GODOT::PageElem;

@ISA = "GODOT::PageElem";

use strict;


use vars qw($AUTOLOAD);

my %fields = (
    'no_holdings'               => undef,
    'skipped_main_no_holdings'  => undef,     ## -contains true/false -- actual text is handled by templates
    'skipped_main_auto_req'     => undef,
    'do_all'                    => undef,

    'get_button'                => undef,
    'req_button'                => undef,
    'chk_button'                => undef,
    'auto_req_button'           => undef,
    'ill_button'                => undef,

    'link_template'             => undef,
    'help'                      => undef,
    'back_to_dbase'             => undef,

    #### 'text'                     => undef
);

##
## -returns a list of no_holdings strings
##
sub no_holdings {
    my $self = shift;

    my $field = 'no_holdings';

    ref($self) || error("PageElem::Instructions::no_holdings - self is not an object");

    if (@_) {
        foreach my $value (@_) {
            if (&GODOT::String::naws($value)) { push(@{$self->{$field}}, $value); }
        }
    }

    if (defined $self->{$field}) { return @{$self->{$field}}; }
    else                         { return ();                 }     
}

##
## -returns a list of link template strings
##
sub link_template {
    my $self = shift;

    my $field = 'link_template';

    ref($self) || error("PageElem::Instructions::link_template - self is not an object");

    if (@_) {
        foreach my $value (@_) {
            if (&GODOT::String::naws($value)) { push(@{$self->{$field}}, $value); }
        }
    }

    if (defined $self->{$field}) { return @{$self->{$field}}; }
    else                         { return ();                 }     
}


sub AUTOLOAD {
    my $self = shift;
    my $class = ref($self) || error("PageElem::Instructions::AUTOLOAD - self is not an object");
    my $field = $AUTOLOAD;    

    $field =~ s/.*://;               ## -strip fully qualified part
   
    unless (exists $self->{_permitted}->{$field}) {
	error "PageElem::Instructions::AUTOLOAD - '$field' is an invalid field for an object of class $class";
    }    

    if (@_) { 
        my $value = shift;
        if (&GODOT::String::naws($value)) { $self->{$field} = $value;   }
    }

    return $self->{$field};
}


sub new {
    my $that = shift;
    my $class = ref($that) || $that;

    return SUPER::new $class %fields;
}


