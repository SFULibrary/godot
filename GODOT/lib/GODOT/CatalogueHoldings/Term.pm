package GODOT::CatalogueHoldings::Term;
##
## Copyright (c) 2003, Kristina Long, Simon Fraser University
##

use Data::Dump qw(dump);

use GODOT::Object;
use GODOT::CatalogueHoldings;
@ISA = qw(GODOT::CatalogueHoldings GODOT::Object);

use GODOT::String;
use GODOT::Encode;
use GODOT::Debug;

use strict;

##
##  *** For the logic in this module to work, these names must match those used by the ***
##  *** GODOT::Citation object.                                                        ***
##
##  *** Any changes here should also be made in Term::Z3950.pm                         ***
##

my @INDEXES = qw(TITLE ISSN ISBN SYSID);

##
## The Terms class implements a data structure containing the following fields:
##

my @FIELDS = qw(Index 
                Term 
                _reason 
                _is_journal);                               

##
## -called using class not object, so appears to need to have 'dispatch' defined explicitly for the class
##
sub dispatch {
    my ($class, $param)= @_;

    my $obj = $class->SUPER::dispatch($param);
    $obj->system(${$param}{'system'});
    return $obj;
}

sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}

sub title {
    my($self, $title, $strip_apostrophe_s, $is_journal) = @_;

    $self->Index('TITLE');
    $self->is_journal($TRUE) if $is_journal; 

    ##
    ## -replace hyphens with spaces so easier to do rest of processing (eg. 'COMPUTERS-AND-MATHEMATICS-WITH-APPLICATIONS')
    ## -remove apostrophe-s (ie. maclean's ===> maclean)
    ##
    $title =~ s#\055# #g;
    $title =~ s#\'s##gi if $strip_apostrophe_s;

    #### debug dump($self);

    return $self->Term($title);
}

sub strip_trailing_year_title {
    my($self, $title, $strip_apostrophe_s, $is_journal) = @_;

    $self->Index('TITLE');
    $self->is_journal($TRUE) if $is_journal; 

    ## -!!!! also need some logic for year range, ex. 1976-1998. !!!

    if ($title =~ m#\d\d\d\d\055\d\d\d\d[\.]?\s*$#) { $title =~ s#\d\d\d\d\055\d\d\d\d[\.]?\s*$##; }
    else                                            { $title =~ s#\d\d\d\d[\.]?\s*$##i;            }

    ##
    ## (10-oct-2010 kl) -- use '$self->title($title)' instead so that catalogue vendor specific processing is done
    ##
    #### return $self->Term($title);
    return $self->title($title);
}


sub encode {
    my($self, $title_index_includes_non_ascii) = @_;

    #### report_location;
    #### debug dump($self);

    my $string = $self->Term;
    $string = encode_catalogue_search_term($string, $self->system, $title_index_includes_non_ascii);        ## from GODOT::Encode
    $self->Term($string);
}


sub issn {
    my($self, $issn, $is_journal) = @_;

    $self->Index('ISSN');
    $self->is_journal($TRUE) if $is_journal;

    $issn =~ s#/##g;                                ## -get rid of forward slashes as they confuse zclient
    $issn =~ s#\055##g;                             ## -remove hyphen            

    $self->Term($issn);
}


sub hyphen_issn {
    my($self, $issn, $is_journal) = @_;

    $self->Index('ISSN');
    $self->is_journal($TRUE) if $is_journal;

    $issn =~ s#/##g;                                ## -get rid of forward slashes as they confuse zclient
    $issn =~ s#\055##g;                             ## -remove hyphen            
    $issn = (substr($issn, 0, 4) . "-" . substr($issn, 4, 4)) unless aws($issn);  ## add back hyphen

    $self->Term($issn);
}

sub isbn {
    my($self, $isbn, $is_journal) = @_;

    $self->Index('ISBN');
    $self->is_journal($TRUE) if $is_journal;

    $isbn =~ s#/##g;                                ## -get rid of forward slashes as they confuse zclient
    $isbn =~ s#\055##g;                             ## -remove hyphens
            
    $self->Term($isbn);
}

sub hyphen_isbn {
    my($self, $isbn, $is_journal) = @_;

    $self->Index('ISBN');
    $self->is_journal($TRUE) if $is_journal;

    $isbn =~ s#/##g;                                ## -get rid of forward slashes as they confuse zclient
    $isbn =~ s#\055##g;                             ## -remove hyphens

    ## 
    ## (01-jan-2007 kl)  !!! TO DO !!! - add logic for hyphenation of isbn-13 -- is there a new version of Business::ISBN?
    ##

    if (length($isbn) == 10)  {
       
        ##
        ## (01-jan-2007 kl) - it turns out that isbn hyphenation is based on the country and publisher codes so
        ##                    use Business::ISBN to hyphenate properly

        #### $isbn =~ m#(\d)(\d\d\d\d)(\d\d\d\d)([\dxX])#;   ## -put hypnens back
        #### $isbn = "$1-$2-$3-$4";

        use Business::ISBN;
        my $obj = Business::ISBN->new($isbn);
        $isbn = $obj->as_string;
    }

    $self->Term($isbn);
}

sub sysid {
    my($self, $sysid, $is_journal) = @_;

    $self->Index('SYSID');
    $self->is_journal($TRUE) if $is_journal;
    $self->Term($sysid);
}

sub is_empty {
    my($self) = @_;

    return (GODOT::String::aws($self->Index) || GODOT::String::aws($self->Term));
}

sub is_journal {
    my($self) = shift;

    if (@_) { return $self->{'_is_journal'} = shift; }
    else    { return $self->{'_is_journal'};         }
}


sub reason {
    my($self) = @_; 
    return $self->_reason;
}

sub is_success {
    my($self) = @_;

    return (! defined $self->_reason);
}

sub is_title { 
    my($self) = @_;
    return ($self->Index eq 'TITLE');
}

sub is_issn { 
    my($self) = @_;
    return ($self->Index eq 'ISSN');
}

sub is_isbn { 
    my($self) = @_;
    return ($self->Index eq 'ISBN');
}

sub is_sysid { 
    my($self) = @_;
    return ($self->Index eq 'SYSID');
}


1;

__END__

