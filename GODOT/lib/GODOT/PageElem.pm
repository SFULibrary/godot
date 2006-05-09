package GODOT::PageElem;

## GODOT::PageElem
##
## Copyright (c) 2002, Kristina Long, Simon Fraser University
##

use GODOT::Constants;
use GODOT::Config;
use GODOT::Debug;
use GODOT::String;

use strict;

use vars qw($AUTOLOAD);

##
## (30-may-2002 kl)
##
## No need for fields as we will not be creating PageElem objects, but rather
## objects that are a subclass of PageElem.
##


my %fields = (
    #### 'type'  => undef,
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


sub AUTOLOAD {
    my $self = shift;
    my $class = ref($self) || error("PageElem::AUTOLOAD - self is not an object");
    my $field = $AUTOLOAD;    

    $field =~ s/.*://;               ## -strip fully qualified part
   
    unless (exists $self->{_permitted}->{$field}) {
	error "PageElem::AUTOLOAD - '$field' is an invalid field for an object of class $class";
    }    

    if (@_) { return $self->{$field} = shift; }
    else    { return $self->{$field}; }	      
}

sub DESTROY {
    my $self = shift;
}



1;

__END__





