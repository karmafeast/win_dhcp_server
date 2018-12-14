define win_dhcp_server::dns::v4 (
  Enum['present', 'absent']$ensure                                      = 'present',
  Array[String[1]] $exec_resource_tags                                  = ['win_dhcp_server', 'win_dhcp_server_dnssetting', 'win_dhcp_server_dnssettingv4'],
  Enum['true', 'false', 'onfailure'] $exec_log_output                   = 'true',
  Optional[String[1]] $scope_id                                         = undef,
  Optional[String[1]] $reserved_ip                                      = undef,
  Optional[String[1]] $policy_name                                      = undef,
  Optional[Boolean] $delete_dns_rr_onlease_expiry                       = undef, #!! can only be set if the DynamicUpdate parameter is set to Always or OnClientRequest.
  Optional[Boolean] $disable_dns_ptr_rr_update                          = undef, #If this value is $True, the DHCP server performs registration for only A records. If this value is $False, the server performs registration of both A and PTR records.
  Optional[String[1, 256]] $dns_suffix_for_registration                 = undef, #!! Do not specify this parameter unless you specify the PolicyName parameter.
  Optional[Enum['Always', 'Never', 'OnClientRequest']] $dynamic_updates = undef,
  Optional[Boolean] $name_protection                                    = undef,
  Optional[Boolean] $update_dns_rr_for_old_clients                      = undef
) {

  #N.B. - there is not a concept of absent for this resource, in that the backend object have dns settings on them, if you ensure absent, we will reset to server level values.
  require win_dhcp_server::prereq::check

  $exec_defaults = {
    'logoutput' => $exec_log_output,
    'provider'  => 'powershell',
    'tag'       => $exec_resource_tags,
  }

  case $ensure {
    'present': {
      exec { "present - win_dhcp_server_v4dns_setting - p:${policy_name}/s:${scope_id}/r:${reserved_ip}":
        command => epp("${module_name}/dns/v4/present-command-win_dhcp_server_v4dns_settings.ps1.epp", {
          'scope_id'                      => $scope_id,
          'reserved_ip'                   => $reserved_ip,
          'policy_name'                   => $policy_name,
          'delete_dns_rr_onlease_expiry'  => $delete_dns_rr_onlease_expiry,
          'disable_dns_ptr_rr_update'     => $disable_dns_ptr_rr_update,
          'dns_suffix_for_registration'   => $dns_suffix_for_registration,
          'dynamic_updates'               => $dynamic_updates,
          'name_protection'               => $name_protection,
          'update_dns_rr_for_old_clients' => $update_dns_rr_for_old_clients }),
        unless  => epp("${module_name}/dns/v4/present-unless-win_dhcp_server_v4dns_settings.ps1.epp", {
          'scope_id'                      => $scope_id,
          'reserved_ip'                   => $reserved_ip,
          'policy_name'                   => $policy_name,
          'delete_dns_rr_onlease_expiry'  => $delete_dns_rr_onlease_expiry,
          'disable_dns_ptr_rr_update'     => $disable_dns_ptr_rr_update,
          'dns_suffix_for_registration'   => $dns_suffix_for_registration,
          'dynamic_updates'               => $dynamic_updates,
          'name_protection'               => $name_protection,
          'update_dns_rr_for_old_clients' => $update_dns_rr_for_old_clients }),
        *       => $exec_defaults,
      }
    }
    #there is not a concept of absent for this resource, in that the backend object have dns settings on them, if you ensure absent, we will reset to server level values.
    'absent': {
      exec { "absent - win_dhcp_server_v4dns_setting - p:${policy_name}/s:${scope_id}/r:${reserved_ip}":
        command => epp("${module_name}/dns/v4/absent-command-win_dhcp_server_v4dns_settings.ps1.epp", {
          'scope_id'    => $scope_id,
          'reserved_ip' => $reserved_ip,
          'policy_name' => $policy_name }),
        unless  => epp("${module_name}/dns/v4/absent-unless-win_dhcp_server_v4dns_settings.ps1.epp", {
          'scope_id'    => $scope_id,
          'reserved_ip' => $reserved_ip,
          'policy_name' => $policy_name }),
        *       => $exec_defaults,
      }
    }
    default: { fail("logic error in case select for ensure state. -- ${module_name}, caller: ${caller_module_name}") }
  }
}