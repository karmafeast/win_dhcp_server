define win_dhcp_server::filter::v4 (
  Enum['Allow', 'Deny'] $list,
  Array[String[1]] $mac_addresses,
  Enum['present', 'absent']$ensure                    = 'present',
  Array[String[1]] $exec_resource_tags                = ['win_dhcp_server', 'win_dhcp_server_filter', 'win_dhcp_server_filterv4'],
  Enum['true', 'false', 'onfailure'] $exec_log_output = 'true',
  Optional[String] $description                       = undef
) {

  require win_dhcp_server::prereq::check

  $exec_defaults = {
    'logoutput' => $exec_log_output,
    'provider'  => 'powershell',
    'tag'       => $exec_resource_tags,
  }

  case $ensure {
    'present': {
      exec { "present - win_dhcp_server_v4filter - list: '${list}' mac: '${mac_addresses}' description: '${description}'":
        command => epp("${module_name}/filter/v4/present-command-win_dhcp_server_v4filter.ps1.epp", {
          'list'          => $list,
          'mac_addresses' => $mac_addresses,
          'description'   => $description }),
        unless  => epp("${module_name}/filter/v4/present-unless-win_dhcp_server_v4filter.ps1.epp", {
          'list'          => $list,
          'mac_addresses' => $mac_addresses,
          'description'   => $description }),
        *       => $exec_defaults,
      }
    }
    'absent': {
      exec { "absent - win_dhcp_server_v4filter - list: '${list}' mac: '${mac_addresses}' description: '${description}'":
        command => epp("${module_name}/filter/v4/absent-command-win_dhcp_server_v4filter.ps1.epp", {
          'list'          => $list,
          'mac_addresses' => $mac_addresses }),
        unless  => epp("${module_name}/filter/v4/absent-unless-win_dhcp_server_v4filter.ps1.epp", {
          'list'          => $list,
          'mac_addresses' => $mac_addresses }),
        *       => $exec_defaults,
      }
    }
    default: { fail("logic error in case select for ensure state. -- ${module_name}, caller: ${caller_module_name}") }
  }
}