package GODOT::Patron::Data;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use GODOT::Debug;
use GODOT::String;

use base qw(GODOT::Object);

use strict;

my @FIELDS = qw(authorized
                authorized_reason

                first_name
                last_name
                library_id

                type
                department
                email

                pickup
                phone
                phone_work

                building
                notification
                street

                city 
                province
                postal_code

                payment_method
                account_number
                note               
               );


my %CONV_MAPPING = ('VALID'                   => 'authorized',
                    'VALID_REASON'            => 'authorized_reason',
 
                    'PATR_FIRST_NAME_FIELD'   => 'first_name',
	            'PATR_LAST_NAME_FIELD'    => 'last_name',
		    'PATR_LIBRARY_ID_FIELD'   => 'library_id',

		    'PATR_PATRON_TYPE_FIELD'  => 'type',
		    'PATR_DEPARTMENT_FIELD'   => 'department',
		    'PATR_PATRON_EMAIL_FIELD' => 'email',

		    'PATR_PICKUP_FIELD'       => 'pickup',
		    'PATR_PHONE_FIELD'        => 'phone',
		    'PATR_PHONE_WORK_FIELD'   => 'phone_work',

		    'PATR_BUILDING_FIELD'     => 'building',
		    'PATR_PATRON_NOTI_FIELD'  => 'notification',
		    'PATR_STREET_FIELD'       => 'street',

		    'PATR_CITY_FIELD'         => 'city',
		    'PATR_PROV_FIELD'         => 'province',
		    'PATR_POSTAL_CODE_FIELD'  => 'postal_code',

		    'PATR_PAID_FIELD'         => 'payment_method',
		    'PATR_ACCOUNT_NO_FIELD'   => 'account_number',
                    'PATR_NOTE_FIELD'         => 'note');


my @INCLUDE_PATH = ([qw(local site)], 
                    [qw(local local)], 
                    [qw(global api)]);

sub dispatch {
    my($class, $param) = @_;

    ${$param}{'site'} =~ s#\055#_#g if (defined ${$param}{'site'});

    return $class->SUPER::dispatch([@INCLUDE_PATH], $param);
}

sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}


sub converted {
    my($self) = @_;
   
    my %patron;

    while (my($old, $new) = each %CONV_MAPPING) {
        $patron{$old} = $self->{$new} if (defined $self->{$new});
    }    
   
    return %patron;
}

##
## -reverse conversion - hold_tab.pm hash to GODOT::Patron::Data object
##
sub converted_2 {
    my($self, $patron) = @_;

    while (my($old, $new) = each %CONV_MAPPING) {
        $self->{$new} = ${$patron}{$old} if (defined ${$patron}{$old});
    }       
}

1;

















