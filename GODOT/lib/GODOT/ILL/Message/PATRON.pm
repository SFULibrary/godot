package GODOT::ILL::Message::PATRON;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use GODOT::Debug;
use GODOT::String;
use GODOT::Object;
use GODOT::ILL::Message;

use base qw(GODOT::ILL::Message);


use strict;

sub format {
    my($self, $reqno) = @_;

    my $citation = $self->citation;
    my $patron   = $self->patron;

    my $date = $self->date;

    my $additional_text = $self->additional_text;
    my $last_name       = $patron->last_name;
    my $first_name      = $patron->first_name;
    my $library_id      = $patron->library_id;
    my $department      = $patron->department;
    my $type            = $patron->type;
    my $note            = $patron->note;
    my $dbase           = $citation->dbase;
    my $not_req_after   = $self->not_req_after;
 

    my %citn;
    foreach my $field qw(ARTAUT ARTTIT AUT TITLE PUB YEAR PGS SERIES VOLISS THESIS_TYPE ISSN ISBN) {
        $citn{$field} = $citation->parsed($field);
    }
    

    my $message .=<<"EOM";    

$additional_text

NAME:        $last_name, $first_name/$library_id 
DEPT:        $department STATUS: $type
NEED BEFORE: $not_req_after

EOM

       my $publisher_statement = $self->publisher_statement;
      
       ##
       ## -bibliographic info
       ##
       if ($citation->is_book || $citation->is_book_article)
       {
               if ($citation->is_book_article) 
               {
                       $message .=<<"EOM";    

ARTICLE AUTHOR: $citn{'ARTAUT'}
ARTICLE TITLE:  $citn{'ARTTIT'}

EOM
               }

               $message .=<<"EOM"; 

AUTHOR:         $citn{'AUT'}
TITLE:          $citn{'TITLE'}
IMPRINT:        $publisher_statement
DATE:           $citn{'YEAR'}
PAGES:          $citn{'PGS'}
SERIES:         $citn{'SERIES'}

EOM
       }       
       elsif ($citation->is_conference) 
       {

               $message .=<<"EOM"; 

AUTHOR:         $citn{'AUT'}
TITLE:          $citn{'TITLE'}
DATE:           $date
SERIES:         $citn{'SERIES'}
IMPRINT:        $publisher_statement

ARTICLE AUTHOR: $citn{'ARTAUT'}
TITLE:          $citn{'ARTTIT'}
PAGES:          $citn{'PGS'}

EOM
       }
       elsif ($citation->is_journal) 
       {

               $message .=<<"EOM";
       
JOURNAL:        $citn{'TITLE'}
SERIES:         $citn{'SERIES'}
ISSUE:          $citn{'VOLISS'}
DATE:           $date
PAGES:          $citn{'PGS'}
IMPRINT:        $publisher_statement

ARTICLE AUTHOR: $citn{'ARTAUT'}
TITLE:          $citn{'ARTTIT'}

EOM
       }
       elsif ($citation->is_tech) 
       {            

               $message .=<<"EOM";

AUTHOR:         $citn{'AUT'}
TITLE:          $citn{'TITLE'}
SERIES:         $citn{'SERIES'}
ISSUE:          $citn{'VOLISS'}
IMPRINT:        $publisher_statement

ARTICLE AUTHOR: $citn{'ARTAUT'}
TITLE:          $citn{'ARTTIT'}
DATE:           $date
PAGES:          $citn{'PGS'}

EOM
       }
       elsif ($citation->is_thesis) 
       {

  	       my $thesis;
               if (naws($citn{'THESIS_TYPE'})) {
                   $thesis = $citn{'TITLE'} . ' ('  . $citn{'THESIS_TYPE'} . ')'; 
               }
               else {
                   $thesis = $citn{'TITLE'};
               }

               $message .=<<"EOM";

AUTHOR:         $citn{'AUT'}
TITLE:          $thesis
IMPRINT:        $publisher_statement
DATE:           $date

EOM
       }

       $message .=<<"EOM";

ISBN:    $citn{'ISBN'} 
ISSN:    $citn{'ISSN'} 

SOURCE:  GODOT $reqno from $dbase
NOTE:    $note

EOM

}


sub subject {
    my($self, $reqno) = @_;

    return "Document Delivery Request for " . $self->patron->last_name;
}

sub transliteration  { return 'utf8'; }

sub encoding         { return 'utf8'; }

1;



