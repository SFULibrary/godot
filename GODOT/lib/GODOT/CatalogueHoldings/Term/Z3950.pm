package GODOT::CatalogueHoldings::Term::Z3950;
##
## Copyright (c) 2003, Kristina Long, Simon Fraser University
##

use GODOT::CatalogueHoldings::Term;
@ISA = qw(GODOT::CatalogueHoldings::Term);

use GODOT::CatalogueHoldings::System::Z3950::Attrib;
use GODOT::Debug;

use strict;

use GODOT::String;

my $FALSE = 0;
my $TRUE  = 1;

my $TITLE_USE_ATTRIB = 4;
my $ISBN_USE_ATTRIB  = 7;
my $ISSN_USE_ATTRIB  = 8;
my $SYSID_USE_ATTRIB = 12;

my %USE_ATTRIB_SUBROUTINE  = ('TITLE' => 'title_use_attrib',
                              'ISBN'  => 'isbn_use_attrib',
                              'ISSN'  => 'issn_use_attrib',
                              'SYSID' => 'sysid_use_attrib'
			     );
my @FIELDS = ();

sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH') { $values = $fields; }          
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}



##
## -create a string in Index Data's prefix query format used by Net::Z3950 
##

sub prefix_syntax {
    my ($self, $system) = @_;

    ##
    ## -determine the appropriate attributes
    ##   

    my $subroutine = $USE_ATTRIB_SUBROUTINE{$self->Index};

    my %attrib;

    $attrib{'use'} = $self->$subroutine($system);

    if ($self->is_title) {

        $attrib{'relation'}     = $self->title_relation_attrib($system);
        $attrib{'position'}     = $self->title_position_attrib($system);
        $attrib{'structure'}    = $self->title_structure_attrib($system);
        $attrib{'truncation'}   = $self->title_truncation_attrib($system);
        $attrib{'completeness'} = $self->title_completeness_attrib($system);
    }

    ##
    ## -check for good attribute values and put together prefix query string
    ##

    my $host  = $system->Host;
    my $port  = $system->Port;
    my $dbase = $system->Database;

    my $string;
    my $attrib_num = 0;

    foreach my $attrib_name (qw(use relation position structure truncation completeness)) {

        $attrib_num++;

        my $attrib = $attrib{$attrib_name};       

        $string .= "\@attr $attrib_num=$attrib " if $attrib;        
    }

    ##
    ## (17-mar-2005 kl) - Endeavor doesn't like this escaping.  Change to stripping quotes out.
    ## 
    ## -append the search term
    ##
    #### (my $term_string = $self->Term) =~ s#"#\\"#g;
    ##

    (my $term_string = $self->Term) =~ s#"##g;

    #### debug "term_string: $term_string";

    return $string . '"' . $term_string . '"';
}

sub title_use_attrib {
    my($self, $system) = @_;

    my $use_attrib;

    ##
    ## -use 'title' use attribute unless 'journal title' attribute is explicitly specified
    ##
    
    my $use_journal_attrib = $self->is_journal && $system->JournalTitle; 

    #### debug "use_journal_attrib:  $use_journal_attrib, is_journal:  ", $self->is_journal, "\n";

    if ($use_journal_attrib) {
        $use_attrib = $system->JournalTitle->UseAttribute if (defined $system->JournalTitle);
    }
    else {
        $use_attrib = $system->Title->UseAttribute if (defined $system->Title);
    }

    if  (! $use_attrib) { $use_attrib = $TITLE_USE_ATTRIB; }

    return &GODOT::String::trim_beg_end($use_attrib);
}

sub isbn_use_attrib {
    my($self, $system) = @_;

    my $use_attrib;

    if (defined $system->ISBN) {
        $use_attrib = ($system->ISBN->UseAttribute) ? $system->ISBN->UseAttribute : $ISBN_USE_ATTRIB;
    }

    if  (! $use_attrib) { $use_attrib = $ISBN_USE_ATTRIB; }

    return &GODOT::String::trim_beg_end($use_attrib);
}


sub issn_use_attrib {
    my($self, $system) = @_;

    my $use_attrib; 

    if (defined $system->ISSN) {
        $use_attrib = ($system->ISSN->UseAttribute) ? $system->ISSN->UseAttribute : $ISSN_USE_ATTRIB;
    }
 
    if  (! $use_attrib) { $use_attrib = $ISSN_USE_ATTRIB; }

    return &GODOT::String::trim_beg_end($use_attrib);
}
sub sysid_use_attrib {
    my($self, $system) = @_;

    my $use_attrib; 

    if (defined $system->SysID) {
        $use_attrib = ($system->SysID->UseAttribute) ? $system->SysID->UseAttribute : $SYSID_USE_ATTRIB;
    }

    if  (! $use_attrib) { $use_attrib = $SYSID_USE_ATTRIB; }

    return &GODOT::String::trim_beg_end($use_attrib);
}


sub title_relation_attrib {
    my($self, $system) = @_;

    return $self->title_attrib($system, 'RelationAttribute');
}

sub title_position_attrib {
    my($self, $system) = @_;

    return $self->title_attrib($system, 'PositionAttribute');
}

sub title_structure_attrib {
    my($self, $system) = @_;

    return $self->title_attrib($system, 'StructureAttribute');
}

sub title_completeness_attrib {
    my($self, $system) = @_;

    return $self->title_attrib($system, 'CompletenessAttribute');
}

sub title_truncation_attrib {
    my($self, $system) = @_;

    return $self->title_attrib($system, 'TruncationAttribute');
}


sub title_attrib {
    my($self, $system, $attrib_type) = @_;

    my $attrib;
    my $term = $self->Term;
 
    my $is_single_word = &GODOT::String::is_single_word($term);
    
    my $use_journal_attrib = ($self->is_journal() && $system->JournalTitle->UseAttribute) ? $TRUE : $FALSE; 

    my $journal_sw  = $system->JournalTitle->$attrib_type('SingleWord');
    my $journal_any = $system->JournalTitle->$attrib_type('AnyNumberWord');
    my $sw          = $system->Title->$attrib_type('SingleWord');
    my $any         = $system->Title->$attrib_type('AnyNumberWord');

    if ($use_journal_attrib)  { 

        if (($journal_sw) && ($is_single_word)) { $attrib = $journal_sw;  }
        elsif ($journal_any)                    { $attrib = $journal_any; }
    }
    else {
        if (($sw) && ($is_single_word))  { $attrib = $sw; }
        elsif ($any)                     { $attrib = $any; }
    }

    return &GODOT::String::trim_beg_end($attrib);



}


1;




