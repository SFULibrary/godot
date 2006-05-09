package password;

use vars qw($TRUE $FALSE);

use GODOT::String;
require parse;
require hold_tab;

$TRUE  = 1;
$FALSE = 0;

my $PASSWORD_ALL          = 'ALL';
my $PASSWORD_JOURNAL_ONLY = 'JOURNAL';
my $PASSWORD_MONO_ONLY    = 'MONO';
my $PASSWORD_NOT_REQUIRED = 'NOT_REQUIRED';



sub use_password {
    my($config, $citation) = @_;

    #### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!! testing only !!!!!!!!!!!!!!!!!!!!!!!!!!
    #### return $TRUE;

    my $use_password = $FALSE;

    if ($config->password_needed eq $PASSWORD_ALL) {

        $use_password = $TRUE;
    }
    elsif ($citation->is_mono && ($config->password_needed eq $PASSWORD_MONO_ONLY))  {
   
        $use_password = $TRUE;  
    }
    elsif ((! $citation->is_mono) && ($config->password_needed eq $PASSWORD_JOURNAL_ONLY))  {      

        $use_password = $TRUE;  
    }

    if ($use_password) {

         if (naws($config->password_value)) {
             return $TRUE; 
         }
         else {
             &glib::send_admin_email("$0: password checking is turned on but password is blank");
         
         } 
    }

    return $FALSE;
}

sub check_password {
    my($password, $config) = @_;

    #### !!!!!!!!!!!!!!!!!!!!!!!!!!!!!! testing only !!!!!!!!!!!!!!!!!!!!!!!!!!
    #### return $TRUE;


    return (strip_white_space($password) eq strip_white_space($config->password_value)); 

}



##--------------------------------------------------------------------------------------------------------------------------------

1;
