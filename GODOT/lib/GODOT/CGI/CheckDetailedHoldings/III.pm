package GODOT::CGI::CheckDetailedHoldings::III;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##
use Exporter;
use GODOT::Debug;
use GODOT::String;
use GODOT::CGI::CheckDetailedHoldings;

@ISA = qw(Exporter GODOT::CGI::CheckDetailedHoldings);
@EXPORT = qw();

use strict;

sub button {
    my($self) = @_;

    use GODOT::PageElem::Button;
    my $button = new GODOT::PageElem::Button;    

    $button->label($self->_button_text);
    $button->action('catalogue_interface_action');
    $button->param("=" . $self->{'site'});

    return $button;
}


1;
