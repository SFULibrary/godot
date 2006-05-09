package GODOT::CUFTS;
##
## Copyright (c) 2003, Kristina Long, Simon Fraser University
##


use GODOT::Debug;
use GODOT::String;

use GODOT::CUFTS::Config;

use GODOT::CUFTS::Object;

use GODOT::CUFTS::Citation;
use GODOT::CUFTS::Resource;
use GODOT::CUFTS::Service;
use GODOT::CUFTS::Search;


use strict;

my $FALSE = 0;
my $TRUE  = 1;


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
