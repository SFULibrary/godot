use GODOTConfig::ConfigTool::CGI;
use CGI qw(:standard);


use strict;

my $CGI;
eval {
        $CGI = new GODOTConfig::ConfigTool::CGI();
};

if ($@) {
        print_error($@);
} elsif (!defined($CGI)) {
        print_error('Unable to create GODOTConfig::ConfigTool::CGI object in maint.cgi');
} else {
        eval {
                print ${$CGI->handler()};
        };
        if ($@) {
                print_error($@);
        }
}

sub print_error {
        my ($err) = @_;

        my $message = ref($@) ? $@->error() : $@;

        warn("Error: $message");
        print header(), start_html('GODOT ConfigTool Error');
        print "<B>Error:</B><BR>$message";
        print end_html();

}

1;


