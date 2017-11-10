#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Long;

#Usage:
# perl mon_e2e.pl --mon <df_mon|db_mon> --cmd <esl_cma> --node_name <node>
# perl mon_e2e.pl --mon <df_mon|db_mon> --cmd <esl_cma> --node_list <input_file>

#To be implemented:
#
#perl mon_e2e.pl --check_test --object <event_obj> --node_name <node>
#perl mon_e2e.pl --check_test --object <event_obj> --node_list <input_file>

#SOL/LIN
#ovdeploy -cmd "ls -l /var/opt/OV/log/OpC/df_mon.log" -node nahuelhuapi.transbank.cl | awk '{print $6" "$7" "$8}'
#WIN_2K3_64/MACH_BBC_WINNT_X86
#ovdeploy -cmd 'dir "c:\osit\log\df_mon.log"' -node tksclctxapp09.transbank.local | grep df_mon.log | awk '{print $1" "$2}'
#/var/opt/OpC_local/MIGTOOL/node_list/managed_node_list.09042017_183514.lst


#Init of main func vars
my $r_timeout = "";
my $sol_name = '';
my $r_solution_pol_check = '';
my $r_solution_bin_check = '';
my $csv_node_found = '';
my $csv_node_https = '';
my $csv_node_sol_pol_check = '';
my $csv_node_sol_bin_check = '';
my $csv_is_pref_path = '';
my $csv_rename_file = '';
my $csv_upload_mon_file = '';
my $csv_node_controlled = '';
my $csv_winmon_uxmon_module_exec = '';
my $csv_check_last_mon_log_lines = '';
my $all_csv_line = '';
my $csv_file_header = '';
my $node_mon_cfg_dir = '';
my $node_mon_log_dir = '';
my $node_os = '';
my @r_node_in_om_db = ();
my $node_mach_type = '';
my $r_file_existance_in_path = '';
my $r_check_nodes_prefered_path = '';
my $r_rename_file_routine = '';
my $r_winmon_uxmon_module_exec = '';
my $r_check_last_mon_log_lines = '';
my $r_upload_mon_file = '';
#Init of script parms
my $mon_name = '';
my $cma_obj = 'MON_E2E';
my $cma = '';
my $node_name = '';
my $node_list = '';
my @input_node_list = ();
#Init of script working paths
my $mon_e2e_cfg_file = '';
my $mon_e2e_dir = '/var/opt/OpC_local/MON_E2E';
my $mon_e2e_log_dir = $mon_e2e_dir.'/log';
my $mon_e2e_tmp_dir = $mon_e2e_dir.'/tmp';
my $mon_e2e_csv_dir = $mon_e2e_dir.'/csv';
my $mon_e2e_cfg_dir = $mon_e2e_dir.'/cfg';
my $mon_e2e_cfg_file_dir_df_mon = '';

chomp(my $datetime_stamp = `date "+%m%d%y_%H%M%S"`);
#Create initial directories if nor found
system("mkdir -p $mon_e2e_dir") if (!-d $mon_e2e_dir);
system("mkdir -p $mon_e2e_log_dir") if (!-d $mon_e2e_log_dir);
system("mkdir -p $mon_e2e_tmp_dir") if (!-d $mon_e2e_tmp_dir);
system("mkdir -p $mon_e2e_csv_dir") if (!-d $mon_e2e_csv_dir);
system("mkdir -p $mon_e2e_cfg_dir") if (!-d $mon_e2e_cfg_dir);
#Definition of all available options within script
GetOptions( 'mon|a=s' => \$mon_name,
            'cma|b=s' => \$cma,
            'cmd_timeout|x=i' => \$r_timeout,
            'node_name|y=s' => \$node_name,
            'node_list|z=s' => \$node_list);
#Mon working directories
my $mon_e2e_log_file_dir = $mon_e2e_log_dir.'/'.$mon_name;
my $mon_e2e_csv_file_dir = $mon_e2e_csv_dir.'/'.$mon_name;
my $mon_e2e_cfg_file_dir = $mon_e2e_cfg_dir.'/'.$mon_name;

my $mon_e2e_cfg_file_dir_df = '';

#Create Mon working directories if not found
system("mkdir -p $mon_e2e_log_file_dir") if (!-d $mon_e2e_log_file_dir);
system("mkdir -p $mon_e2e_csv_file_dir") if (!-d $mon_e2e_csv_file_dir);
system("mkdir -p $mon_e2e_cfg_file_dir") if (!-d $mon_e2e_cfg_file_dir);
#Mon specific file names
my $mon_e2e_log_file = $mon_e2e_log_file_dir.'/'.$mon_name.'.'.$datetime_stamp.'.log';
my $mon_e2e_csv_file = $mon_e2e_csv_file_dir.'/'.$mon_name.'.'.$datetime_stamp.'.csv';
#Clean any previous cfg
system("rm -f $mon_e2e_cfg_file_dir/* ");
#Validate that module to test e2e is defined
if (!$mon_name || ($mon_name !~ m/df_mon|db_mon/))
{
  print "--mon|-a parameter missing or invalid.\nExiting script!\n";
  exit 0;
}
#Validate that either a nodename or nodelist has been defined
if (!$node_name && !$node_list)
{
  print "--node_name|-y or --node_list|-z is mandatory.\nExiting script!\n";
  exit 0;
}
#Define a --cmd_timeout if not defined
if(!$r_timeout)
{
  $r_timeout = "3000";
}
#If --node_list is defined validate that file exists
if ($node_list)
{
  open(NODE_LIST, "< $node_list")
    or die "File $node_list does not exists in path!\nExiting script!\n";
  #Load nodes into array
  while(<NODE_LIST>)
  {
    #print "Adding node into array...\n";
    chomp(my $in_csv_line = $_);
    $in_csv_line =~ m/(.*);(.*);(.*);(.*)/;
    chomp(my $in_node_name = $1);
    #print "Node $in_node_name\n";
    push(@input_node_list, $in_node_name);
  }
}
#If --node_name is defined
if($node_name)
{
  chomp($node_name);
  #Load node into array
  #print "Adding node into array...\n";
  @input_node_list = $node_name;
}
print "\nStarting mon_e2e.pl script...\n";
#$csv_file_header = "node_name,node_mach_type,node_in_db,node_https,node_$mon_name\_pol,node_$mon_name\_bin,is_pref_path,rename_$mon_name\_cfg,upload_mon_cfg";
$csv_file_header = "node_name,node_mach_type,node_in_db,node_controlled,node_https,node_$mon_name\_pol,node_$mon_name\_bin,is_pref_path,upload_mon_cfg,mon_exec,mon_alert";
print "\n$csv_file_header\n";
csv_logger($mon_e2e_csv_file, $csv_file_header);
#$all_csv_line = $e_input_node_list.",".$csv_node_found.",".$csv_node_https.",".$csv_node_sol_pol_check.",".$csv_node_sol_bin_check;
#Validate that managed node exists in HPOML
foreach my $e_input_node_list (@input_node_list)
{
  $node_os = "unix";
  $csv_node_controlled = "0";
  @r_node_in_om_db = check_node_in_HPOM($e_input_node_list);
  #If node OK in OM DB
  if($r_node_in_om_db[0] eq "1")
  {
    $csv_node_https = "NA";
    if ($r_node_in_om_db[5] eq "1")
    {
      $csv_node_controlled = "1";
      $csv_node_https = "NOK";
    }
    #print "Node $e_input_node_list FOUND in OM database!\n";
    #Get node's machine type
    $csv_node_found = "OK";
    $node_mach_type = $r_node_in_om_db[3];
    #Validates https comm to node
    my @r_testOvdeploy_HpomToNode_383_SSL = testOvdeploy_HpomToNode_383_SSL($e_input_node_list, $r_timeout);
    #If https comm is OK
    if ($r_testOvdeploy_HpomToNode_383_SSL[0] eq "1")
    {
      $csv_node_https = "OK";
      #When node is Unix-like
      if ($node_mach_type =~ m/MACH_BBC_LX26|MACH_BBC_SOL|MACH_BBC_HPUX|MACH_BBC_AIX/)
      {
        $mon_e2e_cfg_file = "df_mon.cfg";
         if ($mon_name eq "df_mon")
         {
           $sol_name = "uxmon";
           if($cma)
           {
             $cma = '['.$cma_obj.'_'.$datetime_stamp.','.$cma.']';
           }
           else
           {
             $cma = '['.$cma_obj.'_'.$datetime_stamp.']';
           }
           $mon_e2e_cfg_file_dir_df_mon = $mon_e2e_cfg_file_dir.'/'.$mon_e2e_cfg_file;
         }
        #Defines cfg and log prefered paths based in OS type
        #$node_mon_cfg_dir = '/var/opt/OV/conf/OpC/';
        $node_mon_cfg_dir = '/tmp';
        $node_mon_log_dir = '/var/opt/OV/log/OpC/';
      }
      #When node is Windows
      if ($node_mach_type =~ m/MACH_BBC_WIN/)
      {
        $mon_e2e_cfg_file = "df_mon.cfg";
        $node_os = "win";
        if ($mon_name eq "df_mon")
        {
          $sol_name = "winmon";
          if($cma)
          {
            $cma = '['.$cma_obj.'_'.$datetime_stamp.'],['.$cma.']';
            #$cma = "[MON_E2E]";
          }
          else
          {
            $cma = '['.$cma_obj.'_'.$datetime_stamp.']';
            #$cma = "[MON_E2E]";
          }
          $mon_e2e_cfg_file_dir_df_mon = $mon_e2e_cfg_file_dir.'/'.$mon_e2e_cfg_file;
        }
        #Defines cfg and log prefered paths based in OS type
        #$node_mon_cfg_dir = 'c:\osit\etc\\';
        $node_mon_cfg_dir = 'c:\\temp\\';
        $node_mon_log_dir = 'c:\\osit\\log\\';
      }
      #Validates mon policy is enabled
      $r_solution_pol_check = solution_pol_check($e_input_node_list, $sol_name, $mon_name);
      $csv_node_sol_pol_check = "OK" if ($r_solution_pol_check eq "0");
      $csv_node_sol_pol_check = "NA" if ($r_solution_pol_check eq "2");
      #Validates mon bin is found
      $r_solution_bin_check = solution_bin_check($e_input_node_list, $sol_name, $mon_name);
      $csv_node_sol_bin_check = "OK" if ($r_solution_bin_check eq "0");
      #When mon policy solution is found and enabled and mon bin was found build test cfg file based on module to test
      $csv_winmon_uxmon_module_exec = "NA";
      $csv_check_last_mon_log_lines = "NA";
      $csv_upload_mon_file = "NA";
      if(($r_solution_pol_check eq "0") && ($r_solution_bin_check eq "0"))
      {
        build_df_mon_cfg_file($mon_e2e_cfg_file_dir, $node_os, $cma);
        $cma = "";
        #Check if prefered path exists within a managed node
        $csv_is_pref_path = "NOK";
        $r_check_nodes_prefered_path = check_nodes_prefered_path($e_input_node_list, $node_os, $node_mon_cfg_dir);
        if ($r_check_nodes_prefered_path eq "0")
        {
          $csv_is_pref_path = "OK";
        }
        #If prefered path is found
        if ($csv_is_pref_path eq "OK")
        {
          #Check if within a managed node prefered path, exists a mon.cfg file
          $r_file_existance_in_path = file_existance_in_path($e_input_node_list, $node_os, $node_mon_cfg_dir, $mon_e2e_cfg_file);

          #Make upload of test mon cfg whether if a previous file was renamed OK or if file was not in prefered path
          $csv_upload_mon_file = "NOK";
          #Filename: xxx_mon.cfg.[win|unix]
          $r_upload_mon_file = upload_mon_file($e_input_node_list, $node_os, $mon_name.'.cfg', $mon_e2e_cfg_file_dir, $node_mon_cfg_dir, $r_timeout);
          if ($r_upload_mon_file eq "0")
          {
            $csv_upload_mon_file = "OK";
          }
          #Execute MON module using test xxx_mon.cfg if file's upload is OK or file is already within working directory
          if (($csv_upload_mon_file eq "OK"))
          {
            $r_winmon_uxmon_module_exec = winmon_uxmon_module_exec($e_input_node_list, $node_os, $mon_name, $node_mon_cfg_dir);
            $csv_winmon_uxmon_module_exec = "NOK";
            if ($r_winmon_uxmon_module_exec eq "0")
            {
              $csv_winmon_uxmon_module_exec = "OK";
              $csv_check_last_mon_log_lines = "NOK";
              $r_check_last_mon_log_lines = check_last_mon_log_lines($e_input_node_list, $node_os, $mon_name, $cma_obj.'_'.$datetime_stamp);
              if($r_check_last_mon_log_lines eq "0")
              {
                $csv_check_last_mon_log_lines = $cma_obj.'_'.$datetime_stamp;
              }
              if($r_check_last_mon_log_lines eq "2")
              {
                $csv_check_last_mon_log_lines = "NO_READ_BIN";
              }
            }
          }
        }
      }
    }
    else
    {
      #$csv_node_https = "NOK";
      $csv_node_sol_pol_check = "NA";
      $csv_node_sol_bin_check = "NA";
      $csv_is_pref_path = "NA";
      $csv_rename_file = "NA";
      $csv_upload_mon_file = "NA";
      $csv_winmon_uxmon_module_exec = "NA";
      $csv_check_last_mon_log_lines = "NA";
    }
  }
  else
  {
    $node_mach_type = "NA";
    $csv_node_controlled = "NA";
    if(($r_node_in_om_db[0] eq "1") && ($r_node_in_om_db[5] eq "0"))
    {
      $csv_node_controlled = "0"
    }
    $csv_node_https = "NA";
    $csv_node_sol_pol_check = "NA";
    $csv_node_sol_bin_check = "NA";
    $csv_is_pref_path = "NA";
    $csv_rename_file = "NA";
    $csv_upload_mon_file = "NA";
    $csv_winmon_uxmon_module_exec = "NA";
    $csv_check_last_mon_log_lines = "NA";
  }
  #Joins in a single string all validation test results
  #$all_csv_line = $e_input_node_list.",".$node_mach_type.",".$csv_node_found.",".$csv_node_https.",".$csv_node_sol_pol_check.",".$csv_node_sol_bin_check.",".$csv_is_pref_path.",".$csv_rename_file.",".$csv_upload_mon_file;
  $all_csv_line = $e_input_node_list.",".$node_mach_type.",".$csv_node_found.",".$csv_node_controlled.",".$csv_node_https.",".$csv_node_sol_pol_check.",".$csv_node_sol_bin_check.",".$csv_is_pref_path.",".$csv_upload_mon_file.",".$csv_winmon_uxmon_module_exec.",".$csv_check_last_mon_log_lines;
  print "$all_csv_line\n";
  #Joins in a single string all validation test results
  csv_logger($mon_e2e_csv_file, $all_csv_line);
}
print "\nScript logfile: $mon_e2e_csv_file\n\n";

######################################################################
#Script subroutines
######################################################################
######################################################################
# Sub that checks if a managed node is within a HPOM and if found determine its ip_address, node_net_type, mach_type
#	@Parms:
#		$nodename : Nodename to check
#	Return:
#		@node_mach_type_ip_addr = (node_exists, node_ip_address, node_net_type, node_mach_type, comm_type, is_node_controlled)	:
#															[0|1],
#															[<ip_addr>],
#															[NETWORK_NO_NODE|NETWORK_IP|NETWORK_OTHER|NETWORK_UNKNOWN|PATTERN_IP_ADDR|PATTERN_IP_NAME|PATTERN_OTHER],
#															[MACH_BBC_LX26|MACH_BBC_SOL|MACH_BBC_HPUX|MACH_BBC_AIX|MACH_BBC_WIN|MACH_BBC_OTHER],
#                             [COMM_UNSPEC_COMM|COMM_BBC]
#                             [0,1]
#		$node_mach_type_ip_addr[0] = 0: If nodename is not found within HPOM
#   $node_mach_type_ip_addr[0] = 1: If nodename is found within HPOM
######################################################################
sub check_node_in_HPOM
{
  my $nodename = shift;
	my $nodename_exists = 0;
	my @node_mach_type_ip_addr = ();
  my @is_controlled = ();
	my ($node_ip_address, $node_mach_type, $node_net_type, $node_comm_type, $is_node_controlled) = ("", "", "", "", "");
	my @opcnode_out = qx{opcnode -list_nodes node_list=$nodename};
	foreach my $opnode_line_out (@opcnode_out)
	{
		chomp($opnode_line_out);
		if ($opnode_line_out =~ /^Name/)
		{
			$nodename_exists = 1;					# change to 0 if node is found
      push (@node_mach_type_ip_addr, $nodename_exists);
		}
		if ($opnode_line_out =~ m/IP-Address/)
		{
			$opnode_line_out =~ m/.*=\s(.*)/;
			$node_ip_address = $1;
			chomp($node_ip_address);
			push (@node_mach_type_ip_addr, $node_ip_address);
		}
		if ($opnode_line_out =~ m/Network\s+Type/)
		{
			$opnode_line_out =~ m/.*=\s(.*)/;
			$node_net_type = $1;
			chomp($node_net_type);
			push (@node_mach_type_ip_addr, $node_net_type);
		}
		if ($opnode_line_out =~ m/MACH_BBC_LX26|MACH_BBC_SOL|MACH_BBC_HPUX|MACH_BBC_AIX|MACH_BBC_WIN|MACH_BBC_OTHER/)
		{
			$opnode_line_out =~ m/.*=\s(.*)/;
			$node_mach_type = $1;
			chomp($node_mach_type);
			push (@node_mach_type_ip_addr, $node_mach_type);
		}
    if ($opnode_line_out =~ m/Comm\s+Type/)
    {
      $opnode_line_out =~ m/.*=\s(.*)/;
			$node_comm_type = $1;
			chomp($node_comm_type);
			push (@node_mach_type_ip_addr, $node_comm_type);
    }
	}
	# Nodename not found
	if ($nodename_exists eq 0)
	{
		$node_mach_type_ip_addr[0] = 0;
	}
  #Determine if whether node is controlled
  else
  {
    $is_node_controlled = "0";
    if ($node_mach_type_ip_addr[3] !~ m/MACH_BBC_OTHER_IP|MACH_BBC_OTHER_NON_IP/)
    {
      $is_node_controlled = "1";
      @is_controlled = qx{/opt/OV/bin/OpC/call_sqlplus.sh all_nodes | grep -i $node_mach_type_ip_addr[1]};
      foreach my $r_is_controlled (@is_controlled)
      {
        chomp($r_is_controlled);
        print "sql: $r_is_controlled\n";
        if($r_is_controlled =~ m/Msg Allowed/)
        {
          $is_node_controlled = "0";
        }
      }
    }
    push (@node_mach_type_ip_addr, $is_node_controlled);
  }
  return @node_mach_type_ip_addr;
}
#########################################################
# Sub that checks node's port 383 from HPOM
# @Parms:
#   $nodename:              Nodename
#   $HPOM:                  HPOM FQDN
# Return:
#   1:                      OK
#   0:                      Timed out/Unavailable
###########################################################
sub testOvdeploy_HpomToNode_383_SSL
{
  my ($nodename, $cmdtimeout) = @_;
  my $eServiceOK_found = 1;
  my @remote_bbcutil_ping_node = qx{ovdeploy -cmd bbcutil -par \"-ping https://$nodename\" -ovrg server -cmd_timeout $cmdtimeout};
  foreach my $bbcutil_line_out (@remote_bbcutil_ping_node)
  {
    chomp($bbcutil_line_out);
    if ($bbcutil_line_out =~ m/eServiceOK/)
    {
      last;
    }
    if ($bbcutil_line_out =~ m/^ERROR:/)
    {
      $eServiceOK_found = 0;                                  # change to 1 if error while making test
      last;
    }
  }
  return $eServiceOK_found;
}
#########################################################
# Sub that checks solution's policy to test
# @Parms:
#   $nodename:              Nodename
#   $solution_name:         Solution code name [winmon|uxmon]
#   $solution_mod           Solution module [df_mon|db_mon|...]
# Return:
#   0:                      policy enabled
#   1:                      policy disabled
#   2:                      policy not found
###########################################################
sub solution_pol_check
{
  my ($node_name, $solution_name, $solution_mod) = @_;
  my $mon_pol_name = "";
  if ($solution_mod eq "df_mon")
  {
    $mon_pol_name = "Diskspace-Monitor" if ($solution_name eq "winmon");
    $mon_pol_name = "UXMON_dfmon_" if ($solution_name eq "uxmon");
  }
  my @ovpolicy_check_pol = qx/ovpolicy -list -host $node_name | grep $mon_pol_name/;
  foreach my $r_ovpolicy_check_pol (@ovpolicy_check_pol)
  {
    if ($r_ovpolicy_check_pol =~ m/enabled/)
    {
      return 0;
    }
    if ($r_ovpolicy_check_pol =~ m/disabled/)
    {
      return 1;
    }
  }
  return 2;
}

#########################################################
# Sub that checks solution's bin to perform test
# @Parms:
#   $nodename:              Nodename
#   $solution_name:         Solution code name [winmon|uxmon]
#   $solution_mod           Solution module [df_mon|db_mon|...]
# Return:
#   0:                      policy enabled
#   1:                      policy disabled
#   2:                      policy not found
###########################################################
sub solution_bin_check
{
  my ($node_name, $solution_name, $solution_mod) = @_;
  my $df_mon_bin_name = '';
  my $node_os_instrum = '';
  my $cmd_bin_check = '';
  my @ovpolicy_check_bin = ();
  if ($solution_mod eq "df_mon")
  {
    if ($solution_name eq "winmon")
    {
      $df_mon_bin_name = "df_mon.exe";
      $node_os_instrum = '%ovdatadir%\bin\instrumentation\\';
      $cmd_bin_check = "\'dir \"$node_os_instrum\"\'";
    }
    if ($solution_name eq "uxmon")
    {
      $node_os_instrum = '/var/opt/OV/bin/instrumentation/';
      $df_mon_bin_name = "UXMONbroker";
      $cmd_bin_check = "\"ls -l $node_os_instrum\"";
    }
  }
  @ovpolicy_check_bin = qx/ovdeploy -cmd $cmd_bin_check -node $node_name | grep -i $df_mon_bin_name/;
  foreach my $r_ovpolicy_check_pol (@ovpolicy_check_bin)
  {
    if ($r_ovpolicy_check_pol =~ m/$df_mon_bin_name/)
    {
      return 0;
    }
  }
  return 1;
}

#########################################################
#########################################################
sub build_df_mon_cfg_file
{
  my ($mon_cfg_tmpl_dir, $node_os, $cma) = @_;
  my $cfg_filename = "df_mon.cfg";
  system("rm -f $mon_cfg_tmpl_dir/$cfg_filename > /dev/null");
  #print "$mon_cfg_tmpl_dir/$cfg_filename\n";
  my $cfg_filesystem = "/";
  my $cfg_test_line = "$cfg_filesystem\t1%\t-\twarning";
  if ($node_os eq "win")
  {
    #$cfg_filename = "df_mon.cfg.win";
    $cfg_filesystem = "\"C:\\\"";
    $cfg_test_line = "$cfg_filesystem\tWarning\t99\t%\t*\t0000\t2400\tT";
  }
  open(DF_MON_CFG_TEMPL, "> $mon_cfg_tmpl_dir/$cfg_filename")
    or die "Cannot write to file '$mon_cfg_tmpl_dir/$cfg_filename\n'";
  print DF_MON_CFG_TEMPL "################################################################################\n";
  print DF_MON_CFG_TEMPL "#THIS IS TEST CFG TEMPLATE\n";
  print DF_MON_CFG_TEMPL "#SHOULD NOT BE USED FOR PRODUCTION\n";
  print DF_MON_CFG_TEMPL "################################################################################\n";
  print DF_MON_CFG_TEMPL "INTERVAL = 5\n" if ($node_os eq "win");
  print DF_MON_CFG_TEMPL "DEFAULT_ALERT_TYPE      = T\n" if ($node_os eq "win");
  print DF_MON_CFG_TEMPL "MON_TYPE                = LOGFILE\n" if ($node_os eq "win");
  print DF_MON_CFG_TEMPL "HOUSE_KEEPING           = OVERWRITE_MONTHLY\n" if ($node_os eq "win");
  print DF_MON_CFG_TEMPL "DURATION                = 0\n" if ($node_os eq "win");
  print DF_MON_CFG_TEMPL "REPEAT                  = YES\n" if ($node_os eq "win");
  print DF_MON_CFG_TEMPL "$cma\n";
  print DF_MON_CFG_TEMPL "$cfg_test_line\n";
  print DF_MON_CFG_TEMPL "################################################################################\n";
  print DF_MON_CFG_TEMPL "#THIS IS TEST CFG TEMPLATE\n";
  print DF_MON_CFG_TEMPL "#SHOULD NOT BE USED FOR PRODUCTION\n";
  print DF_MON_CFG_TEMPL "################################################################################\n";
}

#########################################################
#########################################################
sub csv_logger
{
  my ($logfilename_with_path, $entry_to_log) = @_;
  open (MYFILE, ">> $logfilename_with_path")
   or die("File not found: $logfilename_with_path");
  print MYFILE "$entry_to_log\n";
  close (MYFILE);
}

#########################################################
#Sub to check the existance of a file within the OS fs
#Parms:   $node_name:   nodename
#         $os_family:   windows|unix
#         $file_path:   path of file to verify
#         $file_name:   name of file to verify
#Return:  $file_exists_in_path:   0 --> file does not exists in path
#                                 1 --> file exists in path
#########################################################
sub file_existance_in_path
{
  my ($node_name, $node_os, $file_path, $file_name) = @_;
  my $cmd_check_file = "ovdeploy -cmd if -par \"[ -f $file_path/$file_name ]; then echo FOUND $file_name !;else echo NOT_FOUND $file_name;fi\" -host $node_name";
  my @check_file_cmd = qx{};
  my $check_file_cmd_line = '';
  my $file_exists_in_path = '0';
  if ($node_os eq "win")
  {
    $cmd_check_file = "ovdeploy -cmd if -par \"exist $file_path\\$file_name (echo FOUND $file_name) else (echo NOT_FOUND $file_name)\" -host $node_name";
  }
  @check_file_cmd = qx/$cmd_check_file/;
  foreach $check_file_cmd_line (@check_file_cmd)
  {
    chomp($check_file_cmd_line);
    #print "$check_file_cmd_line";
    if ($check_file_cmd_line =~ m/^FOUND/)
    {
      $file_exists_in_path = "1";
      last;
    }
  }
  return $file_exists_in_path;
}

#########################################################
# Sub that checks if the monitoring solutions prefered path exists
# Parms:      $node_name
#             $node_os
#             $file_path
# Return:     0   -->dir FOUND
#             1   -->dir NOT FOUND
#########################################################
sub check_nodes_prefered_path
{
  my ($node_name, $node_os, $dir_path) = @_;
  my $cmd_check_dir = "ovdeploy -cmd if -par \"[ -d $dir_path ]; then echo FOUND $dir_path;else echo NOT_FOUND $dir_path;fi\" -host $node_name";
  my @check_dir_cmd = ();
  my $dir_exists = "0";
  if ($node_os eq "win")
  {
    $cmd_check_dir = "ovdeploy -cmd if -par \"exist $dir_path (echo FOUND $dir_path) else (echo NOT_FOUND $dir_path)\" -host $node_name";
  }
  @check_dir_cmd = qx/$cmd_check_dir/;
  foreach my $check_dir_cmd_line (@check_dir_cmd)
  {
    chomp($check_dir_cmd_line);
    #print "$check_file_cmd_line";
    if ($check_dir_cmd_line =~ m/^NOT_FOUND/)
    {
      $dir_exists = '1';
      last;
    }
    if ($check_dir_cmd_line =~ m/\s+/)
    {
      last;
    }
  }
return $dir_exists;
}

#########################################################
#Sub that renames a file
#Parms:   $logfilename_with_path:   logfile with path where entry will be logged
#         $filename_path_one:       Original target filename + path
#         $filename_path_two:       Backup target filename + path
#         $nodename:                Nodename
#         $node_os:                 Nodes OS
#Return:  $return_code              0   --> file renaming OK
#                                   1   --> file renaming NOK
#########################################################
sub rename_file_routine
{
  my ($nodename, $node_os, $file_path_one, $file_path_two, $filename, $filename_new) = @_;
  my $cmd_rename_file = "ovdeploy -cmd \'mv \"$file_path_one$filename\" \"$file_path_two$filename_new\"\' -node $nodename";
  my @rename_cmd = ();
  #print "$node_os\n";
  my $return_code = "1";
  if ($node_os eq "win")
  {
      $cmd_rename_file = "ovdeploy -cmd \'rename \"$file_path_one$filename\" \"$filename_new\"\' -node $nodename";
  }
  #print "$cmd_rename_file\n";
  @rename_cmd = qx/$cmd_rename_file/;
  foreach my $rename_cmd_line (@rename_cmd)
  {
    chomp($rename_cmd_line);
    if ($rename_cmd_line eq "")
    {
      $return_code = "0";
      last;
    }
  }
  return $return_code;
}

#########################################################
#Sub that uploads a file to a target dir within a managed node
#Parms:   $nodename
#         $up_filename
#         $sd_up_file
#         $td_up_file
#         $timeout
#Return:  0   --> file upload OK
#         1   --> file upload NOK
#########################################################
sub upload_mon_file
{
  my ($nodename, $node_os, $up_filename, $sd_up_file, $td_up_file, $timeout) = @_;
  chomp(my $HPOM = `hostname`);
  my $test_line = '';
  if ($node_os eq "win")
  {
    $test_line = "ovdeploy -cmd \'del /f /q \"$td_up_file$up_filename\"\' -node $nodename > /dev/null\n";
  }
  else
  {
    $test_line = "ovdeploy -cmd \"rm -f $td_up_file/$up_filename\" -node $nodename > /dev/nul\n";
    #system("ovdeploy -cmd \"rm -f $td_up_file\" -node $nodename > /dev/null");
  }
  system("$test_line");
  #print "ovdeploy -cmd \"ovdeploy -upload -file $up_filename -sd $sd_up_file -td \'$td_up_file\' -node $nodename\" -node $HPOM -cmd_timeout $timeout\n";
	my @upload_cmd = qx{ovdeploy -cmd \"ovdeploy -upload -file $up_filename -sd $sd_up_file -td \'$td_up_file\' -node $nodename\" -node $HPOM -cmd_timeout $timeout};
  foreach my $upload_cmd_line (@upload_cmd)
  {
    chomp($upload_cmd_line);
  }
	if ($? eq "0")
	{
  return 0;
	}
  return 1;
}

#########################################################
#Sub that executes mon main binary to trigger an alert
#Parms:   $node_name
#         $node_mach_type
#         $solution_mod
#Return:  0   --> execution OK
#         1   --> execution NOK
#########################################################
sub winmon_uxmon_module_exec
{
  my ($node_name, $node_os, $solution_mod, $mon_test_cfg_path) = @_;
  my $mon_test_cfg_file = $mon_test_cfg_path.$solution_mod.'.cfg';
  my $cmd_mod_exec = '\''."$solution_mod -f -c \"$mon_test_cfg_file\"".'\'';
  if($node_os eq "unix")
  {
    $mon_test_cfg_file = $mon_test_cfg_path.'/'.$solution_mod.'.cfg';
    $solution_mod =~ s/_//;
    $cmd_mod_exec = '"'."/var/opt/OV/bin/instrumentation/UXMONbroker -d $solution_mod -f -c $mon_test_cfg_file".'"';
  }
  #print "ovdeploy -cmd $cmd_mod_exec -node $node_name\n";
  my @mon_mod_exec = qx{ovdeploy -cmd $cmd_mod_exec -node $node_name};
  foreach my $r_mon_mod_exec (@mon_mod_exec)
  {
    chomp($r_mon_mod_exec);
    #print "$r_mon_mod_exec\n";
    if ($r_mon_mod_exec =~ m/^Starting|UXMONdfmon is running now/)
    {
      #print "$r_mon_mod_exec\n";
      #print "Matched!\n";
      return 0;
    }
  }
  return 1;
}

#########################################################
#Sub that checks whether an mon alert tine found using one-time-cma
#Parms:   $node_name
#         $node_os
#         $solution_mod
#         $cma_log_check
#
#Return:  0   --> alert found
#         1   --> bin to read log not found
#         2   --> alert not found
#########################################################
sub check_last_mon_log_lines
{
  my ($node_name, $node_os, $solution_mod, $cma_log_check) = @_;
  my $sol_log_file = $solution_mod.'.log';
  my @cmd_to_read = qw/type/;
  my @cmd_read_ov = ();
  my $alert_line = '';
  my @ovdeploy_read_cmd = ();
  my $ovdeploy_read_cmd_string = "ovdeploy -cmd \'$cmd_to_read[0] \"c:\\osit\\log\\$sol_log_file\"\' -node $node_name";
  if($node_os eq "unix")
  {
    @cmd_to_read = qw/cat strings/;
    foreach my $r_cmd_to_read (@cmd_to_read)
    {
      chomp($r_cmd_to_read);
      @ovdeploy_read_cmd = qx{ovdeploy -cmd "whereis $r_cmd_to_read" -node $node_name};
      foreach my $r_ovdeploy_read_cmd (@ovdeploy_read_cmd)
      {
        chomp($r_ovdeploy_read_cmd);
        #print "$r_ovdeploy_read_cmd\n";
        if ($r_ovdeploy_read_cmd =~ m/\/bin\/$r_cmd_to_read/)
        {
          @cmd_to_read = ();
          $cmd_to_read[0] = $r_cmd_to_read;
          last;
        }
      }
    }
    $ovdeploy_read_cmd_string = "ovdeploy -cmd \"$cmd_to_read[0] /var/opt/OV/log/OpC/$sol_log_file\" -node $node_name";
  }
  if (!$cmd_to_read[0])
  {
    #If no bin to read lofile
    return 2;
  }
  else
  {
    @cmd_read_ov = qx{$ovdeploy_read_cmd_string};
    foreach my $r_cmd_read_ov (@cmd_read_ov)
    {
      chomp($r_cmd_read_ov);
      #print "$r_cmd_read_ov\n";
      if($r_cmd_read_ov =~ m/$cma_log_check/)
      {
        #print "$cma_log_check\n";
        $alert_line = $r_cmd_read_ov;
        last;
      }
    }
    #If alert associated to one-time-only cma found
    return 0;
  }
  #If alert associated to one-time-only cma NOT found
  return 1;
}

#########################################################
#Sub that gets the monitored db instances and return the name of first one
#for testing purposes
#Parms:   $node_name
#         $timeout
#
#Return:  $dbmon_config_instances[0]
#         1   --> no instances found
#########################################################
sub get_dbmon_instances
{
	my $node_name = $_[0];
	my $return_code = "0";
	my @dbmon_config_instances;
	my @dbmon_check_conf = qx{ovdeploy -cmd \"dbspicfg -e\" -node $node_name};
	foreach my $config_out (@dbmon_check_conf)
	{
		chomp($config_out);
		if ($config_out =~ m/ERROR/)
		{
			$return_code = "1";
			last;
		}
		if ($config_out =~ m/.*DATABASE\s+?\"(.*)\"\s+?CONNECT.*/i)
		{
			my $instance = $1;
			chomp($instance);
			push(@dbmon_config_instances, $instance);
		}
	}
	if ($return_code eq "1")
	{
		logger("get_dbmon_instances\(\): ".$nodename, $BIMBO_DBMON_LOG."/".$FILENAME.".log", \@dbmon_check_conf);
		return 1;
	}
	else
	{
		return $dbmon_config_instances[0];
	}
}



#########################################################
#SQL: all_nodes.sql
#########################################################
#REM ***********************************************************************
#REM File:        all_nodes.sql
#REM Description: SQL*Plus report that shows all nodes in the node bank
#REM Language:    SQL*Plus
#REM Package:     HP OpenView Operations for Unix
#REM
#REM (c) Copyright Hewlett-Packard Co. 1993 - 2004
#REM ***********************************************************************
#
#column nn_node_name format A80 truncate
#column label format A25 truncate
#column nodetype format A12
#column isvirtual format A3
#column licensetype format A3
#column hb_flag format A4
#column hb_type format A6
#column hb_agent format A3
#
#        set heading off
#        set echo off
#        set linesize 150
#        set pagesize 0
#        set feedback off
#        set newpage 0;
#        ttitle off;
#
#select '                                   HPOM Report' from dual;
#select '                                   -----------' from dual;
#select ' '  from dual;
#select 'Report Date: ',substr(TO_CHAR(SYSDATE,'DD-MON-YYYY'),1,20) from dual;
#select ' '  from dual;
#select 'Report Time: ',substr(TO_CHAR(SYSDATE,'HH24:MI:SS'),1,20) from dual;
#select ' '  from dual;
#select 'Report Definition:' from dual;
#select '' from dual;
#select '  User:          opc_adm' from dual;
#select '  Report Name:   Nodes Overview' from dual;
#select '  Report Script: /etc/opt/OV/share/conf/OpC/mgmt_sv/reports/C/all_nodes.sql' from dual;
#select ' '  from dual;
#select ' '  from dual;
#
#select '                                                                                                                                <--Heartbeat-->' from dual;
#select 'Node                                                                             Machine Type              Node Type    Lic Vir Flag Type   Agt' from dual;
#select '-------------------------------------------------------------------------------- ------------------------- ------------ --- --- ---- ------ ---' from dual;
#select
#        nn.node_name as nn_node_name,
#        nm.machine_type_str as label,
#        DECODE(no.node_type, 0, 'Not in Realm', 1, 'Unmanaged', 2,
#        'Controlled', 3, 'Monitored', 4, 'Msg Allowed', 'Unknown') as nodetype,
#        DECODE((select 1 from opc_mgmtsv_config m
#                where exists (select 1 from opc_license_info l,
#                              opc_node_names n2
#                    where  l.node_id = nn.node_id
#                    and    plugin_id = 'ovoagt'
#                    and    num_instances > 0
#                    and    m.node_id = n2.node_id
#                    and    n2.node_name = l.license_mgr)), 1,'YES','NO'),
#        DECODE(no.is_virtual, 0, 'NO', 1, 'YES', 'YES') as isvirtual,
#        DECODE(no.heartbeat_flag, 0, 'NO', 'YES ') as hb_flag,
#        DECODE(mod(no.heartbeat_type,4), 0, 'None', 1, 'RPC', 2, 'Ping',
#               'Normal') as hb_type,
#        DECODE(floor(no.heartbeat_type/4), 0, 'NO', 'YES') as hb_agent
#  from
#        opc_nodes       no,
#        opc_node_names  nn,
#        opc_net_machine nm
#  where
#        no.node_id      = nn.node_id
#  and   nn.network_type = nm.network_type
#  and   no.machine_type = nm.machine_type
#order by
#  nn_node_name;
#
#  select
#        np.pattern as nn_node_name,
#        'Node for ext. events'   as label,
#        DECODE(no.node_type, 0, 'Not in Realm', 1, 'Unmanaged', 2,
#               'Controlled', 3, 'Monitored', 4, 'Msg Allowed ', 'Unknown') as nodetype,
#        'NO ' as licensetype,
#        '---','--- ', '------','---'
#  from
#        opc_nodes        no,
#        opc_node_pattern np
#  where
#        no.node_id      = np.pattern_id
#order by
#  nn_node_name;
#
#quit;

#dbmon_save.store
#ARMSTATE DatabaseType=MSSQL Instance=rbclsclsms01 Metric=233 Option=ReportServer CURRENT_STATUS=MAJOR
#ARMSTATE DatabaseType=MSSQL Instance=rbclsclsms01 Metric=233 Option=ReportServer LASTALERT=2017-11-06 14:19:06
#ARMSTATE DatabaseType=MSSQL Instance=rbclsclsms01 Metric=233 Option=ReportServerTempDB CURRENT_STATUS=MAJOR
#ARMSTATE DatabaseType=MSSQL Instance=rbclsclsms01 Metric=233 Option=ReportServerTempDB LASTALERT=2017-11-06 14:19:07
#ARMSTATE DatabaseType=MSSQL Instance=rbclsclsms01 Metric=233 Option=SMS_SAG CURRENT_STATUS=MAJOR
#ARMSTATE DatabaseType=MSSQL Instance=rbclsclsms01 Metric=233 Option=SMS_SAG LASTALERT=2017-11-06 14:19:07
#ARMSTATE DatabaseType=MSSQL Instance=rbclsclsms01 Metric=233 Option=SUSDB CURRENT_STATUS=MAJOR
#ARMSTATE DatabaseType=MSSQL Instance=rbclsclsms01 Metric=233 Option=SUSDB LASTALERT=2017-11-06 14:19:07
#ARMSTATE DatabaseType=MSSQL Instance=rbclsclsms01 Metric=233 Option=master CURRENT_STATUS=MAJOR
#ARMSTATE DatabaseType=MSSQL Instance=rbclsclsms01 Metric=233 Option=master LASTALERT=2017-11-06 14:19:09
#ARMSTATE DatabaseType=MSSQL Instance=rbclsclsms01 Metric=233 Option=model CURRENT_STATUS=MAJOR
#ARMSTATE DatabaseType=MSSQL Instance=rbclsclsms01 Metric=233 Option=model LASTALERT=2017-11-06 14:19:10
#ARMSTATE DatabaseType=MSSQL Instance=rbclsclsms01 Metric=233 Option=msdb CURRENT_STATUS=MAJOR
#ARMSTATE DatabaseType=MSSQL Instance=rbclsclsms01 Metric=233 Option=msdb LASTALERT=2017-11-06 14:19:10
