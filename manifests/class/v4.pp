define win_dhcp_server::class::v4 (
  Enum['present', 'absent']$ensure                    = 'present',
  Array[String[1]] $exec_resource_tags                = ['win_dhcp_server', 'win_dhcp_server_class', 'win_dhcp_server_classv4'],
  Enum['true', 'false', 'onfailure'] $exec_log_output = 'true',
  Optional[Enum['User', 'Vendor']] $class_type        = undef, #if ensure => absent and undef, need to remove any found class, in both user and vendor
  Optional[String[1]] $class_data                     = undef, #ensure => absent need to support removal via name OR ascii data
  Optional[String[1]] $class_name                     = undef, #ensure => absent need to support removal via name OR ascii data
  Optional[String] $description                       = undef
) {

  require win_dhcp_server::prereq::check

  $exec_defaults = {
    'logoutput' => $exec_log_output,
    'provider'  => 'powershell',
    'tag'       => $exec_resource_tags,
  }

  case $ensure {
    'present': {
      exec { "present - win_dhcp_server_v4class - name: '${class_name}' type: '${class_type}'":
        command => epp("${module_name}/class/v4/present-command-win_dhcp_server_v4class.ps1.epp", {
          'class_type'  => $class_type,
          'class_name'  => $class_name,
          'class_data'  => $class_data,
          'description' => $description }),
        unless  => epp("${module_name}/class/v4/present-unless-win_dhcp_server_v4class.ps1.epp", {
          'class_type'  => $class_type,
          'class_name'  => $class_name,
          'class_data'  => $class_data,
          'description' => $description }),
        *       => $exec_defaults,
      }
    }
    'absent': {
      exec { "absent - win_dhcp_server_v4class - name: '${class_name}' type: '${class_type}'":
        command => epp("${module_name}/class/v4/absent-command-win_dhcp_server_v4class.ps1.epp", {
          'class_type' => $class_type,
          'class_name' => $class_name,
          'class_data' => $class_data }),
        unless  => epp("${module_name}/class/v4/absent-unless-win_dhcp_server_v4class.ps1.epp", {
          'class_type' => $class_type,
          'class_name' => $class_name,
          'class_data' => $class_data }),
        *       => $exec_defaults,
      }
    }
    default: { fail("logic error in case select for ensure state. -- ${module_name}, caller: ${caller_module_name}") }
  }
}