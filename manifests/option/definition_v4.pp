define win_dhcp_server::option::definition_v4 (
  Integer[1, 255] $option_id,
  Enum['present', 'absent']$ensure                                                                                                               = 'present',
  Array[String[1]] $exec_resource_tags                                                                                                           = ['win_dhcp_server', 'win_dhcp_server_optiondefinition', 'win_dhcp_server_optiondefinitionv4'],
  Enum['true', 'false', 'onfailure'] $exec_log_output                                                                                            = 'true',
  Optional[String[1]] $definition_name                                                                                                           = undef,
  Optional[Enum['Byte', 'Word', 'DWord', 'DWordDword', 'IPAddress', 'String', 'BinaryData', 'EncapsulatedData', 'IPv6Address']] $value_data_type = undef,
  Optional[Array[String[1]]] $default_value                                                                                                      = undef,
  Optional[String] $description                                                                                                                  = undef,
  Optional[Boolean] $multivalued                                                                                                                 = undef,
  Optional[String[1]] $vendor_class                                                                                                              = undef,
) {

  require win_dhcp_server::prereq::check

  $exec_defaults = {
    'logoutput' => $exec_log_output,
    'provider'  => 'powershell',
    'tag'       => $exec_resource_tags,
  }

  case $ensure {
    'present': {
      exec { "present - win_dhcp_server_v4optiondefinition - ID: '${option_id}' name: '${definition_name}' in: '${vendor_class}'":
        command => epp("${module_name}/option/v4/present-command-win_dhcp_server_v4optiondefinition.ps1.epp", {
          'option_id'       => $option_id,
          'value_data_type' => $value_data_type,
          'definition_name' => $definition_name,
          'default_value'   => $default_value,
          'description'     => $description,
          'multivalued'     => $multivalued,
          'vendor_class'    => $vendor_class }),
        unless  => epp("${module_name}/option/v4/present-unless-win_dhcp_server_v4optiondefinition.ps1.epp", {
          'option_id'       => $option_id,
          'value_data_type' => $value_data_type,
          'definition_name' => $definition_name,
          'default_value'   => $default_value,
          'description'     => $description,
          'multivalued'     => $multivalued,
          'vendor_class'    => $vendor_class }),
        *       => $exec_defaults,
      }
    }
    'absent': {
      exec { "absent - win_dhcp_server_v4optiondefinition - ID: '${option_id}' in: '${vendor_class}'":
        command => epp("${module_name}/option/v4/absent-command-win_dhcp_server_v4optiondefinition.ps1.epp", {
          'option_id'       => $option_id,
          'definition_name' => $definition_name,
          'vendor_class'    => $vendor_class }),
        unless  => epp("${module_name}/option/v4/absent-unless-win_dhcp_server_v4optiondefinition.ps1.epp", {
          'option_id'    => $option_id,
          'vendor_class' => $vendor_class }),
        *       => $exec_defaults,
      }
    }
    default: { fail("logic error in case select for ensure state. -- ${module_name}, caller: ${caller_module_name}") }
  }
}