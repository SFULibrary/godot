package GODOT::Parser::openurl::csa;

use GODOT::Config;
use GODOT::String;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Parser::openurl;
use CGI qw/unescapeHTML/;

@ISA = "GODOT::Parser::openurl";

use strict;


sub parse_citation {

	my ($self, $citation) = @_;
	debug("parse_citation() in GODOT::Parser::openurl::csa") if $GODOT::Config::TRACE_CALLS;

	$self->SUPER::parse_citation($citation); 

        my($pub, $pub_place, $conf_title);

        ##
        ## (22-jan-2002 kl) - ampersands in text are not escaped such that they can be differentiated 
        ##                    from ampersands separating fields - need to email CSA
        ##   
        ## pid format:
        ##
        ##    <AN>33:11092</AN>&<PB>Thames & Hudson, distributed by Hansjorg Mayer</PB>&<AU>Glozer, Laszlo ; Dobke, Dirk</AU>
        ##
  
        ##
        ## -use question mark after quantifier for minimal matching (ie. '.+?')
        ##

        foreach my $item  ($citation->pre('pid') =~ m#<[A-Z]+>.+?</[A-Z]+>#g ) {

            if     ($item =~ m#^<AN>(.+)</AN>$#) { 

                $citation->parsed('SYSID', $1); 
            }
            elsif  ($item =~ m#^<PB>\s*(.+)\s*</PB>$#) { 
            
		$pub = $1;
            }
            elsif  ($item =~ m#^<PL>\s*(.+)\s*</PL>$#) { 

		$pub_place = $1;
            }
            elsif  ($item =~ m#^<SR>(.+)</SR>$#) { 

		$citation->parsed('SERIES', $1);
            }
            elsif  ($item =~ m#^<CT>\s*(.+)\s*</CT>$#) { 

		$conf_title = $1;
            }
            elsif  ($item =~ m#^<RP>(.+)</RP>$#) { 

		$citation->parsed('REPNO', $1);
            }
            elsif  ($item =~ m#^<AU>(.+)</AU>$#) { 
                ##
                ## (19-mar-2009 kl) -- we want complete author statement for importing into citation managers such as refworks so
                ##                     use this author statement if it is longer than the currently extracted one 
                ##
		my $author_stmt = $1;

                if (grep {$citation->pre('genre') eq $_} @GODOT::Config::INDIVIDUAL_ITEM_GENRE_ARR)  { 
	            $citation->parsed('ARTAUT', $author_stmt) if length($author_stmt) > length($citation->parsed('ARTAUT')); 
	        }
	        else { 
	            $citation->parsed('AUT', $author_stmt) if length($author_stmt) > length($citation->parsed('AUT')); 
	        }  
            }
        }

        ##
        ## (19-mar-2009 kl) -- now that we have a GODOT::Citation object field for PUB_PLACE no need to put in PUB field
        ##
        #### my $pub_stmt = $pub . (($pub && $pub_place) ? ', ' : '') . $pub_place;
        #### if ($pub_stmt) { $citation->parsed('PUB', $pub_stmt); }            

        $citation->parsed('PUB', $pub);
        $citation->parsed('PUB_PLACE', $pub_place);

        if (($conf_title)  && (! $citation->parsed('TITLE'))) {   $citation->parsed('TITLE', $conf_title); }  
}

1;

__END__

