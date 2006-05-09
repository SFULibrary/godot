package GODOT::PageElem::Record;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;

use GODOT::PageElem;
@ISA = "GODOT::PageElem";

use strict;

my %fields = (
    'type'           => undef,
    'user'           => undef,
    'buttons'        => undef,
    'description'    => undef,
    'text'           => undef,
    'url'            => undef,
    'fulltext'       => undef,        
    'display_group'  => undef,
    'search_group'   => undef
);

sub new {
    my $that = shift;
    my $class = ref($that) || $that;

    return SUPER::new $class %fields;
}


##
## -returns a list of button objects
##
sub buttons {
    my $self = shift;

    my $field = 'buttons';

    ref($self) || error("PageElem::Record::buttons - self is not an object");

    if (@_) { push(@{$self->{$field}}, shift); }

    if (defined $self->{$field}) { return $self->{$field}; }
    else                         { return [];              }     
}



sub num_req_buttons {
    my $self = shift;

    my $num;

    foreach my $button ($self->buttons()) {
        if ($button->is_req()) { $num++; }
    }
    return $num;
}

sub num_chk_buttons {
    my $self = shift;

    my $num;

    foreach my $button ($self->buttons()) {
        if ($button->is_chk()) { $num++; }
    }
    return $num;
}

