# manage DHCP v4 scope
define win_dhcp_server::scope::v4 (
  String[1] $scope_id,
  String $start_range                                 = '',
  String $end_range                                   = '',
  String $subnet_mask                                 = '',
  String $scope_name                                  = $title,
  Enum['Dhcp', 'Bootp', 'Both'] $scope_type           = 'Both',
  Enum['present', 'absent']$ensure                    = 'present',
  Array[String[1]] $exec_resource_tags                = ['win_dhcp_server', 'win_dhcp_server_scope', 'win_dhcp_server_scopev4'],
  Enum['true', 'false', 'onfailure'] $exec_log_output = 'true',
  Optional[Boolean] $activate_policies                = undef,
  Optional[Integer[0, 1000]] $delay_ms                = undef,
  Optional[String] $description                       = undef,
  Optional[String[1]] $lease_duration                 = undef,
  Optional[Integer[0, 4294967295]] $max_bootp_clients = undef,
  Optional[Boolean] $nap_enable                       = undef,
  Optional[String[1]] $nap_profile                    = undef,
  Optional[Enum['Active', 'InActive']] $active_state  = undef,
  Optional[String] $superscope_name                   = undef,
) {

  require win_dhcp_server::prereq::check

  $exec_defaults = {
    'logoutput' => $exec_log_output,
    'provider'  => 'powershell',
    'tag'       => $exec_resource_tags,
  }

  case $ensure {
    'present': {
      exec { "present - win_dhcp_server_v4scope_${scope_id}":
        command => epp("${module_name}/scope/v4/present-command-win_dhcp_server_scope_basic.ps1.epp", {
          'scope_id'          => $scope_id,
          'scope_type'        => $scope_type,
          'start_range'       => $start_range,
          'end_range'         => $end_range,
          'subnet_mask'       => $subnet_mask,
          'scope_name'        => $scope_name,
          'description'       => $description,
          'active_state'      => $active_state,
          'superscope_name'   => $superscope_name,
          'lease_duration'    => $lease_duration,
          'nap_enable'        => $nap_enable,
          'nap_profile'       => $nap_profile,
          'delay_ms'          => $delay_ms,
          'max_bootp_clients' => $max_bootp_clients,
          'activate_policies' => $activate_policies }),
        unless  => epp("${module_name}/scope/v4/present-unless-win_dhcp_server_scope_basic.ps1.epp", {
          'scope_id'          => $scope_id,
          'scope_type'        => $scope_type,
          'start_range'       => $start_range,
          'end_range'         => $end_range,
          'subnet_mask'       => $subnet_mask,
          'scope_name'        => $scope_name,
          'description'       => $description,
          'active_state'      => $active_state,
          'superscope_name'   => $superscope_name,
          'lease_duration'    => $lease_duration,
          'nap_enable'        => $nap_enable,
          'nap_profile'       => $nap_profile,
          'delay_ms'          => $delay_ms,
          'max_bootp_clients' => $max_bootp_clients,
          'activate_policies' => $activate_policies }),
        *       => $exec_defaults,
      }

    }
    'absent': {
      exec { "absent - win_dhcp_server_v4scope_${scope_id}":
        command => epp("${module_name}/scope/v4/absent-command-win_dhcp_server_scope_basic.ps1.epp", {
          'scope_id' => $scope_id, }),
        unless  => epp("${module_name}/scope/v4/absent-unless-win_dhcp_server_scope_basic.ps1.epp", {
          'scope_id' => $scope_id, }),
        *       => $exec_defaults,
      }
    }
    default: { fail("logic error in case select for ensure state. -- ${module_name}, caller: ${caller_module_name}") }
  }
}