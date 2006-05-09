##
## Copyright (c) 2003, Kristina Long, Simon Fraser University
##

package GODOT::CatalogueHoldings::System::Z3950::Attrib;

use GODOT::Object;
@ISA = qw(GODOT::Object);

use GODOT::Debug;
use GODOT::String;

use strict;

my @RELATION_ATTRIB_ARR     = qw(1 2 3 4 5);
my @POSITION_ATTRIB_ARR     = qw(1 2 3);
my @STRUCTURE_ATTRIB_ARR    = qw(1 2 4 5 101);
my @TRUNCATION_ATTRIB_ARR   = qw(1 100 101);
my @COMPLETENESS_ATTRIB_ARR = qw(1 3);

my @FIELDS = ('UseAttribute',              
              'RelationAttribute', 
              'PositionAttribute', 
              'StructureAttribute', 
              'TruncationAttribute', 
              'CompletenessAttribute');


sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}



sub UseAttribute          { my($self) = shift;  $self->attrib('UseAttribute', @_);          }

sub RelationAttribute     { my($self) = shift;  $self->attrib('RelationAttribute', @_);     }

sub PositionAttribute     { my($self) = shift;  $self->attrib('PositionAttribute', @_);     }

sub StructureAttribute    { my($self) = shift;  $self->attrib('StructureAttribute', @_);    }

sub TruncationAttribute   { my($self) = shift;  $self->attrib('TruncationAttribute', @_);   }

sub CompletenessAttribute { my($self) = shift;  $self->attrib('CompletenessAttribute', @_); }


sub attrib { 
    my($self, $field, $value) = @_;

    if ($value) { 

        my $subroutine = '_valid_' . $field;

        no strict;

        if (! &{$subroutine}($value)) {
           error "invalid value for $field ($value).";
           return undef;
        }
        use strict;

        return $self->{$field} = $value; 
    }
    else { 
        return $self->{$field};         
    }

}

##
## -check that we have valid attributes
##

sub _valid_UseAttribute {
    my($attrib) = @_;

    return (&GODOT::String::all_digits($attrib) && ($attrib > 0) && (! m#^0#));
}

sub _valid_RelationAttribute {
    my($attrib) = @_;

    return (grep {$attrib eq $_} @RELATION_ATTRIB_ARR) ? $TRUE : $FALSE;
}

sub _valid_PositionAttribute {
    my($attrib) = @_;

    return (grep {$attrib eq $_} @POSITION_ATTRIB_ARR) ? $TRUE : $FALSE;
}

sub _valid_StructureAttribute {
    my($attrib) = @_;

    return (grep {$attrib eq $_} @STRUCTURE_ATTRIB_ARR) ? $TRUE : $FALSE;
}

sub _valid_TruncationAttribute {
    my($attrib) = @_;

    return (grep {$attrib eq $_} @TRUNCATION_ATTRIB_ARR) ? $TRUE : $FALSE;
}

sub _valid_CompletenessAttribute {
    my($attrib) = @_;

    return (grep {$attrib eq $_} @COMPLETENESS_ATTRIB_ARR) ? $TRUE : $FALSE;
}





1;

__END__

