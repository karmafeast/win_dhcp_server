class win_dhcp_server::global::database (
  String[1] $database_filename                        = "${facts['system32']}\\dhcp\\dhcp.mdb",
  String[1] $database_backup_path                     = "${facts['system32']}\\dhcp\\backup",
  Integer[1, 71582] $database_backup_interval_min     = 30,
  Integer[1, 71582] $database_cleanup_interval_min    = 60,
  Array[String[1]] $exec_resource_tags                = ['win_dhcp_server', 'win_dhcp_server_global', 'win_dhcp_server_database'],
  Enum['true', 'false', 'onfailure'] $exec_log_output = 'true',
) {
  require win_dhcp_server::prereq::check

  $exec_defaults = {
    'logoutput' => $exec_log_output,
    'provider'  => 'powershell',
    'tag'       => $exec_resource_tags,
  }


  #1./set Database options.

  exec { "win_dhcp_server_database_filename":
    command => epp("${module_name}/global/command-win_dhcp_server_database_filename.ps1.epp", { 'dbpath' => $win_dhcp_server::database_filename }),
    unless  => epp("${module_name}/global/unless-win_dhcp_server_database_filename.ps1.epp", { 'dbpath' => $win_dhcp_server::database_filename }),
    *       => $exec_defaults,
  }

  exec { "win_dhcp_server_backup_path":
    command => epp("${module_name}/global/command-win_dhcp_server_backup_path.ps1.epp", { 'backuppath' => $win_dhcp_server::database_backup_path }),
    unless  => epp("${module_name}/global/unless-win_dhcp_server_backup_path.ps1.epp", { 'backuppath' => $win_dhcp_server::database_backup_path }),
    *       => $exec_defaults,
  }

  exec { "win_dhcp_server_database_backup_interval":
    command => epp("${module_name}/global/command-win_dhcp_server_database_backup_interval.ps1.epp", { 'backup_interval' => $win_dhcp_server::database_backup_interval_min }),
    unless  => epp("${module_name}/global/unless-win_dhcp_server_database_backup_interval.ps1.epp", { 'backup_interval' => $win_dhcp_server::database_backup_interval_min }),
    *       => $exec_defaults,
  }

  exec { "win_dhcp_server_database_cleanup_interval":
    command => epp("${module_name}/global/command-win_dhcp_server_database_cleanup_interval.ps1.epp", { 'cleanup_interval' => $win_dhcp_server::database_cleanup_interval_min }),
    unless  => epp("${module_name}/global/unless-win_dhcp_server_database_cleanup_interval.ps1.epp", { 'cleanup_interval' => $win_dhcp_server::database_cleanup_interval_min }),
    *       => $exec_defaults,
  }
}