# check prerequisites for proper module exection
class win_dhcp_server::prereq::check (
  Enum['true', 'false', 'onfailure'] $exec_log_output = 'false',
  Integer[0, 65535] $module_majorversion              = 2,
  String[1] $winfeature                               = 'DHCP',
  String[1] $servicename                              = 'dhcpserver',
  Array[String[1]] $exec_resource_tags                = ['win_dhcp_server', 'module_prerequisites']
) {

  if($::kernel != 'windows')
  {
    fail("module ${module_name} entered by non-windows kernel [${::kernel}] machine.  this module is unsafe for non-windows kernel - failing run. caller ${caller_module_name}")
  }

  $exec_defaults = {
    'logoutput' => $exec_log_output,
    'provider'  => 'powershell',
    'tag'       => $exec_resource_tags,
  }

  exec { 'win_dhcp_server_feature_check':
    command => epp("${module_name}/prereq/command-win_dhcp_server_feature_check.ps1.epp", { 'winfeature' => $win_dhcp_server::prereq::check::winfeature }),
    unless  => epp("${module_name}/prereq/unless-win_dhcp_server_feature_check.ps1.epp", { 'winfeature' => $win_dhcp_server::prereq::check::winfeature }),
    *       => $exec_defaults,
  }

  exec { 'win_dhcp_server_service_check':
    command => epp("${module_name}/prereq/command-win_dhcp_server_service_check.ps1.epp", { 'servicename' => $win_dhcp_server::prereq::check::servicename }),
    unless  => epp("${module_name}/prereq/unless-win_dhcp_server_service_check.ps1.epp", { 'servicename' => $win_dhcp_server::prereq::check::servicename }),
    *       => $exec_defaults,
  }

  exec { 'win_dhcp_server_module_check':
    command => epp("${module_name}/prereq/command-win_dhcp_server_module_check.ps1.epp", { 'majorversion' => $win_dhcp_server::prereq::check::module_majorversion }),
    unless  => epp("${module_name}/prereq/unless-win_dhcp_server_module_check.ps1.epp", { 'majorversion' => $win_dhcp_server::prereq::check::module_majorversion }),
    *       => $exec_defaults,
  }
}