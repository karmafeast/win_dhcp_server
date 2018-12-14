define win_dhcp_server::scope::v4 (
  String[1] $scope_id, #this is the network ID of the network in which the scope exists
  String $start_range                                 = '', #blow up in epp if you dont specify non empty strings here when ensure => present
  String $end_range                                   = '', #blow up in epp if you dont specify non empty strings here when ensure => present
  String $subnet_mask                                 = '', #blow up in epp if you dont specify non empty strings here when ensure => present
  String $scope_name                                  = $title, #scope name is not unique from the backend perspective
  Enum['Dhcp', 'Bootp', 'Both'] $scope_type           = 'Both', #must be 'Both' to consider max bootp clients
  Enum['present', 'absent']$ensure                    = 'present',
  Array[String[1]] $exec_resource_tags                = ['win_dhcp_server', 'win_dhcp_server_scope', 'win_dhcp_server_scopev4'],
  Enum['true', 'false', 'onfailure'] $exec_log_output = 'true',
  Optional[Boolean] $activate_policies                = undef, #default from backend is true
  Optional[Integer[0, 1000]] $delay_ms                = undef, #default from backend is 0, max is 1000ms (1 second)
  Optional[String] $description                       = undef,
  Optional[String[1]] $lease_duration                 = undef, #default from backend is day.hrs:mins:secs e.g. 8.00:00:00 (8 days)
  Optional[Integer[0, 4294967295]] $max_bootp_clients = undef, #its uint32, effective bounds not tested
  Optional[Boolean] $nap_enable                       = undef,
  Optional[String[1]] $nap_profile                    = undef, #backend default null
  Optional[Enum['Active', 'InActive']] $active_state  = undef, #backend default is to make 'Active' a newly created scope
  Optional[String] $superscope_name                   = undef, #backend default null
) {

  require win_dhcp_server::prereq::check

  $exec_defaults = {
    'logoutput' => $exec_log_output,
    'provider'  => 'powershell',
    'tag'       => $exec_resource_tags,
  }

  case $ensure {
    'present': {
      #check scope with ScopeId (the network in which it exists, you can only serve one scope per subnet, and cannot create a
      #higher bitmasked scope within that.  i.e scopeIds 192.168.0.0 and 192.168.0.224 cannot exist together, a /27 cant live in a /24.

      #1./check/set scope ID exists with settings as appropriate -- at the least it should have a
      #startrange, endrange, subnetmask, name, scopeID (calculated)
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