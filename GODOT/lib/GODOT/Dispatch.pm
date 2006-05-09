package GODOT::Dispatch;

## GODOT::Dispatch
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use GODOT::Constants;
use GODOT::Config;
use GODOT::Debug;
use GODOT::String;
use GODOT::Object;

use GODOT::Dispatch::File;

@ISA = qw(Exporter GODOT::Object);

@EXPORT = qw();

use strict;

use vars qw($AUTOLOAD);

my $LOCAL = 'local';

my @FIELDS = ('files');                  ## ref to list of GODOT::Dispatch::File objects 
        
my $DEBUG = $FALSE;

## 
## (19-feb-2005 kl) 
## -added caching logic so that if we already have found a module for a given class 
##  and set of params we won't need to go through the process of locating the module again
## -disadvantage of this caching is that when new modules are being added, it will be necessary to 
##  restart the server for them to be seen
## -later we can add a flag to disable caching when doing development
## 

BEGIN {
    my %modules;                          ## persistent

    sub dispatch {
        my($self, $class, $param) = @_;

        debug("Dispatching module for $class.") if $DEBUG;

        ##
        ## -check to see that we have only been passed named param that are listed in specified include path
        ##
        unless ($self->_check_param($param)) { return $FALSE; }
   
        ##
        ## -check to see if there the module name we want is cached
        ##
        my $key = _key($class, $param);
        my $module = $modules{$key};
        
        if ($module) {            
            debug("GODOT::Dispatch::dispatch has found module $module in cache") if $DEBUG;

            ##
            ## Require uses filename rather than package name if passed a string
            ##
            (my $file = "$module.pm") =~ s/::/\//g;
            require($file);            
            return $module->new;
        }

        ##
        ## -return module names in the order in which we want them tried
        ##

        foreach my $module ($self->modules($class, $param)) {

            (my $file = "$module.pm") =~ s/::/\//g;

            debug("GODOT::Dispatch::dispatch is trying module: $module ($file)") if $DEBUG;

            eval {require($file)};

            if ($@ eq '') {
                debug("GODOT::Dispatch::dispatch chose module: $module ($file)") if $DEBUG;
                $modules{_key($class, $param)} = $module;                
                return $module->new;
            } 
            else {
                debug("GODOT::Dispatch::dispatch was unable to load module: $module ($file) because: $@") if $DEBUG;
            }
        }
        debug("Could not load a module for $class");
        return $FALSE;
    }

    sub _modules {
        return %modules;
    }
}


sub new {
    my ($self, $include_path) = @_;

    my $class = ref($self) || $self;

    my $obj = $class->SUPER::new([@FIELDS], {});

    foreach my $list (@{$include_path}) {

        my($type, @rest) = @{$list};
        my $file = new GODOT::Dispatch::File;
        $file->type($type);
        $file->components([@rest]);
        $obj->files([$file]);        
    }
    return $obj;
}


##
## -parameter is a reference to an array of one or more GODOT::Dispatch::File objects
##

sub files {
    my $self = shift;    
    my $class = ref($self) || error("Dispatch::files - self is not an object");
    my $dir_ref = shift;    
 
    my $field = 'files';

    if (ref($dir_ref)  &&  @{$dir_ref}) { push(@{$self->{$field}}, @{$dir_ref}); }

    if (defined $self->{$field}) { return $self->{$field}; }    
    else                         { return [];                 }  
} 



sub modules {
    my($self, $class, $param) = @_;

    my @local;
    my @global;

    my ($pkg, @rest) = split('::', $class);
    my $local_class = join('::', $pkg, $LOCAL, @rest); 

    foreach my $file (@{$self->files}) {

        my @components = @{$file->components};
        my $name;
        
        foreach my $component (@components) {
            next if (GODOT::String::aws(${$param}{$component}));
            $name .= "::" . ${$param}{$component}; 
        } 
        
        if (scalar @components) {
             push(@local,  $local_class . $name) if ($name ne '');
             push(@global, $class . $name) if (($name ne '') && ($file->is_global));          
        }
    }

    push(@local,  $local_class);
    push(@global, $class);

    foreach my $name (@local, @global) { 
        #### debug "GODOT::Dispatch::modules:  $name"; 
    }

    return (@local, @global);
}


sub _key {
    my($class, $param) = @_;

    my @keys;
    while (my($field, $value) = each(%{$param})) {
        push(@keys, ($field . '=' . $value)) if ($value ne '');
    }     
    return join('&', $class, @keys);
}

sub _check_param {
    my($self, $param) = @_; 

    my @components;
    foreach my $file (@{$self->files}) {
        push(@components, @{$file->components}); 
    }    
    
    foreach my $key (keys %{$param}) {        

	unless (grep {$key eq $_} @components) {
            error "'$key' is not a valid dispatch parameter for ", ref($self);;
	    return $FALSE;
	}
    }

    return $TRUE;
}   



1;

__END__

