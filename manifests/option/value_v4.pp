define win_dhcp_server::option::value_v4 (
  Integer[1, 255] $option_id,
  Enum['present', 'absent']$ensure                    = 'present',
  Array[String[1]] $exec_resource_tags                = ['win_dhcp_server', 'win_dhcp_server_optionvalue', 'win_dhcp_server_optionvaluev4'],
  Enum['true', 'false', 'onfailure'] $exec_log_output = 'true',
  Optional[Array[String[1]]] $value                   = undef, #optional in epp when ensure => absent
  Optional[String[1]] $policy_name                    = undef,
  Optional[String[1]] $reserved_ip                    = undef,
  Optional[String[1]] $scope_id                       = undef,
  Optional[String[1]] $user_class                     = undef,
  Optional[String[1]] $vendor_class                   = undef,
) {
  #we're not going to support the crazy inbuilt common params on the backend like -Router.
  #in this example - Router is optionID 3 in $null vendorclass.  so don't be lazy, define your option values by ID!
  #remember to create option defintions BEFORE trying to set values for them
  #i.e. - you need a option 252 in vendorclass $null (maybe named WPAD) prior to being able to set a value for that defined option
  require win_dhcp_server::prereq::check

  $exec_defaults = {
    'logoutput' => $exec_log_output,
    'provider'  => 'powershell',
    'tag'       => $exec_resource_tags,
  }

  case $ensure {
    'present': {
      exec { "present - win_dhcp_server_v4optionvalue - ID: '${option_id}' in: 'v:${vendor_class}/u:${user_class}/p:${policy_name}/s:${scope_id}/r:${reserved_ip}'":
        command => epp("${module_name}/option/v4/present-command-win_dhcp_server_v4optionvalue.ps1.epp", {
          'option_id'    => $option_id,
          'value'        => $value,
          'scope_id'     => $scope_id,
          'reserved_ip'  => $reserved_ip,
          'user_class'   => $user_class,
          'policy_name'  => $policy_name,
          'vendor_class' => $vendor_class }),
        unless  => epp("${module_name}/option/v4/present-unless-win_dhcp_server_v4optionvalue.ps1.epp", {
          'option_id'    => $option_id,
          'value'        => $value,
          'scope_id'     => $scope_id,
          'reserved_ip'  => $reserved_ip,
          'user_class'   => $user_class,
          'policy_name'  => $policy_name,
          'vendor_class' => $vendor_class }),
        *       => $exec_defaults,
      }
    }
    'absent': {
      exec { "absent - win_dhcp_server_v4optionvalue - ID: '${option_id}' in: 'v:${vendor_class}/u:${user_class}/p:${policy_name}/s:${scope_id}/r:${reserved_ip}'":
        command => epp("${module_name}/option/v4/absent-command-win_dhcp_server_v4optionvalue.ps1.epp", {
          'option_id'    => $option_id,
          'scope_id'     => $scope_id,
          'reserved_ip'  => $reserved_ip,
          'user_class'   => $user_class,
          'policy_name'  => $policy_name,
          'vendor_class' => $vendor_class }),
        unless  => epp("${module_name}/option/v4/absent-unless-win_dhcp_server_v4optionvalue.ps1.epp", {
          'option_id'    => $option_id,
          'scope_id'     => $scope_id,
          'reserved_ip'  => $reserved_ip,
          'user_class'   => $user_class,
          'policy_name'  => $policy_name,
          'vendor_class' => $vendor_class }),
        *       => $exec_defaults,
      }
    }
    default: { fail("logic error in case select for ensure state. -- ${module_name}, caller: ${caller_module_name}") }
  }
}