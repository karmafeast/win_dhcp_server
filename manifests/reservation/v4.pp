# manage DHCP v4 IP reservation
define win_dhcp_server::reservation::v4 (
  String[1] $scope_id,
  String[1] $client_id,
  String $ipaddress                                         = '', #required for ensure present as non empty by EPP
  Enum['present', 'absent']$ensure                          = 'present',
  Optional[String] $reservation_name                        = undef,
  Optional[String] $description                             = undef,
  Optional[Enum['Dhcp', 'Bootp', 'Both']] $reservation_type = undef,
  Array[String[1]] $exec_resource_tags                      = ['win_dhcp_server', 'win_dhcp_server_reservation', 'win_dhcp_server_reservationv4'],
  Enum['true', 'false', 'onfailure'] $exec_log_output       = 'true',
) {
  require win_dhcp_server::prereq::check

  $exec_defaults = {
    'logoutput' => $exec_log_output,
    'provider'  => 'powershell',
    'tag'       => $exec_resource_tags,
  }

  case $ensure {
    'present': {
      exec { "present - win_dhcp_server_v4reservation_${scope_id} - id: ${client_id} IP: ${ipaddress}":
        command => epp("${module_name}/reservation/v4/present-command-win_dhcp_server_reservation.ps1.epp", {
          'scope_id'         => $scope_id,
          'client_id'        => $client_id,
          'ipaddress'        => $ipaddress,
          'reservation_name' => $reservation_name,
          'description'      => $description,
          'reservation_type' => $reservation_type }),
        unless  => epp("${module_name}/reservation/v4/present-unless-win_dhcp_server_reservation.ps1.epp", {
          'scope_id'         => $scope_id,
          'client_id'        => $client_id,
          'ipaddress'        => $ipaddress,
          'reservation_name' => $reservation_name,
          'description'      => $description,
          'reservation_type' => $reservation_type }),
        *       => $exec_defaults,
      }
    }
    'absent': {
      exec { "present - win_dhcp_server_v4reservation_${scope_id} - id: ${client_id} IP: ${ipaddress}":
        command => epp("${module_name}/reservation/v4/absent-command-win_dhcp_server_reservation.ps1.epp", {
          'scope_id'  => $scope_id,
          'client_id' => $client_id,
          'ipaddress' => $ipaddress }),
        unless  => epp("${module_name}/reservation/v4/absent-unless-win_dhcp_server_reservation.ps1.epp", {
          'scope_id'  => $scope_id,
          'client_id' => $client_id,
          'ipaddress' => $ipaddress }),
        *       => $exec_defaults,
      }
    }
    default: { fail("logic error in case select for ensure state. -- ${module_name}, caller: ${caller_module_name}") }
  }
}