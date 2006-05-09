package GODOT::CUFTS::Resource;
##
## Copyright (c) 2003, Kristina Long, Simon Fraser University
##



use Exporter;
use GODOT::Debug;
use GODOT::String;
use GODOT::CUFTS::Object;

@ISA = qw(Exporter GODOT::CUFTS::Object);

#### @EXPORT = qw();

#### use vars qw();

use strict;

my $FALSE = 0;
my $TRUE  = 1;

my @FIELDS = ('name',
              'rank',
              'provider',
              '_services',            ## GODOT::CUFTS::Service              
              '_status_message',
              '_error_message'
             );


sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    my %init_values = ('services' => [ [] ]);

    foreach my $key (keys %init_values) {
        if (defined ${$values}{$key}) { $init_values{$key} = ${$values}{$key}; }
    }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}


sub services {
    my($self) = @_;

    return (defined $self->{'_services'}) ? $self->{'_services'} : [];
}


sub error_message {
    my($self) = @_;    

    return $self->{'_error_message'};
}

sub result {
    my($self) = @_;

    return (($self->{'_error_message'}) ? $FALSE : $TRUE);    
}

sub xml_input {
    my($self, $string) = @_;

    if ($string =~ m#<resource (.+?)>(.+)</resource>#s) {

	 my $attributes = $1;
	 my $content = $2;

         while ($attributes =~ m#\s*(.+?)="(.*?)"#sg) {

	     my $attrib = $1;
	     my $value  = $2;

	     unless (grep {$attrib eq $_} qw(name rank provider)) { next; }
             
             $self->$attrib($value);         		
	 }

         my @services;
    
         while ($content =~ m#(<service .+?>.+?</service>)#sg) {

	     my $string = $1;

             use GODOT::CUFTS::Service;             
	     my $service = new GODOT::CUFTS::Service;

	     if ($service->xml_input($string)) {

                 push(@services, $service);
             }
	     else {
                 $self->{'_error_message'} = "unexpected response from CUFTS";
                 debug "\nunexpected response from CUFTS (service xml could not be parsed: " .
                       $service->result  . "):\n" . $string . "\n";

                 return undef;                      
             }
         }

         $self->{'_services'} = [ @services ];
    } 
    else {

        $self->{'_error_message'} = "unexpected response from CUFTS";
        debug "\nunexpected response from CUFTS (no '<resource>' and '</resource>')\n" . $string . "\n";

        return undef;                      
    }
       
    return $TRUE;
} 




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
