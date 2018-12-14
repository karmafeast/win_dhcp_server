# manage DHCP v4 multicast scope
define win_dhcp_server::scope::multicast_v4 (
  String[1] $scope_name                               = $title,
  Enum['present', 'absent']$ensure                    = 'present',
  Array[String[1]] $exec_resource_tags                = ['win_dhcp_server', 'win_dhcp_server_multicastscope', 'win_dhcp_server_multicastscopev4'],
  Enum['true', 'false', 'onfailure'] $exec_log_output = 'true',
  Optional[String[1]] $start_range                    = undef,
  Optional[String[1]] $end_range                      = undef,
  Optional[String] $description                       = undef,
  Optional[String[1]] $expiry_time                    = undef,
  Optional[String[1]] $lease_duration                 = undef,
  Optional[Enum['Active', 'InActive']] $active_state  = undef,
  Optional[Integer[1, 255]] $ttl                      = undef,
) {

  require win_dhcp_server::prereq::check

  $exec_defaults = {
    'logoutput' => $exec_log_output,
    'provider'  => 'powershell',
    'tag'       => $exec_resource_tags,
  }

  case $ensure {
    'present': {
      exec { "present - win_dhcp_server_multicastv4scope_${scope_name}":
        command => epp("${module_name}/scope/v4/present-command-win_dhcp_server_multicastscope.ps1.epp", {
          'start_range'    => $start_range,
          'end_range'      => $end_range,
          'scope_name'     => $scope_name,
          'description'    => $description,
          'active_state'   => $active_state,
          'lease_duration' => $lease_duration,
          'expiry_time'    => $expiry_time,
          'ttl'            => $ttl }),
        unless  => epp("${module_name}/scope/v4/present-unless-win_dhcp_server_multicastscope.ps1.epp", {
          'start_range'    => $start_range,
          'end_range'      => $end_range,
          'scope_name'     => $scope_name,
          'description'    => $description,
          'active_state'   => $active_state,
          'lease_duration' => $lease_duration,
          'expiry_time'    => $expiry_time,
          'ttl'            => $ttl }),
        *       => $exec_defaults,
      }

    }
    'absent': {
      exec { "absent - win_dhcp_server_multicastv4scope_${scope_name}":
        command => epp("${module_name}/scope/v4/absent-command-win_dhcp_server_multicastscope.ps1.epp", {
          'scope_name' => $scope_name }),
        unless  => epp("${module_name}/scope/v4/absent-unless-win_dhcp_server_multicastscope.ps1.epp", {
          'scope_name' => $scope_name }),
        *       => $exec_defaults,
      }
    }
    default: { fail("logic error in case select for ensure state. -- ${module_name}, caller: ${caller_module_name}") }
  }
}