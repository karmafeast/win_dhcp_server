define win_dhcp_server::policy::iprange_v4 (
  String[1] $policy_name,
  String[1] $scope_id,
  Enum['present', 'absent']$ensure                    = 'present',
  Array[String[1]] $exec_resource_tags                = ['win_dhcp_server', 'win_dhcp_server_policyiprange', 'win_dhcp_server_policyiprangev4'],
  Enum['true', 'false', 'onfailure'] $exec_log_output = 'true',
  Optional[String[1]] $start_range                    = undef, #always required in epp for ensure => present, if undef in absent, kill all ranges in scope for policy
  Optional[String[1]] $end_range                      = undef, #^can specify start or end range as target for removal, as can have several ranges in a scope
) {

  require win_dhcp_server::prereq::check

  $exec_defaults = {
    'logoutput' => $exec_log_output,
    'provider'  => 'powershell',
    'tag'       => $exec_resource_tags,
  }

  case $ensure {
    'present': {
      exec { "present - win_dhcp_server_v4policy_IPRange - scope ID: '${scope_id}' start: '${start_range}' end: '${end_range}'":
        command => epp("${module_name}/policy/v4/present-command-win_dhcp_server_v4policy_iprange.ps1.epp", {
          'policy_name' => $policy_name,
          'scope_id'    => $scope_id,
          'start_range' => $start_range,
          'end_range'   => $end_range }),
        unless  => epp("${module_name}/policy/v4/present-unless-win_dhcp_server_v4policy_iprange.ps1.epp", {
          'policy_name' => $policy_name,
          'scope_id'    => $scope_id,
          'start_range' => $start_range,
          'end_range'   => $end_range }),
        *       => $exec_defaults,
      }
    }
    'absent': {
      exec { "absent - win_dhcp_server_v4policy_IPRange - scope ID: '${scope_id}' start: '${start_range}' end: '${end_range}'":
        command => epp("${module_name}/policy/v4/absent-command-win_dhcp_server_v4policy_iprange.ps1.epp", {
          'policy_name' => $policy_name,
          'scope_id'    => $scope_id,
          'start_range' => $start_range,
          'end_range'   => $end_range }),
        unless  => epp("${module_name}/policy/v4/absent-unless-win_dhcp_server_v4policy_iprange.ps1.epp", {
          'policy_name' => $policy_name,
          'scope_id'    => $scope_id,
          'start_range' => $start_range,
          'end_range'   => $end_range }),
        *       => $exec_defaults,
      }
    }
    default: { fail("logic error in case select for ensure state. -- ${module_name}, caller: ${caller_module_name}") }
  }
}