# win_dhcp_server

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Important Caveats](#important-caveats)
4. [Setup - The basics of getting started with win_dhcp_server](#setup)
    * [Setup requirements](#setup-requirements)
    * [Beginning with win_dhcp_server](#beginning-with-win_dhcp_server)
5. [Usage - Configuration options and additional functionality](#usage)
    * [An Example Data Driven Configuration](#an-example-data-driven-configuration)
    * [Looking at init.pp](#looking-at-init.pp)
      * [Order of Execution](#order-of-execution)
      * [data loaded from params specified or implicit to init.pp](#data-loaded-from-params-specified-or-implicit-to-init.pp)
      * [params to class win_dhcp_server](#params-to-class-win_dhcp_server)
6. [Reference - class by class](#reference)
7. [Development - Guide for contributing to the module](#development)

## Overview

win_dhcp_server is a puppet module for configuration management of MSFT Windows DHCP server services.

## Module Description

This module allows for doing just about anything you can achieve via the `dhcpserver` PowerShell module, for IPv4 related
DHCP server management tasks.

It is highly advised that you data drive this module, and a utility for generation of yaml for an existing DHCP server is
included in this module's `/util/GenerateYaml.psm1`.  

While you can use the classes directly to create resources, you may experience issues with ordering in their creation if you
deviate from the order followed in `init.pp`.  You'll have a far nicer time if you simply include the class, and provide data
through implicit lookup for its params.

## Important Caveats

**This module will not**:

* **No support for IPv6 related resource management** - I simply didn't have time.  Good news is I've arranged everything into 'v4'
designates, so the module would be easy enough to extend, and the vast majority of the code would be the same. So please open PR!

* Authorize a DHCP server for you in an Active Directory.  To achieve this utilize the `dhcpserver` PowerShell module commandlet
`AddDhcpServerInDC` as shown (may add task for this in future release):

~~~ powershell
Add-DhcpServerInDC -DnsName "dhcpserver.contoso.com" -IPAddress 10.10.10.2
~~~
(see <https://docs.microsoft.com/en-us/powershell/module/dhcpserver/add-dhcpserverindc?view=win10-ps>)

* Manage credentials used for resource record management for DHCP clients.  You will need to set the credentials used with
the `dhcpserver` PowerShell module as shown (may add task for this in future release):

~~~ powershell
$myUserName = 'this';
$plainTextPw = 'that';
$myPassword = convertto-securestring $plainTextPw -asplaintext -force;
$cred = New-Object System.Management.Automation.PsCredential($myUserName,$myPassword);
Set-DhcpServerDnsCredential -Credential $Cred -ComputerName "DhcpServer03.Contoso.com";
~~~
(see <https://docs.microsoft.com/en-us/powershell/module/dhcpserver/set-dhcpserverdnscredential?view=win10-ps>)

* Manage security groups for you, as referenced in the `dhcpserver` commandlet `Add-DhcpServerSecurityGroup`

* Manage or consider failover relationships

* Perform exports or imports of entire DHCP server configurations.  Though you will be able to achieve such effectively through
use of resources in this module, for IPv4 related configuration.

## Setup

### Requirements

* the module assumes you have PowerShell 5 on the running node.  code will fail due to syntax errors if you attempt to run it on an older version
of PowerShell.

* the module assumes you have full control of DHCP server configuration elements on the running node (e.g. the puppet agent
is running as 'localsystem' or a full administrator account on the node).  Actions may fail with permissions errors should you
elect not to meet this requirement.

* the module class `win_dhcp_server::prereq::check` in `/manifests/prereq/check.pp` if referenced as a requirement by all other
classes in the module.
  - this will check that the running node has the windows feature 'DHCP' installed.  It will do this through PowerShell exec.
  you do not need to be using the `windowsfeature` Puppet module for the management of windows features, and the module logic
  will not create `windowsfeature` resources for you.  It may be a good idea to use this module for the management of windows
  features.
  - this will check the running node has a windows service named `dhcpserver` available to `get-service`. It will not create
  `service` puppet resources for you.  It may be a good idea to manage services on your windows nodes using the inbuilt `service`
  resource type.
  - this will check the running node has a PowerShell module installed named `dhcpserver` - it assumes this is the MSFT module
  of the same name.  **The check will fail on nodes where the PowerShell `dhcpserver` PowerShell module major version is <2**.
    - Note: the yaml generator in `/util/GenerateYaml.psm1`, which can be used to easily gather data for use with this module from
  and existing DHCP server, will gather data from a v1 PowerShell module `dhcpserver`, if passed a param indicating it should.

### Beginning with win_dhcp_server

Optionally, if your node already runs a DHCP server configuration you would like to obtain yaml for that can drive the class,
as an administrator on the node in question run the `Get-DhcpServerv4HostYaml` function in `/util/GenerateYaml.psm1` on the node.

~~~ powershell
#assuming you are in the module root directory
using module '.\util\GenerateYaml.psm1';
$outputFullFilePathWhereRunningContextCanWriteFiles = 'c:\temp\mynodename.yaml';
Get-DhcpServerv4HostYaml -outputpath $outputFullFilePathWhereRunningContextCanWriteFiles;

#if you want to allow data gather from v1 dhcpserver powershell module systems do the below.
#you'll be shown warnings for sutff that cannot work, e.g. multicast scope related commandlets, certain dns settings commandlets
#Get-DhcpServerv4HostYaml -outputpath 'c:\temp\oldbox.yaml' -allowModulev1 $true;
~~~

Either via manual creation, or utilizing the PS module functions referenced immediately prior, you're easiest way to begin
managing a windows dhcp server with this module is to populate lookup data for the node, such as in node yaml for a configured 
hiera yaml backend.

Then simply `include win_dhcp_server` in the node catalog. Implicit lookup on params will handle the rest.

## Usage

### An Example Data Driven Configuration

You will find an example configuration yaml for data driven use of the module in `/example_data/myserver.contoso.com.yaml`.
We'll go through the elements of it, but basically you're setting a large number of `win_dhcp_server::...` key values which will
be processed by `init.pp` when you include the class `win_dhcp_server` in node catalog.

If you provide data to classes via something other than hiera, in some fashion provide implicit lookup answers to the class appropriate
to your node(s), or utilize defined resources appropriately in a manner akin to the order followed in `init.pp`.

### Looking at init.pp

#### Order of Execution

Execution ordering is important for the objects created as a result of this module.
For example, you cannot have an option value for an option definition that does not exist, against a user or vendor class
which may not exist - and so on.

It is recommended you utilize `init.pp` (include the class `win_dhcp_server` in your target node catalog) for this reason.

If you consider an enterprise DHCP server configuration, where hundreds or thousands of reservations may exist alone, it
may be wise to follow this path as part of your configuration management strategy with this module.

1. set Database options.
2. set Auditing options.
3. set global general settings
4. set MAC filterlist enable states
5. set filter entries prior to making further config
6. set IPv4 scopes (if provided data to do so exists)
7. set IPv4 multicast scopes (if provided data to do so exists)
8. set IPv4 superscopes (if provided data to do so exists)
9. set IPv4 exclusion ranges (if provided data to do so exists)
10. set IPv4 multicast exclusion ranges (if provided data to do so exists)
11. set IPv4 client ID reservations (if provided data to do so exists)
12. set IPv4 classes (if provided data to do so exists)
13. set IPv4 options definitions (if provided data to do so exists)
14. set IPv4 policies (if provided data to do so exists)
15. set IPv4 policy IP ranges (if provided data to do so exists)
16. set IPv4 option values (if provided data to do so exists)
17. set IPv4 dns settings for server/scopes/policies/reservedIP (if provided data to do so exists)
18. set IPv4 interface bindings (if provided data to do so exists)

#### data loaded from params specified or implicit to init.pp
yes.

e.g. (from `init.pp`)
~~~puppet
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
~~~

#### params to class `win_dhcp_server`

If you provide no data whatsoever (effectively no param values to the class), OS defaults will be used for essential
configuration elements.

You will notice a number of optional hash params, these will drive the bulk of the action of the module.

As with all classes in the module, `win_dhcp_server` requires successful execution of `win_dhcp_server::prereq::check`


~~~ puppet
class win_dhcp_server (
  String[1] $database_filename                                   = "${facts['system32']}\\dhcp\\dhcp.mdb",
  String[1] $database_backup_path                                = "${facts['system32']}\\dhcp\\backup",
  Integer[1, 71582] $database_backup_interval_min                = 30,
  Integer[1, 71582] $database_cleanup_interval_min               = 60,
  Boolean $auditlog_enable                                       = true,
  String[1] $auditlog_path                                       = "${facts['system32']}\\dhcp",
  Integer[0, 4294967295] $auditlog_max_size_mb                   = 70,
  Integer[2, 4294967295] $auditlog_diskcheck_interval            = 50,
  Integer[0, 4294967295] $auditlog_min_diskspace_mb              = 20,
  Integer[0, 5] $conflict_detection_attempts                     = 0,
  Boolean $nap_enable                                            = false,
  Enum['Full', 'Restricted', 'NoAccess'] $nps_unreachable_action = 'Full',
  Boolean $activate_policies                                     = true,
  Boolean $enable_v4_allow_filter_list                           = false,
  Boolean $enable_v4_deny_filter_list                            = false,
  Enum['true', 'false', 'onfailure'] $exec_log_output            = 'true',
  Array[String[1]] $exec_resource_tags                           = ['win_dhcp_server'],
  Optional[Hash] $v4_interface_bindings                          = undef,
  Optional[Hash] $v4_dns_settings                                = undef,
  Optional[Hash] $v4_filters                                     = undef,
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
){
  require win_dhcp_server::prereq::check
...}
~~~

##### database_filename
* Associated with class in this module: `win_dhcp_server::global::database`
 
The `String[1]` (default `"${facts['system32']}\\dhcp\\dhcp.mdb"`) full file path of the windows DHCP Server dhcp database.  

Changing this value will cause services for dhcp to restart
via the powershell backend (it will ignore for this action, and is unaware of  
any configuration you may or may not have for a `service` resource to affect your desired state).

##### database_backup_path
* Associated with class in this module: `win_dhcp_server::global::database`

The `String[1]` (default `"${facts['system32']}\\dhcp\\backup"`) folder path of the DHCP server backup file location. 

Changing this value will cause services for dhcp to restart
via the powershell backend (it will ignore for this action, and is unaware of  
any configuration you may or may not have for a `service` resource to affect your desired state).

##### database_backup_interval_min
* Associated with class in this module: `win_dhcp_server::global::database`

The `Integer[1, 71582]` (default `30`)value for DHCP database backup interval, in minutes.

##### database_cleanup_interval_min
* Associated with class in this module: `win_dhcp_server::global::database`

The `Integer[1, 71582]` (default `60`) value for DHCP database cleanup actions, in minutes.

##### auditlog_enable
* Associated with class in this module: `win_dhcp_server::global::audit`

The `Boolean` (default `true`) value for whether DHCP audit logging is enabled on the DHCP server.

Changing this value will cause services for dhcp to restart
via the powershell backend (it will ignore for this action, and is unaware of  
any configuration you may or may not have for a `service` resource to affect your desired state).

##### auditlog_path
* Associated with class in this module: `win_dhcp_server::global::audit`

The `String[1]` (default `"${facts['system32']}\\dhcp"`) folder path, where if enabled as an option, audit logging
output is placed.

Changing this value will cause services for dhcp to restart
via the powershell backend (it will ignore for this action, and is unaware of  
any configuration you may or may not have for a `service` resource to affect your desired state).

##### auditlog_max_size_mb
* Associated with class in this module: `win_dhcp_server::global::audit`

The `Integer[0, 4294967295]` (default `70`) maximum size, in MB, of the DHCP server audit log.
While you are able to set 0 as a value here via the backend, you might as well turn off audit logging using the appropriate
other configuration option.

Changing this value will cause services for dhcp to restart
via the powershell backend (it will ignore for this action, and is unaware of  
any configuration you may or may not have for a `service` resource to affect your desired state).

##### auditlog_diskcheck_interval
* Associated with class in this module: `win_dhcp_server::global::audit`

The `Integer[2, 4294967295]` (default `50`) number of audit log events after which the DHCP server service checks the available disk space
for audit logging, at the audit logging path.  While possible to set a value of 0 at the backend, it will be ignored and set to '2'
should you attempt to do so.

Changing this value will cause services for dhcp to restart
via the powershell backend (it will ignore for this action, and is unaware of  
any configuration you may or may not have for a `service` resource to affect your desired state).

##### auditlog_min_diskspace_mb
* Associated with class in this module: `win_dhcp_server::global::audit`

The `Integer[0, 4294967295]` (default `20`) value, in MB, required at every 'auditlog_diskcheck_interval' before the
DHCP Server Services will halt audit logging, or stop due to inability to log.

Changing this value will cause services for dhcp to restart
via the powershell backend (it will ignore for this action, and is unaware of  
any configuration you may or may not have for a `service` resource to affect your desired state).

##### conflict_detection_attempts
* Associated with class in this module: `win_dhcp_server::global::general`

The `Integer[0, 5]` (default `0`) number of conflict detection events which will be performed by the DHCP server, prior
to leasing a given IP address.  This uses ICMP ping of the lease prospect from the dhcp server, 
and incurs the 'cost' of delaying lease handout associated with ping timeout.

MSFT doesn't recommend taking this above '2'.

##### nap_enable
* Associated with class in this module: `win_dhcp_server::global::general`

The `Boolean` (default `false`) specifying the enabled state for the Network Access Policy (NAP) check on the 
DHCP server service. If you set this parameter to true, NAP is enabled and the DHCP server service uses 
the Network Policy Server (NPS) (which must exist) to perform a NAP check before leasing an IP address.

##### nps_unreachable_action
* Associated with class in this module: `win_dhcp_server::global::general`

The `Enum['Full', 'Restricted', 'NoAccess']` (default `Full`) value that, if `nap_enable` is true, and valid configuration
from module external sources exists for nps server configuration,
and the NPS server is unreachable, the default action that the DHCP server service performs. 

##### activate_policies
* Associated with class in this module: `win_dhcp_server::global::general`

The `Boolean` (default `true`) specifying the activation state for the enforcement of policies on the DHCP server.

##### enable_v4_allow_filter_list
* Associated with class in this module: `win_dhcp_server::global::filterlist`

The `Boolean` (default `false`) specifying whether the MAC filtration 'Allow' list is enabled.

Note that this setting is relevant to IPv4 or 6, a machine is either allowed or denied access to DHCP server services by
MAC address, which does not vary between IP versions (different element of stack).  It is managed at the backend in v4
space.

##### enable_v4_deny_filter_list
* Associated with class in this module: `win_dhcp_server::global::filterlist`

The `Boolean` (default `false`) specifying whether the MAC filtration 'Deny' list is enabled.

Note that this setting is relevant to IPv4 or 6, a machine is either allowed or denied access to DHCP server services by
MAC address, which does not vary between IP versions (different element of stack).  It is managed at the backend in v4
space.

##### exec_log_output
The `Enum['true', 'false', 'onfailure']` (default `true`) passed to exec resources in this module as 'logoutput' param.

##### exec_resource_tags
The `Array[String[1]]` (default `['win_dhcp_server']`) added to exec resources in this module.

##### v4_interface_bindings
* Associated with class in this module: `win_dhcp_server::binding::v4`

The `Optional[Hash]` of `win_dhcp_server::binding::v4` (ipv4 interface binding information).  
Entries per mac of network interface to control binding state of.
Control which interfaces on the node are associated with DHCP server services.

Example data:
~~~ yaml
win_dhcp_server::v4_interface_bindings:
  'Ethernet0 - (01-01-01-01-01-01) - this resource will fail with this eg mac':
    mac_address: '01-01-01-01-01-01'
    binding_state: true
~~~

**IMPORTANT**: note that setting an ensure => absent in a hash element of the v4_interface_bindings hash will unbind 
the interface if it exists, and not care (exit 0) if you've provided a non existent mac address.  
ensure => absent will also reject setting a binding_state of true at the EPP.

##### v4_dns_settings
* Associated with class in this module: `win_dhcp_server::dns::v4`

The `Optional[Hash]` of `win_dhcp_server::dns::v4` (ipv4 dns settings information).  
Can target Server, scope, policy, policy in scope, ip reservation.

Example data:
~~~ yaml
win_dhcp_server::v4_dns_settings:
  'p: puppet scope policy 0 in s: 192.168.98.0 dns':
    policy_name: 'puppet scope policy 0'
    scope_id: '192.168.98.0'
    dns_suffix_for_registration: 'foo1.moo1'
    dynamic_updates: 'OnClientRequest'
    delete_dns_rr_onlease_expiry: false
    update_dns_rr_for_old_clients: true
    disable_dns_ptr_rr_update: true
    name_protection: true
~~~

##### v4_filters
* Associated with class in this module: `win_dhcp_server::filter::v4`

The `Optional[Hash]` of `win_dhcp_server::filter::v4`, which consist of MAC addresses, 
either for 'Allow' or 'Deny' filter lists.

Example data:
~~~ yaml
win_dhcp_server::v4_filters:
  'deny list entries with no description':
    list: 'Deny'
    mac_addresses:
      - 'EE-EE-EE-EE-EE-EE'
      - 'B9-B9-B9-B9-B9-B9'
      - 'B8-B8-B8-B8-B8-B8'
      - 'B7-B7-B7-B7-B7-B7'
      - 'B6-B6-B6-B6-B6-B6'
      - 'B5-B5-B5-B5-B5-B5'
      - 'B4-B4-B4-B4-B4-B4'
      - 'B3-B3-B3-B3-B3-B3'
      - 'B2-B2-B2-B2-B2-B2'
      - 'B1-B1-B1-B1-B1-B1'
      - 'B0-B0-B0-B0-B0-B0'
  'AD-AD-AD-AD-AD-AD in Allow':
    list: 'Allow'
    description: 'test allow entries from puppet'
    mac_addresses:
      - 'AD-AD-AD-AD-AD-AD'
  'EA-EA-EA-EA-EA-EA in Deny':
    list: 'Deny'
    description: 'test deny entries from puppet'
    mac_addresses:
      - 'EA-EA-EA-EA-EA-EA'
~~~

##### v4_scopes
* Associated with class in this module: `win_dhcp_server::scope::v4`

The `Optional[Hash]` of `win_dhcp_server::scope::v4` (ipv4 dhcp scopes, not multicast, that's another one).

Example data:
~~~ yaml
win_dhcp_server::v4_scopes:
  'puppet test scope present 0':
    scope_name: 'puppet test scope present 0'
    scope_id: '192.168.98.0'
    subnet_mask: '255.255.255.0'
    start_range: '192.168.98.10'
    end_range: '192.168.98.99'
    lease_duration: '8.00:00:00'
    nap_enable: false
    active_state: 'InActive'
    scope_type: 'Bootp'
    activate_policies: true
  'puppet test scope present 1':
    scope_name: 'puppet test scope present 1'
    scope_id: '192.168.198.0'
    subnet_mask: '255.255.255.0'
    description: 'puppet set random description text'
    superscope_name: 'blah'
    start_range: '192.168.198.110'
    end_range: '192.168.198.199'
    lease_duration: '8.00:00:00'
    nap_enable: false
    active_state: 'InActive'
    scope_type: 'Dhcp'
    activate_policies: true
~~~

##### v4_superscopes
* Associated with class in this module: `win_dhcp_server::scope::super_v4`

The `Optional[Hash]` of `win_dhcp_server::scope::super_v4` (ipv4 dhcp superscopes).

Example data:
~~~ yaml
win_dhcp_server::v4_superscopes:
  'blah':
    scope_ids:
      - '192.168.98.0'
      - '192.168.198.0'
~~~

##### v4_exclusions
* Associated with class in this module: `win_dhcp_server::exclusion::v4`

The `Optional[Hash]` of `win_dhcp_server::exclusion::v4` (ipv4 exclusion ranges, not multicast, that's another one).

Example data:
~~~ yaml
win_dhcp_server::v4_exclusions:
  '192.168.98.50 - 192.168.98.55':
    scope_id: '192.168.98.0'
    start_range: '192.168.98.50'
    end_range: '192.168.98.55'
~~~

##### v4_reservations
* Associated with class in this module: `win_dhcp_server::reservation::v4`

The `Optional[Hash]` of `win_dhcp_server::reservation::v4` (ipv4 in scope reservations).

Example data:
~~~ yaml
win_dhcp_server::v4_reservations:
  'r: 192.168.98.78 in s: 192.168.98.0':
    scope_id: '192.168.98.0'
    client_id: '6c-6c-6c-6c-6c-6c'
    ipaddress: '192.168.98.78'
    reservation_type: 'Both'
    reservation_name: 'mynode.contoso.com'
    description: 'this and that'
~~~

##### v4_multicastscopes
* Associated with class in this module: `win_dhcp_server::scope::multicast_v4`

The `Optional[Hash]` of `win_dhcp_server::scope::multicast_v4` (ipv4 multicast scopes).

Example data:
~~~ yaml
win_dhcp_server::v4_multicastscopes:
  'multi-testy-scope':
    scope_name: 'multi-testy-scope'
    start_range: '229.0.0.1'
    end_range: '229.0.1.3'
    description: 'descriptive text'
    expiry_time: '1/1/2021 1:01:01 AM'
    lease_duration: '20.00:00:00'
    active_state: 'InActive'
    ttl: 32
~~~

##### v4_multicastexclusions
* Associated with class in this module: `win_dhcp_server::exclusion::multicast_v4`

The `Optional[Hash]` of `win_dhcp_server::exclusion::multicast_v4` (ipv4 multicast scope exclusion ranges).

Example data:
~~~ yaml
win_dhcp_server::v4_multicastexclusions:
  '229.0.0.23_229.0.0.31':
    scope_name: 'multi-testy-scope'
    start_range: '229.0.0.23'
    end_range: '229.0.0.31'
~~~

##### v4_classes
* Associated with class in this module: `win_dhcp_server::class::v4`

The `Optional[Hash]` of `win_dhcp_server::class::v4` (ipv4 user / vendor classes).

Example data (class_data is the backend 'ASCIIData' as a string, for readability, and this is what the backend takes):
~~~ yaml
win_dhcp_server::v4_classes:
  'User - contoso1 - contoso1':
    class_type: 'User'
    class_name: 'contoso1'
    class_data: 'contoso1'
  'Vendor - contoso - contoso':
    class_type: 'Vendor'
    class_name: 'contoso'
    class_data: 'contoso'
    description: 'puppet set description'
~~~

##### v4_policies
* Associated with class in this module: `win_dhcp_server::policy::v4`

The `Optional[Hash]` of `win_dhcp_server::policy::v4` (ipv4 policies. can target server or scope).

Example data:
~~~ yaml
win_dhcp_server::v4_policies:
  'puppet server policy 0 at s: 0.0.0.0':
    policy_name: 'puppet server policy 0'
    scope_id: '0.0.0.0'
    processing_order: 1
    condition_operator: 'OR'
    vendor_class:
      - 'EQ'
      - 'Microsoft Options'
      - 'EQ'
      - 'contoso'
    user_class:
      - 'EQ'
      - 'contoso1'
    mac_addresses:
      - 'EQ'
      - 'ea-ea-ea-*'
    client_id:
      - 'EQ'
      - '0f-*'
    fqdn:
      - 'EQ'
      - 'contoso.*'
    relay_agent:
      - 'EQ'
      - '0f-1a-*'
    circuit_id:
      - 'EQ'
      - '02-00'
      - 'EQ'
      - '01-00'
    remote_id:
      - 'EQ'
      - '0f'
    subscriber_id:
      - 'EQ'
      - '11'
    lease_duration: '10.00:00:00'
  'puppet scope policy 0 at s: 192.168.98.0':
    policy_name: 'puppet scope policy 0'
    scope_id: '192.168.98.0'
    processing_order: 1
    condition_operator: 'OR'
    vendor_class:
      - 'EQ'
      - 'Microsoft Options'
      - 'EQ'
      - 'contoso'
    user_class:
      - 'EQ'
      - 'contoso1'
    mac_addresses:
      - 'EQ'
      - 'ea-ea-ea-*'
    client_id:
      - 'EQ'
      - '0f-*'
    relay_agent:
      - 'EQ'
      - '0f-1a-*'
    circuit_id:
      - 'EQ'
      - '02-00'
      - 'EQ'
      - '01-00'
    remote_id:
      - 'EQ'
      - '0f'
    subscriber_id:
      - 'EQ'
      - '11'
    lease_duration: '10.00:00:00'
~~~

##### v4_policy_ipranges
* Associated with class in this module: `win_dhcp_server::policy::iprange_v4`

The `Optional[Hash]` of `win_dhcp_server::policy::iprange_v4` (ipv4 policy IP ranges).

Example data:
~~~ yaml
win_dhcp_server::v4_policy_ipranges:
  '192.168.98.44_192.168.98.55 in s: 192.168.98.0':
    policy_name: 'puppet scope policy 0'
    scope_id: '192.168.98.0'
    start_range: '192.168.98.44'
    end_range: '192.168.98.55'
~~~

##### v4_optiondefinitions
* Associated with class in this module: `win_dhcp_server::option::definition_v4`

The `Optional[Hash]` of `win_dhcp_server::option::definition_v4` (ipv4 option definitions).

Example data:
~~~ yaml
win_dhcp_server::v4_optiondefinitions:
  'option id 252':
    option_id: 252
    definition_name: 'WPAD'
    value_data_type: 'String'
    default_value:
      - 'my.proxy.for.autodiscovery'
  'option id 1 in contoso':
    vendor_class: 'contoso'
    option_id: 1
    definition_name: 'puppetdefinition1'
    value_data_type: 'String'
    default_value:
      - 'contoso'
    description: 'descriptive text blah blah'
  'option id 11 in contoso':
    vendor_class: 'contoso'
    option_id: 11
    definition_name: 'puppetdefinition11'
    value_data_type: 'String'
    default_value:
      - 'contoso'
      - 'MSFT'
    multivalued: true
    description: 'descriptive text blah blah'
~~~

##### v4_optionvalues
* Associated with class in this module: `win_dhcp_server::option::value_v4`

The `Optional[Hash]` of `win_dhcp_server::option::value_v4` (ipv4 option values).

Example data:
~~~ yaml
win_dhcp_server::v4_optionvalues:
  'id: 15':
    option_id: 15
    value:
      - 'contoso.com'
  'id: 1 v: contoso':
    option_id: 1
    value:
      - 'this is a value'
    vendor_class: 'contoso'
  'id: 11 v: contoso':
    option_id: 11
    value:
      - 'another_target_to_test'
    vendor_class: 'contoso'
  'id: 1 v: contoso u: contoso1':
    option_id: 1
    value:
      - 'targetme_another_value'
    vendor_class: 'contoso'
    user_class: 'contoso1'
  'id: 51 s:192.168.98.0':
    option_id: 51
    scope_id: '192.168.98.0'
    value:
      - '604800'
~~~

## Reference - class by class

While you can used the defined resources discussed below directly, it is strongly advised you access they via 
`win_dhcp_server`  `/manifests/init.pp` - which will load hash of hashes you provide it, and execute their 
creation / management in a manner which is likely to succeed.

As such, in this section, we will discuss particulars and any restrictions to be aware of inherent in the DHCP server
technology or the PowerShell backend this module drives.

**We'll exclude params to these classes that relate to logging of the resource execution or tagging, and ensure state,
for the sake of brevity.**

You will find example data to drive creation of these defined resources via `win_dhcp_server` in 
`example_data/myserver.contoso.com.yaml`, and in earlier sections of this document.

The templated PowerShell which drives the action of this module will validate a lot of your specified data, check IP ranges are valid,
boot you for using forbidden combinations of potential param options etc etc.  Examine them in the `/templates` directory subtree.

### win_dhcp_server::binding::v4

#### params
~~~ puppet
define win_dhcp_server::binding::v4 (
  String[1] $mac_address                              = $title,
  Optional[Boolean] $binding_state                    = undef
) {...}
~~~
##### mac_address
MAC address for binding state management

##### binding_state
This param is optional, as it is not considered when in `ensure => absent` - in such a case, the interface either exists
as a potential network interface with a IPv4 address, and if such is so will be set to binding_state false.

### win_dhcp_server::class::v4

#### params
~~~ puppet
define win_dhcp_server::class::v4 (
  Optional[Enum['User', 'Vendor']] $class_type        = undef, 
  Optional[String[1]] $class_data                     = undef, 
  Optional[String[1]] $class_name                     = undef, 
  Optional[String] $description                       = undef
) {...}
~~~

##### class_type
'User' or 'Vendor' - the type of class.  It is required for ensure => present in the relevant templated PowerShell.

##### class_data
the ASCIIData for the class (you dont need to specify the raw byte data).  This is the format on creation for the
PowerShell backend.

##### class_name
The name of the class, which must be unique among those of the class type.

##### description
String of description text for the object

### win_dhcp_server::dns::v4

#### params
~~~ puppet
define win_dhcp_server::dns::v4 (
  Optional[String[1]] $scope_id                                         = undef,
  Optional[String[1]] $reserved_ip                                      = undef,
  Optional[String[1]] $policy_name                                      = undef,
  Optional[Boolean] $delete_dns_rr_onlease_expiry                       = undef, #!! can only be set if the DynamicUpdate parameter is set to Always or OnClientRequest.
  Optional[Boolean] $disable_dns_ptr_rr_update                          = undef, 
  Optional[String[1, 256]] $dns_suffix_for_registration                 = undef, #!! Do not specify this parameter unless you specify the PolicyName parameter.
  Optional[Enum['Always', 'Never', 'OnClientRequest']] $dynamic_updates = undef,
  Optional[Boolean] $name_protection                                    = undef, #!! cannot be set on reserved_ip
  Optional[Boolean] $update_dns_rr_for_old_clients                      = undef
) {...}
~~~

##### scope_id
Optionally specify the scope_id (alone or with policy_name) with which the dns settings are associated.

##### reserved_ip
Optionally specify the reserved IP with which the dns settings are associated.

##### policy_name
Optionally specify the policy name with which the dns settings are associated.

##### delete_dns_rr_onlease_expiry
Optionally specify whether resource records created for a lease client should be deleted on the expiry of the lease

##### disable_dns_ptr_rr_update
Optionally specify whether PTR (reverse lookup) resource records should NOT be updated for a lease client / IP.

##### dns_suffix_for_registration
Optionally specify a dns suffix to use in dns record registration. Only specify for policies / policies in scopes.

##### dynamic_updates
Optionally specify whether dynamic updates are enabled for dns resource records at this dns setting target.

NOTE: you cannot set `delete_dns_rr_onlease_expiry` as `true` if `dynamic_updates` is `Never`

##### name_protection
Optionally specify name protection options for the dns settings target.

NOTE: you cannot set name protection (either true or false, at all) when the target of settings is a reserved IP.

NOTE: some settings cannot be changed specifically when name protection is enabled.  if these linked settings desired state is 
changed the module will have no choice but to temporarily set name protection off, make changes, and set name protection to the
desired state as specified in the hash resource for the settings target. this will result in ~1s or so where there is 
associated change in name protection state.  This will be logged in the last run report, and will emit to an interactive run

### win_dhcp_server::exclusion::multicast_v4

#### params
~~~ puppet
define win_dhcp_server::exclusion::multicast_v4 (
  String[1] $scope_name,
  String $start_range                                 = '',
  String $end_range                                   = '',
) {...}
~~~

##### scope_name
The IPv4 multicast scope name (not scope id as with regular exclusion ranges, 
in this case of multicast exclusion ranges) to target.  

NOTE: if no 'start_range' and / or 'end_range' are specified and ensure => absent, ALL exclusion ranges in the scope_name
will be removed.

##### start_range
The start of the IPv4 multicast exclusion range to target

##### end_range
The end of the IPv4 multicast exclusion range to target

### win_dhcp_server::exclusion::v4

#### params
~~~ puppet
define win_dhcp_server::exclusion::v4 (
  String[1] $scope_id,
  String $start_range                                 = '',
  String $end_range                                   = '',
) {...}
~~~
##### scope_id
The IPv4 multicast scope ID to target.  

NOTE: if no 'start_range' and / or 'end_range' are specified and ensure => absent, ALL exclusion ranges in the scope_id
will be removed.

##### start_range
The start of the IPv4 exclusion range to target

##### end_range
The end of the IPv4 exclusion range to target

### win_dhcp_server::filter::v4
not to be confused with enable state management of the filter list functionality in `win_dhcp_server::global::filterlist`,
this resource type is associated with entries in the 'Allow'/'Deny' MAC filter lists, and pays no concern as to the enable state
of those lists - you're either on a list or not.

If you have entries in one, and you change desired configuration to the other (e.g. ALLOW to DENY) those entries will be moved
between lists.  It is not possible for a MAC address to be both on the Allow AND Deny list.  Configuring such will result
in ever changing state as the result is conflicting information on mac list presence.

#### params
~~~ puppet
define win_dhcp_server::filter::v4 (
  Enum['Allow', 'Deny'] $list,
  Array[String[1]] $mac_addresses,
  Optional[String] $description                       = undef
) {...}
~~~

##### list
'Allow' or 'Deny' - the list being targeted by the resource.

##### mac_addresses
An array of mac addresses being targeted.

##### description
Optionally descriptive text for the filter entries (e.g. 'a strange and terrible print device')

### win_dhcp_server::global::audit
This class (if you follow advice repeated throughout this readme) straps global auditing options for the DHCP server as part 
of init.pp.

#### params
~~~ puppet
class win_dhcp_server::global::audit (
  Boolean $auditlog_enable                            = true,
  String[1] $auditlog_path                            = "${facts['system32']}\\dhcp",
  Integer[0, 4294967295] $auditlog_max_size_mb        = 70,
  Integer[2, 4294967295] $auditlog_diskcheck_interval = 50,
  Integer[0, 4294967295] $auditlog_min_diskspace_mb   = 20,
) {...}
~~~

These params are discussed in earlier sections of this document, where the actions of `win_dhcp_server` / `init.pp` are
discussed.

### win_dhcp_server::global::database
This class (if you follow advice repeated throughout this readme) straps global database options for the DHCP server as part 
of init.pp.

#### params
~~~ puppet
class win_dhcp_server::global::database (
  String[1] $database_filename                        = "${facts['system32']}\\dhcp\\dhcp.mdb",
  String[1] $database_backup_path                     = "${facts['system32']}\\dhcp\\backup",
  Integer[1, 71582] $database_backup_interval_min     = 30,
  Integer[1, 71582] $database_cleanup_interval_min    = 60,
) {...}
~~~

These params are discussed in earlier sections of this document, where the actions of `win_dhcp_server` / `init.pp` are
discussed.

### win_dhcp_server::global::filterlist
This class (if you follow advice repeated throughout this readme) straps global database options for the DHCP server as part 
of init.pp.

#### params
~~~ puppet
class win_dhcp_server::global::filterlist (
  Boolean $enable_v4_allow,
  Boolean $enable_v4_deny,
) {...}
~~~

These params are discussed in earlier sections of this document, where the actions of `win_dhcp_server` / `init.pp` are
discussed.

### win_dhcp_server::global::general
This class (if you follow advice repeated throughout this readme) straps global database options for the DHCP server as part 
of init.pp.

#### params
~~~ puppet
class win_dhcp_server::global::general (
  Boolean $nap_enable                                            = false,
  Enum['Full', 'Restricted', 'NoAccess'] $nps_unreachable_action = 'Full',
  Boolean $activate_policies                                     = true,
  Integer[0, 5] $conflict_detection_attempts                     = 0,
) {...}
~~~

These params are discussed in earlier sections of this document, where the actions of `win_dhcp_server` / `init.pp` are
discussed.

### win_dhcp_server::option::definition_v4

#### params
~~~ puppet
define win_dhcp_server::option::definition_v4 (
  Integer[1, 255] $option_id,
  Optional[String[1]] $definition_name                  = undef,
  Optional[Enum['Byte', 
  'Word', 'DWord',
  'DWordDword', 'IPAddress',
  'String', 'BinaryData', 
  'EncapsulatedData', 'IPv6Address']] $value_data_type  = undef,
  Optional[Array[String[1]]] $default_value             = undef,
  Optional[String] $description                         = undef,
  Optional[Boolean] $multivalued                        = undef,
  Optional[String[1]] $vendor_class                     = undef,
) {
~~~

##### option_id
The Option id to define, an integer 1-255.  Can be combined with 'vendor_class' to create option id definitions for
that vendor class.

##### definition_name
Required when ensure => present, optional when ensure => absent (enforced in rendered EPP).  The name of the option
being defined in $null or vendor class

##### value_data_type
Required when ensure => present, not included when ensure => absent. The value data type.

##### default_value
The (optional) default value for the option being defined.  It is always an array, even in case of
1 element array with a string value at index 0.
* Byte, Word, DWord, DWordDword. - These values can be specified as decimal or hexadecimal strings.
* IPAddress, IPv6Address. - These values can be specified as IP address strings.
* String. - This value can be specified as a string.
* BinaryData, EncapsulatedData. - These values can be specified as hexadecimal strings.

##### description
Optional descriptive string for the option being defined

##### multivalued
Required when ensure => present, optional when ensure => absent (enforced in rendered EPP). Boolean true if the value
data can contain an array with a length of greater than 1.

##### vendor_class
The (optional) vendor class for the option being defined.  Options defined with no vendor class end up as default
options - an example of one such common to add might be option ID 252, with a name of 'WPAD', value_data_type 'String'
and a default value of a web proxy that supports windows proxy auto discovery.

### win_dhcp_server::option::value_v4
Manage option values (which must exist either by default or via creation with `win_dhcp_server::option::definition_v4`).
Utilizing the ordering in `init.pp` / `win_dhcp_server` will assure options are defined prior to attempting to set values
on them, assuming you feed correct data to it.

#### params
~~~ puppet
define win_dhcp_server::option::value_v4 (
  Integer[1, 255] $option_id,
  Optional[Array[String[1]]] $value                   = undef,
  Optional[String[1]] $policy_name                    = undef,
  Optional[String[1]] $reserved_ip                    = undef,
  Optional[String[1]] $scope_id                       = undef,
  Optional[String[1]] $user_class                     = undef,
  Optional[String[1]] $vendor_class                   = undef,
) {...}
~~~

##### option_id
The option id to target.

##### value
An array of string values for the option, appropriately formatted for the data type of the option.
* Byte, Word, DWord, DWordDword. - These values can be specified as decimal or hexadecimal strings.
* IPAddress, IPv6Address. - These values can be specified as IP address strings.
* String. - This value can be specified as a string.
* BinaryData, EncapsulatedData. - These values can be specified as hexadecimal strings.

###### policy_name
Optionally specify a policy name for targeting option.

##### reserved_ip
Optionally specify a reserved IP for targeting.  Do not combine with 'policy_name' 
(doing so will cause the resource to be rejected).

##### scope_id
Optionally specify a scope ID for targeting.  Remember, you can target scope policies by combining policy_name with 
scope_id.

##### user_class
Optionally specify a user class for targeting.

##### vendor_class
Optionally specify a vendor class for targeting.

### win_dhcp_server::policy::iprange_v4
A policy on a scope, **NOT a server level policy**, can be restricted to be applicable to IP ranges, rather than a scope
in its entirety, should this be desired.

Attempting to set a policy IP range on scope ID '0.0.0.0' will cause the resource to be rejected, as this is targeting
of a server level policy.

#### params
~~~ puppet
define win_dhcp_server::policy::iprange_v4 (
  String[1] $policy_name,
  String[1] $scope_id,
  Optional[String[1]] $start_range                    = undef, #always required in epp for ensure => present, if undef in absent, kill all ranges in scope for policy
  Optional[String[1]] $end_range                      = undef, #^can specify start or end range as target for removal, as can have several ranges in a scope
) {...}
~~~

##### policy_name
The name of the policy to target for policy IP range management.

##### scope_id
The scope_id of the scope level policy to manage an IP range for.

##### start_range
Required when ensure => present, optional when ensure => absent.  The start of the IP range being managed.

##### end_range
Required when ensure => present, optional when ensure => absent.  The end of the IP range being managed.

### 

#### params
~~~ puppet
define win_dhcp_server::policy::v4 (
  String[1] $policy_name,
  String[1] $scope_id                                 = '0.0.0.0',
  Boolean $enabled                                    = true,
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
) {...}
~~~ 

REMEMBER: should you find this particular syntax horrific, feel free to use the mmc snap-in for dhcp server management,
create a fake policy with the conditional logic set you care to configure, then export the puppet yaml of that by
utilizing `util/GenerateYaml.psm1` as described earlier in this document.  Grab the bit you want and you've a start
for what you're trying to do.  

(PS - you'll find 'relay_agent', 'circuit_id', 'remote_id', 'subscriber_id' in the 'Relay Agent Information' criteria
menu, as these settings pertain to it - in the policy properties conditions tab, in the dhcp server mmc snap-in)

An example of yaml showing the somewhat nasty stanza based syntax used in DHCP policies:
~~~ yaml
~~~ yaml
win_dhcp_server::v4_policies:
  'puppet server policy 0 at s: 0.0.0.0':
    policy_name: 'puppet server policy 0'
    scope_id: '0.0.0.0'
    processing_order: 1
    condition_operator: 'OR'
    vendor_class:
      - 'EQ'
      - 'Microsoft Options'
      - 'EQ'
      - 'contoso'
    user_class:
      - 'EQ'
      - 'contoso1'
    mac_addresses:
      - 'EQ'
      - 'ea-ea-ea-*'
    client_id:
      - 'EQ'
      - '0f-*'
    fqdn:
      - 'EQ'
      - 'contoso.*'
    relay_agent:
      - 'EQ'
      - '0f-1a-*'
    circuit_id:
      - 'EQ'
      - '02-00'
      - 'EQ'
      - '01-00'
    remote_id:
      - 'EQ'
      - '0f'
    subscriber_id:
      - 'EQ'
      - '11'
    lease_duration: '10.00:00:00'
~~~

##### policy_name
The policy name being targeted.

##### scope_id
The scope id being targeted. '0.0.0.0' is the default value, and refers to policies bound to all, or '0.0.0.0' - a server
level policy.  If targeting a scope level policy, utilize an appropriate scope_id.

##### enabled
The enable state of the policy, where boolean true indicates that the policy is enabled.

##### condition_operator
The logical operator between conditions when multiple conditions are specified. 
The acceptable values for this parameter are: 'AND' and 'OR'.

##### circuit_id
Specifies the comparator to use and the values with which to compare the circuit id sub-option. 

The first element is the comparator, either EQ or NE, followed by a single value.

If the last character in a value is an asterisk, then the subsequent characters are treated as wildcard characters 
for the comparison. 

If the first character in a value-element is an asterisk, the preceding characters are treated 
as wildcard characters for comparison.

The value can again be followed by another comparator, either 'EQ' or 'NE', which is followed by another value for 
comparison.

**The input format (per non-logic array element) for the value is a hexadecimal string with or without hyphen separation.**

That's the MSFT blurb; what it amounts to is a string array with conditional stanza that are read from index 0 and on.

You'll see an example of yaml data for this class above in this section.

You either target by having one of the conditions met with 'condition_operator' 'OR', or needing to match them all with
'AND'.  This, as one might imagine, can require you to create a number of policies to achieve the desired policy application
state across your DHCP server configuration.

##### client_id
Specifies the comparator to use and the values with which to compare client identifier. 

The first element is the comparator, either EQ or NE, and subsequent elements are values.

If the last character in a value is an asterisk, then the subsequent characters are treated as wildcard characters 
for the comparison. 

If the first character in a value-element is an asterisk, the preceding characters are treated 
as wildcard characters for comparison.

The values can again be followed by another comparator, either EQ or NE, which is followed by another set of values 
for comparison.

**The input format (per non-logic array element) is a hexadecimal string with or without hyphen separation.**

For example: `['EQ', '00-11-22-33-44-55', 'AA-BB-CC-DD-EE*']`

The values that follow the EQ operator are treated as multiple assertions which are logically combined (OR'd).

The values that follow the NE operator are treated as multiple assertions which are logically differenced (AND'd).

You'll see an example of yaml data for this class above in this section.

##### fqdn
Specifies the comparator to use and the values with which to compare the fully qualified domain name (FQDN) in the 
client request. 

The first element is the comparator, 'EQ', 'NE', 'Isl', or 'Insl', and the subsequent elements are 
values. 

For the comparators Island 'Insl', use a blank value. 

If the last character in a value is an asterisk, then the subsequent characters are treated as wildcard characters 
for the comparison. If the first character in a value-element is an asterisk, the preceding characters are treated 
as wildcard characters for comparison.

The values can again be followed by another comparator, 'EQ' or 'NE', which is followed by another set of values.

A trailing wildcard character can be present to indicate partial match.

The values that follow the 'EQ' operator are treated as multiple assertions which are logically combined (OR'd).

The values that follow the 'NE' operator are treated as multiple assertions which are logically differenced (AND'd).

You'll see an example of yaml data for this class above in this section.

##### mac_addresses
Specifies the comparator to use and the values with which to compare the MAC Address in the client request. 

The first element is the comparator, EQ or NE, and the subsequent elements are values. 

If the last character in a value is an asterisk, then the subsequent characters are treated as wildcard characters 
for the comparison. 

If the first character in a value-element is an asterisk, the preceding characters are treated as for comparison.

The values can again be followed by another comparator, 'EQ' or 'NE', which is followed by another set of values.

**The input format (per non-logic array element) is a hexadecimal string with or without hyphen separation.** 

A trailing wildcard character can be present to indicate partial match. 

For example: `['EQ','00-1F-3B-7C-B7-89', '00-1F-3B-7C-B7-*', '001F3B7CB789','NE','FF-FF-FF-FF-FF-FF']`. 

The values that follow the EQ operator are treated as multiple assertions which are logically combined (OR'd).

The values that follow the NE operator are treated as multiple assertions which are logically differenced (AND'd).

You'll see an example of yaml data for this class above in this section.

##### relay_agent
Specifies the comparator to use and values with which to compare the relay agent information. 

The first element is the comparator, 'EQ' or 'NE', and subsequent elements are values. 

If the last character in a value is an asterisk, then the subsequent characters are treated as wildcard characters 
for the comparison. 

If the first character in a value-element is an asterisk, 
the preceding characters are treated as wildcard characters for comparison.

The values can again be followed by another comparator, 'EQ' or 'NE', which is followed by another set of values.

**The input format (per non-logic array element) is a hexadecimal string with or without hyphen separation.**

You'll see an example of yaml data for this class above in this section.

##### remote_id
Specifies the comparator to use and values with which to compare the remote ID sub-option.

The first element is the comparator, EQ or NE, followed by a single value.

If the last character in a value is an asterisk, then the subsequent characters are treated as wildcard characters 
for the comparison. 

If the first character in a value-element is an asterisk, the preceding characters are treated as wildcard 
characters for comparison.

The value can again be followed by another comparator, 'EQ' or 'NE', which is followed by another value.

**The input format (per non-logic array element) for the value is a hexadecimal string with or without hyphen separation.**

You'll see an example of yaml data for this class above in this section.

##### subscriber_id
Specifies the comparator to use and the values with which to compare the subscriber ID sub-option. 

The first element is the comparator, 'EQ' or 'NE', and followed by a single value. 

If the last character in a value is an asterisk, then the subsequent characters are treated as wildcard characters 
for the comparison. 

If the first character in a value-element is an asterisk, the preceding characters are treated as wildcard characters 
for comparison.

The value can again be followed by another comparator, 'EQ' or 'NE', which is followed by another value.

**The input format (per non-logic array element) is a hexadecimal string with or without hyphen separation.**

You'll see an example of yaml data for this class above in this section.

##### user_class
Specifies the comparator to use and the user class values to compare with the user class field in the client request. 

The first element to be specified is the comparator, 'EQ' or 'NE', and the subsequent elements are values. 

If the last character in a value is an asterisk, then the subsequent characters are treated as wildcard characters 
for the comparison. 

If the first character in a value-element is an asterisk, the preceding characters are treated as wildcard characters 
for comparison.

The values can again be followed by another comparator, 'EQ' or 'NE', which is followed by another set of values.

The values to be specified are the user class names which already exist on the server.

The values that follow the 'EQ' operator are treated as multiple assertions which are logically combined (OR'd).

The values that follow the 'NE' operator are treated as multiple assertions which are logically differenced (AND'd).

You'll see an example of yaml data for this class above in this section.

##### vendor_class
Specifies the comparator to use and vendor class values to compare with the vendor class field in the client request. 

The first element is the comparator, 'EQ' or 'NE', and the subsequent elements are values. 

If the last character in a value is an asterisk, then the subsequent characters are treated as wildcard characters 
for the comparison. 

If the first character in a value-element is an asterisk, the preceding characters are treated as wildcard characters 
for comparison.

The values can again be followed by another comparator, 'EQ' or 'NE', which is followed by another set of values.

**The values to be specified are the vendor class names which already exist on the server.**

The values that follow the 'EQ' operator are treated as multiple assertions which are logically combined (OR'd).

The values that follow the 'NE' operator are treated as multiple assertions which are logically differenced (AND'd).

##### description
Optionally specify string of descriptive text for the policy being targeted.

##### lease_duration
string timespan of the lease duration associated with the policy.

format is: day.hrs:mins:secs e.g. '8.00:00:00'   #(8 days)

##### processing_order
Specifies the order of this policy with regard to other policies in the scope or server. 

The DHCP server service processes the policies in the specified order when evaluating client requests.

### win_dhcp_server::prereq::check
Called as a require by other classes in this module, it checks that: 
* the windows feature 'DHCP' is installed on the node
* the service 'dhcpserver' is present on the node
* the powershell module 'dhcpserver' is present on the node and at a major version equal or greater to 2.

These checks are done without creation, consideration or requirement for associated puppet resources external to
this module.

#### params
~~~ puppet
class win_dhcp_server::prereq::check (
  Integer[0, 65535] $module_majorversion              = 2,
  String[1] $winfeature                               = 'DHCP',
  String[1] $servicename                              = 'dhcpserver',
) {...}
~~~

##### module_majorversion
Modification of this param value away from its default is not supported.

##### winfeature
Modification of this param value away from its default is not supported.

##### servicename
Modification of this param value away from its default is not supported.

### win_dhcp_server::reservation::v4

#### params
~~~ puppet
define win_dhcp_server::reservation::v4 (
  String[1] $scope_id, 
  String[1] $client_id, 
  String $ipaddress                                         = '',
  Optional[String] $reservation_name                        = undef,
  Optional[String] $description                             = undef,
  Optional[Enum['Dhcp', 'Bootp', 'Both']] $reservation_type = undef,
) {...}
~~~

##### scope_id
The scope id in which the reservation exists, should (not) exist.

##### client_id
The MAC addresss for the reservation

##### ipaddress
The IP address to reserve, it must be valid within the scope_id and subnet mask of the scope in question.
The default of '' can be relevant when ensure => absent, when the MAC alone can be used for removal of a reservation.

##### reservation_name
Optionally specify a name for the reservation, which can be useful in identification

##### description
Optional string of descriptive text for the reservation

##### reservation_type
Optional reservation type.  The backend default (if not specified as a param to the resource) is 'Both'.

### win_dhcp_server::scope::multicast_v4

#### params
~~~ puppet
define win_dhcp_server::scope::multicast_v4 (
  String[1] $scope_name                               = $title,
  Optional[String[1]] $start_range                    = undef,
  Optional[String[1]] $end_range                      = undef,
  Optional[String] $description                       = undef,
  Optional[String[1]] $expiry_time                    = undef,
  Optional[String[1]] $lease_duration                 = undef,
  Optional[Enum['Active', 'InActive']] $active_state  = undef,
  Optional[Integer[1, 255]] $ttl                      = undef,
) {...}
~~~

##### scope_name
The scope name for targeting. There is no concept of a 'scope_id' or subnet mask with multicast v4 scopes, 
its basically a range of IPs within the multicast CIDR blocks.

##### start_range
The start of the multicast scope IP range. Optional when ensure => absent.

##### end_range
The end of the multicast scope IP range.  Optional when ensure => absent.

##### description
Optional string of descriptive text for the multicast scope.

##### expiry_time
The expiry time of the multicast scope.  The backend default (when not specified as a param to this resource) is
an non-expiring multicast scope.

time format like "1/1/2020 0:01 AM"

##### lease_duration
the lease duration for the multicast scope. dd.hh:mm:ss - e.g. '20.0:0:0' (20 days)

##### active_state
String value indicating whether the multicast scope is 'Active' or 'InActive'.

##### ttl
Integer number of routers traffic will pass through, backend default is 32 (when not specified as a param to this resource)

### win_dhcp_server::scope::super_v4

#### params
~~~ puppet
define win_dhcp_server::scope::super_v4 (
  String[1] $superscope_name                          = $title,
  Optional[Array[String[1]]] $scope_ids               = undef,
) {...}
~~~

##### superscope_name
The name of the super scope, it must be unique amongst superscopes.

##### scope_ids
An array of strings, specifying the scope_ids which should be members of the super scope.

Optional when ensure => absent, required when ensure => present. (you cannot create a superscope with no scope members,
removal of the final member of a super scope removes the superscope - enforced in EPP).

### win_dhcp_server::scope::v4

#### params
~~~ puppet
define win_dhcp_server::scope::v4 (
  String[1] $scope_id,
  String $start_range                                 = '',
  String $end_range                                   = '',
  String $subnet_mask                                 = '',
  String $scope_name                                  = $title,
  Enum['Dhcp', 'Bootp', 'Both'] $scope_type           = 'Both'
  Optional[Boolean] $activate_policies                = undef,
  Optional[Integer[0, 1000]] $delay_ms                = undef,
  Optional[String] $description                       = undef,
  Optional[String[1]] $lease_duration                 = undef,
  Optional[Integer[0, 4294967295]] $max_bootp_clients = undef,
  Optional[Boolean] $nap_enable                       = undef,
  Optional[String[1]] $nap_profile                    = undef,
  Optional[Enum['Active', 'InActive']] $active_state  = undef,
  Optional[String[1]] $superscope_name                = undef,
) {...}
~~~

##### scope_id
The scope_id (the network ID) of the targeted scope.

##### start_range
The start of the IP range served by the scope.  Validation of IP used being in range of the network ID and mask will
occur when ensure => present.  Required when ensure => present as a non empty value (enforced in EPP).

##### end_range
The end of the IP range served by the scope.  Validation of IP used being in range of the network ID and mask will
occur when ensure => present.  Required when ensure => present as a non empty value (enforced in EPP).

##### subnet_mask
The subnet mask of the scope.  Combining with scope_id will establish the valid start/end range for serve bounds,
as well as bounds for any reservations or exclusions that may be created (reservations do not have to be within the
served start/end range. 

e.g. you could have a start/end of x.x.x.100-x.x.x.200, while creating reservations at
x.x.x.201 for example, when the scope id is x.x.x.0 with a subnet mask of 255.255.255.0).

##### scope_name
Optional name for the scope, does NOT need to be unique amongst scope names on server.

##### scope_type
The scope type.

NOTE: must be 'Both' to consider param 'max_bootp_clients' when ensure => present.

##### activate_policies
Specifies the enabled state of the policy enforcement on the scope that is added where Boolean true indicates policy
enablement.

Backend default (when no param value specified to this resource) is true.

##### delay_ms
Specifies the Integer number of milliseconds by which the DHCP server service should wait before responding 
to the client requests. 

Specify this parameter if the scope is part of a split scope deployment and this DHCP server service should act 
as a secondary DHCP server service for the scope being added.

The backend default (when no param value is specified to this resource) is 0 - or no delay in response.

##### description
Optional string of descriptive text for the scope.

##### lease_duration
Optional lease duration for the scope.  The backend default is 8 days.
String time format: dd.hh:mm:ss e.g. '8.0:0:0'

##### max_bootp_clients
Relevant only when ensure => present and 'scope_type' 'Both'.
Specifies the max number of bootp clients which will be served within the scope at a given time, when DHCP and BootP
clients compete for addresses within the scope.

##### nap_enable
Optional boolean specifying whether or not NAP is enabled for the scope.
A valid configuration must exist external to this module, or setting this true will cause the resource to fail.

##### nap_profile
Optional string name of the nap profile associated with this scope.
A valid configuration must exist external to this module, or setting this value will cause the resource to fail.

##### active_state
Optional string 'Active' or 'InActive' - specifies whether or not the scope is active and serving to interfaces
where DHCP v4 services are bound. 

Backend default is 'Active' (when no param value is specified to this resource).

##### superscope_name
The optional name of the superscope with which this scope is associated.

Be aware that you can manage scope memberships of superscopes with `win_dhcp_server::scope::super_v4`

**Don't provide conflicting information on the scope configuration versus that which would add the 
scope_id to a superscope configuration.**

To not be a member of a super scope, set this value to '' (an empty string) - which is the backend default
when no param value is specified for this resource - i.e. a newly created scope without this param is not
a member of a named superscope, or more specifically is a member of the super scope with name ''.


## Development - Guide for contributing to the module

I enjoy all contributions, want to know about issues you encounter should you do so (there is a lot going
on in this module).

Could use someone to do IPv6 supported features.

I'm in two minds about implementing failover support - as we'd need to consider inter-machine state,
and certainly where I've been involved there tends to be replication of config and control of relay agents
as an alternative.

Performance of the module (~=<1s per resource) could be improved, by not considering all resources to be managed as individual resources, 
instead feeding in the entire block of the desired config for scopes as an example, and processing it as a whole.

I chose not to do this for a couple of reasons:
* i want the puppet practitioner to be able to define and use the resources as single units
* i have no choice when working with windows but to interact with API based OS components.
By this I mean, we're not just editing files, we're interfacing with a database management system front
ended by DHCP server services, and other relevant function.
  * in other words, we're doing this with PowerShell, either as I have via templated execs and defined
  resources - or should you please as type/provider wrapped versions of the same thing (which would still need
  to go via PowerShell, and either hook into existing powershell provider, or replicate (no) its function).

In practice I've got enterprise systems running 1000 resources or so in this module, takes a new machine
under 2016 no GUI 2x vCPU and 16GB ram around 900 seconds to converge, and around 450 seconds to check 
on unchanged runs.

As you'll notice, the unless blocks, which run to determine if change is required, here often involve
very detailed analysis of the backend objects in question.

I could cache state, but that induces a lag and potential for inaccuracy. 

All in all I'm happy, as our my admins - who no longer have to touch DHCP servers as far as IPv4 is 
concerned, and now work with hiera yaml to configure (and partially share config between 
using lookup_options on inherent lookup for various keys!) quite nicely.
