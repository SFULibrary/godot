package GODOTConfig::Configuration;

use Class::Accessor;
use base 'Class::Accessor';

use Data::Dumper;

use GODOTConfig::Config;

use GODOTConfig::Exceptions;

use GODOTConfig::DB::Sites;
use GODOTConfig::DB::Site_Chains;

use GODOTConfig::Debug;
use GODOT::String;
use GODOT::Debug;


use strict;

my $TRUE  = 1;
my $FALSE = 0;


use vars qw($AUTOLOAD);

__PACKAGE__->mk_accessors(qw(
	site
	type
));


sub new {
	my ($class, $site_key) = @_; 
       		
        my $self = bless {}, $class;
        my $type;
        $self->init($site_key, $type);

        return $self; 
}

sub init {
	my ($self, $site_key, $type) = @_;

	defined($site_key) && $site_key ne '' or
		GODOTConfig::Exception::App->throw('$site_key undefined in GODOTConfig::Configuration::init()');
		
	my $site = GODOTConfig::DB::Sites->search('key' => $site_key)->first;
	
	defined($site) or GODOTConfig::Exception::App->throw("Site not found: $site_key");

        ##
        ## Need to add to GODOTConfig::Cache instead
        ##
	#### $site->active or GODOTConfig::Exception::App->throw("Site is not active: $site_key");
		
	$self->site($site);
	$self->type($type || 'active');
	
	return $self;
}

sub template_include_path {
	my ($self) = @_;
	
	if ($self->type eq 'active') {
		return $self->_template_include_path;
	} elsif ($self->type eq 'sandbox') {
		return $self->_sandbox_template_include_path;
	} else {
		GODOTConfig::Exception::App->throw("Unrecognized type in template_include_path: ". $self->type);
	}
}

sub _template_include_path {
	my ($self) = @_;

	my @path = ($GODOTConfig::Config::GODOT_GLOBAL_TEMPLATE_DIR);

	my @chained_sites = $self->site->chains;
	foreach my $chained_site (sort {$a->rank <=> $b->rank} @chained_sites) {
		unshift @path, "$GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/active/" . $chained_site->chain->id;	
	}

	unshift @path, "$GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/active/" . $self->site->id;

	return @path;
}

sub _sandbox_template_include_path {
	my ($self) = @_;

	my @path = ($GODOTConfig::Config::GODOT_GLOBAL_TEMPLATE_DIR);

	my @chained_sites = $self->site->chains;
	foreach my $chained_site (sort {$a->rank <=> $b->rank} @chained_sites) {
		unshift @path, "$GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/active/" . $chained_site->chain->id;	
	}

	unshift @path, "$GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/active/" . $self->site->id;
	unshift @path, "$GODOTConfig::Config::GODOT_SITE_TEMPLATE_DIR/sandbox/" . $self->site->id;

	return @path;
}

sub css {
	my ($self) = @_;
	my @css = ("$GODOTConfig::Config::GODOT_GLOBAL_CSS_HTTP_BASE/godot.css");

	if ($self->type eq 'active') {
		my @chained_sites = $self->site->chains;
		foreach my $chained_site (sort {$a->rank <=> $b->rank} @chained_sites) {
			my $site_id = $chained_site->chain->id;
			-e "$GODOTConfig::Config::GODOT_SITE_CSS_DIR/active/$site_id/godot.css" and
				push @css, "$GODOTConfig::Config::GODOT_SITE_CSS_HTTP_BASE/active/$site_id/godot.css";
		}
		my $site_id = $self->site->id;
		-e "$GODOTConfig::Config::GODOT_SITE_CSS_DIR/active/$site_id/godot.css" and
			push @css, "$GODOTConfig::Config::GODOT_SITE_CSS_HTTP_BASE/active/$site_id/godot.css";
	} elsif ($self->type eq 'sandbox') {
		my @chained_sites = $self->site->chains;
		foreach my $chained_site (sort {$a->rank <=> $b->rank} @chained_sites) {
			my $site_id = $chained_site->chain->id;
			-e "$GODOTConfig::Config::GODOT_SITE_CSS_DIR/sandbox/$site_id/godot.css" and
				push @css, "$GODOTConfig::Config::GODOT_SITE_CSS_HTTP_BASE/sandbox/$site_id/godot.css";
		}
		my $site_id = $self->site->id;
		-e "$GODOTConfig::Config::GODOT_SITE_CSS_DIR/sandbox/$site_id/godot.css" and
			push @css, "$GODOTConfig::Config::GODOT_SITE_CSS_HTTP_BASE/sandbox/$site_id/godot.css";
	} else {
		GODOTConfig::Exception::App->throw("Unrecognized type in css: ". $self->type);
	}

        return @css;
}


sub name {
    my($self) = @_;

    return $self->site->key;
}

sub full_name {
    my($self) = @_;

    return $self->site->name;
}

#
# (21-mar-2005 kl) - try replacing with AUTOLOAD routine as many (~ 130) config options are being added 
# 

sub AUTOLOAD {
        my $self = shift;
        my $class = ref($self) || error("GODOTConfig::Configuration::AUTOLOAD - self is not an object");
        my $field = $AUTOLOAD;

        $field =~ s/.*://;               ## -strip fully qualified part
  
        unless (grep {$field eq $_} GODOTConfig::DB::Sites->all_config_options) { 
                error ("GODOTConfig::Configuration::AUTOLOAD - invalid field ($field)");
	        return undef;
        }

        return $self->site->$field;
}


sub DESTROY {

}



1;












