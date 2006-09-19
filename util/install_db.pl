#!/usr/local/bin/perl
##
## GODOTConfig database installation script.
##
## -m    check for required modules and then exit without installing GODOT
##
##
use strict;

use FindBin qw($Bin);
use lib ("$Bin/../GODOT/lib", "$Bin/../GODOTConfig/lib");

use DBI;
use CGI qw(:escape);

use Install::GODOT;
use Install::GODOTConfig;
use GODOT::String;
use GODOT::Debug;
use GODOTConfig::Config;

use Term::ReadLine;

use Template;
use Template::Stash;

my $TRUE  = 1;
my $FALSE = 0;

my $PACKAGE = 'GODOTConfig';
my $DEMO_DATA_SQL = "$Install::GODOT::DISTRIB_DIR/sql/demo_data.sql";

my $db_exists = 0;

my $term = new Term::ReadLine 'GODOT Database Installation';

&show_introduction;

if (&db_exists) {

    printw "A database already exists with the name '", 
           $GODOTConfig::Config::GODOT_DB, 
           "'. Do you want to drop ", 
           "this database before continuing with installation?  If you do not drop the database, installation ", 
           "will continue without database modifications.\n\n** WARNING: dropping the database will lose any ", 
           "content currently stored! **\n\nDrop database?\n";

    my $input = $term->readline("[y/N]: ");
		
    if ($input =~ /^\s*y/i) { &drop_database; } 
    else                    { $db_exists = 1; }
}

exit if $db_exists;    

##
## Create database
##

printw "Creating database.\n\nIf you specifed a database password when installing the GODOTConfig files, you will be asked to enter it again.\n";
my $pw = defined($GODOTConfig::Config::GODOT_PASSWORD) && $GODOTConfig::Config::GODOT_PASSWORD ne '' ? '--password' : '';

my $create_db_command = "createdb --username=$GODOTConfig::Config::GODOT_USER $pw $GODOTConfig::Config::GODOT_DB";

printw "creating the database with:\n\n", "    $create_db_command\n";

my $result = `$create_db_command`;

if ($result !~ /CREATE\sDATABASE/) {
    diew "\n\nError creating database: $result\n\nIf the above error is something like FATAL: IDENT auth failed, " . 
         "you are trying to create the database as a user other than the one you are currently logged in as, " . 
         "and PostgreSQL is set to use 'ident' authentication. See the pg_hba.conf PostgreSQL config file.\n";
}

print "Database created.\n\n";

##
## Create tables
##
		
printw "Creating database tables and seeding database. Ignore the NOTICE: lines.\n", 
       "You may be asked for the password again.\n";

$result = `cat $PACKAGE/sql/*.sql | psql -q --username=$GODOTConfig::Config::GODOT_USER $pw $GODOTConfig::Config::GODOT_DB`;

if ($result =~ /ERROR/) {
    diew "Error creating/seeding database: $result";
}

printw "\n\nDone with basic database setup.\n";

printw "\nInitialize the database with demo profiles?\nCaution - this will trash any data you have already loaded. Load data?";
my $input = $term->readline('[y/N]: ');

if ($input =~ /^\s*y/i) {
    ##
    ## Query for demo values for admin account password and for borrowing and lending email addresses.
    ##
                    
    printw "\nWhat password do you want to use for the 'admin' account?  You may change it later using the GODOT configuration tool.";

    my $password;

    foreach my $count (1 .. 3) {
        $input = $term->readline('Password []: ');
        my $message = &check_password($input);
        if ($message) { 
             printw "\n$message"; 
        }
        else {
            $password = crypt($input, 'admin'); 
            last; 
        }                        
    }

    if (aws($password)) {                    
        diew "\nYou need to enter a valid password for the 'admin' account.";
    }

    printw "\nWhat email address do you want to use for the lending and borrowing email options for the demo profiles?  You may change them later using the GODOT configuration tool.";
    my $email;

    $input = $term->readline('Email [' . $ENV{'GODOT_ADMIN_EMAIL'}  . ']: ');
    if (aws($input)) {
        $email = $ENV{'GODOT_ADMIN_EMAIL'}; 
    }
    else {
        $email = $input;
    }

    if (aws($password)) {                    
        diew "\nYou need to enter a valid email address for the demo profiles.";
    }
 
    unless (&update_demo_data($DEMO_DATA_SQL, $password, $email)) {
        diew "\nUnable to update '$DEMO_DATA_SQL' with specified password and email address.";
    }

    printw "\nLoading demo data to '", $GODOTConfig::Config::GODOT_DB, "'.  This may take a while...\n";

    `cat $DEMO_DATA_SQL | psql -q --username=$GODOTConfig::Config::GODOT_USER $pw $GODOTConfig::Config::GODOT_DB`;

    print "Done!\n";

    printw "\nUpdating site profile cache ...\n";

    `$GODOTConfig::Config::GODOT_ROOT/util/update_cache.pl`;

    printw "\n\n";
}

sub show_introduction {
    print "Configuring GODOT Profile Database\n";
    print "==================================\n";
    printw "This script sets up the configuration profile database and optionally installs demo profile data.\n\nYou may want to run the database install as a different user (ie. postgres) depending on the postgres rights of the current user.\n\n";

}



sub db_exists {

    print "Trying DBI connection...";
		
    my $dbh = DBI->connect("dbi:Pg:dbname=$GODOTConfig::Config::GODOT_DB", $GODOTConfig::Config::GODOT_USER, $GODOTConfig::Config::GODOT_PASSWORD, {'PrintError' => 0});
    if (defined($dbh)) {
	print " found.\n";
	return 1;
    } else {
	print " not found.\n";

	if ($DBI::errstr =~ /database\s".*"\sdoes\snot\sexist/) {
	    return 0;
	}

	if ($DBI::errstr =~ /user\s".*"\sdoes\snot\sexist/) {
	    diew "The user you entered does not exist in the database. Please add the user before attempting to install, ",
                 "or skip the automated database installation.\n";
	}
		
	diew "Unexpected DBI error connecting to database: $DBI::errstr\n";
    }
}	


sub drop_database {

    printw "Dropping database. If you have entered a password above, you will be asked to enter it again.\n";
    my $pw = defined($GODOTConfig::Config::GODOT_PASSWORD) && $GODOTConfig::Config::GODOT_PASSWORD ne '' ? '--password' : '';
    my $result = `dropdb --username=$GODOTConfig::Config::GODOT_USER $pw $GODOTConfig::Config::GODOT_DB`;
    if ($result !~ /DROP\sDATABASE/) {
	diew "Error dropping database: $result";
    }	
}

sub check_password {
    my($string) = @_;

    naws($string)      || return "Password cannot be blank."; 
    ($string !~ m#\s#) || return "Password cannot contain blanks."; 
                        
    my $min_length;
    (length($string) >= $min_length)  || return "Password must be at least $min_length characters long.";                       
    return '';
}

sub update_demo_data {
    my($file, $password, $email) = @_;
		    
    my $backup = "$file.backup";

    printw "\nMaking a backup copy of $file in $backup.\n";

    if (-e $backup)  {
	printw "A copy of $backup already exists. Proceed?";
	my $input = $term->readline('[y/N]: ');
	return $FALSE unless $input =~ /^\s*y/i;
    }

    my $res = `cp '$file' $backup`;
    printw "$res\n", "\n" if ($res);


    use FileHandle;
    my $fh = new FileHandle "< $file";
    unless (defined $fh) { diew "Unable to open $file for reading."; }
    my $content;
    while (<$fh>) {
        s#\{\{admin_password\}\}#$password#g;
        s#\{\{from_email\}\}#$email#g;
        s#\{\{ill_local_system_email\}\}#$email#g;
        s#\{\{request_msg_email\}\}#$email#g;
        $content .= $_;
    }
    $fh->close;   

    $fh = new FileHandle "> $file";
    unless (defined $fh) { diew "Unable to open $file for writing."; }
    print $fh $content;
    $fh->close;   

    return $TRUE;
}


1;

__END__












