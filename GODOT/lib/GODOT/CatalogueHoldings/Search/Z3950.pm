##
## Copyright (c) 2003, Kristina Long, Simon Fraser University
##

package GODOT::CatalogueHoldings::Search::Z3950;

use GODOT::CatalogueHoldings::Search;
push @ISA, qw(GODOT::CatalogueHoldings::Search);

use GODOT::CatalogueHoldings::Record::Z3950;

use GODOT::Object;
use GODOT::Debug;
use Net::Z3950;

use GODOT::String;

@EXPORT = qw($SYSID_USE_ATTRIB $ISBN_USE_ATTRIB $ISSN_USE_ATTRIB $TITLE_USE_ATTRIB $JOURNAL_TITLE_USE_ATTRIB);

use strict;

use vars qw($SYSID_USE_ATTRIB $ISBN_USE_ATTRIB $ISSN_USE_ATTRIB $TITLE_USE_ATTRIB $JOURNAL_TITLE_USE_ATTRIB);

$SYSID_USE_ATTRIB         = 12;
$ISBN_USE_ATTRIB          = 7;
$ISSN_USE_ATTRIB          = 8;
$TITLE_USE_ATTRIB         = 4;
$JOURNAL_TITLE_USE_ATTRIB = 33;

my @SYNTAXES = qw(OPAC USMARC);

my $DEFAULT_SYNTAX = 'USMARC';

##
## -on failure returns undef and sets '_error_message' appropriately
##
sub search_no_timeout {
    my($self, $system, $condition, $max_hits) = @_;

    #### debug "///////////////////";
    #### debug $system->dump;
    #### debug "///////////////////";
    
    ##
    ## -Net::Z3950 Connection is picky about leading or trailing whitespace 
    ##

    my $host     = &GODOT::String::trim_beg_end($system->Host);
    my $database = &GODOT::String::trim_beg_end($system->Database); 
    my $port     = &GODOT::String::trim_beg_end($system->Port);


    if (! $host || ! $database) { 
        $self->{'_error_message'} = 'Host not specified.' if (! $host);
        $self->{'_error_message'} = 'Database name not specified.' if (! $database);
        return undef;
    }

    if (! grep {$condition eq $_} @GODOT::CatalogueHoldings::Search::CONDITIONS) {

        $self->{'_error_message'} = ($condition) ? 'Unexpected search condition (' . $condition . ').'
                                                 : 'Search condition required.';
        return undef;
    }

    my $syntax_name = $self->syntax;

    if (! grep {$syntax_name eq $_} @SYNTAXES) {

        $self->{'_error_message'} = "Unexpected Z39.50 record syntax specified ($syntax_name)."; 
        return undef;
    } 

    no strict 'refs';
    my $syntax_res = &{'Net::Z3950::RecordSyntax::' . $syntax_name};
    use strict 'refs';

    ##
    ## -make the connection
    ##

    debug ">>>> ", join('--', $host, $port, $database, $syntax_res);

    my $conn = new Net::Z3950::Connection($host,
                                          $port,
                                          databaseName => $database,    		   		          
    		   		          preferredRecordSyntax => $syntax_res, 
                                         );                       

    if (! $conn) {

        $self->{'_error_message'} = "Unable to connect to host ($host).";
        return undef;
    }

    ##
    ## -for each search term, determine the search command and then do the search 
    ##

    my $total_hits;

    my %rec_hash;

    foreach my $term ($self->all_terms_ranked) {

        my $cmd = $term->prefix_syntax($system);
        
        debug location, " >>>> $database/$host:$port cmd <<<<:  $cmd";

        $self->{'_error_message'} = '';            ## -initialize error message in case last search failed

        my $rs;

        if (! ($rs = $conn->search($cmd))) { 

            $self->{'_error_message'} = "search failed:  " . $conn->errmsg();

            ## (12-mar-2005 kl) - if search fails don't return -- try other searches instead.
            #### return undef;

            next;
        } 
        
        $rs->option(elementSetName => $self->element_set); 

        ##
        ## -condition logic
        ## 
   
        my $get_records = $FALSE; 
        my $done = $FALSE;

        if ((($condition eq $EXACTLY_ONE) && ($rs->size == 1)) || 
            (($condition eq $AT_LEAST_ONE) && ($rs->size >= 1))) {

            $done = $TRUE;
            $get_records = $TRUE;
            push(@{$self->{'_successful_terms'}}, $term);
        }
        elsif (($condition eq $ALL_AVAIL) && ($rs->size >= 1)) {

            $get_records = $TRUE;
            push(@{$self->{'_successful_terms'}}, $term);
        }

        $total_hits += $rs->size;

        
        ##
        ## -check for too many hits in total
        ##
        if ($total_hits > $max_hits)  {

            $conn->close();

            $self->{'_docs'} = $total_hits;
            $self->{'_error_message'} = "Too many hits to process ($total_hits).";

            return undef;
        }

        my $n = $rs->size();

        for (my $i = 0; $i < $n; $i++) {

	    my $rec = $rs->record($i+1);

	    if (!defined $rec) {

                 #### debug "Record ", $i+1,  ", error ", $rs->errcode(),  " (",  $rs->errmsg(), "): ", $rs->addinfo(), "\n";
	    }
	    else {

                ##
                ## -deduping logic       
                ##

                my $key = &key($rec);

                if (! defined $rec_hash{$key}) {

                    $self->{'_docs'}++;
               
                    my $record = GODOT::CatalogueHoldings::Record->dispatch({'site'   => $system->Site, 
                                                                             'system' => $system->Type});                    
        
                    if (! $record) {
                        $self->{'_error_message'} = "Unable to dispatch GODOT::CatalogueHoldings::Record.";
                        return undef;
                    }

                    $record->record($rec);                                        

	            push(@{$self->{'_records'}}, $record);

		    $rec_hash{$key} = $TRUE;
	        }
	    }
        }


        if ($done) { last; }              ## break out of search term loop 
    }

    $conn->close();

    return $TRUE;
}

sub key {
    my($rec) = @_;

    ##
    ## -dedup based on bibliographic, holdings and circulation information
    ## 

    unless (defined $rec) { return ''; }

    my $string = $rec->render;    
    $string =~ s#\n# #g;

    return $string;
}


sub syntax {
    return $DEFAULT_SYNTAX;
}

sub element_set {
    return 'F';
}


1;

__END__


