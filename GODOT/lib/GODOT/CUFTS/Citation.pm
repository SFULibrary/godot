package GODOT::CUFTS::Citation;
##
## Copyright (c) 2003, Kristina Long, Simon Fraser University
##

use CGI qw(:escape);

use Encode;

use GODOT::Debug;
use GODOT::String;
use GODOT::Encode;
use GODOT::Config;
use GODOT::CUFTS::Config;

use base qw(GODOT::CUFTS::Object);

use strict;

my $FALSE = 0;
my $TRUE  = 1;

##
## OpenURL (version 0.1) fields
##
my @FIELDS = qw(genre
                aulast aufirst auinit auinit1 auinitm
                issn eissn coden isbn
                sici bici
                title stitle atitle
                volume part issue spage epage pages artnum
                date ssn quarter                                 
               );


sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}

##
## (30-nov-2003 kl) - temporary fix to deal with namespace problem that has not yet
##                    been solved
##

sub title {
    my $self = shift;

    my $field = 'title';

    if (@_) { return $self->{$field} = shift; }
    else    { return $self->{$field}; }
}


sub query_url {
    my($self, $site) = @_;

    my $count;
    my $url;
    foreach my $field (@FIELDS) {
        next if aws($self->$field);

        my $delim = ($count) ? '&' : '?';
        $count++;

        ##
        ## (30-jan-2010 kl) -- transliterate characters not in latin1 range 
        ##                  -- cufts currently expects latin1 but future version will take utf8
        ##                  -- encode as latin1 before uri escaping
        ##  
        my $escaped_value = escape(encode('iso-8859-1', utf8_to_latin1_transliteration($self->$field)));
        #### my $escaped_value = escape(utf8_to_latin1_transliteration($self->$field));

        $url .= join('', $delim, $field, '=', $escaped_value);                
    }
    
    if ($url) {

        my $sites = $site->site;

        debug location, ":  before assoc_sites: $sites";
         
        if (&GODOT::String::naws($site->assoc_sites)) { 

            #### debug location, "assoc_sites: ", $site->assoc_sites;
            $sites  = join(',', $sites, split(/\s+/, $site->assoc_sites));
        }

        debug location, ":  this is the site list for CUFTS:  $sites";  
        debug location, ":  bccampus:  ", $site->is_bccampus;  

        $url = $GODOT::Config::CUFTS_SERVER_URL . 
               (($GODOT::Config::CUFTS_SERVER_URL =~ m#\/$#) ? '' : '/' ) . 
               $sites .  
               "/resolve/openurl/xml" . $url;

        ##
        ## (28-jan-2005 kl) - BC Campus logic -- need to move to 'local' class .... 
        ##

        if ($site->is_bccampus) {  $url .= '%26<CUFTSproxy>alternate</CUFTSproxy>';  }
    }


    debug "CUFTS::Citation::query_url:  $url\n";

    return $url;
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
