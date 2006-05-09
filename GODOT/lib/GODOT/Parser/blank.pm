package GODOT::Parser::blank;

use GODOT::Config;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Date;
use GODOT::String;

@ISA = "GODOT::Parser";


use strict;

sub parse_citation {
	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::blank") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation);

	my $source = $citation->parsed('SOURCE');

	##---------------Customized code goes here-------------------##


        if (($citation->is_book()) || ($citation->is_book_article())) {   
           
            $citation->parsed('TITLE', $citation->pre('SO'));
            $citation->parsed('SERIES', $citation->pre('SE'));
            $citation->parsed('AUT', $citation->pre('AU'));

            $citation->parsed('PUB', $citation->pre('PUB') . '; ' . $citation->pre('PB'));    ## -fix later !!!!
            $citation->parsed('ISSN', $citation->pre('ISSN'));
            $citation->parsed('ISBN', $citation->pre('ISBN'));
            $citation->parsed('YEAR', $citation->pre('PY'));

            $citation->parsed('EDITION', $citation->pre('ED'));
        
            if ($citation->is_book_article()) {
		 $citation->parsed('ARTTIT', $citation->pre('TI'));
                 $citation->parsed('ARTAUT', $citation->pre('CA'));
                 $citation->parsed('PGS', $citation->pre('PG'));
            }
        }
        elsif ($citation->is_conference()) {

            $citation->parsed('TITLE', $citation->pre('SO'));      
            $citation->parsed('MONTH', $citation->pre('MON'));

            $citation->parsed('NOTE', $citation->pre('CT'));    

            $citation->parsed('AUT', $citation->pre('AU'));
            $citation->parsed('SERIES', $citation->pre('SE'));

            $citation->parsed('ISSN', $citation->pre('ISSN'));
            $citation->parsed('ISBN', $citation->pre('ISBN'));
            $citation->parsed('YEAR', $citation->pre('PY'));

            $citation->parsed('PUB', $citation->pre('PUB') . '; ' . $citation->pre('PB'));    ## -fix later !!!!

	    $citation->parsed('ARTTIT', $citation->pre('TI'));
            $citation->parsed('ARTAUT', $citation->pre('CA'));
            $citation->parsed('PGS', $citation->pre('PG'));
        }
        elsif ($citation->is_journal()) {       
        
            $citation->parsed('TITLE', $citation->pre('SO'));

            $citation->parsed('YEAR', $citation->pre('PY'));
            $citation->parsed('ISSN', $citation->pre('ISSN'));
            $citation->parsed('ISBN', $citation->pre('ISBN'));
            $citation->parsed('SERIES', $citation->pre('SE'));

            $citation->parsed('PUB', $citation->pre('PUB') . '; ' . $citation->pre('PB'));    ## -fix later !!!!

        }
        elsif ($citation->is_tech())  {
            
            $citation->parsed('TITLE', $citation->pre('SO'));
            $citation->parsed('AUT', $citation->pre('AU'));
            $citation->parsed('REPNO', $citation->pre('NU'));    
            $citation->parsed('MONTH', $citation->pre('MON'));

            $citation->parsed('YEAR', $citation->pre('PY'));
            $citation->parsed('ISSN', $citation->pre('ISSN'));
            $citation->parsed('ISBN', $citation->pre('ISBN'));
            $citation->parsed('SERIES', $citation->pre('SE'));

            $citation->parsed('PUB', $citation->pre('PUB') . '; ' . $citation->pre('PB'));    ## -fix later !!!!        
        }
        elsif ($citation->is_thesis()) {   
            
            $citation->parsed('TITLE', $citation->pre('SO'));
            $citation->parsed('AUT', $citation->pre('AU'));
            $citation->parsed('MONTH', $citation->pre('MON'));

            $citation->parsed('YEAR', $citation->pre('PY'));
            $citation->parsed('ISSN', $citation->pre('ISSN'));
            $citation->parsed('ISBN', $citation->pre('ISBN'));

            $citation->parsed('UMI_DISS_NO', $citation->pre('ON'));    

            $citation->parsed('THESIS_TYPE', $citation->pre('LV'));    

            if ($citation->parsed('THESIS_TYPE') =~ m#other#i) {
                $citation->parsed('THESIS_TYPE', $citation->pre('RT'));    
            } 

            $citation->parsed('PUB', $citation->pre('PUB') . '; ' . $citation->pre('PB'));    ## -fix later !!!!        
        
        }


        my $note = $citation->parsed('NOTE');
        if (naws($note)) {  $note .= '; ';  }
        $note .= $citation->pre('NT'); 
        $citation->parsed('NOTE', $note);


	##---------------Customized code ends here-------------------##

	return $citation;
}

sub get_req_type {
        my ($self, $citation) = @_;
        debug("get_req_type() in GODOT::Parser::blank") if $GODOT::Config::TRACE_CALLS;

	my $reqtype = $self->SUPER::get_req_type($citation); 

	##---------------Customized code goes here-------------------##

        $reqtype = uc($citation->parsed('PUBTYPE'));

        ##
        ## -if book and have chapter title, chapter author or pages
        ##
        if ($reqtype eq $GODOT::Constants::BOOK_TYPE)  {
            if ($citation->pre('TI') || $citation->pre('CA') || $citation->pre('PG')) {
                $reqtype = $GODOT::Constants::BOOK_ARTICLE_TYPE;
            }
        }
    
	##---------------Customized code ends here-------------------##

	return $reqtype;
}


1;

__END__

