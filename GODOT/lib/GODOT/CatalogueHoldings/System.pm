package GODOT::CatalogueHoldings::System;
##
## Copyright (c) 2003, Kristina Long, Simon Fraser University
##

use GODOT::Object;
use GODOT::CatalogueHoldings;
@ISA = qw(GODOT::CatalogueHoldings GODOT::Object);

use GODOT::CatalogueHoldings::Config;
use GODOT::Debug;

use strict;

##
## The System class implements a data structure containing the following fields:
##

my @FIELDS = ('Use',        ## Enable searching for this catalogue
              'Site',       ## usually the NUC code, eg. BVAS
              'Type',       ## Vendor (eg. III, SIRSI, ENDEAVOR)
              'Host',
              'Port',
              'Database',
              'Timeout',
              'ID', 
              'Password');
                    


##
## -called using class not object, so appears to need to have 'dispatch' defined explicitly for the class
##
sub dispatch {
    my ($class, $param)= @_;    

    return $class->SUPER::dispatch($param);
}

sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}

sub Type {
    my $self = shift;
    
    my $class = ref($self) || $self;

    if (@_) {
        my $type = shift; 

        if (! grep {$type eq $_} @SYSTEM_TYPES) { 
            error "The value '$type' is an invalid value for the 'Type' field for a $class object."; 
            return undef; 
        }

        return $self->{'Type'} = $type; 
    }
    else    { 
        return $self->{'Type'}; 
    }
}

1;

__END__

-----------------------------------------------------------------------------------------

    



-----------------------------------------------------------------------------------------

=head1 NAME

GODOT::System - 

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
