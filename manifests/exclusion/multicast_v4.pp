# manage DHCP v4 multicast exclusion range
define win_dhcp_server::exclusion::multicast_v4 (
  String[1] $scope_name,
  String $start_range                                 = '',
  String $end_range                                   = '',
  Enum['present', 'absent']$ensure                    = 'present',
  Array[String[1]] $exec_resource_tags                = ['win_dhcp_server', 'win_dhcp_server_multicastexclusion', 'win_dhcp_server_multicastexclusionv4'],
  Enum['true', 'false', 'onfailure'] $exec_log_output = 'true',
) {

  require win_dhcp_server::prereq::check

  $exec_defaults = {
    'logoutput' => $exec_log_output,
    'provider'  => 'powershell',
    'tag'       => $exec_resource_tags,
  }

  case $ensure {
    'present': {
      exec { "present - win_dhcp_server_v4multicastexclusion - start: ${start_range} end: ${end_range}":
        command => epp("${module_name}/exclusion/v4/present-command-win_dhcp_server_multicastexclusion.ps1.epp", {
          'scope_name'  => $scope_name,
          'start_range' => $start_range,
          'end_range'   => $end_range }),
        unless  => epp("${module_name}/exclusion/v4/present-unless-win_dhcp_server_multicastexclusion.ps1.epp", {
          'scope_name'  => $scope_name,
          'start_range' => $start_range,
          'end_range'   => $end_range }),
        *       => $exec_defaults,
      }
    }
    'absent': {
      exec { "absent - win_dhcp_server_v4multicastexclusion - start: ${start_range} end: ${end_range}":
        command => epp("${module_name}/exclusion/v4/absent-command-win_dhcp_server_multicastexclusion.ps1.epp", {
          'scope_name'  => $scope_name,
          'start_range' => $start_range,
          'end_range'   => $end_range }),
        unless  => epp("${module_name}/exclusion/v4/absent-unless-win_dhcp_server_multicastexclusion.ps1.epp", {
          'scope_name'  => $scope_name,
          'start_range' => $start_range,
          'end_range'   => $end_range }),
        *       => $exec_defaults,
      }
    }
    default: { fail("logic error in case select for ensure state. -- ${module_name}, caller: ${caller_module_name}") }
  }
}