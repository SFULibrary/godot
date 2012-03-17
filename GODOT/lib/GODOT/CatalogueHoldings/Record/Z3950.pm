package GODOT::CatalogueHoldings::Record::Z3950;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##
use GODOT::CatalogueHoldings::Record;
push @ISA, qw(GODOT::CatalogueHoldings::Record);

use Data::Dump qw(dump);

use GODOT::Debug;
use GODOT::String;
use GODOT::Normalize;
use GODOT::Encode;

use strict;

my $MARC_LEADER_FIELD             = '000';
my $MARC_ISBN_FIELD               = '020';
my $MARC_ISSN_FIELD               = '022';
my $MARC_OTHER_STANDARD_ID_FIELD  = '024';
my $MARC_TITLE_FIELD              = '245';
my $MARC_VARYING_FORM_TITLE_FIELD = '246';

my $FALSE = 0;
my $TRUE  = 1;
my $BLANK = ' ';

sub bibliographic {
    my($self) = @_;

    return $self->record;
}

##
## (08-oct-2010 kl) 
## - moved older version of logic from good_match
##
sub bib_record_read_correct_decode {
    my($self) = @_;

    use MARC::Record;
    my $bib = $self->bibliographic;
    my $rawdata = $bib->rawdata();     

    my ($encoding, $try_to_read) = bib_record_detect_encoding($rawdata);

    unless ($try_to_read) {
        debug location_plus, "encoding is $encoding -- record is being tossed out";
        return $FALSE;
    }

    my $leader_09 = substr($rawdata, 9, 1);
    my $new_leader_09 = leader_09_for_encoding($encoding);
 
    if ($leader_09 ne $new_leader_09) {
        substr($rawdata, 9, 1) = $new_leader_09;
        #### debug location_plus, "leader changed from '$leader_09' to '$new_leader_09'";
    }

    my $bib_record_object;
    eval {  $bib_record_object = MARC::Record->new_from_usmarc($rawdata); };
    my $eval_res = $@;
    debug location_plus, "eval error -- $eval_res" if $eval_res;

    unless (defined $bib_record_object) {
        debug location_plus, "bibliographic record object could not be created";
        return $FALSE;
    }

    ## 
    ## (23-oct-2010)
    ## If marc record was encoded in utf8 the $bib_record_object data will be in perl internal format.
    ## If marc record was encoded in marc8 the $bib_record_oject data will *still* be encoded in marc8.
    ##
    #### debug '-----------------before------------------------------------';
    #### debug location;
    #### debug Data::Dump::dump($bib_record_object);
    #### debug '-----------------------------------------------------';

    my $bib_record_object_decoded = MARC::Record->new();

    ##
    ## (26-mar-2011 kl) - added as leader was not being included in $bib_record_object_decoded
    ##
    $bib_record_object_decoded->leader($bib_record_object->leader);

    ##
    ## Copy all fields to $bib_record_object_decoded using a decoded version of all non-control fields.
    ## !!!! Below will cause problems if any MARC::Field or MARC::Record logic is used that assumes data is still encoded.  However this should be ok for now for our purposes. !!!
    ##    
    my @cloned_fields;
    foreach my $field ($bib_record_object->fields()) {
        my $cloned_field;
        ##
        ## -are we likely to have other than ascii data in control fields ??
        ##
        if ($field->is_control_field) {                      
            $cloned_field = $field->clone;
        }
        else {
            $cloned_field = decode_marc_record_field_clone($bib_record_object, $field, $encoding);        
        }
        push @cloned_fields, $cloned_field;
    }

    $bib_record_object_decoded->append_fields(@cloned_fields);

    ##
    ## Data in all non-control fields should now be in perl internal format.
    ##
    #### debug '-----------------after------------------------------------';
    #### debug location;
    #### debug Data::Dump::dump($bib_record_object_decoded);
    #### debug '-----------------------------------------------------';

    $self->bib_record_object($bib_record_object_decoded);
    return $TRUE;
}

sub good_match {
    my($self, $db_config, $citation) = @_;

    #### report_location;

    my $bib_record_object = $self->bib_record_object;

    #### debug '-----------------------------------------------------';
    #### debug location;
    #### debug Data::Dump::dump($bib_record_object);
    #### debug '-----------------------------------------------------';

    ##
    ## -remove all leading and trailing white space so can later test for null string instead of all-white-space
    ##
    my $citation_title =  normalize_for_catalogue_match($citation->parsed('TITLE'));

    ##
    ## (14-feb-2003 kl) - added logic to make ISSN and ISBN uppercase
    ##
    my $citation_issn = $citation->parsed('ISSN');
    $citation_issn =~ s#[\055\s]##g;                          ## remove hyphen and white space
    $citation_issn = uc($citation_issn);

    my $citation_isbn = $citation->parsed('ISBN');
    $citation_isbn =~ s#[\055\s]##g;                          ## remove hyphen and white space
    $citation_isbn = uc($citation_isbn);

    ##
    ## (01-jan-2006 kl) - can the citation isbn-13 be converted?  
    ## 
    my @citation_isbns = convert_ISBN($citation_isbn);

    my $citation_isbn_converted;

    if (scalar(@citation_isbns) == 2) {
        $citation_isbn_converted = $citation_isbns[1];
        $citation_isbn_converted =~ s#[\055\s]##g;                          ## remove hyphen and white space
	    $citation_isbn_converted = uc($citation_isbn_converted);
    }

    ##
    ## (03-jun-1999 kl) - need to add logic for some more marc title fields  (210-a, 212-a, 214-a, 222-a, 240-a, 242-ab)                     
    ##
    my %subroutines = ($MARC_ISBN_FIELD               => '_clean_isbn', 
                       $MARC_OTHER_STANDARD_ID_FIELD  => '_clean_isbn',
                       $MARC_ISSN_FIELD               => '_clean_issn', 
                       $MARC_TITLE_FIELD              => '_clean_title', 
                       $MARC_VARYING_FORM_TITLE_FIELD => '_clean_varying_form_title');
    my %clean;

    my $leader = $bib_record_object->leader;

    #### debug "good_match leader:  $leader";

    foreach my $marc_field ($MARC_ISBN_FIELD, $MARC_OTHER_STANDARD_ID_FIELD, $MARC_ISSN_FIELD, $MARC_TITLE_FIELD, $MARC_VARYING_FORM_TITLE_FIELD) {

        $clean{$marc_field} = [];

        unless (defined $subroutines{$marc_field}) { 
            debug location, ":  no subroutine defined for $marc_field";
            return ($FALSE, '');
        }

        foreach my $field ($bib_record_object->field($marc_field)) {
            no strict 'refs';
            my @cleaned_up = &{$subroutines{$marc_field}}($field, $leader);
            use strict;
            push @{$clean{$marc_field}}, @cleaned_up;
	     }
    }
                             
    #### debug "-----------------------------------";
    #### debug "from citation ... ISBN:  $citation_isbn, ISBN CONVERTED:  $citation_isbn_converted, ISSN:  $citation_issn, TITLE:  $citation_title";
    #### debug "from catalogue ..."; 
    #### debug "leader:  ", $leader; 
    #### foreach (@{$clean{$MARC_ISBN_FIELD}}, @{$clean{$MARC_OTHER_STANDARD_ID_FIELD}})   { debug "isbn:  $_"; }
    #### foreach (@{$clean{$MARC_ISSN_FIELD}})   { debug "issn:  $_"; }
    #### foreach (@{$clean{$MARC_TITLE_FIELD}})  { debug "title 245:  $_"; }
    #### foreach (@{$clean{$MARC_VARYING_FORM_TITLE_FIELD}}) { debug "title 246:  $_"; }
    #### debug  "------------------------------------";

    return ($FALSE, '') unless $self->leader_match($leader, $citation);

    ##
    ## (23-oct-2001 kl) - added logic that checks that if both a citation ISSN/ISBN and 
    ##                    at least one record ISSN/ISBN exist, then they need to match in order for the 
    ##                    record to be considered a good match
    ##  

    my @isbns = (@{$clean{$MARC_ISBN_FIELD}}, @{$clean{$MARC_OTHER_STANDARD_ID_FIELD}});

    my $num_record_isbn = scalar @isbns;
    my $num_record_issn = scalar @{$clean{$MARC_ISSN_FIELD}};

    ##
    ## (02-jan-2007 kl) - added logic for converted ISBN
    ##

    if (($citation_isbn || $citation_isbn_converted) && $num_record_isbn)   {
        
        if (grep {$citation_isbn  eq $_} (@{$clean{$MARC_ISBN_FIELD}}, @{$clean{$MARC_OTHER_STANDARD_ID_FIELD}})) {

            return ($TRUE, $MARC_ISBN_FIELD);
        }
        elsif (grep {$citation_isbn_converted  eq $_} (@{$clean{$MARC_ISBN_FIELD}}, @{$clean{$MARC_OTHER_STANDARD_ID_FIELD}})) {

            return ($TRUE, $MARC_ISBN_FIELD);
        }
        else {
            return ($FALSE, '');
        }
    }

    if ($citation_issn && $num_record_issn)   {

        if (grep {$citation_issn  eq $_} @{$clean{$MARC_ISSN_FIELD}}) {

            return ($TRUE, $MARC_ISSN_FIELD);
        }
        else {
            return ($FALSE, '');
        }
    }

    if (($citation_title) && (grep {$citation_title eq $_} @{$clean{$MARC_TITLE_FIELD}})) { 

        return ($TRUE, $MARC_TITLE_FIELD); 
    }

    if (($citation_title) && (grep {$citation_title eq $_} @{$clean{$MARC_VARYING_FORM_TITLE_FIELD}}))  { 

        return ($TRUE, $MARC_VARYING_FORM_TITLE_FIELD); 
    }

    
    return ($FALSE, '');
}

sub _clean_isbn {
    my($field, $leader) = @_;

    my @cleaned_up;
 
    foreach my $subfield ($field->subfields) {
	next unless defined $subfield;
                     
	my($code, $data) = @{$subfield};      

        if ($code eq 'a') {

            my $clean = clean_ISBN($data);

            push(@cleaned_up, uc($clean)) if $clean;
        }
    }
    return @cleaned_up;
}


sub _clean_issn {
    my($field, $leader) = @_;

    my @cleaned_up;

    foreach my $subfield ($field->subfields) {
	next unless defined $subfield;
                     
	my($code, $data) = @{$subfield};      

        ##
        ## (28-aug-2003 kl) - added logic to also use 022-z for matching, see emails from Elena Romaniuk 
        ## (26-aug-2003 kl) - added logic to also use 022-y for matching
        ##

        if ($code =~ m#^[ayz]$#) {
            my $clean = uc(clean_ISSN($data));
            $clean =~ s#[\055\s]##g;                      ## remove hyphen and whitespace

            push(@cleaned_up, $clean) unless ($clean eq '');
        }
    }
    return @cleaned_up;
}


sub _clean_title {
    my($field, $leader) = @_;

    my $title;
    my @cleaned_up;

    foreach my $subfield ($field->subfields) {
	    next unless defined $subfield;
                     
	    my($code, $data) = @{$subfield};      

        if ($code eq 'a') {
            $title =  normalize_for_catalogue_match($data, $leader);
            push(@cleaned_up, $title) unless aws($title);
        }
        elsif ($code eq 'b') {
            my $remainder = normalize_for_catalogue_match($data, $leader);

            ##
            ## -assume that 245-a, if it exists, will always come before 245-b
            ##
            if ($remainder) {
                if ($title) { push @cleaned_up, "$title $remainder"; }
                else        { push @cleaned_up, $remainder;          }
            }
        }
    }

    return @cleaned_up;
}

##
## ## variant forms of title
##

sub _clean_varying_form_title {
    my($field, $leader) = @_;

    my @cleaned_up;

    foreach my $subfield ($field->subfields) {
       next unless defined $subfield;

       my($code, $data) = @{$subfield};

       if ($code eq 'a') {
           my $title = normalize_for_catalogue_match($data, $leader);
           push(@cleaned_up, $title) unless aws($title);
       }
   }    

   return @cleaned_up;
}



sub leader_match {
    my($self, $leader, $citation) = @_;

    ##
    ## (07-may-2005 kl) - turned on for all sites but only if they have an expected leader-07 value
    ##
    ## (24-mar-2005 kl) - leader-07 limit logic for UVic as Endeavor doesn't have journal index searching via Z39.50
    ##                    
    ##                  - if works OK for UVic, turn on for all Endeavor and possibly for all sites with no
    ##                    journal index (or add as site configurable option)
    ##

    my @leader_07_for_journal = qw(s i);
    my $leader_07 = substr($leader, 7, 1);

    #### debug location_plus, "leader_07:  $leader_07";

    if (grep {$leader_07 eq $_} qw(a b c d i m s)) {
                
	    if ($citation->is_journal) {
            return $FALSE unless (grep {$leader_07 eq $_} @leader_07_for_journal);
        }
	    else {
            return $FALSE if (grep {$leader_07 eq $_} @leader_07_for_journal);
	    }		
    } 

    return $TRUE;   
}


1;

__END__


