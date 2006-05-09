package GODOT::Parser::openurl::isi::wos;

use GODOT::Config;
use GODOT::String;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Parser::openurl;
use CGI qw/unescapeHTML/;

@ISA = "GODOT::Parser::openurl";

my $TRUE  = 1;
my $FALSE = 0;

use strict;

sub get_req_type {
    my ($self, $citation) = @_;
    debug("get_req_type() in GODOT::Parser::openurl::isi::wos") if $GODOT::Config::TRACE_CALLS;

    return $GODOT::Constants::JOURNAL_TYPE;
}

1;

__END__

