## GODOT::Object
##
## Copyright (c) 2001, Todd Holbrook, Simon Fraser University
##
## Code common to most GODOT:: objects, mostly error handling code. 
##
##
package GODOT::Object;

@ISA = qw(Exporter);
@EXPORT = qw($TRUE $FALSE);

use vars qw($TRUE $FALSE $AUTOLOAD);
$FALSE = 0;
$TRUE  = 1;

use strict;

use GODOT::Debug;

my $INDENT_SIZE = 4;
my @FIELDS = ();

##
## Error support functions
##

sub _set_error {
	my ($self, @strings) = @_;
	
	$self->{'__Object_err'} = 1;
	$self->{'__Object_errstr'} = join '', @strings;
}

sub _clear_errors {
	my $self = shift;
		
	$self->{'__Object_err'} = 0;
	$self->{'__Object_errstr'} = undef;
}


sub err {
	my $self = shift;

	if ($self->{'__Object_err'} == 1) {
		$self->{'__Object_err'} = 0;
		return 1;
	}
	return 0;
}

sub errstr {
	my $self = shift;

	my $temp = $self->{'__Object_errstr'};
	$self->{'__Object_errstr'} = undef;

	return $temp;
}

sub dispatch {
    my($class, $include_path, $param) = @_;
   
    #### debug location;

    my $dispatch = new GODOT::Dispatch $include_path;
    $dispatch->dispatch($class, $param);    
}

##
## (16-feb-2005 kl) - added methods that had previously been in GODOT::XXX::Object.pm files
##


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

            debug "parameter ($key) incorrectly passed to 'new' for $class.";
        }
	else { 

            my @param = @{$values_hash{$key}};
            $self->$key(@param) if (scalar @param);
        }
    }

    return $self;
}

sub empty {
    my($self) = @_;


    foreach my $field (@{$self->{'_permitted'}}) {
        $self->{$field} = undef;
    }

    #### debug "\n__________________\n", $self->dump, "\n__________________\n";

    return $self;
}

sub is_empty {
    my($self) = @_;

    foreach my $field (@{$self->{'_permitted'}}) {
        if (defined $self->{$field}) { return $FALSE; }
    }

    return $TRUE;
}

sub valid_field {
    my($self, $field) = @_;

    return grep {$field eq $_} @{$self->{'_permitted'}};    
}


##
## Only making a copy of the first level
##
sub copy {
    my($self, $copy_this) = @_;

    foreach my $field (@{$self->{'_permitted'}}) {

        $self->{$field} = $copy_this->{$field};
    }
    return $self;    
}



sub AUTOLOAD {
    my $self = shift;

    #### my ($pack, $file, $link, $subname, $hasargs, $wantarray) = caller(1);
    #### debug "AUTOLOAD -- $subname -- $AUTOLOAD";

    my $class = ref($self) || error("Object::AUTOLOAD - self is not an object");
    my $field = $AUTOLOAD;


    $field =~ s/.*://;               ## -strip fully qualified part

    unless (grep {$field eq $_} (@{$self->{'_permitted'}})) {
        error "Object::AUTOLOAD - '$field' is an invalid field for an object of class $class";
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
        ## -(18-feb-2005 kl) - added logic to handle a reference to an array of scalars
        ##
        ## -assume for now that the value is either a scalar, a reference to an object or a reference
        ##  to an array of objects
        ##

        if ($ref) {     

            my $field_text = "$field:  ";

            if ($ref eq 'ARRAY') {

                my $field_indent = GODOT::String::rep_char(' ', length($field_text));

                my $count;
                my @items = @{${$self}{$field}};
                
                foreach my $item (@items) {
                              
                    $count++;

                    $string .= join('', "\n", $indent, $ws_indent, (($count == 1) ? $field_text : $field_indent));              
                    $string .= (ref($item)) ? join('', $item->tagged($indent_size + $max_field_len + 3), "\n") : $item;
                }
            }
            else {

	        $string .= join('', "\n", $indent, 
                                    $ws_indent, $field_text, 
                                    ${$self}{$field}->tagged($indent_size + $max_field_len + 3));
	    }
        }
        else {
            $string .= join('', "\n", $indent, $ws_indent, "$field:  ", ${$self}{$field});
        }
    }


    $string .= "\n";

    return $string;
}


sub dump {
    my($self) = @_;

    use Data::Dumper;
    return Dumper($self);
}

sub dump_ordered {
    my($self) = @_;

    use Data::Dumper;
    return Dumper($self);
}


1;

__END__
