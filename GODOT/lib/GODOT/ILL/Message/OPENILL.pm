package GODOT::ILL::Message::OPENILL;
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
    my $patron = $self->patron;

    my $message;

    my $date = $self->date;

    $message .= "1: ";					# item type
    $message .= $citation->is_journal ? '2' : '1';
    $message .= "\n";
    
    $message .= "2: 1\n";				        # medium type
    $message .= "3: " . $citation->parsed('CALL_NO') . "\n";	# call-number
    $message .= "4: " . $citation->parsed('AUT') . "\n";	# author
    $message .= "5: " . $citation->parsed('TITLE') . "\n";	# title
    $message .= "6: \n";				        # sub-title
    $message .= "7: \n";				        # sponsoring body
    $message .= "8: " .  $citation->parsed('PUB_PLACE') . "\n";	# place of pub
    $message .= "9: " .  $citation->parsed('PUB') . "\n";	# publisher
    $message .= "10: " . $citation->parsed('SERIES') . "\n";	# series title num
    $message .= "11: " . $citation->parsed('VOLISS') . "\n";	# volume/issue
    $message .= "12: " . $citation->parsed('EDITION') . "\n";	# edition
    $message .= "13: $date\n";    				# publication date
    $message .= "14: \n";				        # publication date of component
    $message .= "15: " . $citation->parsed('ARTAUT') . "\n";	# article author
    $message .= "16: " . $citation->parsed('PGS') . "\n";	# pagination
    $message .= "17: \n";				        # national bib no
    $message .= "18: " . $citation->parsed('ISBN') . "\n";	# isbn
    $message .= "19: " . $citation->parsed('ISSN') . "\n";	# issn
    $message .= "20: " . $citation->parsed('SYSID') . "\n";	# system number
    $message .= "21: \n";				        # additional numbers
    $message .= "22: " . $self->source . " ($reqno)\n";
    $message .= "23: " . $citation->parsed('ARTTIT') . "\n";	# title of article
    
    $message .= "\n\n";
    
    # other GODOT fields
    
    $message .= "GODOT REQUEST TYPE: " . $citation->req_type . "\n\n";

    $message .= "PATRON FIRST NAME: " . $patron->first_name . "\n";
    $message .= "PATRON LAST NAME: " . $patron->last_name . "\n";
    $message .= "PATRON LIBRARY ID: " . $patron->library_id . "\n";
    $message .= "PATRON DEPARTMENT: " . $patron->department . "\n";
    $message .= "PATRON TYPE: " . $patron->type . "\n";
    $message .= "PATRON EMAIL: " . $patron->email . "\n";
    $message .= "PATRON NEEDBY: " . $self->not_req_after . "\n";
    $message .= "PATRON REQUEST TYPE: " . $self->request_type . "\n";
    $message .= "PATRON PICKUP: " . $patron->pickup . "\n";
    $message .= "PATRON PHONE: " . $patron->phone . "\n";
    $message .= "PATRON WORK PHONE: " . $patron->phone_work . "\n";
    $message .= "PATRON STREET: " . $patron->street . "\n";
    $message .= "PATRON CITY: " . $patron->city . "\n";
    $message .= "PATRON PROV: " . $patron->province . "\n";
    $message .= "PATRON POSTAL CODE: " . $patron->postal_code . "\n";
    $message .= "PATRON NOTES: " . $patron->note . "\n";

    $message .= "\n\n";
    
    $message .= "MEDIATED: " . ($self->request_type eq 'M' ? "1\n" : "0\n");

    ##
    ## (21-sep-2005 kl) - the first site in the 'HOLDINGS:' field needs to be the lender 
    ##                  - the lender site should then be removed from the rest of the holdings site string 
    ##                    (ie. it only needs to appear at the beginning)
    ## 
    my @holdings_site;

    unless (aws($self->holdings_site)) {

	my $lender_site = GODOT::ILL::Site->dispatch({'site' => $self->lender_site});
	$lender_site->nuc($self->lender_nuc);

        push(@holdings_site,  $lender_site->description);
        foreach my $site (split(/\s+/, $self->holdings_site)) {
            push(@holdings_site,  $site) unless ($site eq $lender_site->description);	
        }
    }

    $message .= "HOLDINGS: " . trim_beg_end(join(' ', @holdings_site)) . "\n";

    $message .= "LENDER EMAIL: " . $self->lender_email . "\n";

    #### debug "------------------- openill -------------------------------------------------------\n",
    ####      $message, 
    ####      "-----------------------------------------------------------------------------------\n";

    return $message;


}

sub date {
    my($self) = @_;

    my $citation = $self->citation;
    return join('-', $citation->parsed('YEAR'), $citation->parsed('MONTH'), $citation->parsed('DAY'));
}


1;





