package GODOT::ILL::Site;
##
## Copyright (c) 2005, Kristina Long, Simon Fraser University
##

use Exporter;
use GODOT::Config;
use GODOT::Debug;
use GODOT::String;
use GODOT::Object;

@ISA = qw(Exporter GODOT::Object);
@EXPORT = qw();

use strict;

my @FIELDS = ('site', 
              'nuc');


my @INCLUDE_PATH = ([qw(local  site)],
                    [qw(local  local)],
                    [qw(global)]);
##
## -called using class not object, so appears to need to have 'dispatch' defined explicitly for the class 
##

sub dispatch {
    my ($class, $param)= @_;

    my $site = ${$param}{'site'};
    ##    
    ## -for ELN-AG, ELN-AG-MONO, NEOS-OTHER, BNM-COW, BNM-NAN and BNM-POW
    ##
    ${$param}{'site'} =~ s#\055#_#g if (defined ${$param}{'site'});
    my $obj = $class->SUPER::dispatch([@INCLUDE_PATH], $param);
    $obj->{'site'} = $site;
    return $obj;
}

sub new {
    my ($self, $fields, $values) = @_;

    my $class = ref($self) || $self;
    if (ref($fields) eq 'HASH')  { $values = $fields; }
    if (ref($fields) ne 'ARRAY') { $fields = [];      }

    #### my ($pack, $file, $link, $subname, $hasargs, $wantarray) = caller(1);
    #### debug "----------- ", $subname;

    return $class->SUPER::new([@FIELDS, @{$fields}], $values);
}

##
## -return '<user>' if user and nuc are same, otherwise return '<user>[<nuc>]'  
##
##  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! change comments as appropriate for new GODOT::ILL::Message classes !!!!!!!!!!!!!!
## -if format output below ever gets changed, make sure that logic that formats 'NextPartners' field 
##  in &ill_rss_form_msg(...) and &ill_rss_form_msg_2(...) also gets changed 
##
sub description {
    my($self) = @_;

    my $site = $self->site;
    my $nuc  = $self->nuc;

    if ($site eq $nuc)  { return $nuc; }
    else                { return "$nuc\[$site\]"; }


}


sub borrowing_site {
    my($self) = @_;

    return $self->site;
}

1;
