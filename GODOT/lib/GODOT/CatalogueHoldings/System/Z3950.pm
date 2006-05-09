## GODOT::CatalogueHoldings::System::Z3950
##
## Copyright (c) 2003, Kristina Long, Simon Fraser University
##

package GODOT::CatalogueHoldings::System::Z3950;

use GODOT::Debug;

use GODOT::CatalogueHoldings::System::Z3950::Attrib::Title;

use GODOT::Object;
use GODOT::CatalogueHoldings::System;

@ISA = qw(GODOT::CatalogueHoldings::System GODOT::Object);

use strict;

##
## The System::Z3950 class implements a data structure containing the following fields:
##

use strict;

my @FIELDS = ('Title',                  # GODOT::CatalogueHoldings::System::Z3950::Attrib::Title
              'JournalTitle',           # GODOT::CatalogueHoldings::System::Z3950::Attrib::Title

              'SysID',                  # GODOT::CatalogueHoldings::System::Z3950::Attrib
              'ISBN',                   # GODOT::CatalogueHoldings::System::Z3950::Attrib
              'ISSN');                  # GODOT::CatalogueHoldings::System::Z3950::Attrib             



sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    use GODOT::CatalogueHoldings::System::Z3950::Attrib::Title;
    use GODOT::CatalogueHoldings::System::Z3950::Attrib;

    my %init_values = ('Title'        => [ new GODOT::CatalogueHoldings::System::Z3950::Attrib::Title ],
                       'JournalTitle' => [ new GODOT::CatalogueHoldings::System::Z3950::Attrib::Title ],
                       'SysID'        => [ new GODOT::CatalogueHoldings::System::Z3950::Attrib ],
                       'ISBN'         => [ new GODOT::CatalogueHoldings::System::Z3950::Attrib ],
                       'ISSN'         => [ new GODOT::CatalogueHoldings::System::Z3950::Attrib ]
                      );

    foreach my $key (keys %init_values) {
        if (defined ${$values}{$key}) { $init_values{$key} = ${$values}{$key}; }
    }


    return $class->SUPER::new([@FIELDS, @{$fields}], { %init_values });
}


sub Use {
    my $self = shift;
    
    if (@_) {
        my $use = shift; 
        if (! grep {$use eq $_} ($TRUE, $FALSE)) { return undef; }
        return $self->{'Use'} = $use; 
    }
    else    { 
        return $self->{'Use'}; 
    }
}


sub Title {
    my($self) = shift;
    
    $self->title_attrib('Title', @_);
}


sub JournalTitle {
    my($self) = shift;
    
    $self->title_attrib('JournalTitle', @_);
}


sub SysID {
    my($self) = shift;

    $self->attrib_field('SysID', @_);
}

sub ISSN {
    my($self) = shift;

    $self->attrib_field('ISSN', @_);
}


sub ISBN {
    my($self) = shift;

    $self->attrib_field('ISBN', @_);
}


sub title_attrib {
    my($self) = shift;
    my($field) = shift;

    my $class = ref($self) || $self;

    if (@_) {

        my $attrib_obj = shift; 

        my $obj_type = ref($attrib_obj) || $attrib_obj;

        my $title_obj_type = 'GODOT::CatalogueHoldings::System::Z3950::Attrib::Title';

        if ($obj_type ne $title_obj_type) {
            error "expected value of '$title_obj_type', not value of '$obj_type' for '$field' in an object of class $class";
            return undef;
        }

        return $self->{$field} = $attrib_obj; 
    }
    else { 

        return $self->{$field}; 
    }
}

sub attrib_field {
    my($self) = shift;
    my($field) = shift;

    my $class = ref($self) || $self;

    if (@_) {
        my $attrib_obj = shift; 

        my $obj_type = ref($attrib_obj);

        if ($obj_type ne 'GODOT::CatalogueHoldings::System::Z3950::Attrib') {
            error "unexpected value of $obj_type for '$field' in an object of class $class";
            return undef;
        }

        return $self->{$field} = $attrib_obj; 
    }
    else    { 
        return $self->{$field}; 
    }
}

sub uses_HTTP  { return $FALSE; }

sub uses_Z3950 { return $TRUE; }


1;

__END__

-----------------------------------------------------------------------------------------

=head1 NAME

GODOT::XXX - 

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
