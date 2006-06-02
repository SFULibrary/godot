#!/usr/local/bin/perl

use strict;
use Cwd;

use Getopt::Long;
my $code_only;
GetOptions('code_only' => \$code_only);   ## --code_only

my $ROOT        = '/home/kristina/godot_ni';
my $TAR_INCLUDE      = $ROOT . '/util/tar.include';
my $TAR_EXCLUDE      = $ROOT . '/util/tar.exclude';
my $VERSION_FILE     = $ROOT . '/util/version';

my $TAR_DIR_ROOT     = '/tmp';
my $TAR_NAME         = 'godot';

my $VERSION_PATTERN = '^\s*\d+\.\d+\.\d+\s*$';

my $start_wd = cwd;

use Term::ReadLine;
my $term = new Term::ReadLine 'making godot distribution';

unless ($start_wd eq $ROOT) {
    print "\nCurrent working directory is $start_wd\n", "Changing to $ROOT\n\n";
    chdir $ROOT or die "Can't cd to '$ROOT':  $!\n";
}

my $tar_include = $TAR_INCLUDE;

if ($code_only) {

    my $code_only_tar_include = "/$TAR_DIR_ROOT/tar.code_only.include";
    use FileHandle;

    my $co_fh = new FileHandle;
    $co_fh->open("> $code_only_tar_include") || return;

    my $fh = new FileHandle;
    $fh->open("< $TAR_INCLUDE") || return;

    while (<$fh>) {
        s#\s+$##;
        next unless (m#\.cgi# || m#\.pl# || m#\.pm#);
        next if (m#AdvancedConfig.pm# || m#BasicConfig.pm#);      
        print $co_fh $_, "\n";
    }
       
    $co_fh->close;
    $fh->close;

    $tar_include = $code_only_tar_include;
}


-e $tar_include  or die "$tar_include does not exist\n";
-e $TAR_EXCLUDE  or die "$TAR_EXCLUDE does not exist\n";
-e $VERSION_FILE or die "$VERSION_FILE does not exist\n";

##
## Get version number, update if required
##

open VERSION, $VERSION_FILE  or die "Unable to open version file for reading: $!";
my $version = trim_ws(<VERSION>);
($version =~ m#$VERSION_PATTERN#) or die "Version ($version) was not in the expected format\n";
close VERSION;

my $input = $term->readline("Current version number [$version]: ");
my $new_version = trim_ws($input);;

if ($new_version eq '') { 

    print "Using current version ($version)\n"; 
}
elsif  ($new_version =~ m#$VERSION_PATTERN#) { 

    if ($version ne $new_version) {
        open VERSION, "> $VERSION_FILE"  or die "Unable to open version file for writing: $!";
        print VERSION $new_version, "\n";
        close VERSION;
        $version = $new_version;
    }
}
else {
    die "Entered version ($new_version) was not in the expected format\n"; 
}


 
my $tar_file  = "$TAR_DIR_ROOT/$TAR_NAME"          . 
                (($code_only) ? '-code-only' : '') . 
                "-$version.tar";

my $tar_file_tmp = "$tar_file.tmp";
my $tar_res      = "$tar_file.result";

##
## run tar
##

my $cmd = "tar cfTX $tar_file_tmp  $tar_include $TAR_EXCLUDE --no-recursion > $tar_res; ";

`$cmd`;


##
## Create versioned directory in which to expand tar file and then tar up again.
##
my $tar_dir = "$TAR_DIR_ROOT/$TAR_NAME-$version";
my $tar_subdir = "$TAR_NAME-$version";

if (-d $tar_dir) {
    die "\n'$tar_dir' already exists.  Please remove it.\n";
}

`mkdir $tar_dir` unless (-d $tar_dir);;

chdir $tar_dir or die "Can't cd to '$tar_dir':  $!\n";
my $cwd = cwd;

unless ($tar_dir eq $cwd) { 
    die "Was not able to change to '$tar_dir'.  Currently in '$cwd'.\n";
}

##
## -expand into versioned directory
##
$cmd = "tar xvf $tar_file_tmp > $tar_res; ";

`$cmd`;

##
## -tar up again with versioned directory as root
##

chdir $TAR_DIR_ROOT or die "Can't cd to '$TAR_DIR_ROOT':  $!\n";

$cmd = "tar cvf $tar_file  $tar_subdir > $tar_res; ";

`$cmd`;

`gzip $tar_file`;

unless ($start_wd eq $ROOT) {
    print "\nChanging back to $start_wd\n";
    chdir $start_wd or die "Can't cd to '$start_wd':  $!\n";
}

print "\ngzipped tar file:\n", 
      `ls -l $tar_file.gz`, 
      "\n";


sub trim_ws { 
    my($string) = @_;
    $string =~ s#^\s+##g;
    $string =~ s#\s+$##g;
    return $string;
}




