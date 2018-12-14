# manage DHCP Server!
class win_dhcp_server (
  String[1] $database_filename                                   = "${facts['system32']}\\dhcp\\dhcp.mdb",
  String[1] $database_backup_path                                = "${facts['system32']}\\dhcp\\backup",
  Integer[1, 71582] $database_backup_interval_min                = 30,
  Integer[1, 71582] $database_cleanup_interval_min               = 60,
  Boolean $auditlog_enable                                       = true,
  String[1] $auditlog_path                                       = "${facts['system32']}\\dhcp",
  Integer[0, 4294967295] $auditlog_max_size_mb                   = 70, #you can set 0, but might as well turn audit logging off via 'audit_log_enabled'
  Integer[2, 4294967295] $auditlog_diskcheck_interval            = 50, #number of events between disk space check, 2 is min, if set 0 itll set back 2
  Integer[0, 4294967295] $auditlog_min_diskspace_mb              = 20,
  Integer[0, 5] $conflict_detection_attempts                     = 0,
  Boolean $nap_enable                                            = false,
  Enum['Full', 'Restricted', 'NoAccess'] $nps_unreachable_action = 'Full',
  Boolean $activate_policies                                     = true,
  Boolean $enable_v4_allow_filter_list                           = false,
  Boolean $enable_v4_deny_filter_list                            = false,
  Enum['true', 'false', 'onfailure'] $exec_log_output            = 'true',
  Array[String[1]] $exec_resource_tags                           = ['win_dhcp_server'],
  Optional[Hash] $v4_interface_bindings                          = undef, #we'll get it by mac
  Optional[Hash] $v4_dns_settings                                = undef,
  Optional[Hash] $v4_filters                                     = undef, #this will contain ALLOW and DENY entries
  Optional[Hash] $v4_scopes                                      = undef,
  Optional[Hash] $v4_superscopes                                 = undef,
  Optional[Hash] $v4_exclusions                                  = undef,
  Optional[Hash] $v4_reservations                                = undef,
  Optional[Hash] $v4_multicastscopes                             = undef,
  Optional[Hash] $v4_multicastexclusions                         = undef,
  Optional[Hash] $v4_classes                                     = undef,
  Optional[Hash] $v4_policies                                    = undef,
  Optional[Hash] $v4_policy_ipranges                             = undef,
  Optional[Hash] $v4_optiondefinitions                           = undef,
  Optional[Hash] $v4_optionvalues                                = undef,
) {
  #IMPORTANT -
  #some resources here WILL restart the service within their powershell backend scripts - e.g. if you change the dhcp server database path

  #DOES NOT -
  # manage resources commonly managed by other modules such as 'windowsfeature'
  # ensure you have the powershell module 'dhcpserver' 2.x.x or higher
  # manage the service 'dhcpserver' -- you might well be doing so elsewhere, or with a provider fancy enough to set user/pwd
  # detect or set directory authorization state
  # allow for get or set of dns credentials for resource record updates related to dhcp objects
  # support v6 stuff - had no time unfortunately.  though... its largely the same, and I like incoming PR! have at it!
  require win_dhcp_server::prereq::check

  $exec_defaults = {
    'logoutput' => $exec_log_output,
    'provider'  => 'powershell',
    'tag'       => $exec_resource_tags,
  }

  #1./set Database options.
  class { win_dhcp_server::global::database:
    database_filename             => $database_filename,
    database_backup_path          => $database_backup_path,
    database_backup_interval_min  => $database_backup_interval_min,
    database_cleanup_interval_min => $database_cleanup_interval_min,
    exec_log_output               => $exec_log_output,
    exec_resource_tags            => $exec_resource_tags + ['win_dhcp_server_global', 'win_dhcp_server_database'],
  }

  #2./set Auditing Options.
  class { win_dhcp_server::global::audit:
    auditlog_enable             => $auditlog_enable,
    auditlog_path               => $auditlog_path,
    auditlog_max_size_mb        => $auditlog_max_size_mb,
    auditlog_diskcheck_interval => $auditlog_diskcheck_interval,
    auditlog_min_diskspace_mb   => $auditlog_min_diskspace_mb,
    exec_log_output             => $exec_log_output,
    exec_resource_tags          => $exec_resource_tags + ['win_dhcp_server_global', 'win_dhcp_server_audit'],
  }

  #3./set global general settings
  class { win_dhcp_server::global::general:
    nap_enable                  => $nap_enable,
    nps_unreachable_action      => $nps_unreachable_action,
    activate_policies           => $activate_policies,
    conflict_detection_attempts => $conflict_detection_attempts,
    exec_log_output             => $exec_log_output,
    exec_resource_tags          => $exec_resource_tags + ['win_dhcp_server_global', 'win_dhcp_server_general'],
  }

  #4./set mac filterlist state
  class { win_dhcp_server::global::filterlist:
    enable_v4_allow => $enable_v4_allow_filter_list,
    enable_v4_deny  => $enable_v4_deny_filter_list,
  }

  #5./ set filter entries prior to making any scopes etc.
  if($v4_filters) {
    if(!empty($v4_filters))
    {
      $v4_filters.each |$key, $value| {
        win_dhcp_server::filter::v4 {
          $key:
            * => $value;
        }
      }
    }
  }

  #6./set IPv4 scopes
  if($v4_scopes) {
    if(!empty($v4_scopes))
    {
      $v4_scopes.each |$key, $value| {
        win_dhcp_server::scope::v4 {
          $key:
            * => $value;
        }
      }
    }
  }

  #7./set IPv4 multicast scopes
  if($v4_multicastscopes) {
    if(!empty($v4_multicastscopes))
    {
      $v4_multicastscopes.each |$key, $value| {
        win_dhcp_server::scope::multicast_v4 {
          $key:
            * => $value;
        }
      }
    }
  }

  #8./set IPv4 superscopes
  if($v4_superscopes) {
    if(!empty($v4_superscopes))
    {
      $v4_superscopes.each |$key, $value| {
        win_dhcp_server::scope::super_v4 {
          $key:
            * => $value;
        }
      }
    }
  }

  #9./set IPv4 exclusion ranges
  if($v4_exclusions) {
    if(!empty($v4_exclusions))
    {
      $v4_exclusions.each |$key, $value| {
        win_dhcp_server::exclusion::v4 {
          $key:
            * => $value;
        }
      }
    }
  }

  #10./set IPv4 multicast exclusion ranges
  if($v4_multicastexclusions) {
    if(!empty($v4_multicastexclusions))
    {
      $v4_multicastexclusions.each |$key, $value| {
        win_dhcp_server::exclusion::multicast_v4 {
          $key:
            * => $value;
        }
      }
    }
  }

  #11./set IPv4 client ID reservations
  if($v4_reservations) {
    if(!empty($v4_reservations))
    {
      $v4_reservations.each |$key, $value| {
        win_dhcp_server::reservation::v4 {
          $key:
            * => $value;
        }
      }
    }
  }

  #12./ set IPv4 classes, you need these to exist prior to options (you cant put an option definition in a class that not exist)
  if($v4_classes) {
    if(!empty($v4_classes))
    {
      $v4_classes.each |$key, $value| {
        win_dhcp_server::class::v4 {
          $key:
            * => $value;
        }
      }
    }
  }

  #13./ set IPv4 options definitions
  if($v4_optiondefinitions) {
    if(!empty($v4_optiondefinitions))
    {
      $v4_optiondefinitions.each |$key, $value| {
        win_dhcp_server::option::definition_v4 {
          $key:
            * => $value;
        }
      }
    }
  }

  #14./set IPv4 policies
  if($v4_policies) {
    if(!empty($v4_policies))
    {
      $v4_policies.each |$key, $value| {
        win_dhcp_server::policy::v4 {
          $key:
            * => $value;
        }
      }
    }
  }

  #15./set IPv4 policy IP ranges
  if($v4_policy_ipranges) {
    if(!empty($v4_policy_ipranges))
    {
      $v4_policy_ipranges.each |$key, $value| {
        win_dhcp_server::policy::iprange_v4 {
          $key:
            * => $value;
        }
      }
    }
  }

  #16./set IPv4 option values
  if($v4_optionvalues) {
    if(!empty($v4_optionvalues))
    {
      $v4_optionvalues.each |$key, $value| {
        win_dhcp_server::option::value_v4 {
          $key:
            * => $value;
        }
      }
    }
  }

  #17./set IPv4 dns settings for server/scopes/policies/reservedIP
  if($v4_dns_settings) {
    if(!empty($v4_dns_settings))
    {
      $v4_dns_settings.each |$key, $value| {
        win_dhcp_server::dns::v4 {
          $key:
            * => $value;
        }
      }
    }
  }

  #18./set IPv4 interface bindings
  if($v4_interface_bindings) {
    if(!empty($v4_interface_bindings))
    {
      $v4_interface_bindings.each |$key, $value| {
        win_dhcp_server::binding::v4 {
          $key:
            * => $value;
        }
      }
    }
  }
}