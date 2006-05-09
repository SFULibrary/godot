package GODOT::Parser::curcon;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;
use GODOT::String;

@ISA = "GODOT::Parser";


use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::curcon") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##

        if ($citation->is_journal())  {

            my $dotv = index($source,".");
            my $semiv = index($source,";",$dotv);    
            my $colonv = index($source,":",$semiv);

            $citation->parsed('TITLE', trim_beg_end(substr($source,0,$dotv)));
            $citation->parsed('MONTH', trim_beg_end(substr($source,$dotv + 1,$semiv - ($dotv + 1)))); 
            $citation->parsed('VOLISS', trim_beg_end(substr($source, $semiv + 1,$colonv - ($semiv + 1))));
            
            $citation->parsed('PGS', trim_beg_end(substr($source, $colonv + 1, length($source) - ($colonv - 1)))); 

            ##
            ## ex. 33 ( Pt 1)  
            ##     19(210)
            ##
            if ($citation->parsed('VOLISS') =~ m#([\055\d]+)\s*\(([\s\w\055]+)\)#)  {
     
                $citation->parsed('VOL', $1);
                $citation->parsed('ISS', $2);
            }

            my $title = $citation->parsed('TITLE');
            $title =~ s/([^\-])-([^\-])/$1 $2/g;    # Get rid of -s   
            $citation->parsed('TITLE', $title);
        }

	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::curcon") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

