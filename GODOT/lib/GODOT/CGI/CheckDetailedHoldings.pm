package GODOT::CGI::CheckDetailedHoldings;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##
use Exporter;
use GODOT::Debug;
use GODOT::String;
use GODOT::Object;

@ISA = qw(Exporter GODOT::Object);
@EXPORT = qw();

use strict;

my @FIELDS = qw(site system);

my @INCLUDE_PATH = ([qw(local site)],
                    [qw(global system)]);

my $BUTTON_TEXT = 'CHK';

##
## -called using class not object, so appears to need to have 'dispatch' defined explicitly for the class 
##
sub dispatch {
    my ($class, $param)= @_;

    my $site = ${$param}{'site'};    
    
    ##
    ## -for ELN-AG, ELN-AG-MONO, NEOS-OTHER, BNM-COW, BNM-NAN and BNM-POW
    ##    
    ${$param}{'site'} =~ s#\055#_#g if (defined ${$param}{'site'});

    my $obj = $class->SUPER::dispatch([@INCLUDE_PATH], $param);

    $obj->{'site'} = $site if (naws($site));
    $obj->{'system'} = ${$param}{'system'} if (naws(${$param}{'system'}));

    return $obj;
}

sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}

sub button {
    my($self) = @_;

    use GODOT::PageElem::Button;
    my $button = new GODOT::PageElem::Button;    

    $button->label($self->_button_text);
    $button->action('catalogue_action');
    $button->param("=" . $self->{'site'});

    return $button;
}

sub _button_text { return $BUTTON_TEXT; }


1;
