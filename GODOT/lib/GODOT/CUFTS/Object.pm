package GODOT::CUFTS::Object;

##
## Copyright (c) 2003, Kristina Long, Simon Fraser University
##

use GODOT::Debug;
use GODOT::Object;

@ISA = qw(GODOT::Object);

use strict;

my $FALSE = 0;
my $TRUE  = 1;

my $INDENT_SIZE = 4;

use vars qw($AUTOLOAD);


my @FIELDS = ();

sub new {
    my($self, $fields, $values) = @_;    

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH') { $values = $fields;  }             ## -no fields were passed

    my @fields_arr = (ref($fields) eq 'ARRAY') ? @{$fields} : @FIELDS;

    my %fields_hash;

    foreach my $field (@fields_arr) { $fields_hash{$field} = undef; }

    $self = {
        '_permitted' => [ @fields_arr ],
        %fields_hash
    };

    bless $self, $class;

    my %values_hash = (ref($values) eq 'HASH') ? %{$values} : (); 

    foreach  my $key (keys %values_hash) {
     
        if (ref($values_hash{$key}) ne 'ARRAY') { 

            debug "parameters incorrectly passed to 'new' for $class.";
        }
	else { 

            my @param = @{$values_hash{$key}};
            $self->$key(@param) if (scalar @param);
        }
    }

    return $self;
}



sub AUTOLOAD {
    my $self = shift;
    my $class = ref($self) || error("CUFTS::Object::AUTOLOAD - self is not an object");
    my $field = $AUTOLOAD;

    $field =~ s/.*://;               ## -strip fully qualified part

    unless (grep {$field eq $_} (@{$self->{'_permitted'}})) {
        #### my ($pack, $file, $link, $subname, $hasargs, $wantarray) = caller(1);
        #### debug ">> $subname <<";
        error "CUFTS::AUTOLOAD - '$field' is an invalid field for an object of class $class";
    }

    if (@_) { return $self->{$field} = shift; }
    else    { return $self->{$field}; }
}


sub DESTROY {
    my $self = shift;

    #### debug "DESTROYING $self";
}


##
## -this will only work if the object is implemented as reference to a hash
##

sub xml {
    my $self = shift;
    my $indent_size = shift;

    my $class = ref($self);
    
    use GODOT::String;

    my $indent = GODOT::String::rep_char(' ', $indent_size); 

    my $string = join('', $indent, '<object>', "\n", 
                          $indent, '<type>', $class, '</type>', "\n", 
                          $indent, '<contents>', "\n"); 
    
    foreach my $field (@{$self->{'_permitted'}}) {
        

        my $ref = ref(${$self}{$field});

        ##
        ## -assume for now that the value is either a scalar, a reference to an object or a reference to a list
        ##  of objects
        ##

        if ($ref) {

            if ($ref eq 'ARRAY') {

                my $count;
                my @objs = @{${$self}{$field}};
                
                foreach my $object (@objs) {
                                                       
                    $count++;
    	            $string .= join('', $indent, "<$field>\n", $object->xml($indent_size + $INDENT_SIZE), "</$field>\n");  
                }
            }
            else {

                $string .= join('', $indent, "<$field>\n", ${$self}{$field}->xml($indent_size + $INDENT_SIZE), "</$field>\n");
            }
        }
        else {            
            $string .= join('', $indent, "<$field>", ${$self}{$field}, "</$field>\n");
        }
    }

    $string .= join('', $indent, '</contents>', "\n", 
                        $indent, '</object>', "\n");

    return $string;
}


sub tagged {
    my $self = shift;
    my $indent_size = shift;

    my $class = ref($self);
  
    use GODOT::String;

    my $string = join('', "< $class >"); 
    
    my $max_field_len;

    foreach my $field (keys %{$self}) {

        if ($field eq '_permitted') { next; }
 
        if (length($field) > $max_field_len) { $max_field_len = length($field); }
    }

    foreach my $field (@{$self->{'_permitted'}}) {
    
        my $ws_len = $max_field_len - length($field);
 
        my $ws_indent = GODOT::String::rep_char(' ', $ws_len);
        my $indent    = GODOT::String::rep_char(' ', $indent_size);
        
	my $ref = ref(${$self}{$field});

        ##
        ## -assume for now that the value is either a scalar, a reference to an object or a reference
        ##  to an array of objects
        ##

        if ($ref) {     

            my $field_text = "$field:  ";

            if ($ref eq 'ARRAY') {

                my $field_indent = GODOT::String::rep_char(' ', length($field_text));

                my $count;
                my @objs = @{${$self}{$field}};
                
                foreach my $object (@objs) {
                                                       
                    $count++;
    	            $string .= join('', "\n", $indent, 
                                        $ws_indent, (($count == 1) ? $field_text : $field_indent), 
                                        $object->tagged($indent_size + $max_field_len + 3), 
                                        "\n");                    
                }
            }
            else {

	        $string .= join('', "\n", $indent, 
                                    $ws_indent, $field_text, 
                                    ${$self}{$field}->tagged($indent_size + $max_field_len + 3));
	    }
        }
        else {
            $string .= join('', "\n", $indent,
                                $ws_indent, "$field:  ", ${$self}{$field});
        }
    }


    $string .= "\n";

    return $string;
}






1;

__END__

-----------------------------------------------------------------------------------------

=head1 NAME

GODOT::Object - 

=head1 METHODS

=head2 Constructor

=over 4

=item new([$dbase])

=back

Returns a reference to Citation object. I<$dbase> is a refenerce
to Database object.

=head2 ACCESSOR METHODS

=over 4

=item mysubroutine([$value])

Accessor methods for checking $self->{'req_type'} for a specific type of
document, or for setting the Citation object to be a certain type of
document.  These methods are similar to the req_type(), but use boolean
values for each document type rather than returning or setting the actual
req_type value which req_type() does.


=back

=head1 AUTHORS / ACKNOWLEDGMENTS

Kristina Long


=cut
