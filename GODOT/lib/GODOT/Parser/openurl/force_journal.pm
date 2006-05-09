package GODOT::Parser::openurl::force_journal;

use GODOT::Config;
use GODOT::String;
use GODOT::Constants;
use GODOT::Debug;
use GODOT::Parser::openurl;

@ISA = "GODOT::Parser::openurl";

use strict;

sub pre_parse {
    my ($self, $citation) = @_;
    debug("pre_parse() in GODOT::Parser::openurl::force_journal") if $GODOT::Config::TRACE_CALLS;
    $citation->pre('genre', $GODOT::Config::ARTICLE_GENRE);
}


1;

__END__

