## GODOT::Citation
##
## Copyright (c) 2001, Todd Holbrook, Simon Fraser University
##
## Carries the citation from a database in both its pre-parsed and parsed 
## formats.  It may include some methods for manipulation, but right now
## it's mostly for carrying data around.

package GODOT::Citation;

use GODOT::Object;
push @ISA, 'GODOT::Object';

use GODOT::Constants;
use GODOT::Config;
use GODOT::Debug;
use GODOT::String;

use GODOT::Database;

use Text::Striphigh 'striphigh';
use URI::Escape;

use strict;


# Field list of hold_tab params and what they map to internally

use vars qw(
	%HOLD_TAB_PARAM_MAPPINGS
	%CITATION_MAPPINGS

	@PRE_FIELDS
	@PARSED_FIELDS
);

##
## (15-feb-2006 kl) - 'rft.*' added for OpenURL v1.0
##
%HOLD_TAB_PARAM_MAPPINGS = (
	'PN'   => 'hold_tab_pn',
	'PD'   => 'hold_tab_pd',
	'PU'   => 'hold_tab_pu',
	'CY'   => 'hold_tab_cy',

	'PT'   => 'hold_tab_pt',
	'DT'   => 'hold_tab_dt',
	'TI'   => ['hold_tab_ti', 'ti', 'title', 'rft.title', 'rft.jtitle'],
	'PB'   => ['hold_tab_pb', 'p'],
	'CT'   => 'hold_tab_ct',

        'ST'   => 'hold_tab_st',

	'CA'   => ['hold_tab_ca', 'ca'],
	'AU'   => ['hold_tab_au', 'rft.au'],
	'PY'   => 'hold_tab_py',
	'AD'   => 'hold_tab_ad',

	'IS'   => 'hold_tab_is',
	'SN'   => 'hold_tab_sn',
	'ISSN' => ['hold_tab_issn', 'issn', 'rft.issn'],
	'ISBN' => ['hold_tab_isbn', 'isbn', 'rft.isbn'],
	'SICI' => ['hold_tab_sici', 'sici', 'rft.sici'], 
	'NU'   => 'hold_tab_nu',	

	'IB'   => 'hold_tab_ib',
	'BN'   => 'hold_tab_bn',

	'SO'   => ['hold_tab_so', 'so'],
	'SE'   => 'hold_tab_se',

	'JN'   => 'hold_tab_jn',
	'AS'   => 'hold_tab_as',
  
	'RT'   => 'hold_tab_rt',
	'PG'   => ['hold_tab_pg', 'pg', 'pages', 'rft.pages'],
	'AV'   => 'hold_tab_av',

	'VOL'  => ['hold_tab_vol', 'vol', 'volume', 'rft.volume'],
	'ISS'  => ['hold_tab_iss', 'iss', 'issue', 'rft.issue'],
	'MON'  => ['hold_tab_mon', 'mon'],
	'PUB'  => 'hold_tab_pub',

	'AN'   => 'hold_tab_an',
	'LV'   => 'hold_tab_lv',

	'NT'   => 'hold_tab_nt',
	'CP'   => 'hold_tab_cp',
	'CS'   => 'hold_tab_cs',

	'ON'   => 'hold_tab_on',
	'MN'   => 'hold_tab_mn',            ## Microlog number (ex. 96-04469) - CRI database
	'SID'  => ['hold_tab_sid', 'sid'],  ## System ID (DRA database ctrl num)
	'UR'   => 'hold_tab_ur',            ## URL in record - may be to fulltext
	'ED'   => 'hold_tab_ed',
	'FT'   => ['hold_tab_ft', 'ft'],

	'BK'   => 'hold_tab_bk',
	'BA'   => 'hold_tab_ba',
	'BL'   => 'hold_tab_bl',
	'BY'   => 'hold_tab_by',

	'CN'   => 'hold_tab_cn',
	'DI'   => 'hold_tab_di', 
	'DG'   => 'hold_tab_dg', 

	'NN'   => 'hold_tab_nn',
	'RN'   => 'hold_tab_rn',

	'HC'   => 'hold_tab_hc',       ## For SocWork
	'DA'   => 'hold_tab_da',       ## For SocWork
    
	'FA'   => 'hold_tab_fa',       ## CBCA FT Education
	'JT'   => 'hold_tab_jt',       ## CWI
	'DL'   => 'hold_tab_dl',       ## ERIC document link field

        't'    => 't',                 ## Ebscohost - HTML Full Text available 
        'p'    => 'p',                 ## Ebscohost - PDF Full Text available


	'T000' => 'hold_tab_t000',     ## MARC leader
	'T001' => 'hold_tab_t001',     ## MARC 001
	'T008' => 'hold_tab_t008',     ## MARC 008 (Fixed Length Data Elements)   
	'T020' => 'hold_tab_t020',
	'T022' => 'hold_tab_t022',     
	'T027' => 'hold_tab_t027',     
	'T035' => 'hold_tab_t035',
	'T090' => 'hold_tab_t090',     
	'T099' => 'hold_tab_t099',     
	'T100' => 'hold_tab_t100', 
	'T110' => 'hold_tab_t110', 
	'T111' => 'hold_tab_t111', 
	'T245' => 'hold_tab_t245', 
	'T250' => 'hold_tab_t250', 
	'T260' => 'hold_tab_t260', 
	'T440' => 'hold_tab_t440', 
	'T700' => 'hold_tab_t700', 
	'T773' => 'hold_tab_t773', 
	'T775' => 'hold_tab_t775', 
	'T800' => 'hold_tab_t800',
	'T852' => 'hold_tab_t852',
	'T856' => 'hold_tab_t856', 
	'T907' => 'hold_tab_t907', 
	'T920' => 'hold_tab_t920',
	'T926' => 'hold_tab_t926',
	'T979' => 'hold_tab_t979',
	'T984' => 'hold_tab_t984',
	'T988' => 'hold_tab_t988',
	'T992' => 'hold_tab_t992',

	'id' => 'id',
	'pid' => 'pid',
	'genre' => ['genre', 'rft.genre'],
	'aulast' => ['aulast', 'rft.aulast'],
	'aufirst' => ['aufirst', 'rft.aufirst'],
	'auinit' => ['auinit', 'rft.auinit'],
	'auinit1' => ['auinit1', 'rft.auinit1'],
	'auinitm' => ['auinitm', 'rft.auinitm'],
	'eissn' => ['eissn', 'rft.eissn'],
	'coden' => ['coden', 'rft.coden'],
	'bici' => ['bici', 'rft.bici'],
	'stitle' => ['stitle', 'rft.stitle'],
	'atitle' => ['atitle', 'rft.atitle'],
	'part' => ['part', 'rft.part'],
	'spage' => ['spage', 'rft.spage'],
	'epage' => ['epage', 'rft.epage'],
	'artnum' => ['artnum', 'rft.artnum'],
	'date' => ['date', 'rft.date'],
	'ssn' => ['ssn', 'rft.ssn'],
	'quarter' => ['quarter', 'rft.quarter']
);


%CITATION_MAPPINGS = (
	'REQTYPE'            => '_ht_reqtype',
	'PUBTYPE'            => '_ht_pubtype',
	'TITLE'              => '_ht_title',
	'ARTTIT'             => '_ht_arttit',
	'SERIES'             => '_ht_series',
	'AUT'                => '_ht_aut',
	'ARTAUT'             => '_ht_artaut',
	'PUB'                => '_ht_pub',
	'ISSN'               => '_ht_issn',
	'ISBN'               => '_ht_isbn',
	'SICI'		     => '_ht_sici',     
	'VOLISS'             => '_ht_voliss',
	'VOL'                => '_ht_vol',
	'ISS'                => '_ht_iss',
	'PGS'                => '_ht_pgs',
	'YEAR'               => '_ht_year',
	'MONTH'              => '_ht_month',
	'DAY'                => '_ht_day',
	'YYYYMMDD'           => '_ht_yyyymmdd',
	'EDITION'            => '_ht_edition',
	'THESIS_TYPE'        => '_ht_thesis_type',
	'FTREC'              => '_ht_ftrec',
	'URL'                => '_ht_url',
	'NOTE'               => '_ht_note',
	'REPNO'              => '_ht_repno',
	'SYSID'              => '_ht_sysid',
	'ERIC_NO'            => '_ht_eric_no',
	'ERIC_AV'            => '_ht_eric_av',
	'ERIC_FT_AV'         => '_ht_eric_ft_av',
	'MLOG_NO'            => '_ht_mlog_no',
	'UMI_DISS_NO'        => '_ht_umi_diss_no',
	'CALL_NO'            => '_ht_call_no',
	'DOI'                => '_ht_doi',
	'PMID'               => '_ht_pmid',
	'BIBCODE'            => '_ht_bibcode',
	'OAI'                => '_ht_oai',
	'URL_MSG'            => '_ht_url_msg', 
        'WARNING'            => '_ht_warning',
        'GENRE'              => '_ht_genre',           ## for OpenURL links
        'PATENT_NO'          => '_ht_patent_no',
        'PATENTEE'           => '_ht_patentee',
        'PATENT_YEAR'        => '_ht_patent_year',
        'NO_HOLDINGS_SEARCH' => '_ht_no_holdings_search',   
);

@PRE_FIELDS = keys(%HOLD_TAB_PARAM_MAPPINGS);
@PARSED_FIELDS = (keys(%CITATION_MAPPINGS), 'SOURCE');

# String used in the external (old) GODOT interface when a record contains fulltext
use vars qw($FULLTEXT_AVAILABLE_STRING);
$FULLTEXT_AVAILABLE_STRING = 'fulltext_rec';

# new - Returns a bless GODOT::Citation object

sub new {
	my ($class, $Database) = @_;

	# Initialize things that are to be hashes.
	my $var = {};
	$var->{'pre'} = {};
	$var->{'parsed'} = {};
	$var->{'Database'} = $Database if defined($Database);

	return bless $var, $class;
}

# req_type - Returns or sets the req_type flag for the Citation object

sub req_type {
	my ($self, $value) = @_;
	if (defined($value)) {
		$self->{'req_type'} = $value;
		return $value;
	} else {
		return $self->{'req_type'};
	}
}

# fulltext_available - Returns or sets the fulltext_available flag for the Citation object

sub fulltext_available {
	my ($self, $value) = @_;
	if ($value) {
		$self->{'fulltext_available'} = 1;
		return $value;
	} else {
		return $self->{'fulltext_available'};
	}
}

# fulltext_available - Returns or sets the fulltext_available flag for the Citation object

sub eric_fulltext_available {
	my ($self, $value) = @_;
	if ($value) {
		$self->{'parsed'}->{'ERIC_FT_AV'} = 1;
		return $value;
	} else {
		return $self->{'ERIC_FT_AV'};
	}
}

#
# (15-may-2002 kl) 
#
# -added here to deal with openurl genre=journal case, perhaps it should be moved elsewhere?
#

sub need_article_info {
       my ($self) = @_;

       return ($self->{'parsed'}->{'GENRE'} eq $GODOT::Config::JOURNAL_GENRE);


}

# is_* - Returns true if the request is of the specified request or 
# database type. 
# These are easier/safer to use than checking the return from req_type
# against a bunch of different options.

sub is_journal {
	my ($self) = @_;
	return $self->{'req_type'} eq $GODOT::Constants::JOURNAL_TYPE;
}

sub is_conference {
       my ($self) = @_;
       return $self->{'req_type'} eq $GODOT::Constants::CONFERENCE_TYPE;
}

sub is_book {
	my ($self) = @_;
	return $self->{'req_type'} eq $GODOT::Constants::BOOK_TYPE;
}

sub is_book_article {
	my ($self) = @_;
	return $self->{'req_type'} eq $GODOT::Constants::BOOK_ARTICLE_TYPE;
}

sub is_thesis {
	my ($self) = @_;
	return $self->{'req_type'} eq $GODOT::Constants::THESIS_TYPE;
}

sub is_tech {
	my ($self) = @_;
	return $self->{'req_type'} eq $GODOT::Constants::TECH_TYPE;
}

sub is_preprint {
	my ($self) = @_;
	return $self->{'req_type'} eq $GODOT::Constants::PREPRINT_TYPE;
}

sub is_unknown {
	my ($self) = @_;
	return $self->{'req_type'} eq $GODOT::Constants::UNKNOWN_TYPE;
}

sub is_mono {
	my ($self) = @_;
	($self->{'req_type'} ne $GODOT::Constants::JOURNAL_TYPE);
}


# Gets/sets the BRS database flag.
sub is_brs_database {
	my $self = shift;
	return $self->{'Database'}->is_brs_database(@_);
}

# Gets/sets the III database flag.
sub is_iii_database {
	my $self = shift;
	return $self->{'Database'}->is_iii_database(@_);
}

sub dbase_type {
	my $self = shift;
	return $self->{'Database'}->dbase_type(@_);	
}

sub dbase {
	my $self = shift;
	return $self->{'Database'}->dbase(@_);	
}

sub get_dbase() {
	my ($self) = @_;
	if (defined ($self->{'Database'})) {
	  return $self->{'Database'};
	}
	else {
	  return $FALSE;
	}
}


# Accessor methods for pre/parse fields
sub pre {
	my ($self, $field, $value) = @_;
	
	# Check whether $field is valid
	unless (grep {$field eq $_} @PRE_FIELDS) {
		error("Citation::pre() - unrecognized field: $field");
		return undef;  # die??
	}

	$self->{'pre'}->{$field} = $value if defined($value);
	return $self->{'pre'}->{$field};
}

sub parsed {
	my ($self, $field, $value) = @_;
	
	# Pass through "special" parsed fields to internal accessor methods
	if ($field eq 'DATABASE') {
		return $self->dbase($value);
	}

	# Check whether $field is valid
	unless (grep {$field eq $_} @PARSED_FIELDS) {
		error("Citation::parsed() - unrecognized field: $field");
		return undef;  # die??
	}

	$self->{'parsed'}->{$field} = $value if defined($value);
	return $self->{'parsed'}->{$field};
}



# ---------- Extra stuff to support hooking into existing GODOT code ---------


# godot_citation - Converts the internal parsed citation into the GODOT
# $citation{$hold_tab::XXX_FIELD} format

sub godot_citation {
	my ($self) = @_;
	
	my %citation;
	foreach my $field (keys %CITATION_MAPPINGS) {
		$citation{$CITATION_MAPPINGS{$field}} = $self->{'parsed'}->{$field};
	}
	$citation{'_ht_ftrec'} = $FULLTEXT_AVAILABLE_STRING if $self->fulltext_available();
	$citation{'_ht_eric_ft_av'} = $FULLTEXT_AVAILABLE_STRING if $self->eric_fulltext_available();
	$citation{'_ht_reqtype'} = $self->req_type();
	return %citation;
}



# init_from_params - Initializes the Citation object from CGI param fields.

sub init_from_params {
	my ($self) = @_;
	
	require CGI;

	# Grab the citation fields (pre-parse), mostly the two digit mappings from ERL
	foreach my $field (keys %HOLD_TAB_PARAM_MAPPINGS) {
		my $string;
		
		if (ref($HOLD_TAB_PARAM_MAPPINGS{$field}) eq 'ARRAY') {
			foreach my $field2 (@{$HOLD_TAB_PARAM_MAPPINGS{$field}}) {
				$string = CGI::param($field2);
				last if defined($string);
			}
		} else {
			$string = CGI::param($HOLD_TAB_PARAM_MAPPINGS{$field});
		}
		chomp $string;

		$self->{'pre'}->{$field} = $self->clean_field($string);
	}

	return $self;
}


# init_from_parsed_params - Initializes the Citation object from CGI param fields, but
# assumes that all parameters are already parsed and sticks them directly into the PARSED fields
# *** Looks for new GODOT style 'ARTTIT', 'AUTHOR', etc. fields to load

sub init_from_parsed_params {
	my ($self) = @_;
	
	require CGI;

	# Grab the citation fields (parsed) from CGI params matching mostly
	# the left side of %CITATION_MAPPINGS like "ARTTIT", "SOURCE", etc.

	foreach my $field (@PARSED_FIELDS) {
		my $string = CGI::param($field) || '';
		next if $string eq '';
		chomp $string;

		$self->parsed($field, $string);
	}

	# Grab a few extra parameters that are useful for handling the request

	$self->{'Database'}->dbase(CGI::param('DBASE'));

	$self->req_type(CGI::param('REQTYPE'));

	return $self;
}


# init_from_godot_parsed_params - Initializes the Citation object from CGI param fields, but
# assumes that all parameters are already parsed and sticks them directly into the PARSED fields.
# *** Looks for old GODOT style '_ht_****' fields to load

sub init_from_godot_parsed_params {
	my ($self) = @_;
	
	require CGI;

	# Grab the citation fields (parsed) from old GODOT style CGI params
	# matching mostly the left side of %CITATION_MAPPINGS like "_ht_arttit",
	# "_ht_source", etc.

	my %old_godot_mapping = reverse(%CITATION_MAPPINGS);
	foreach my $field (keys %old_godot_mapping) {
		my $string = CGI::param($field) || '';
		next if $string eq '';
		chomp $string;

		$self->parsed($old_godot_mapping{$field}, $string);
	}

	# Grab a few extra parameters that are not in the %CITATION_MAPPINGS hash

	# Database is not set in current old godot _ht_fields
#	$self->{'Database'}->dbase(CGI::param('DBASE'));

	$self->req_type(CGI::param('_ht_reqtype'));

	return $self;
}

#
# Cleans up citation fields by doing stuff like stripping ERL highlighting 
# characters, unescaping URI %XX characters, etc. 
# Takes: $string
# Returns: $string
#

sub clean_field {
	my ($self, $string) = @_;
	
	return $string if !defined($string) || $string eq '';

#	print STDERR "clean_field, string in: $string\n";

	# Strip out weird escape sequences introduced by highlighting codes in webspirs
	$string =~ s#%1bh##ig;        
	$string =~ s#\x1bh##ig;

	# Translate %xx to their character equivalents
	$string = uri_unescape($string);

	# Change high characters to their low character equivalents
	$string = striphigh($string);


	# If it's a BRS database, then further stuff needs doing.
		
	if ($self->is_brs_database()) {
		
		$string = strip_extra_leading_subfield($string);
		
		# Temporary fix for ECDB
		$string =~ s#\174([a-z0-9])#\037$1#g;
	}

#	print STDERR "clean_field, string out: $string\n";

	return $string;
}	


1;

__END__

=head1 NAME

GODOT::Citation - Citation object for the GODOT system

=head1 METHODS

=head2 Constructor

=over 4

=item new([$dbase])

=back

Returns a reference to Citation object. I<$dbase> is a refenerce
to Database object.

=head2 ACCESSOR METHODS

=over 4

=item is_book([$value])

=item is_book_article([$value])

=item is_journal([$value])

=item is_thesis([$value])

=item is_tech([$value])

=item is_preprint([$value])

=item is_mono()

Accessor methods for checking $self->{'req_type'} for a specific type of
document, or for setting the Citation object to be a certain type of
document.  These methods are similar to the req_type(), but use boolean
values for each document type rather than returning or setting the actual
req_type value which req_type() does.

=item need_article_info()

Returns true if the citation is such that article information is needed to 
make it suitable for ILL requesting.

=item get_dbase()

Returns a reference to the sub Database object if it exists,
otherwise zero.

=item req_type()

$document_type = req_type([$document_type_value])

Accessor method for the request type ($self->{'req_type'}) value.  It
returns a request type constant out of GODOT::Constants, and can also set
the value to a request type constant.  The accessor methods above this one
show the various is_* boolean checks that can be done for each individual
request type rather than dealing with a constant value.

=back

=head1 DATA LAYOUT

Please try to use accessor methods for data whenever they are available.  In
typical Perl style, I wont stop you from modifying the data directly, but
you're bypassing some protection.

=over 4

=item req_type - SCALAR

Contains the request type, can be accessed through req_type().

=item pre - HASH

Contains all the raw database fields for the citation, roughly equivalent
to all the old $XXX_PRE_FIELD variables.  These are often the short field
names which come out of ERL/Webspirs, though other systems often get mapped
to these as well.


=item parsed - HASH

Contains all the parsed fields for the citation, generally created by the
GODOT::Parser[::xxx] object.  This is roughly equivalent to the old
$citation{$hold_tab::XXX_FIELD} variables.

=item Database - REFERENCE

Points to a Database object.

=back

=head1 AUTHORS / ACKNOWLEDGMENTS

Written by Todd Holbrook, based on existing GODOT code by Kristina Long and
others over the years at SFU.

=cut
