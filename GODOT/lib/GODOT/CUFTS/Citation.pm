package GODOT::CUFTS::Citation;
##
## Copyright (c) 2003, Kristina Long, Simon Fraser University
##

use CGI qw(:escape);
use Encode;
use GODOT::Debug;
use GODOT::String;
use GODOT::Encode;
use GODOT::Encode::Transliteration;
use GODOT::Config;
use GODOT::CUFTS::Config;

use base qw(GODOT::CUFTS::Object);

use strict;

my $FALSE = 0;
my $TRUE  = 1;

##
## OpenURL (version 0.1) fields 
## 
##
my @FIELDS = qw(genre
                aulast aufirst auinit auinit1 auinitm
                issn eissn coden isbn
                sici bici
                title stitle atitle
                volume part issue spage epage pages artnum
                date ssn quarter                                 
                doi pmid bibcode oai
               );

my @ID_FIELDS = qw(doi pmid bibcode oai);

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
        my $escaped_value = escape(GODOT::String::encode_string('latin1', utf8_to_latin1_transliteration($self->$field)));

        if (grep { $field eq $_} @ID_FIELDS) {
            $url .= join('', $delim, 'id', '=', $field, ':', $escaped_value);                
        }
        else {
            $url .= join('', $delim, $field, '=', $escaped_value);                
        }
    }
    
    if ($url) {
        my $sites = $site->site;
         
        if (&GODOT::String::naws($site->assoc_sites)) { 
            $sites  = join(',', $sites, split(/\s+/, $site->assoc_sites));
        }

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

