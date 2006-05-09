package GODOT::Parallel;
##
## Copyright (c) 2003, Kristina Long, Simon Fraser University
##

use CGI qw(:escape);

use GODOT::Debug;
use GODOT::String;

use base qw(GODOT::Object);

use strict;

my $FALSE = 0;
my $TRUE  = 1;

##
## !!!!!!!!!!!!! look at getting rid of cgi_param and is_bccampus !!!!!!!!!!
##
my @FIELDS = qw(query_name
                command
                site
                source
                cgi_param
                source_name
                search_type
                live_source
                sources_to_try
                is_bccampus
                citation
                filename
                start_time
                end_time
                result
                reason
                message_type
                message_args
                data
           
               );

sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}


1;

__END__


