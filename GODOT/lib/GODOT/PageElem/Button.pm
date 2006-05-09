package GODOT::PageElem::Button;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;

use GODOT::PageElem;

@ISA = "GODOT::PageElem";

my $TRUE  = 1;
my $FALSE = 0;

use strict;

my %fields = (
    'label'  => undef,
    'action' => undef,
    'param'  => undef
);


sub new {
    my $that = shift;
    my $class = ref($that) || $that;

    return SUPER::new $class %fields;
}


##
## !!!! -change so that literals are not used !!!!
## !!!! -should use same constant as for &GODOT::hold_tab::generic_xxx_button_text routines !!!!
##

sub is_req {
    my $self = shift;

    if ($self->label eq 'REQ') { return $TRUE; }
    return $FALSE;
}

sub is_chk {
    my $self = shift;

    if ($self->label eq 'CHK') { return $TRUE; }
    return $FALSE;
}

sub link {
    my($self, $page, $screen, $param_ref) = @_;

    use CGI qw(:escape);
    
    my $param = $self->param;

    if (ref($param_ref) eq 'ARRAY') {
        foreach my $tmp (@{$param_ref}) {
            $param .= '=' . $tmp;
        }
    }

    return join('', $page->form_url, '?hold_tab_screen=', $screen,
                                     '&hold_tab_cookie=', $page->session_id, 
                                     '&', escape($self->action .  $param), '=', escape($self->label));
}



