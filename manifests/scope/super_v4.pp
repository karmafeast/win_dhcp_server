define win_dhcp_server::scope::super_v4 (
  String[1] $superscope_name                          = $title,
  Enum['present', 'absent']$ensure                    = 'present',
  Array[String[1]] $exec_resource_tags                = ['win_dhcp_server', 'win_dhcp_server_superscope', 'win_dhcp_server_superscopev4'],
  Enum['true', 'false', 'onfailure'] $exec_log_output = 'true',
  Optional[Array[String[1]]] $scope_ids               = undef, #only optional when ensure => absent, otherwise if not specified EPP will boot you
) {
  require win_dhcp_server::prereq::check

  $exec_defaults = {
    'logoutput' => $exec_log_output,
    'provider'  => 'powershell',
    'tag'       => $exec_resource_tags,
  }

  case $ensure {
    'present': {
      exec { "present - win_dhcp_server_v4superscope_${scope_ids}":
        command => epp("${module_name}/scope/v4/present-command-win_dhcp_server_superscope.ps1.epp", {
          'scope_ids'       => $scope_ids,
          'superscope_name' => $superscope_name }),
        unless  => epp("${module_name}/scope/v4/present-unless-win_dhcp_server_superscope.ps1.epp", {
          'scope_ids'       => $scope_ids,
          'superscope_name' => $superscope_name }),
        *       => $exec_defaults,
      }
    }
    'absent': {
      exec { "absent - win_dhcp_server_v4superscope_${scope_ids}":
        command => epp("${module_name}/scope/v4/absent-command-win_dhcp_server_superscope.ps1.epp", {
          'superscope_name' => $superscope_name }),
        unless  => epp("${module_name}/scope/v4/absent-unless-win_dhcp_server_superscope.ps1.epp", {
          'superscope_name' => $superscope_name }),
        *       => $exec_defaults,
      }
    }
    default: { fail("logic error in case select for ensure state. -- ${module_name}, caller: ${caller_module_name}") }
  }
}