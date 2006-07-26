## GODOT::Database
##
## Copyright (c) 2001, Todd Holbrook, Simon Fraser University
##
## Carries the information that GODOT knows about a specific database.  This
## usually works in conjunction with GODOT::Citation to provide enough information
## to the parsers to do their work.

package GODOT::Database;


use GODOT::Constants;
use GODOT::Config;
use GODOT::Debug;
use GODOT::String;

use GODOT::Object;
@ISA = qw(GODOT::Object);

use GODOT::Database::Config;

use strict;

my @FIELDS = ('dbase',
              'dbase_local',
              'dbase_type',
              'dbase_syntax',
              'dbase_fullname',
              'brs_database',
              'iii_database');


my @INCLUDE_PATH = ([qw(local dbase)],
                    [qw(global dbase)]);

sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}

# Gets/sets the BRS database flag.
sub is_brs_database {
	my ($self, $set) = @_;
	$self->{'brs_database'} = ($set ? 1 : 0) if defined($set);
	return $self->{'brs_database'} == 1;
}

# Gets/sets the III database flag.
sub is_iii_database {
	my ($self, $set) = @_;
	$self->{'iii_database'} = ($set ? 1 : 0) if defined($set);
	return $self->{'iii_database'} == 1;
}

sub dbase {
	my ($self, $set) = @_;

        if (defined $set) { $self->{'dbase'} = $set; }
        return $self->{'dbase'};
}

sub dbase_local {
	my ($self, $set) = @_;
	$self->{'dbase_local'} = $set if defined($set);
	return $self->{'dbase_local'};
}

sub dbase_type {
	my ($self, $set) = @_;
	$self->{'dbase_type'} = $set if defined($set);
	return $self->{'dbase_type'};
}

sub dbase_syntax {
	my ($self, $set) = @_;
	$self->{'dbase_syntax'} = $set if defined($set);
	return $self->{'dbase_syntax'};
}

sub dbase_fullname {
	my ($self, $set) = @_;
	$self->{'dbase_fullname'} = $set if defined($set);
	return $self->{'dbase_fullname'};
}

##
## -a number of 'item' databases are both a database from which you would link to godot
##  and a source of holdings for godot (ex. ecdb, ubc, csti)
##
## -shows the relationship between the names used in the parsing
##  logic for these databases and the names used when they are accessed as sources
##
sub source {
        my($self) = @_;

        return $GODOT::Database::Config::DBASE_SOURCE_MAPPING{$self->dbase};
}


## -mapping that shows the locations that are contained in item databases
##  so that godot can decide when to use the '$SAME_AS_DBASE_[MONO|JOURNAL]_SOURCE_TYPE' line 
##  in '%SOURCE_HASH'

sub source_sites { 
        my ($self) = @_;

        if (defined $GODOT::Database::Config::DBASE_SOURCE_SITES_MAPPING{$self->dbase}) {
            return @{$GODOT::Database::Config::DBASE_SOURCE_SITES_MAPPING{$self->dbase}};
        }
        elsif (defined $GODOT::Database::Config::DBASE_SOURCE_MAPPING{$self->dbase}) {
            return ($GODOT::Database::Config::DBASE_SOURCE_MAPPING{$self->dbase});
        }

        return (); 
}

sub init_from_params {
	my ($self) = @_;

	require CGI;
	
	# Grab a few extra parameters that are useful for handling the request
	$self->dbase(CGI::param('hold_tab_dbase'));
	$self->dbase_type(CGI::param('hold_tab_dbase_type'));
	$self->dbase_local(CGI::param('hold_tab_dbase_local'));
	
	return $self;
}

sub init_dbase {
	require openurl;

	my ($self, $param_names_ref, $hold_tab_syntax, $db_type, $db_local, $db_type_abbrev, $db_local_abbrev) = @_;
	my ($syntax, $unknown_param, $param_name);

	if ($hold_tab_syntax) {
	    $self->dbase_syntax($hold_tab_syntax);
            
            ##
            ## (06-feb-2002 kl) 
            ##

            $self->dbase_type($db_type);
            $self->dbase_local($db_local);
	} else {
            ##
	    ## Check whether it's original syntax.
            ##
	    foreach $param_name (@$param_names_ref) { 
	    	next if $param_name eq 'hold_tab_branch';  # TH - Allow for hold_tab_branch to be used with OpenURLs for now
	    	next if $param_name eq 'hold_tab_back_url';  # TH - Allow for hold_tab_back_url to be used with OpenURLs for now
		if (($param_name =~ m#^SP\.#) || ($param_name =~ m#^DEFAULT\.SP\.#)) { ## -ignore fields from Webspirs
		    next; 
		}       
		if ($param_name =~ m#$GODOT::Constants::HOLD_TAB_PREFIX#) { 

		    $self->dbase_syntax($GODOT::Constants::ORIG_SYNTAX);
		    $self->dbase_type($db_type);
		    $self->dbase_local($db_local);
		    last;
		}
	    }

            ##
	    ## Check whether it's openurl syntax.
            ##
	    if (!defined($self->dbase_syntax())) {
		my $fuzzy_value = 0;

		foreach $param_name (@$param_names_ref) {
			$fuzzy_value += &openurl::openurl_is_field($param_name)
		}                

		if ($fuzzy_value > 0)  {
			$self->dbase_syntax($GODOT::Constants::OPENURL_SYNTAX);
			$self->dbase_type(&openurl::openurl_dbase_type());
			$self->dbase_local(&openurl::openurl_dbase_local());
		} else {
			$syntax = '';
		}
	    }


            ##
            ## (14-feb-2006 kl) - check whether its OpenURL version 1.0
            ##

		if (!defined($self->dbase_syntax())) {
		    foreach $param_name (@$param_names_ref) {
			if ($param_name eq 'url_ver') {
			    $self->dbase_syntax($GODOT::Constants::OPENURL_SYNTAX);

                            my $type = &openurl::openurl_dbase_type();
                            my $local = &openurl::openurl_dbase_local();
                        
                            #### debug "..............", CGI::param('rfr_id'), "....................";

                            if (CGI::param('rfr_id') =~ m#www\.isinet\.com#) {
                                $type = 'ISI';
                                my @arr = split(':', CGI::param('rfr_id'));
                                $local = $arr[2];
                            }
                                                        
			    $self->dbase_type($type);
			    $self->dbase_local($local);
			    last;
			}
		    }
		}


            ##
	    ## Check whether it's ebscohost syntax
            ##
	    if (!defined($self->dbase_syntax())) {
		foreach $param_name (@$param_names_ref) {
		    if (grep {$param_name eq $_} @GODOT::Constants::ABBREV_SYNTAX_FIELDS_ARR)  { 
			$syntax = $GODOT::Constants::ABBREV_SYNTAX; 
		    } else { 
			$unknown_param = $param_name;      
			$syntax = '';   
			last;  
		    }
		}
		if ($syntax)  { ## Is abbre syntax.
		    $self->dbase_syntax($syntax);
		    $self->dbase_type($db_type_abbrev);
		    $self->dbase_local($db_local_abbrev);
		}
	    }
	}

	#### debug "---------------------------------------------";
	#### debug "syntax:  ", $self->dbase_syntax;
	#### debug "type:  ", $self->dbase_type;
	#### debug "local:  ", $self->dbase_local;
	#### debug "---------------------------------------------";

	if (defined($self->dbase_syntax())) { ## Succeed
	    return $TRUE;
	} else { ## Failed
	    return $FALSE;
	}
}

#### sub check_dbase {
####	my($self, $dbase, $message_ref, $self_ref) = @_;
####
####        $self->_check_dbase($dbase, $message_ref);
####        $self->_change_class($self_ref);
#### }

sub check_dbase {
	my($self, $dbase, $message_ref) = @_;
	my($key, $tmpstr);

	if (grep {$dbase eq $_} @GODOT::Config::DBASE_ARR) {
	    $self->dbase($dbase);
	    $self->dbase_fullname($GODOT::Config::DBASE_INFO_HASH{$dbase}->{'fullname'});
	    return $TRUE;
	}

	if (GODOT::String::aws($self->dbase_local()) || GODOT::String::aws($self->dbase_type())) {
	    ${$message_ref} = "Fields $GODOT::Constants::DBASE_LOCAL_FIELD and/or " . 
		"$GODOT::Constants::DBASE_TYPE_FIELD were empty.";
	    return $FALSE;
	}

        ##
	## Both dbase_local and dbase_type have value.
        ##

	if (!(grep {$self->dbase_type() eq $_} @GODOT::Constants::DBASE_TYPE_ARR)) {
	    ${$message_ref} = "Field $GODOT::Constants::DBASE_TYPE_FIELD (" . $self->dbase_type() . ") was invalid.";  
	    return $FALSE;
	}
       
	##
	## determine %DBASE_LOCAL_HASH key, ex. 'erl.BI'
	##
	$tmpstr = $self->dbase_local();

	if ($self->dbase_type() eq 'erl')  {
	    if ($tmpstr =~ m#^I\((.+)\).+$#)  {    ## ex. I(CCON0005) 
		#### $tmpstr = substr($1, 0, 2);            
		$tmpstr = $1;            
	    }
	    else {
		${$message_ref} = "Field $GODOT::Constants::DBASE_LOCAL_FIELD was not in expected format $tmpstr.";
		return $FALSE;                   
	    }
	}   

	$key = $self->dbase_type() . '.' . $tmpstr;    

        ##
        ## (21-jan-2003 kl) - added some special logic for ERL as codes vary in length
        ##

        if ($self->dbase_type() eq 'erl') {

            sub by_length_descending { length($b) <=> length($a); }
    
            my @erl_codes = grep /^erl\./, (keys %GODOT::Config::DBASE_LOCAL_MAPPING);

            foreach my $erl_code (sort by_length_descending @erl_codes) {

                if ($key =~ m#^$erl_code#) { 
                    $self->dbase($GODOT::Config::DBASE_LOCAL_MAPPING{$erl_code}); 
                    last;
                } 
            }
        }
	elsif (defined($GODOT::Config::DBASE_LOCAL_MAPPING{$key}))   {
	    $self->dbase($GODOT::Config::DBASE_LOCAL_MAPPING{$key});
	}
        ##
        ## (24-jul-2006 kl) - added so that we do not need to maintain a list of all ebscohost databases,
        ##                    only those that require special parsing logic 
        ##
        elsif ($self->dbase_type() eq 'ebscohost') {
            my $dbase_local = $self->dbase_local();
            $dbase_local =~ s#\s+#-#g;
            $self->dbase($self->dbase_type() . ':' . $dbase_local);            
        }
        ##
        ## (06-feb-2002 kl) - added so that we do not need to add a list of all databases that contain openurl links
        ##
        elsif ($self->dbase_syntax() eq $GODOT::Constants::OPENURL_SYNTAX) {
            $self->dbase($self->dbase_type() . ':' . $self->dbase_local());
        }
	else {
	    ${$message_ref} = "No database defined for $key.";
	    return $FALSE;
	}



	if (grep {$self->dbase() eq $_} @GODOT::Config::DBASE_ARR) {
	    $self->dbase_fullname($GODOT::Config::DBASE_INFO_HASH{$self->dbase()}->{'fullname'});
	    return $TRUE;
	}

        ##
        ## (24-jul-2006 kl) - see comment above from same date
        ##
        elsif ($self->dbase_type() eq 'ebscohost') {
            $self->dbase_fullname('Ebscohost ' . $self->dbase_local());            
            return $TRUE;
        }
        ##
        ## (06-feb-2002 kl) - just use dbase name for fullname - also see above 
        ##
        elsif ($self->dbase_syntax() eq $GODOT::Constants::OPENURL_SYNTAX) {
	    $self->dbase_fullname('OpenURL ' . $self->dbase());                          
            return $TRUE;
        }


	##
	## !!!!!! if you change this message make the corresponding change to hold_tab.pm  !!!!!!
	## !!!!!! -search for 'does not currently work with database'
	##

	${$message_ref} = "This program ($GODOT::Constants::PROG_NAME) does not currently work with database " .
			  $self->dbase() . ".";
	return $FALSE;       
}


sub no_back_to_database {
    my($self) = @_;

    if (grep {$self->dbase() eq $_} @GODOT::Config::NO_BACK_TO_DATABASE_DBASE_ARR)           { return $TRUE; }
    if (grep {$self->dbase_type() eq $_} @GODOT::Config::NO_BACK_TO_DATABASE_DBASE_TYPE_ARR) { return $TRUE; }

    return $FALSE;
}

sub is_blank_dbase {
    my($self) = @_;
    return ($self->dbase() eq 'blank');
}

sub is_item_dbase {
    my($self) = @_;
    if (grep {$self->dbase() eq $_} @GODOT::Constants::ITEM_DB_ARR) { return $TRUE; }
    else { return $FALSE; }     
}

sub is_openurl_dbase {
    my($self) = @_;
    if (grep {$self->dbase() eq $_} @GODOT::Constants::OPENURL_DB_ARR) { return $TRUE;  }
    else { return $FALSE; }  
}

sub dump {
	my($self) = @_;
	my $key;
	foreach $key (keys %{$self}){
	    print STDERR "$key => " . $self->{$key} . "\n";
	}
}

1;

__END__

=head1 NAME

GODOT::Database - Database object for the GODOT system

=head1 METHODS

=head2 ACCESSOR METHODS

=over 4

=item dbase([$value])

=item dbase_type([$value])

=item dbase_local([$value])

=item dbase_syntax([$value])

=item dbase_fullname([$value])

Accessor methods for retrieving or setting the different fields of
the Database object.

=item S<init_dbase($param_names_ref, $hold_tab_syntax, $type, $local, $type_abbrev, $local_abbrev)>

Based on C<param()> names, init_dbase decides the dbase_syntax, dbase_local, and 
dbase_type fields of the calling Database object. It should be used in 
place of the old C<syntax()> function and the code segment in hold_tab.cgi 
which decides the values of C<param($hold_tab::DBASE_TYPE_FIELD)> and 
C<param($hold_tab::DBASE_LOCAL_FIELD)>. init_dbase returns nonzero if it can
decide dbase_syntax, otherwise returns zero.

I<$param_names_ref> is a reference to the name list returned from 
C<param()>.

I<$hold_tab_syntax> = C<param($hold_tab::SYNTAX_FIELD)>

I<$type> = C<param($hold_tab::DBASE_TYPE_FIELD)>

I<$local> = C<param($hold_tab::DBASE_LOCAL_FIELD)>

I<$type_abbrev> = C<param($hold_tab::DBASE_TYPE_ABBREV_FIELD)>

I<$local_abbrev> = C<param($hold_tab::DBASE_LOCAL_ABBREV_FIELD)>

=item check_dbase($dbase, $message_ref)

B<Precondition:> C<init_dbase()> has been called.

C<check_dbase()> is very similar to the old C<parse::check_dbase()> function.
It 1) returns nonzero if I<$dbase> contains a valid database name; 2)returns  
nonzero if after evaluating contents of dbase_local and dbase_type of the calling 
Database object, the database name can be determined; 3)OTHERWISE ... assigns
message to I<$message_ref> and returns zero. 

I<$dbase> gets its value from the first element returned from C<param($hold_tab::DBASE_FIELD)>

I<$message_ref> is a reference to a piece of allocated memory.

=item no_back_to_database()

Should a link be provided to to back to the database interface from a GODOT screen? Returns
true if no link should be provided.

=item is_blank_dbase()

=item is_item_dbase()

=item is_openurl_dbase()

Function C<is_???_dbase()> returns nonzero if the calling Database object is
??? database, otherwise it returns zero. 

=back

=head1 DATA LAYOUT

Please try to use accessor methods for data whenever they are available.  In
typical Perl style, I wont stop you from modifying the data directly, but
you're bypassing some protection.

=over 4

=item dbase - SCALAR

Contains the database the citation came from in its raw form - not mapped
to an internal database string.

=item dbase_local - SCALAR

The extra database localization string, used mostly for EBSCO.  For example,
dbase might be 'ebsco' while dbase_local is 'Proquest'.

=item dbase_type - SCALAR

The type of database, i.e. ERL, BRS, etc.

=item dbase_syntax - SCALAR

The syntax of the database the citation came from: original syntax,
openurl syntax, or abbreviated syntax.

=item dbase_fullname - SCALAR

The full name of the database. E.g., "Academic Search FullTEXT Elite".

=back

=head1 AUTHORS / ACKNOWLEDGMENTS

Written by Todd Holbrook, based on existing GODOT code by Kristina Long and
others over the years at SFU.

=cut
