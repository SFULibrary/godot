##
## Copyright (c) 2003, Kristina Long, Simon Fraser University
##

package GODOT::CatalogueHoldings::System::Z3950::Attrib::Title;

use GODOT::CatalogueHoldings::System::Z3950::Attrib;
@ISA = qw( GODOT::CatalogueHoldings::System::Z3950::Attrib );

use GODOT::Debug;

use strict;

my $FALSE = 0;
my $TRUE  = 1;

my @FIELDS = ();

my @WORD_TYPES = qw(SingleWord AnyNumberWord);


sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    use GODOT::CatalogueHoldings::System::Z3950::Word;

    my %init_values = ('RelationAttribute'     => [ new GODOT::CatalogueHoldings::System::Z3950::Word ], 
                       'PositionAttribute'     => [ new GODOT::CatalogueHoldings::System::Z3950::Word ],
                       'StructureAttribute'    => [ new GODOT::CatalogueHoldings::System::Z3950::Word ],
                       'TruncationAttribute'   => [ new GODOT::CatalogueHoldings::System::Z3950::Word ],
                       'CompletenessAttribute' => [ new GODOT::CatalogueHoldings::System::Z3950::Word ]);

    foreach my $key (keys %init_values) {

        if (defined ${$values}{$key}) { $init_values{$key} = ${$values}{$key}; } 
    }


    return $class->SUPER::new([@FIELDS, @{$fields}], {%init_values});
}


sub RelationAttribute     { my($self) = shift;  $self->word_attrib('RelationAttribute', @_);     }

sub PositionAttribute     { my($self) = shift;  $self->word_attrib('PositionAttribute', @_);     }

sub StructureAttribute    { my($self) = shift;  $self->word_attrib('StructureAttribute', @_);    }

sub TruncationAttribute   { my($self) = shift;  $self->word_attrib('TruncationAttribute', @_);   }

sub CompletenessAttribute { my($self) = shift;  $self->word_attrib('CompletenessAttribute', @_); }


sub word_attrib {
    my($self, $field, $param_3, $param_4) = @_;    

    my $class = ref($self) || $self;

    if (ref($param_3) eq 'GODOT::CatalogueHoldings::System::Z3950::Word') {

        $self->{$field} = $param_3;
        return $self->{$field};
    } 

    use GODOT::CatalogueHoldings::System::Z3950::Word;

    ##
    ## -figure out what 3rd and 4th parameters are
    ##
    
    my $value;
    my $word_type;

    if (grep {$param_3 eq $_} @WORD_TYPES)  {
        $value     = '';
        $word_type = $param_3;
    }
    else {
        $value     = $param_3; 
        $word_type = $param_4;

        if ($word_type eq '') { $word_type = 'AnyNumberWord'; }

        if (! grep {$word_type eq $_} @WORD_TYPES) {

            error "Invalid word type ($word_type) for $class.";
            return undef;
        }
    }

    ##
    ## -do we want to set a value or retrieve one?
    ##

    my $word;

    if (! defined $self->{$field} ) {
  
        $word = new GODOT::CatalogueHoldings::System::Z3950::Word;
        $self->{$field} = $word;
    }
    else {

        $word = $self->{$field};
        my $obj_type = ref($word);    

        if ($obj_type ne 'GODOT::CatalogueHoldings::System::Z3950::Word') {
            error "unexpected value of $obj_type for \'$field\' in an object of class $class";
            return undef;
        }
    }

    if ($value) {

        my $subroutine = 'GODOT::CatalogueHoldings::System::Z3950::Attrib::' . '_valid_' . $field;

        no strict;

        if (! &{$subroutine}($value)) {
            error "invalid value for $field ($value).";
            return undef;
        }

        use strict;

        return $word->$word_type($value); 
    }
    else    { 
        return $word->$word_type;
    }

}


1;


__END__

