# manage DHCP server settings related to audit
class win_dhcp_server::global::audit (
  Boolean $auditlog_enable                            = true,
  String[1] $auditlog_path                            = "${facts['system32']}\\dhcp",
  Integer[0, 4294967295] $auditlog_max_size_mb        = 70, #you can set 0, but might as well turn audit logging off via 'audit_log_enabled'
  Integer[2, 4294967295] $auditlog_diskcheck_interval = 50, #number of events between disk space check, 2 is min, if set 0 itll set back 2
  Integer[0, 4294967295] $auditlog_min_diskspace_mb   = 20,
  Array[String[1]] $exec_resource_tags                = ['win_dhcp_server', 'win_dhcp_server_global', 'win_dhcp_server_audit'],
  Enum['true', 'false', 'onfailure'] $exec_log_output = 'true',
) {
  require win_dhcp_server::prereq::check

  $exec_defaults = {
    'logoutput' => $exec_log_output,
    'provider'  => 'powershell',
    'tag'       => $exec_resource_tags,
  }

  exec { 'win_dhcp_server_auditlog_enable':
    command => epp("${module_name}/global/command-win_dhcp_server_auditlog_enable.ps1.epp", { 'auditlog_enable' => $win_dhcp_server::global::audit::auditlog_enable }),
    unless  => epp("${module_name}/global/unless-win_dhcp_server_auditlog_enable.ps1.epp", { 'auditlog_enable' => $win_dhcp_server::global::audit::auditlog_enable }),
    *       => $exec_defaults,
  }

  exec { 'win_dhcp_server_auditlog_path':
    command => epp("${module_name}/global/command-win_dhcp_server_auditlog_path.ps1.epp", { 'auditlog_path' => $win_dhcp_server::global::audit::auditlog_path }),
    unless  => epp("${module_name}/global/unless-win_dhcp_server_auditlog_path.ps1.epp", { 'auditlog_path' => $win_dhcp_server::global::audit::auditlog_path }),
    *       => $exec_defaults,
  }

  exec { 'win_dhcp_server_auditlog_max_size_mb':
    command => epp("${module_name}/global/command-win_dhcp_server_auditlog_max_size.ps1.epp", { 'auditlog_max_size_mb' => $win_dhcp_server::global::audit::auditlog_max_size_mb }),
    unless  => epp("${module_name}/global/unless-win_dhcp_server_auditlog_max_size.ps1.epp", { 'auditlog_max_size_mb' => $win_dhcp_server::global::audit::auditlog_max_size_mb }),
    *       => $exec_defaults,
  }

  exec { 'win_dhcp_server_auditlog_diskcheck_interval':
    command => epp("${module_name}/global/command-win_dhcp_server_auditlog_diskcheck_interval.ps1.epp", { 'auditlog_diskcheck_interval' => $win_dhcp_server::global::audit::auditlog_diskcheck_interval }),
    unless  => epp("${module_name}/global/unless-win_dhcp_server_auditlog_diskcheck_interval.ps1.epp", { 'auditlog_diskcheck_interval' => $win_dhcp_server::global::audit::auditlog_diskcheck_interval }),
    *       => $exec_defaults,
  }

  exec { 'win_dhcp_server_auditlog_min_diskspace':
    command => epp("${module_name}/global/command-win_dhcp_server_auditlog_min_diskspace.ps1.epp", { 'auditlog_min_diskspace' => $win_dhcp_server::global::audit::auditlog_min_diskspace_mb }),
    unless  => epp("${module_name}/global/unless-win_dhcp_server_auditlog_min_diskspace.ps1.epp", { 'auditlog_min_diskspace' => $win_dhcp_server::global::audit::auditlog_min_diskspace_mb }),
    *       => $exec_defaults,
  }
}