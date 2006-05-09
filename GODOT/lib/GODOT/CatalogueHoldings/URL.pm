##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

package GODOT::CatalogueHoldings::URL;

use GODOT::CatalogueHoldings;
use GODOT::Object;
@ISA = qw (GODOT::CatalogueHoldings GODOT::Object);

use GODOT::Debug;
use GODOT::String;

use strict;

my @FIELDS = qw(url text); 

sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}
                
sub url {
    my($self, $url) = @_;
    
    $self->{'url'} = $url unless (aws($url));
    return $self->{'url'};
}

sub text {
    my($self, $text) = @_;

    unless ($self->{'url'}) {
        debug(location, ":  please set the URL before setting the text");
        return undef;
    } 

    if (defined $text) { $self->{'text'} = $text; }      ## -let text be set to ''

    return $self->{'text'};
}




1;

__END__

