package link_template;

require gconst;
require glib;

use GODOT::Encode;

use CGI qw(-no_xhtml :standard);

@LINK_TEMPLATE_FIELD_ARR = (

    [$gconst::DBASE_FIELD,       'DBASE',        'Database code for database from which citation originated'],
    [$gconst::BRANCH_FIELD,      'BRANCH',       'Site code'],
    
    [$gconst::REQTYPE_FIELD,     'REQTYPE',     'One of (' . join(' ', @gconst::REQTYPE_ARR) . ')'],
    [$gconst::PUBTYPE_FIELD,     'PUBTYPE',     'Publication type as given in citation database'],  

    [$gconst::TITLE_FIELD,       'TITLE',       'Title of book, journal, etc'],
    [$gconst::ARTTIT_FIELD,      'ARTTIT',      'Article title'],
    [$gconst::SERIES_FIELD,      'SERIES',      'Series'],

    [$gconst::AUT_FIELD,         'AUT',         'Author or editor'],  
    [$gconst::ARTAUT_FIELD,      'ARTAUT',      'Article or chapter author'],

    [$gconst::PUB_FIELD,         'PUB',         'Publishing information'],

    [$gconst::ISSN_FIELD,        'ISSN',        'ISSN'],
    [$gconst::ISBN_FIELD,        'ISBN',        'ISBN'],

    [$gconst::VOLISS_FIELD,      'VOLISS',      'Volume and issue (use if volume and issue cannot be parsed out)'],
    [$gconst::VOL_FIELD,         'VOL',         'Volume'], 
    [$gconst::ISS_FIELD,         'ISS',         'Issue'],
    [$gconst::PGS_FIELD,         'PGS',         'Pages'],
    [$gconst::YEAR_FIELD,        'YEAR',        'Year (YYYY)'],
    [$gconst::MONTH_FIELD,       'MONTH',       'Month - any format'],

    [$gconst::YYYYMMDD_FIELD,    'YYYYMMDD',    'Numeric date'], 
                                             
    [$gconst::EDITION_FIELD,     'EDITION',     'Edition'],
    
    [$gconst::THESIS_TYPE_FIELD, 'THESIS_TYPE', 'Thesis type (eg. Master\'s, Ph.D)'],

    [$gconst::FTREC_FIELD,       'FTREC',       'Is included in database record?'],
    [$gconst::URL_FIELD,         'URL',         'URL field found in citation'],
    [$gconst::NOTE_FIELD,        'NOTE',        'Note'],

    [$gconst::REPNO_FIELD,       'REPNO',       'Report number'], 
    [$gconst::SYSID_FIELD,       'SYSID',       'System ID or accession number from citation database.'],
    
    [$gconst::ERIC_NO_FIELD,     'ERIC_NO',     'ERIC document number  - used to access microfiche'],
    [$gconst::ERIC_AV_FIELD,     'ERIC_AV',     'ERIC Level of Availability field'], 
    [$gconst::ERIC_FT_AV_FIELD,  'ERIC_FT_AV',  'ERIC document is available online and is specified in the ERIC citation record'], 

    [$gconst::MLOG_NO_FIELD,     'MLOG_NO',     'Microlog number - used to access microfiche'],    
    [$gconst::UMI_DISS_NO_FIELD, 'UMI_DISS_NO', 'UMI Dissertation Number - in future use as link to UMI...'],

    [$gconst::CALL_NO_FIELD,     'CALL_NO',     'Call number - for item databases such as the UBC Catalogue'],

    [$gconst::DOI_FIELD,         'DOI',         'Digital object identifier'],
    [$gconst::PMID_FIELD,        'PMID',        'PubMed identifier'],
    [$gconst::BIBCODE_FIELD,     'BIBCODE',     'Identifier used in Astrophysics Data System'],
    [$gconst::OAI_FIELD,         'OAI',         'Identifier used in the Open Archives initiative']    

);


use vars qw(@COOKIE_VALUES_ARR $NO_LINK_TEMPLATE $SFU_LINK_TEMPLATE $YOUR_LINK_TEMPLATE);

@COOKIE_VALUES_ARR = ($NO_LINK_TEMPLATE   = 'none',
                      $SFU_LINK_TEMPLATE  = 'from BVAS profile',
                      $YOUR_LINK_TEMPLATE = 'from your own profile');


use vars qw($LINK_TEMPLATE_COOKIE);

$LINK_TEMPLATE_COOKIE = 'godot_link_template_cookie';

##
## -returns hash of form '<template variable> => <param field name>'
##
sub link_template_map {

    my(%template_map);

    foreach my $ref (@LINK_TEMPLATE_FIELD_ARR) {

        my($param_field, $template_field, $desc) = @{$ref}; 

        $template_map{$template_field} = $param_field;
    }

    return %template_map; 
}


sub link_template_text {
    my($template) = @_;

    my(%link_template_map) = &link_template_map();
    my($string) = $template;

    $string =~ s#{([^{}]+)}#&replace_variable($1, \%link_template_map)#ge;

    return $string;
}

sub replace_variable {
    my($variable, $map_ref) = @_;

    (defined ${$map_ref}{$variable}) ? &CGI::escape(link_template_field(param(${$map_ref}{$variable}))) : "{$variable}";

}

sub use_link_templates {

    cookie($LINK_TEMPLATE_COOKIE);
}













