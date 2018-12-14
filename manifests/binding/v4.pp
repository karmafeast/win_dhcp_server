# manage binding for IPv4 DHCP server services
define win_dhcp_server::binding::v4 (
  String[1] $mac_address                              = $title,
  Enum['present', 'absent']$ensure                    = 'present',
  Array[String[1]] $exec_resource_tags                = ['win_dhcp_server', 'win_dhcp_server_binding', 'win_dhcp_server_bindingv4'],
  Enum['true', 'false', 'onfailure'] $exec_log_output = 'true',
  Optional[Boolean] $binding_state                    = undef
) {
  require win_dhcp_server::prereq::check

  $exec_defaults = {
    'logoutput' => $exec_log_output,
    'provider'  => 'powershell',
    'tag'       => $exec_resource_tags,
  }

  case $ensure {
    'present': {
      exec { "present - win_dhcp_server_v4binding - mac: '${mac_address}' binding state: '${binding_state}'":
        command => epp("${module_name}/binding/v4/present-command-win_dhcp_server_v4binding.ps1.epp", {
          'mac_address'   => $mac_address,
          'binding_state' => $binding_state }),
        unless  => epp("${module_name}/binding/v4/present-unless-win_dhcp_server_v4binding.ps1.epp", {
          'mac_address'   => $mac_address,
          'binding_state' => $binding_state }),
        *       => $exec_defaults,
      }
    }
    'absent': {
      exec { "absent - win_dhcp_server_v4binding - mac: '${mac_address}' binding state: '${binding_state}'":
        command => epp("${module_name}/binding/v4/absent-command-win_dhcp_server_v4binding.ps1.epp", {
          'mac_address' => $mac_address }),
        unless  => epp("${module_name}/binding/v4/absent-unless-win_dhcp_server_v4binding.ps1.epp", {
          'mac_address' => $mac_address }),
        *       => $exec_defaults,
      }
    }
    default: { fail("logic error in case select for ensure state. -- ${module_name}, caller: ${caller_module_name}") }
  }
}