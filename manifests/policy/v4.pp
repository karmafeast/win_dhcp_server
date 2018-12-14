# manage DHCP v4 policy
define win_dhcp_server::policy::v4 (
  String[1] $policy_name,
  String[1] $scope_id                                 = '0.0.0.0', #0.0.0.0 is a server level policy, if other scope level then specify it here
  Enum['present', 'absent']$ensure                    = 'present',
  Boolean $enabled                                    = true,
  Array[String[1]] $exec_resource_tags                = ['win_dhcp_server', 'win_dhcp_server_policy', 'win_dhcp_server_policyv4'],
  Enum['true', 'false', 'onfailure'] $exec_log_output = 'true',
  Optional[Enum['AND', 'OR']] $condition_operator     = undef,
  Optional[Array[String]] $circuit_id                 = undef,
  Optional[Array[String]] $client_id                  = undef,
  Optional[Array[String]] $fqdn                       = undef,
  Optional[Array[String]] $mac_addresses              = undef,
  Optional[Array[String]] $relay_agent                = undef,
  Optional[Array[String]] $remote_id                  = undef,
  Optional[Array[String]] $subscriber_id              = undef,
  Optional[Array[String]] $user_class                 = undef,
  Optional[Array[String]] $vendor_class               = undef,
  Optional[String] $description                       = undef,
  Optional[String[1]] $lease_duration                 = undef, #day.hrs:mins:secs e.g. 8.00:00:00 (8 days)
  Optional[Integer[1, 65535]] $processing_order       = undef,
) {

  require win_dhcp_server::prereq::check

  $exec_defaults = {
    'logoutput' => $exec_log_output,
    'provider'  => 'powershell',
    'tag'       => $exec_resource_tags,
  }

  case $ensure {
    'present': {
      exec { "present - win_dhcp_server_v4policy - name: '${policy_name}', scope id: '${scope_id}'":
        command => epp("${module_name}/policy/v4/present-command-win_dhcp_server_v4policy.ps1.epp", {
          'policy_name'        => $policy_name,
          'enabled'            => $enabled,
          'condition_operator' => $condition_operator,
          'circuit_id'         => $circuit_id,
          'client_id'          => $client_id,
          'fqdn'               => $fqdn,
          'mac_addresses'      => $mac_addresses,
          'relay_agent'        => $relay_agent,
          'remote_id'          => $remote_id,
          'subscriber_id'      => $subscriber_id,
          'user_class'         => $user_class,
          'vendor_class'       => $vendor_class,
          'scope_id'           => $scope_id,
          'description'        => $description,
          'lease_duration'     => $lease_duration,
          'processing_order'   => $processing_order }),
        unless  => epp("${module_name}/policy/v4/present-unless-win_dhcp_server_v4policy.ps1.epp", {
          'policy_name'        => $policy_name,
          'enabled'            => $enabled,
          'condition_operator' => $condition_operator,
          'circuit_id'         => $circuit_id,
          'client_id'          => $client_id,
          'fqdn'               => $fqdn,
          'mac_addresses'      => $mac_addresses,
          'relay_agent'        => $relay_agent,
          'remote_id'          => $remote_id,
          'subscriber_id'      => $subscriber_id,
          'user_class'         => $user_class,
          'vendor_class'       => $vendor_class,
          'scope_id'           => $scope_id,
          'description'        => $description,
          'lease_duration'     => $lease_duration,
          'processing_order'   => $processing_order }),
        *       => $exec_defaults,
      }
    }
    'absent': {
      exec { "absent - win_dhcp_server_v4policy - name: '${policy_name}', scope id: '${scope_id}'":
        command => epp("${module_name}/policy/v4/absent-command-win_dhcp_server_v4policy.ps1.epp", {
          'policy_name' => $policy_name,
          'scope_id'    => $scope_id }),
        unless  => epp("${module_name}/policy/v4/absent-unless-win_dhcp_server_v4policy.ps1.epp", {
          'policy_name' => $policy_name,
          'scope_id'    => $scope_id }),
        *       => $exec_defaults,
      }
    }
    default: { fail("logic error in case select for ensure state. -- ${module_name}, caller: ${caller_module_name}") }
  }
}