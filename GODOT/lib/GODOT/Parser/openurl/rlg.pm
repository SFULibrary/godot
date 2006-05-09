package GODOT::Parser::openurl::rlg;

use GODOT::Config;
use GODOT::String;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Parser::openurl;
use CGI qw/unescapeHTML/;

@ISA = "GODOT::Parser::openurl";

use strict;

sub pre_parse {
    my ($self, $citation) = @_;
    debug("pre_parse() in GODOT::Parser::openurl::rlg") if $GODOT::Config::TRACE_CALLS;

    if (($citation->pre('genre') eq $GODOT::Config::ARTICLE_GENRE) && 
        (! $citation->pre('ISSN')) &&
        ($citation->pre('ISBN'))) {

        ## 
        ## (15-jan-2003 kl)
        ##
        ## -to improve problem in RLG system where articles in books were being given a genre of 'article' 
        ##  instead of 'bookitem'
        ##
        ## -see 15-jan-2003 email from Walt Crawford 
        ## 

        $citation->pre('genre', $GODOT::Config::BOOKITEM_GENRE);
    }
}


sub parse_citation {

	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::openurl::rlg") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation); 

        ## 
        ## pid=id={record id}[:aloc={aloc value}]
        ##

        if (($citation->pre('pid') =~ m#id=(.+):#) || ($citation->pre('pid') =~ m#id=(.+)#)) {

	    $citation->parsed('SYSID', $1);
        }
        

}

1;

__END__

