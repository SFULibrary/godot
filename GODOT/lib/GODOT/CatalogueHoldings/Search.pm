## GODOT::CatalogueHoldings::Search
##
## Copyright (c) 2003, Kristina Long, Simon Fraser University
##

package GODOT::CatalogueHoldings::Search;

use Exporter;
use GODOT::Debug;
use GODOT::String;
use GODOT::Object;
use GODOT::CatalogueHoldings;

@ISA = qw(Exporter GODOT::CatalogueHoldings GODOT::Object);

@EXPORT = qw(@CONDITIONS $EXACTLY_ONE $AT_LEAST_ONE $ALL_AVAIL $UNIQUE_ONLY_SEARCH $UNIQUE_INCLUDE_SEARCH $NO_UNIQUE_SEARCH);
use vars qw(@CONDITIONS $EXACTLY_ONE $AT_LEAST_ONE $ALL_AVAIL $UNIQUE_ONLY_SEARCH $UNIQUE_INCLUDE_SEARCH $NO_UNIQUE_SEARCH);

$EXACTLY_ONE    = 'exactly_one';
$AT_LEAST_ONE   = 'at_least_one';
$ALL_AVAIL      = 'all_avail';

@CONDITIONS = ($EXACTLY_ONE, $AT_LEAST_ONE, $ALL_AVAIL);

$UNIQUE_ONLY_SEARCH     = 'unique_only_search';
$UNIQUE_INCLUDE_SEARCH  = 'unique_include_search';
$NO_UNIQUE_SEARCH       = 'no_unique_search';

use strict;

my $FALSE = 0;
my $TRUE  = 1;

my @ALL_INDEX = qw(TITLE ISSN ISBN SYSID); 

my @FIELDS = ('_records',                    ## GODOT::CatalogueHoldings::Record
              '_TITLE',
              '_ISSN',
              '_ISBN',
              '_SYSID',
              '_status_message',
              '_error_message',
              '_successful_terms',
              '_docs'
             );

##
## -called using class not object, so appears to need to have 'dispatch' defined explicitly for the class 
##
sub dispatch {
    my ($class, $param)= @_;

    my $search = $class->SUPER::dispatch($param);
    
    $search->site(${$param}{'site'});
    $search->system(${$param}{'system'});
    
    return $search;
}

sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}


sub all_terms {
    my($self) = @_;

    return $self->terms();
}

sub all_terms_except_title {
    my($self) = @_;

    return $self->terms(qw(ISSN ISBN SYSID));
}


sub docs {
    my($self, $message) = @_;

    return $self->{'_docs'} || 0;
}


sub successful_search_terms {
    my($self) = @_;

    return (defined $self->{'_successful_terms'}) ? @{$self->{'_successful_terms'}} : ();
}


sub records {
    my($self) = @_;

    return (defined $self->{'_records'}) ? @{$self->{'_records'}} : ();
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
    my($self, $system, $condition, $max_hits) = @_;

    my $timeout = $system->Timeout;

    $SIG{ALRM} = sub { 
                         warn ".............timed out.............\n"; 
                         die "timeout" 
                     };

    my $search_res; 
   
    eval
    {
        alarm($timeout);

        $search_res = $self->search_no_timeout($system, $condition, $max_hits);

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
	 $self->{'_error_message'} = "A problem occurred during searching ($eval_res).";
      }
     
      return undef; 
   }


    #### debug ".....................................................................";
    #### debug $self->dump;
    #### debug ".....................................................................";
}


##
##  $search->terms($term);            ## -adds Term object and returns a list of all Term objects
##  $search->terms(@terms);           ## -same as above, but adds one or more Term objects
##  $search->terms('TITLE', 'ISSN');  ## -returns 'TITLE' and 'ISSN' term objects
##  $search->terms();                 ## -returns all term objects
##

sub terms {
    my($self, @rest) = @_;

    my @index_arr;

    ##
    ## -determine if we are to to add a new term or return an existing term 
    ##

    if ((ref $rest[0])) {                   ## -we have been passed at least one Term object  

        foreach my $term (@rest) {            
           
            unless (ref($term)) { debug "Expected only Term objects to be passed to" . ref($self) . "::term."; }

            unless ($term->is_empty) {

                my $index = '_' . $term->Index;    
              
                push(@{$self->{$index}}, $term);
	    }
        }
    }
    else {

        @index_arr = @rest;            
    }

    if (! @index_arr) { @index_arr = @ALL_INDEX; }

    my @term_arr;

    foreach my $index (@index_arr) {
            
        push(@term_arr, @{$self->{'_' . $index}}) if (defined $self->{'_' . $index}) ;
    }
  
    return @term_arr;
}


##
## (28-apr-2005 kl) - Adds 'TITLE' GODOT::Term objects. 
##

##
## !!!!!!!!!!!!!!! when move to new config tool for all options, query re 'strip apostrophe s' in this function 
##                 and remove from param 
## !!!!!!!!!!!!!!!
##

sub title_terms {
    my($self, $citation, $strip_apostrophe_s) = @_;

    my(@terms);

    my $site = $self->site; 
    my $system = $self->system;

    my $title = $citation->parsed('TITLE');

    $title =~ s#/# #g;                     ## -replace (instead of remove) forward slashes as they confuse zclient
           
    my $term = GODOT::CatalogueHoldings::Term->dispatch({'site' => $site, 'system' => $system});
    $term->title($title, $strip_apostrophe_s, $citation->is_journal);
    $self->terms($term);

    my $sty_term = GODOT::CatalogueHoldings::Term->dispatch({'site' => $site, 'system' => $system});
    $sty_term->strip_trailing_year_title($title, $strip_apostrophe_s, $citation->is_journal);

    ##
    ## -don't add duplicate term
    ##

    if ($term->Term ne $sty_term->Term) { $self->terms($sty_term); }

    ##
    ## -replace '&' with 'and' before cleaning up as otherwise '&' will get cleaned up
    ##
    my $title_repl_ampersand = $title;    
    $title_repl_ampersand =~ s#\&# and #g;

    if ($title_repl_ampersand ne $title) {

        $term = GODOT::CatalogueHoldings::Term->dispatch({'site' => $site, 'system' => $system});
        $term->title($title_repl_ampersand, $strip_apostrophe_s, $citation->is_journal);
        $self->terms($term);

        $sty_term = GODOT::CatalogueHoldings::Term->dispatch({'site' => $site, 'system' => $system});
        $sty_term->strip_trailing_year_title($title_repl_ampersand, $strip_apostrophe_s, $citation->is_journal);

        ##
        ## -don't add duplicate term
        ##

        if ($term->Term ne $sty_term->Term) { $self->terms($sty_term); }
    }

    #### debug "/////////////////////////////////////////////////////////////////////////", "\n",
    ####      $self->dump,
    ####      "/////////////////////////////////////////////////////////////////////////", "\n";

}


sub issn_terms {
    my($self, $citation) = @_;

    my $site = $self->site;
    my $system = $self->system;

    my $term = GODOT::CatalogueHoldings::Term->dispatch({'site' => $site, 'system' => $system});
    $term->issn($citation->parsed('ISSN'), $citation->is_journal);
    $self->terms($term);

    my $hyphen_term = GODOT::CatalogueHoldings::Term->dispatch({'site' => $site, 'system' => $system});
    $hyphen_term->hyphen_issn($citation->parsed('ISSN'), $citation->is_journal);
    $self->terms($hyphen_term);
}


sub isbn_terms {
    my($self, $citation) = @_;

    my $site = $self->site;
    my $system = $self->system;

    my $term = GODOT::CatalogueHoldings::Term->dispatch({'site' => $site, 'system' => $system});
    $term->isbn($citation->parsed('ISBN'), $citation->is_journal);
    $self->terms($term);

    my $hyphen_term = GODOT::CatalogueHoldings::Term->dispatch({'site' => $site, 'system' => $system});
    $hyphen_term->hyphen_isbn($citation->parsed('ISBN'), $citation->is_journal);
    $self->terms($hyphen_term);
}


sub sysid_terms {
    my($self, $citation) = @_;

    my $site = $self->site;
    my $system = $self->system;

    my $term = GODOT::CatalogueHoldings::Term->dispatch({'site' => $site, 'system' => $system});
    $term->sysid($citation->parsed('SYSID'), $citation->is_journal);
    $self->terms($term);
}


sub unique_search_type {
    my($self, $dbase) = @_;

    return $NO_UNIQUE_SEARCH;
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
