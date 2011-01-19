package GODOT::Template;

## GODOT::Template
##
## Copyright (c) 2003, Kristina Long, Simon Fraser University
##

use CGI qw(:escapeHTML :escape :cookie);
use Encode;

use Template;
use Template::Stash;

use GODOT::Constants;
use GODOT::Config;

use GODOT::Debug;
use GODOT::String;
use GODOT::Encode::Transliteration;

use GODOT::Template::Object;
use GODOT::Template::Config;


@ISA = qw(Exporter GODOT::Template::Object);

@EXPORT = qw($TEST_TEMPLATE_COOKIE     
             $TEST_TEMPLATE_TRUE     
             $TEST_TEMPLATE_FALSE
             $SANDBOX_OBJECT_COOKIE    
             $SANDBOX_OBJECT_TRUE    
             $SANDBOX_OBJECT_FALSE
             $SANDBOX_OBJECT_NAME_COOKIE
             $USE_NEW_INTERFACE_COOKIE             
             $USE_NEW_INTERFACE_TRUE 
             $USE_NEW_INTERFACE_FALSE);

use vars qw($TEST_TEMPLATE_COOKIE $TEST_TEMPLATE_TRUE $TEST_TEMPLATE_FALSE);

$TEST_TEMPLATE_COOKIE = 'godot_test_template';
$TEST_TEMPLATE_TRUE   = 'use',
$TEST_TEMPLATE_FALSE  = 'do not use';

use vars qw($SANDBOX_OBJECT_COOKIE $SANDBOX_OBJECT_TRUE $SANDBOX_OBJECT_FALSE $SANDBOX_OBJECT_NAME_COOKIE);

$SANDBOX_OBJECT_COOKIE = 'GODOT_SANDBOX_OBJECT';
$SANDBOX_OBJECT_TRUE   = 'save',
$SANDBOX_OBJECT_FALSE  = 'do not save';

$SANDBOX_OBJECT_NAME_COOKIE = 'GODOT_SANDBOX_OBJECT_NAME';

use vars qw($USE_NEW_INTERFACE_COOKIE $USE_NEW_INTERFACE_TRUE $USE_NEW_INTERFACE_FALSE);

$USE_NEW_INTERFACE_COOKIE = 'godot_use_new_interface_cookie'; 
$USE_NEW_INTERFACE_TRUE   = 'use';
$USE_NEW_INTERFACE_FALSE  = 'do not use';

use strict;


$Template::Stash::SCALAR_OPS->{'aws'} = sub { 
    my $x = shift; 
    return &GODOT::String::aws($x); 
};

$Template::Stash::SCALAR_OPS->{'naws'} = sub { 
    my $x = shift; 
    return &GODOT::String::naws($x); 
};

$Template::Stash::SCALAR_OPS->{'not_empty'} = sub { 
    my $x = shift; 
    ##
    ## (14-jan-2005 kl) - change to be equivalent to naws
    ##
    #### return(defined($x) && $x ne '') 
    return &GODOT::String::naws($x);
};

$Template::Stash::SCALAR_OPS->{'lc'} = sub { 
    my $x = shift;
    return lc $x; 
};

$Template::Stash::SCALAR_OPS->{'uc'} = sub { 
    my $x = shift;
    return uc $x; 
};

$Template::Stash::SCALAR_OPS->{'trim'} = sub { 
    my $x = shift;
    return &GODOT::String::trim_beg_end($x); 
};


$Template::Stash::SCALAR_OPS->{'strip_html'} = sub {
    my $x = shift;
    return &GODOT::String::strip_html($x);
};


$Template::Stash::SCALAR_OPS->{'comp_ws'} = sub { 
    my $x = shift;
    return &GODOT::String::comp_ws($x); 
};

$Template::Stash::SCALAR_OPS->{'substr'} = sub { 
    my ($scalar, $offset, $length) = @_; 
    return defined($length) ? substr($scalar, $offset, $length) : substr($scalar, $offset); 
};

$Template::Stash::SCALAR_OPS->{'escapeHTML'} = sub { 
    my $x = shift; 
    return escapeHTML($x);
};

$Template::Stash::SCALAR_OPS->{'escape'} = sub { 
    my $x = shift; 
    return escape($x);
};

$Template::Stash::SCALAR_OPS->{'encode_utf8'} = sub { 
    my $x = shift; 
    return GODOT::String::encode_string('utf8', $x);
};

$Template::Stash::SCALAR_OPS->{'transliterate_to_latin1'} = sub { 
    my $x = shift; 
    ##### return GODOT::String::transliterate_string('latin1', $x);
    return GODOT::Encode::Transliteration::transliterate_string('latin1', $x);
};

$Template::Stash::SCALAR_OPS->{'encode_latin1'} = sub { 
    my $x = shift; 
    return GODOT::String::encode_string('latin1', $x);
};



$Template::Stash::LIST_OPS->{'sort_by_service'} =  sub { 
  
    my $list = shift;

    my @sorted = sort by_service @{$list};

    return [ @sorted ];

    sub by_service {

        my %services_in_order = ('fulltext'          => 1, 
                                 'table of contents' => 2, 
                                 'journal'           => 3, 
                                 'database'          => 4, 
                                 'holdings'          => 5, 
                                 'web search'        => 6);
  
        $services_in_order{$a->name} <=> $services_in_order{$b->name};
    }

};

$Template::Stash::LIST_OPS->{'dumper'} = sub {
	my $x = shift;
	use Data::Dumper;
	return Dumper($x);
};

$Template::Stash::SCALAR_OPS->{'clean_ISSN_dash_format'} = sub { 
    my $x = shift;
    return &GODOT::String::clean_ISSN($x, $TRUE); 
};


##
## ?????????????????? do we still need ??????????????????
##
use vars qw(@TEST_PAGE_FORMATTERS_ARR $TEST_PAGE_FORMATTERS_COOKIE $TEST_PAGE_FORMATTERS_TRUE $TEST_PAGE_FORMATTERS_FALSE);

$TEST_PAGE_FORMATTERS_COOKIE = 'test_page_formatters_cookie';

@TEST_PAGE_FORMATTERS_ARR = ($TEST_PAGE_FORMATTERS_TRUE  = 'use',
                             $TEST_PAGE_FORMATTERS_FALSE = 'do not use');

use vars qw($REQ_BUTTON $CHK_BUTTON $GET_BUTTON $ILL_BUTTON $AUTO_REQ_BUTTON $CONTINUE_BUTTON);

$REQ_BUTTON      = 'request_button';
$CHK_BUTTON      = 'check_button';
$GET_BUTTON      = 'get_button';
$ILL_BUTTON      = 'ill_button';
$AUTO_REQ_BUTTON = 'auto_req_button';
$CONTINUE_BUTTON = 'continue_button';

use vars qw($CONTINUE_BUTTON_TEXT $REQ_BUTTON_TEXT $CHK_BUTTON_TEXT $GET_BUTTON_TEXT $ILL_BUTTON_TEXT $AUTO_REQ_BUTTON_TEXT);

$CONTINUE_BUTTON_TEXT  = 'Continue';
$REQ_BUTTON_TEXT        = "[REQ]";
$AUTO_REQ_BUTTON_TEXT   = $REQ_BUTTON_TEXT;
$CHK_BUTTON_TEXT        = "[CHK]";
$GET_BUTTON_TEXT        = "[GET]";
$ILL_BUTTON_TEXT        = "[ILL]";

my %BUTTON_TEXT_HASH = ($CONTINUE_BUTTON => $CONTINUE_BUTTON_TEXT,
                        $REQ_BUTTON      => $REQ_BUTTON_TEXT, 
                        $CHK_BUTTON      => $CHK_BUTTON_TEXT,
                        $GET_BUTTON      => $GET_BUTTON_TEXT,
                        $ILL_BUTTON      => $ILL_BUTTON_TEXT,
                        $AUTO_REQ_BUTTON => $AUTO_REQ_BUTTON_TEXT);


use vars qw($AUTOLOAD);

my $TRUE  = 1;
my $FALSE = 0;

my @FIELDS = qw(name site include_path config);

sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;

    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }
   
    my $name   = ${$values}{'name'};
    my $site   = ${$values}{'site'};
    my $config = ${$values}{'config'};     ## cached config

    my $config_from_db = new GODOTConfig::Configuration($config->name);
   
    unless (GODOT::String::naws($site)) {
        error "GODOT::Template::new - no site specified";
        return undef;
    }

    ##
    ## -assemble INCLUDE_PATH
    ##  
    my @dirs;

    if (cookie($TEST_TEMPLATE_COOKIE) eq $TEST_TEMPLATE_TRUE) { 
        push(@dirs, "$LOCAL_TEMPLATE_DIR/$TEST_TEMPLATE_SUBDIR/$site", 
                    "$GODOT::Config::TEMPLATE_DIR/$TEST_TEMPLATE_SUBDIR");
    }

    push(@dirs, $config_from_db->template_include_path);

    debug "INCLUDE_PATH:";
    my $count = 1;
    foreach my $dir (@dirs) { 
        debug "$count - $dir"; 
        $count++;
    }

    my $include_path = join(':', @dirs);
   
    return $class->SUPER::new([@FIELDS, @{$fields}], {'name'         => [$name],
                                                      'site'         => [$site],
                                                      'include_path' => [$include_path], 
                                                      'config'       => [$config_from_db],
                                                      });
}

sub format {
    my($self, $vars) = @_;
   
    #### debug("GODOT::Template::format using template: " . $self->{'name'});
    
    my $template = new Template({'INCLUDE_PATH' => $self->include_path, 
                                 'ENCODING'     => 'utf8',
                                 'PRE_CHOMP'    => 1,
			         'POST_CHOMP'   => 1,
			         'VARIABLES'    => {'config'     => $self->config},
                               });

    ## 
    ## (13-may-2004 kl) - dump objects so that we can use the sandbox feature of the new GODOTConfig::Configuration tool 
    ##

    $self->dump($vars);

    my $text;

    $template->process($self->{'name'}, $vars, \$text);

    if ($template->error) { debug("GODOT::Template::format - " . $template->error); }

    return $text;
}


sub dump {
    my($self, $vars) = @_;

    #### debug location, "--", $SANDBOX_OBJECT_COOKIE, "--", cookie($SANDBOX_OBJECT_COOKIE), "--", $SANDBOX_OBJECT_TRUE;
    
    unless (cookie($SANDBOX_OBJECT_COOKIE) eq $SANDBOX_OBJECT_TRUE) { return; }

    use FileHandle;

    my ($site, $screen, $scrno);

    $site = $self->config->name;

    foreach my $key (keys %{$vars}) {

        if (ref($vars->{$key}) eq 'GODOT::Page')       { $scrno = $vars->{$key}->scrno; }
        if ($key eq 'screen')                          { $screen = $vars->{$key};       }
    }

    my $object_name = &GODOT::String::trim_beg_end(cookie($SANDBOX_OBJECT_NAME_COOKIE));

    my $file = "$GODOT::Config::SANDBOX_OBJECT_DIR/" . 
               (($site) ? ("$site") : '') . 
               '.' . $screen .
               (($object_name ne '') ? (".$object_name") : '') .
               (($scrno) ? (".$scrno") : '');

    my $dump_fh;

    if (! ($dump_fh = new FileHandle "> $file")) {
        debug("GODOT::Template::dump - unable to open '$file' for writing.");
        return;
    }

    use Data::Dumper;
    print $dump_fh Dumper($vars); 
                   
    $dump_fh->close;
}



1;

__END__

