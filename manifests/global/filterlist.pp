# manage DHCP server settings related to filter list enablement
class win_dhcp_server::global::filterlist (
  Boolean $enable_v4_allow,
  Boolean $enable_v4_deny,
  Array[String[1]] $exec_resource_tags                = ['win_dhcp_server', 'win_dhcp_server_global', 'win_dhcp_server_filterlist'],
  Enum['true', 'false', 'onfailure'] $exec_log_output = 'true',
) {
  require win_dhcp_server::prereq::check

  $exec_defaults = {
    'logoutput' => $exec_log_output,
    'provider'  => 'powershell',
    'tag'       => $exec_resource_tags,
  }

  exec { "win_dhcp_server_enable_v4_allow_filter_list - ${enable_v4_allow}":
    command => epp("${module_name}/global/command-win_dhcp_server_v4_allow_filter_list.ps1.epp", { 'enable_v4_allow_filter_list' => $win_dhcp_server::global::filterlist::enable_v4_allow }),
    unless  => epp("${module_name}/global/unless_win_dhcp_server_v4_allow_filter_list.ps1.epp", { 'enable_v4_allow_filter_list' => $win_dhcp_server::global::filterlist::enable_v4_allow }),
    *       => $exec_defaults,
  }

  exec { "win_dhcp_server_enable_v4_deny_filter_list - ${enable_v4_deny}":
    command => epp("${module_name}/global/command-win_dhcp_server_v4_deny_filter_list.ps1.epp", { 'enable_v4_deny_filter_list' => $win_dhcp_server::global::filterlist::enable_v4_deny }),
    unless  => epp("${module_name}/global/unless_win_dhcp_server_v4_deny_filter_list.ps1.epp", { 'enable_v4_deny_filter_list' => $win_dhcp_server::global::filterlist::enable_v4_deny }),
    *       => $exec_defaults,
  }
}