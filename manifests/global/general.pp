class win_dhcp_server::global::general (
  Boolean $nap_enable                                            = false,
  Enum['Full', 'Restricted', 'NoAccess'] $nps_unreachable_action = 'Full',
  Boolean $activate_policies                                     = true,
  Integer[0, 5] $conflict_detection_attempts                     = 0,
  Array[String[1]] $exec_resource_tags                           = ['win_dhcp_server', 'win_dhcp_server_global', 'win_dhcp_server_general'],
  Enum['true', 'false', 'onfailure'] $exec_log_output            = 'true',
) {
  require win_dhcp_server::prereq::check

  $exec_defaults = {
    'logoutput' => $exec_log_output,
    'provider'  => 'powershell',
    'tag'       => $exec_resource_tags,
  }

  exec { "win_dhcp_server_nap_enable":
    command => epp("${module_name}/global/command-win_dhcp_server_nap_enable.ps1.epp", { 'nap_enable' => $win_dhcp_server::global::general::nap_enable }),
    unless  => epp("${module_name}/global/unless-win_dhcp_server_nap_enable.ps1.epp", { 'nap_enable' => $win_dhcp_server::global::general::nap_enable }),
    *       => $exec_defaults,
  }

  exec { "win_dhcp_server_nps_unreachable_action":
    command => epp("${module_name}/global/command-win_dhcp_server_nps_unreachable_action.ps1.epp", { 'nps_unreachable_action' => $win_dhcp_server::global::general::nps_unreachable_action }),
    unless  => epp("${module_name}/global/unless-win_dhcp_server_nps_unreachable_action.ps1.epp", { 'nps_unreachable_action' => $win_dhcp_server::global::general::nps_unreachable_action }),
    *       => $exec_defaults,
  }

  exec { "win_dhcp_server_activate_policies":
    command => epp("${module_name}/global/command-win_dhcp_server_activate_policies.ps1.epp", { 'activate_policies' => $win_dhcp_server::global::general::activate_policies }),
    unless  => epp("${module_name}/global/unless-win_dhcp_server_activate_policies.ps1.epp", { 'activate_policies' => $win_dhcp_server::global::general::activate_policies }),
    *       => $exec_defaults,
  }

  exec { "win_dhcp_server_conflict_detection_attempts":
    command => epp("${module_name}/global/command-win_dhcp_server_conflict_detection_attempts.ps1.epp", { 'conflict_detection_attempts' => $win_dhcp_server::global::general::conflict_detection_attempts }),
    unless  => epp("${module_name}/global/unless-win_dhcp_server_conflict_detection_attempts.ps1.epp", { 'conflict_detection_attempts' => $win_dhcp_server::global::general::conflict_detection_attempts }),
    *       => $exec_defaults,
  }
}