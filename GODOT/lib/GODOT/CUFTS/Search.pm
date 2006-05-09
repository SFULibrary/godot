package GODOT::CUFTS::Search;
##
## Copyright (c) 2003, Kristina Long, Simon Fraser University
##



use Exporter;
use GODOT::Debug;
use GODOT::String;

use GODOT::CUFTS::Config;
use GODOT::CUFTS::Object;

@ISA = qw(Exporter GODOT::CUFTS::Object);

#### @EXPORT = qw();

#### use vars qw();

use strict;

my $FALSE = 0;
my $TRUE  = 1;

my @FIELDS = ('citation',                   ## GODOT::CUFTS::Citation                              
              'site',                       ## GODOT::CUFTS::Site 
              '_resources',                 ## list of GODOT::CUFTS::Resource objects
              '_status_message',
              '_error_message'
             );


sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    use GODOT::CUFTS::Citation;
    use GODOT::CUFTS::Resource;

    ##
    ## (24-oct-2004 kl) %init_values not used so commented out
    ##

    #### my %init_values = ('citation'  => [ new GODOT::CUFTS::Citation ],
    ####                    'resources' => [ [] ],                      
    ####	           );
    #### 
    #### foreach my $key (keys %init_values) {
    ####    if (defined ${$values}{$key}) { $init_values{$key} = ${$values}{$key}; }
    #### }
    ####

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}


sub resources {
    my($self) = @_;

    return (defined $self->{'_resources'}) ? $self->{'_resources'} : [];
}



sub resources_by_rank {
    my($self) = @_;


    if (defined $self->{'_resources'}) {

        my @sorted = sort by_rank @{$self->resources};


        return [ @sorted ];
    }
    else {
        return [];
    }
}

sub by_rank {    
    return $b->rank <=> $a->rank;
}


sub result {
    my($self) = @_;

    return (($self->{'_error_message'}) ? $FALSE : $TRUE);    
}


sub error_message {
    my($self) = @_;    

    return $self->{'_error_message'};
}

sub search {
    my($self, $timeout) = @_;

    if (! $timeout)  {  $timeout = $GODOT::CUFTS::CUFTS_TIMEOUT; }

    $SIG{ALRM} = sub { 
                         warn ".............timed out.............\n"; 
                         die "timeout" 
                     };

    my $search_res; 
   
    eval
    {
        alarm($timeout);

        $search_res = $self->search_no_timeout;

        alarm(0);
    };

    
    my($eval_res) = $@;


    if ($eval_res)   {

      if ($eval_res =~ /timeout/) {  

         alarm(0);         
         $self->{'_error_message'} = "Search has timed out.";
      }
      else {
        
         alarm(0);
	 $self->{'_error_message'} = "A problem occurred during searching.";
      }
     
      return undef; 
   }

}

## !!!!!
## !!!!! -when GODOT::Citation includes repeat fields will also need to add similar logic 
## !!!!!  to this package and to GODOT::CUFTS::Citation and possibly others....           
## !!!!! -to this file will need to add:   
## !!!!!     -take already filled citation and ask for a list of CUFTS query URLs
## !!!!!     -run an LWP request for each one and save returned resources
## !!!!!     -dedup resources
## !!!!!     


sub search_no_timeout {
    my($self) = @_;
   
    my $url = $self->citation->query_url($self->site);

    use LWP::UserAgent;

    my($ua) = new LWP::UserAgent;
    my($request) = new HTTP::Request GET => $url;

    $request->header('Accept' => 'text/html');
    my($res) = $ua->request($request);

    

    if (! $res->is_success) {

        $self->{'_error_message'} = "failed GET request - $url (" . $res->message . ")";
        return undef;
    }
 
    my $content = GODOT::String::trim_beg_end($res->content);

    #### warn "\n----------------------< query return >-------------------------\n", 
    ####      $content, 
    ####      "\n----------------------------------------------------------------\n";

    unless ($content =~ m#^<\?xml version="1.0" \?>#) {

        $self->{'_error_message'} = "unexpected response from CUFTS";
        debug "\nunexpected response from CUFTS (no '<?xml version=\"1.0\" ?>'):\n" . $content . "\n";
	return undef;
    } 

    if ($content =~ m#<CUFTS>(.*)</CUFTS>#s) {

        $content = $1;

        ##
        ## -is it safe to change all '&amp;' to '&' here??
        ##
        $content =~ s#\&amp;#\&#g;
                 
    }
    else {

        $self->{'_error_message'} = "unexpected response from CUFTS";
        debug "\nunexpected response from CUFTS (no '<CUFTS>' and '</CUFTS>'):\n" . $content . "\n";
        return undef;         
    }

    my @resources;
    
    while ($content =~ m#(<resource .+?>.+?</resource>)#sg) {

	my $string = $1;

	my $resource = new GODOT::CUFTS::Resource;

	if ($resource->xml_input($string)) {

	    push(@resources, $resource);
        }
	else {

            $self->{'_error_message'} = "unexpected response from CUFTS";
            debug "\nunexpected response from CUFTS (resource xml could not be parsed: " .
                  $resource->result  . "):\n" . $string . "\n";

            return undef;         
        }
    }
        
    $self->{'_resources'} = [ @resources ];

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
