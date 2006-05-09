package GODOT::ILL::Message::AVISO_3;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use GODOT::Debug;
use GODOT::String;
use GODOT::Object;
use GODOT::Constants;

use base qw(GODOT::ILL::Message);

my $WRAP_INDENT = 20;
my $WRAP_LEN    = 60;

use strict;


sub format {
    my($self, $reqno) = @_;

    my $message;
    my $imprint; 

    my $citation = $self->citation;
    my $patron = $self->patron;
    my $date = $self->date;

    my $last_name = $patron->last_name;
    my $first_name = $patron->first_name;
    my $library_id = $patron->library_id;
    my $department = $patron->department;
    my $type = $patron->type;
    my $email = $patron->email;
    my $pickup = $patron->pickup;
    my $not_req_after = $self->not_req_after;
    my $request_type = $self->request_type;

    my %citn;
    foreach my $field qw(REQTYPE ARTAUT ARTTIT AUT TITLE PUB YEAR PGS SERIES VOLISS THESIS_TYPE ISSN ISBN) {
        $citn{$field} = $citation->parsed($field);
    }

    $message .=<<"EOM";  

{CO:

REQUEST FOR: $citn{'REQTYPE'}

PNAME   $last_name, $first_name/$library_id

PDEPT   $department

PSTAT   $type

EMAIL ADDRESS:  $email

NEEDBY $not_req_after
REQ    

EOM
        ##
        ## bibiliographic information
        ##

        if (! (aws($citn{'ISSN'}) && aws($citn{'ISBN'}))) {
                $imprint = "ISN: $citn{'ISSN'} $citn{'ISBN'} "; 
        }

        if (! aws($citn{'PUB'})) {

                if ($imprint)  { $imprint .= " - $citn{'PUB'}"; }
                else           { $imprint = $citn{'PUB'};       }
        }
  
       if ($citation->is_book || $citation->is_book_article)	
       {
               $message .=<<"EOM";   

LNTYPE MO
AU     $citn{'AUT'}
TI     $citn{'TITLE'}

IMP    $imprint
DATE   $citn{'YEAR'}

AU     $citn{'ARTAUT'}
ARTTI  $citn{'ARTTIT'}

SERIES $citn{'SERIES'}
PAGES  $citn{'PGS'}

EOM
       }
       elsif ($citation->is_conference)
       {
              $message .=<<"EOM";           

LNTYPE CO
AU     $citn{'AUT'}
TI     $citn{'TITLE'}
DATE   $date
 
SERIES $citn{'SERIES'}
 
AU     $citn{'ARTAUT'}
ARTTI  $citn{'ARTTIT'}

PAGES  $citn{'PGS'}
 
IMP    $imprint
EOM
       }
       elsif ($citation->is_journal)
       {
              $message .=<<"EOM";           

LNTYPE JO
TI     $citn{'TITLE'}

ISSUE  $citn{'VOLISS'}
DATE   $date
SERIES $citn{'SERIES'}
PAGES  $citn{'PGS'}

IMP    $imprint

AU     $citn{'ARTAUT'}

ARTTI  $citn{'ARTTIT'}

EOM
       }
       elsif ($citation->is_tech)
       {
                $message .=<<"EOM";    
LNTYPE RP
AU     $citn{'AUT'}
TI     $citn{'TITLE'}
 
SERIES $citn{'SERIES'}
ISSUE  $citn{'VOLISS'}
DATE   $date
 
AU     $citn{'ARTAUT'}
ARTTI  $citn{'ARTTIT'}
 
PAGES  $citn{'PGS'}
 
IMP    $imprint
EOM
      }
      elsif ($citation->is_thesis)


      {
	  my $thesis;

               if (naws($citn{'THESIS_TYPE'})) {
                   $thesis = "$citn{'TITLE'} ($citn{'THESIS_TYPE'})"; 
               }
               else {
                   $thesis = $citn{'TITLE'};
               }

               $message .=<<"EOM";    
LNTYPE TH

AU    $citn{'AUT'}
TI    $thesis

IMP   $imprint

DATE  $date

EOM
      }
      else  { 
              $message = '';
      }

      if ($message) {              

              $message .= "RSN    $reqno\n";
              $message .= "SOURCE " . $self->source .  "\n\n";
              $message .= "TEXT                 $pickup\n" if (naws($pickup));    
              $message .= "TEXT                 $email\n" if (naws($email));    
              $message .= "TEXT                 $department\n" if (naws($department));    
              $message .= "TEXT                 $type\n" if (naws($type));    
              $message .= "TEXT";
              
              my $tmp_str = $self->message_note($reqno); 
              $tmp_str =~ s#^\*   ##g;

              $message .= $tmp_str;

              if ($message !~ m#\n$#) { $message .= "\n"; } 

              $message .= '||||||||||';             # add end of note terminator  
      }

      return ($message);     # will be '' if there was an error 
}


sub _do_not_include {
    my($self) = @_;

    return qw(reqno type not_req_after department email pickup);
}



sub _add_leading_char { return $TRUE; }

sub _wrap_indent      { return $WRAP_INDENT; }

sub _wrap_len         { return $WRAP_LEN;  }


1;





