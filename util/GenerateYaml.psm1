function Get-DhcpServerv4Prereqs {
    param([Boolean]$allowModulev1 = $false)

    if($allowModulev1){
        [Int32]$majorversion = 1;
        Write-Warning 'allowing dhcp module v1 due to override';
    }
    else {
        [Int32]$majorversion = 2;
    }

    if ((get-windowsfeature 'DHCP').installstate -ne 'Installed') {
        Write-Warning "'DHCP' windows feature is not installed.";
        return $false;
    };
    if ($null -eq (get-service 'dhcpserver' -ErrorAction SilentlyContinue)) {
        Write-Warning "'dhcpserver' service does not exist.";
        return $false;
    }
    try{import-module dhcpserver;}
    catch [Exception]{
        Write-Warning ("unable to import dhcpserver powerhsell module - {0}" -f $_.Exception.Message);
        return $false;
    }
    [Int32]$probeval = (Get-Module DhcpServer).Version.Major;
    if (0 -eq $probeval) {
        Write-Warning "'dhcpserver' PowerShell module does not exist.";
        return $false;
    }
    if ($probeval -lt $majorversion) {
        Write-Warning "'dhcpserver' PowerShell module major version: ${probeval} too low.";
        return $false;
    }
    return $true;
}
function Get-DhcpServerv4HostYaml {
    param(
        [string]$outputpath,
        [Boolean]$allowModulev1 = $false
    )
    [Boolean]$prereqsMet = Get-DhcpServerv4Prereqs -allowModulev1 $allowModulev1;
    [Int32]$moduleMajorVersion = (Get-Module DhcpServer).Version.Major;
    if (!$prereqsMet) {Write-Error "prerequisites not satisfied. cannot continue."; return; }
    try {import-module dhcpserver; }
    catch [Exception] {Write-Error ("unable to import 'dhcpserver' PowerShell module. cannot continue. - {0}" -f $_.Exception.Message); return; }

    [String[]]$dnsCompareProps = @('DynamicUpdates', 'DeleteDnsRROnLeaseExpiry', 'UpdateDnsRRForOlderClients', 'DnsSuffix', 'DisableDnsPtrRRUpdate', 'NameProtection');
    [String[]]$classAsciiDataIgnoreList = @('RRAS.Microsoft', 'BOOTP.Microsoft', 'MSFT 5.0', 'MSFT 98', 'MSFT');
    [int32[]]$ignoredVendorNullDefs = @(1..49) + @(51, 58, 59) + @(64..76) + @(121);
    [int32[]]$ignoredVendorMsftOpts = @(1..3);
    [String[]]$remainderOptionsFilterVendors = @('Microsoft Windows 2000 Options', 'Microsoft Options');


    [System.Collections.ArrayList]$output = [System.Collections.ArrayList]::new();
    write-host 'Gathering global settings...';
    if ($null -ne (Get-DhcpServerDatabase).FileName) {$output.Add("win_dhcp_server::database_filename: '{0}'" -f "$((Get-DhcpServerDatabase).FileName)".ToLower()) > $null; }
    if ($null -ne (Get-DhcpServerDatabase).BackupPath) {$output.Add("win_dhcp_server::database_backup_path: '{0}'" -f "$((Get-DhcpServerDatabase).BackupPath)".ToLower()) > $null; }
    if ($null -ne (Get-DhcpServerDatabase).BackupInterval) {$output.Add("win_dhcp_server::database_backup_interval_min: {0}" -f (Get-DhcpServerDatabase).BackupInterval) > $null; }
    if ($null -ne (Get-DhcpServerDatabase).CleanupInterval) {$output.Add("win_dhcp_server::database_cleanup_interval_min: {0}" -f (Get-DhcpServerDatabase).CleanupInterval) > $null; }
    if ($null -ne (Get-DhcpServerAuditLog).Enable) {$output.Add("win_dhcp_server::auditlog_enable: {0}" -f "$((Get-DhcpServerAuditLog).Enable)".ToLower()) > $null; }
    if ($null -ne (Get-DhcpServerAuditLog).Path) {$output.Add("win_dhcp_server::auditlog_path: '{0}'" -f "$((Get-DhcpServerAuditLog).Path)".ToLower()) > $null; }
    if ($null -ne (Get-DhcpServerAuditLog).MaxMBFileSize) {$output.Add("win_dhcp_server::auditlog_max_size_mb: {0}" -f (Get-DhcpServerAuditLog).MaxMBFileSize) > $null; }
    if ($null -ne (Get-DhcpServerAuditLog).DiskCheckInterval) {$output.Add("win_dhcp_server::auditlog_diskcheck_interval: {0}" -f (Get-DhcpServerAuditLog).DiskCheckInterval) > $null; }
    if ($null -ne (Get-DhcpServerAuditLog).MinMBDiskSpace) {$output.Add("win_dhcp_server::auditlog_min_diskspace_mb: {0}" -f (Get-DhcpServerAuditLog).MinMBDiskSpace) > $null; }
    if ($null -ne (Get-DhcpServerSetting).ConflictDetectionAttempts) {$output.Add("win_dhcp_server::conflict_detection_attempts: {0}" -f (Get-DhcpServerSetting).ConflictDetectionAttempts) > $null; }
    if ($null -ne (Get-DhcpServerSetting).NapEnabled) {$output.Add("win_dhcp_server::nap_enable: {0}" -f "$((Get-DhcpServerSetting).NapEnabled)".ToLower()) > $null; }
    if ($null -ne (Get-DhcpServerSetting).NpsUnreachableAction) {$output.Add("win_dhcp_server::nps_unreachable_action: '{0}'" -f "$((Get-DhcpServerSetting).NpsUnreachableAction)") > $null; }
    if ($null -ne (Get-DhcpServerSetting).ActivatePolicies) {$output.Add("win_dhcp_server::activate_policies: {0}" -f "$((Get-DhcpServerSetting).ActivatePolicies)".ToLower()) > $null; }
    if ($null -ne (Get-DhcpServerv4FilterList).Allow) {$output.Add("win_dhcp_server::enable_v4_allow_filter_list: {0}" -f "$((Get-DhcpServerv4FilterList).Allow)".ToLower()) > $null; }
    if ($null -ne (Get-DhcpServerv4FilterList).Deny) {$output.Add("win_dhcp_server::enable_v4_deny_filter_list: {0}" -f "$((Get-DhcpServerv4FilterList).Deny)".ToLower()) > $null; }

    if ($null -ne (Get-DhcpServerv4Filter)) {
        write-host 'Gathering MAC filter entries...(if you want to combine these you can, the hash for each mac_addresses is an array, will pull as separate entries if have description)';
        $output.Add('win_dhcp_server::v4_filters:') > $null;

        #allows with no description
        $noDescAllows = (Get-Dhcpserverv4Filter | Where-Object 'Description' -eq '' | Where-Object 'List' -eq 'Allow');
        if ($null -ne $noDescAllows) {
            $output.Add("  'allow list entries with no description':") > $null;
            $output.Add("    list: 'Allow'") > $null;
            $output.Add("    mac_addresses:") > $null;
            foreach ($filterEntry in $noDescAllows) {
                $output.Add(("      - '{0}'" -f $filterEntry.MacAddress)) > $null;
            }
        }
        #denies with no description
        $noDescDenies = (Get-Dhcpserverv4Filter | Where-Object 'Description' -eq '' | Where-Object 'List' -eq 'Deny');
        if ($null -ne $noDescDenies) {
            $output.Add("  'deny list entries with no description':") > $null;
            $output.Add("    list: 'Deny'") > $null;
            $output.Add("    mac_addresses:") > $null;
            foreach ($filterEntry in $noDescDenies) {
                $output.Add(("      - '{0}'" -f $filterEntry.MacAddress)) > $null;
            }
        }
        #others
        $otherFilterEntries = (Get-Dhcpserverv4Filter | Where-Object 'Description' -ne '');
        if ($null -ne $otherFilterEntries) {
            foreach ($filterEntry in $otherFilterEntries) {
                $output.Add(("  '{0} in {1}':" -f $filterEntry.MacAddress, $filterEntry.List)) > $null;
                $output.Add(("    list: '{0}'" -f $filterEntry.List)) > $null;
                $output.Add(("    description: '{0}'" -f $filterEntry.Description)) > $null;
                $output.Add("    mac_addresses:") > $null;
                $output.Add(("      - '{0}'" -f $filterEntry.MacAddress)) > $null;
            }
        }
    }

    [System.Collections.ArrayList]$bindingData = [System.Collections.ArrayList]::new();
    if($null -ne (Get-DhcpServerv4Binding)){
        Write-Host 'generating ipv4 interface binding yaml...';
        foreach($binding in (Get-DhcpServerv4Binding)){
            [System.Collections.ArrayList]$hashdata = [System.Collections.ArrayList]::new();
            $macInHash = (Get-NetAdapter -InterfaceAlias $binding.InterfaceAlias).MacAddress;
            $hashtitle = ("  '{0} - ({1})':" -f $binding.InterfaceAlias, $macInHash);
            $hashdata.Add(("    mac_address: '{0}'" -f $macInHash)) > $null;
            $hashdata.Add(("    binding_state: {0}" -f "$($binding.BindingState)".ToLower() )) > $null;
            $bindingData.Add($hashtitle) > $null;
            $bindingData.Add($hashdata) > $null;
        }
    }
    if($bindingData.Count -gt 0){
        $output.Add('win_dhcp_server::v4_interface_bindings:') > $null;
        $output.AddRange($bindingData) > $null;
    }

    if ($null -ne (Get-DhcpServerv4Scope)) {
        write-host 'Gathering IPv4 Scope yaml...';
        $ipv4scopes = get-dhcpserverv4scope;
        $output.Add("win_dhcp_server::v4_scopes:") > $null;
        foreach ($scope in $ipv4scopes) {
            if ($scope.name.length -gt 0) {
                $output.Add(("  '{0}':" -f $scope.Name)) > $null;
            }
            else {
                $output.Add(("  '{0}_{1}:" -f $scope.ScopeId, $scope.SubnetMask)) > $null;
            }
            if ($scope.name.length -gt 0) {
                $output.Add(("    scope_name: '{0}'" -f $scope.name)) > $null;
            }
            $output.Add(("    scope_id: '{0}'" -f $scope.scopeid)) > $null;
            $output.Add(("    subnet_mask: '{0}'" -f $scope.subnetmask)) > $null;
            if ('' -ne $scope.Description) {
                $output.Add(("    description: '{0}'" -f $scope.Description)) > $null;
            }
            if ('' -ne $scope.SuperscopeName) {
                $output.Add(("    superscope_name: '{0}'" -f $scope.SuperscopeName)) > $null;
            }

            $output.Add(("    start_range: '{0}'" -f $scope.startrange)) > $null;
            $output.Add(("    end_range: '{0}'" -f $scope.endrange)) > $null;
            $output.Add(("    lease_duration: '{0}'" -f $scope.leaseduration)) > $null;
            if ('' -ne $scope.NapProfile) {
                $output.Add(("    nap_profile: '{0}'" -f $scope.NapProfile)) > $null;
            }
            $output.Add(("    nap_enable: {0}" -f "$($scope.NapEnable)".ToLower())) > $null;
            if (0 -ne $scope.Delay) {
                $output.Add(("    delay_ms: {0}" -f $scope.Delay)) > $null;
            }

            if ($scope.State -eq "Inactive") {
                $output.Add("    active_state: 'InActive'") > $null;
            }

            $output.Add(("    scope_type: '{0}'" -f $scope.Type)) > $null;
            if (4294967295 -ne $scope.MaxBootpClients) {
                $output.Add(("    max_bootp_clients: '{0}'" -f $scope.MaxBootpClients)) > $null;
            }
            $output.Add(("    activate_policies: {0}" -f "$($scope.ActivatePolicies)".ToLower())) > $null;
        }
    }

    if($moduleMajorVersion -lt 2){Write-Warning ("skipping multicast scope yaml generation as not supported in dhcpserver module majorversion {0}" -f $moduleMajorVersion)}

    if (($moduleMajorVersion -ge 2) -and ($null -ne (Get-DhcpServerv4MulticastScope))) {
        write-host 'Gathering IPv4 multicast Scope yaml...';
        $ipv4multicastscopes = Get-DhcpServerv4MulticastScope;
        $output.Add("win_dhcp_server::v4_multicastscopes:") > $null;
        foreach ($multicastscope in $ipv4multicastscopes) {
            if ($multicastscope.name.length -gt 0) {
                $output.Add(("  '{0}':" -f $multicastscope.Name)) > $null;
            }
            else {
                $output.Add(("  '{0}_{1}:" -f $multicastscope.StartRange, $multicastscope.EndRange)) > $null;
            }
            if ($multicastscope.name.length -gt 0) {
                $output.Add(("    scope_name: '{0}'" -f $multicastscope.name)) > $null;
            }
            $output.Add(("    start_range: '{0}'" -f $multicastscope.StartRange)) > $null;
            $output.Add(("    end_range: '{0}'" -f $multicastscope.EndRange)) > $null;
            if ('' -ne $multicastscope.Description) {
                $output.Add(("    description: '{0}'" -f $multicastscope.Description)) > $null;
            }
            if ($null -ne ($multicastscope.ExpiryTime)) {
                $output.Add(("    expiry_time: '{0}'" -f $multicastscope.ExpiryTime)) > $null;
            }

            $output.Add(("    lease_duration: '{0}'" -f $multicastscope.leaseduration)) > $null;

            if ($multicastscope.State -eq "Inactive") {
                $output.Add("    active_state: 'InActive'") > $null;
            }

            $output.Add(("    ttl: {0}" -f $multicastscope.Ttl)) > $null;
        }
    }

    [System.Collections.ArrayList]$superScopeData = [System.Collections.ArrayList]::new();

    if ($null -ne (Get-DhcpServerv4Superscope)) {
        write-host 'Gathering IPv4 Superscopes yaml...does not include null superscope entry';
        foreach ($superScope in (Get-DhcpServerv4Superscope)) {
            if('' -ne ($superScope.SuperscopeName)){
                $superScopeData.Add(("  '{0}':" -f $superScope.SuperscopeName)) > $null;
                $superScopeData.Add("    scope_ids:") > $null;
                foreach ($scopeId in $superScope.ScopeId) {
                    $superScopeData.Add(("      - '{0}'" -f $scopeId)) > $null;
                }
            }
        }
    }
    if($superScopeData.Count -gt 0){
        $output.Add("win_dhcp_server::v4_superscopes:") > $null;
        $output.AddRange($superScopeData) >$null;
    }

    if ($null -ne (Get-DhcpServerv4Scope)) {
        write-host 'Gathering IPv4 Exclusion range yaml...';
        [System.Collections.ArrayList]$exclusionsYaml = [System.Collections.ArrayList]::new();

        foreach ($scope in $ipv4scopes) {
            $exclusions = Get-DhcpServerv4ExclusionRange -ScopeId $scope.scopeid.IPAddressToString;
            if ($null -ne $exclusions) {
                foreach ($exclusion in $exclusions) {
                    $exclusionsYaml.Add(("  '{0} - {1}':" -f $exclusion.StartRange, $exclusion.EndRange)) > $null;
                    $exclusionsYaml.Add(("    scope_id: '{0}'" -f $exclusion.ScopeId)) > $null;
                    $exclusionsYaml.Add(("    start_range: '{0}'" -f $exclusion.StartRange)) > $null;
                    $exclusionsYaml.Add(("    end_range: '{0}'" -f $exclusion.EndRange)) > $null;
                }
            }
        }
        if ($exclusionsYaml.Count -gt 0) {
            $output.Add("win_dhcp_server::v4_exclusions:") > $null;
            $output.AddRange($exclusionsYaml);
        }
    }

    if($moduleMajorVersion -lt 2){Write-Warning ("skipping multicast scope exclusion range yaml generation as not supported in dhcpserver module majorversion {0}" -f $moduleMajorVersion)}
    if (($moduleMajorVersion -ge 2) -and ($null -ne (Get-DhcpServerv4MulticastExclusionRange))) {
        write-host 'Gathering IPv4 multicast Exclusions range yaml...';
        $output.Add("win_dhcp_server::v4_multicastexclusions:") > $null;
        foreach ($multicastExclusionRange in (Get-DhcpServerv4MulticastExclusionRange)) {
            $output.Add(("  '{0}_{1}':" -f $multicastExclusionRange.StartRange, $multicastExclusionRange.EndRange)) > $null;
            $output.Add(("    scope_name: '{0}'" -f $multicastExclusionRange.Name)) > $null;
            $output.Add(("    start_range: '{0}'" -f $multicastExclusionRange.StartRange)) > $null;
            $output.Add(("    end_range: '{0}'" -f $multicastExclusionRange.EndRange)) > $null;
        }
    }

    if ($null -ne (Get-DhcpServerv4Scope)) {
        write-host 'Gathering IPv4 Reservations yaml...';
        [System.Collections.ArrayList]$reservationsYaml = [System.Collections.ArrayList]::new();

        foreach ($scope in $ipv4scopes) {
            $reservations = Get-DhcpServerv4Reservation -ScopeId $scope.scopeid.IPAddressToString;
            if ($null -ne $reservations) {
                foreach ($reservation in $reservations) {
                    $reservationsYaml.Add(("  'r: {0} in s: {1}':" -f $reservation.IPAddress.IPAddressToString, $reservation.scopeid)) > $null;
                    $reservationsYaml.Add(("    scope_id: '{0}'" -f $reservation.ScopeId)) > $null;
                    $reservationsYaml.Add(("    client_id: '{0}'" -f $reservation.ClientId)) > $null;
                    $reservationsYaml.Add(("    ipaddress: '{0}'" -f $reservation.IPAddress.IPAddressToString)) > $null;
                    $reservationsYaml.Add(("    reservation_type: '{0}'" -f $reservation.Type)) > $null;
                    if ($reservation.name.length -gt 0) {
                        $reservationsYaml.Add(("    reservation_name: '{0}'" -f $reservation.Name)) > $null;
                    }
                    if ($reservation.description.length -gt 0) {
                        $reservationsYaml.Add(("    description: '{0}'" -f $reservation.description)) > $null;
                    }
                }
            }
        }
        if ($reservationsYaml.Count -gt 0) {
            $output.Add("win_dhcp_server::v4_reservations:") > $null;
            $output.AddRange($reservationsYaml) > $null;
        }
    }

    if ($null -ne (Get-DhcpServerv4Class | Where-Object 'AsciiData' -NotIn $classAsciiDataIgnoreList)) {
        write-host 'Gathering class definition yaml...';
        $output.Add('win_dhcp_server::v4_classes:') > $null;
        foreach ($classdef in (Get-DhcpServerv4Class | Where-Object 'AsciiData' -NotIn $classAsciiDataIgnoreList)) {
            $output.Add(("  '{0} - {1} - {2}':" -f $classdef.Type, $classdef.AsciiData, $classdef.Name)) > $null;
            $output.Add(("    class_type: '{0}'" -f $classdef.Type)) > $null;
            $output.Add(("    class_name: '{0}'" -f $classdef.Name)) > $null;
            $output.Add(("    class_data: '{0}'" -f $classdef.AsciiData)) > $null;
            if ($null -ne ($classdef.description)) {
                $output.Add(("    description: '{0}'" -f $classdef.Description)) > $null;
            }
        }
    }


    if ($null -ne (Get-DhcpServerv4OptionDefinition -All)) {
        write-host 'Gathering option definition yaml...';
        $v4OptionDefs = Get-DhcpServerv4OptionDefinition -All;
        [System.Collections.ArrayList]$configOptDefs = [System.Collections.ArrayList]::new();
        foreach ($optDef in $v4OptionDefs) {
            if ('' -eq ($optDef.VendorClass)) {
                if ($optDef.OptionId -In $ignoredVendorNullDefs) {continue; }
            }
            elseif ($optDef.VendorClass -In $remainderOptionsFilterVendors) {
                if ($optDef.OptionId -in $ignoredVendorMsftOpts) {continue; }
            }

            if ('' -eq ($optDef.VendorClass)) {
                $configOptDefs.Add(("  'option id {0}':" -f $optDef.OptionId)) > $null;
            }
            else {
                $configOptDefs.Add(("  'option id {0} in {1}':" -f $optDef.OptionId, $optDef.VendorClass)) > $null;
                $configOptDefs.Add(("    vendor_class: '{0}'" -f $optDef.VendorClass)) > $null;
            }
            $configOptDefs.Add(("    option_id: {0}" -f $optDef.OptionId)) > $null;
            $configOptDefs.Add(("    definition_name: '{0}'" -f $optDef.Name)) > $null;
            $configOptDefs.Add(("    value_data_type: '{0}'" -f $optDef.Type)) > $null;
            $configOptDefs.Add(("    default_value:")) > $null;
            foreach ($s in $optDef.DefaultValue) {
                $configOptDefs.Add(("      - '{0}'" -f $s)) > $null;
            }
            if ($optDef.MultiValued) {
                $configOptDefs.Add(("    multivalued: {0}" -f "$($optDef.MultiValued)".ToLower())) > $null;
            }
            if ('' -ne $optDef.Description) {
                $configOptDefs.Add(("    description: '{0}'" -f $optDef.Description)) > $null;
            }
        }
        if ($configOptDefs.Count -gt 0) {
            $output.Add('win_dhcp_server::v4_optiondefinitions:');
            $output.AddRange($configOptDefs) >$null;
        }
    }

    [System.Collections.ArrayList]$optionValuesData = [System.Collections.ArrayList]::new();

    if($null -ne (Get-DhcpServerv4OptionValue -All)){
        write-host 'Gathering option value yaml at server scope...';
        $optionValues = Get-DhcpServerv4OptionValue -All;

        foreach($optval in $optionValues){
            $hashtitle = ("  'id: {0}" -f $optval.OptionId);
            [System.Collections.ArrayList]$hashdata = [System.Collections.ArrayList]::new();
            $hashdata.Add(("    option_id: {0}" -f $optval.OptionId)) > $null;

            $hashdata.Add("    value:") > $null;
            foreach($s in $optval.Value){
                $hashdata.Add(("      - '{0}'" -f $s)) > $null;
            }
            if($null -ne $optval.PolicyName){
                $hashtitle = $hashtitle + (" p: {0}" -f $optval.PolicyName);
                $hashdata.Add(("    policy_name: '{0}'" -f $optval.PolicyName)) > $null;
            }
            if('' -ne $optval.VendorClass){
                $hashtitle = $hashtitle + (" v: {0}" -f $optval.VendorClass);
                $hashdata.Add(("    vendor_class: '{0}'" -f $optval.VendorClass)) > $null;
            }
            if('' -ne $optval.UserClass){
                $hashtitle = $hashtitle + (" u: {0}" -f $optval.UserClass);
                $hashdata.Add(("    user_class: '{0}'" -f $optval.UserClass)) > $null;
            }

            $hashtitle = $hashtitle + "':";
            $optionValuesData.Add($hashtitle) > $null;
            $optionValuesData.AddRange($hashdata) > $null;
        }
    }

    if($null -ne (Get-DhcpServerv4Scope)){
        foreach($scope in (Get-DhcpServerv4Scope)){
            if($null -ne (Get-DhcpServerv4OptionValue -ScopeId $scope.scopeid -All)){
                write-host ("Gathering option value yaml at scope: {0}..." -f $scope.scopeid);
                foreach($optval in (Get-DhcpServerv4OptionValue -ScopeId $scope.scopeid -All)){
                    $hashtitle = ("  'id: {0} s:{1}" -f $optval.OptionId, $scope.ScopeId);
                    [System.Collections.ArrayList]$hashdata = [System.Collections.ArrayList]::new();
                    $hashdata.Add(("    option_id: {0}" -f $optval.OptionId)) > $null;
                    $hashdata.Add(("    scope_id: '{0}'" -f $scope.ScopeId)) > $null;

                    $hashdata.Add("    value:") > $null;
                    foreach($s in $optval.Value){
                        $hashdata.Add(("      - '{0}'" -f $s)) > $null;
                    }
                    if($null -ne $optval.PolicyName){
                        $hashtitle = $hashtitle + (" p: {0}" -f $optval.PolicyName);
                        $hashdata.Add(("    policy_name: '{0}'" -f $optval.PolicyName)) > $null;
                    }
                    if('' -ne $optval.VendorClass){
                        $hashtitle = $hashtitle + (" v: {0}" -f $optval.VendorClass);
                        $hashdata.Add(("    vendor_class: '{0}'" -f $optval.VendorClass)) > $null;
                    }
                    if('' -ne $optval.UserClass){
                        $hashtitle = $hashtitle + (" u: {0}" -f $optval.UserClass);
                        $hashdata.Add(("    user_class: '{0}'" -f $optval.UserClass)) > $null;
                    }

                    $hashtitle = $hashtitle + "':";
                    $optionValuesData.Add($hashtitle) > $null;
                    $optionValuesData.AddRange($hashdata) > $null;
                }
            }
        }
    }

    if($null -ne (Get-DhcpServerv4Scope)){
        foreach($scope in (Get-DhcpServerv4Scope)){
            if($null -ne (Get-DhcpServerv4Reservation -ScopeId $scope.ScopeId)){
                $reservations = Get-DhcpServerv4Reservation -ScopeId $scope.ScopeId;
                foreach($ip in $reservations){
                    if($null -ne (Get-DhcpServerv4OptionValue -ReservedIP $ip.IPAddress)){
                        write-host ("Gathering option value yaml at reserved ip: {0}..." -f $ip.IPAddress);
                        foreach($optval in (Get-DhcpServerv4OptionValue -ReservedIP $ip.IPAddress)){
                            $hashtitle = ("  'id: {0} r:{1}" -f $optval.OptionId, $ip.IPAddress);
                            [System.Collections.ArrayList]$hashdata = [System.Collections.ArrayList]::new();
                            $hashdata.Add(("    option_id: {0}" -f $optval.OptionId)) > $null;
                            $hashdata.Add(("    reserved_ip: '{0}'" -f $ip.IPAddress)) > $null;
                            $hashdata.Add("    value:") > $null;
                            foreach($s in $optval.Value){
                                $hashdata.Add(("      - '{0}'" -f $s)) > $null;
                            }
                            if($null -ne $optval.PolicyName){
                                $hashtitle = $hashtitle + (" p: {0}" -f $optval.PolicyName);
                                $hashdata.Add(("    policy_name: '{0}'" -f $optval.PolicyName)) > $null;
                            }
                            if('' -ne $optval.VendorClass){
                                $hashtitle = $hashtitle + (" v: {0}" -f $optval.VendorClass);
                                $hashdata.Add(("    vendor_class: '{0}'" -f $optval.VendorClass)) > $null;
                            }
                            if('' -ne $optval.UserClass){
                                $hashtitle = $hashtitle + (" u: {0}" -f $optval.UserClass);
                                $hashdata.Add(("    user_class: '{0}'" -f $optval.UserClass)) > $null;
                            }

                            $hashtitle = $hashtitle + "':";
                            $optionValuesData.Add($hashtitle) > $null;
                            $optionValuesData.AddRange($hashdata) > $null;
                        }
                    }
                }
            }
        }
    }
    if($optionValuesData.Count -gt 0){
        $output.Add('win_dhcp_server::v4_optionvalues:') > $null;
        $output.AddRange($optionValuesData) > $null;
    }

    #policy
    [System.Collections.ArrayList]$policyData = [System.Collections.ArrayList]::new();

    if($null -ne (Get-DhcpServerv4Policy)){
        write-host "Gathering policy yaml at scope id: 0.0.0.0...";
        foreach($policy in (Get-DhcpServerv4Policy)){
            $hashtitle = ("  '{0} at s: {1}':" -f $policy.Name, $policy.ScopeId);
            [System.Collections.ArrayList]$hashdata = [System.Collections.ArrayList]::new();
            $hashdata.Add(("    policy_name: '{0}'" -f $policy.Name)) > $null;
            $hashdata.Add(("    scope_id: '{0}'" -f $policy.ScopeId)) > $null;
            $hashdata.Add(("    processing_order: {0}" -f $policy.ProcessingOrder)) > $null;
            $hashdata.Add(("    condition_operator: '{0}'" -f $policy.Condition)) > $null;
            if($null -ne ($policy.VendorClass)){
                $hashdata.Add("    vendor_class:") > $null;;
                foreach($s in ($policy.VendorClass)){
                    $hashdata.Add(("      - '{0}'" -f $s)) > $null;
                }
            }
            if($null -ne ($policy.UserClass)){
                $hashdata.Add("    user_class:") > $null;;
                foreach($s in ($policy.UserClass)){
                    $hashdata.Add(("      - '{0}'" -f $s)) > $null;
                }
            }
            if($null -ne ($policy.MacAddress)){
                $hashdata.Add("    mac_addresses:") > $null;;
                foreach($s in ($policy.MacAddress)){
                    $hashdata.Add(("      - '{0}'" -f $s)) > $null;
                }
            }
            if($null -ne ($policy.ClientId)){
                $hashdata.Add("    client_id:") > $null;;
                foreach($s in ($policy.ClientId)){
                    $hashdata.Add(("      - '{0}'" -f $s)) > $null;
                }
            }
            if($null -ne ($policy.Fqdn)){
                $hashdata.Add("    fqdn:") > $null;;
                foreach($s in ($policy.Fqdn)){
                    $hashdata.Add(("      - '{0}'" -f $s)) > $null;
                }
            }
            if($null -ne ($policy.RelayAgent)){
                $hashdata.Add("    relay_agent:") > $null;;
                foreach($s in ($policy.RelayAgent)){
                    $hashdata.Add(("      - '{0}'" -f $s)) > $null;
                }
            }
            if($null -ne ($policy.CircuitId)){
                $hashdata.Add("    circuit_id:") > $null;;
                foreach($s in ($policy.CircuitId)){
                    $hashdata.Add(("      - '{0}'" -f $s)) > $null;
                }
            }
            if($null -ne ($policy.RemoteId)){
                $hashdata.Add("    remote_id:") > $null;;
                foreach($s in ($policy.RemoteId)){
                    $hashdata.Add(("      - '{0}'" -f $s)) > $null;
                }
            }
            if($null -ne ($policy.SubscriberId)){
                $hashdata.Add("    subscriber_id:") > $null;;
                foreach($s in ($policy.SubscriberId)){
                    $hashdata.Add(("      - '{0}'" -f $s)) > $null;
                }
            }
            if($null -ne ($policy.LeaseDuration)){
                $hashdata.Add(("    lease_duration: '{0}'" -f $policy.LeaseDuration)) > $null;
            }

            $policyData.Add($hashtitle) > $null;
            $policyData.AddRange($hashdata) > $null;
        }
    }

    if($null -ne (Get-DhcpServerv4Scope)){
        foreach($scope in (Get-DhcpServerv4Scope)){
            if($null -ne (Get-DhcpServerv4Policy -ScopeId $scope.ScopeId)){
                write-host ("Gathering policy yaml at scope id: {0}..." -f $scope.ScopeId);
                foreach($policy in (Get-DhcpServerv4Policy -ScopeId $scope.ScopeId)){
                    $hashtitle = ("  '{0} at s: {1}':" -f $policy.Name, $policy.ScopeId);
                    [System.Collections.ArrayList]$hashdata = [System.Collections.ArrayList]::new();
                    $hashdata.Add(("    policy_name: '{0}'" -f $policy.Name)) > $null;
                    $hashdata.Add(("    scope_id: '{0}'" -f $policy.ScopeId)) > $null;
                    $hashdata.Add(("    processing_order: {0}" -f $policy.ProcessingOrder)) > $null;
                    $hashdata.Add(("    condition_operator: '{0}'" -f $policy.Condition)) > $null;
                    if($null -ne ($policy.VendorClass)){
                        $hashdata.Add("    vendor_class:") > $null;;
                        foreach($s in ($policy.VendorClass)){
                            $hashdata.Add(("      - '{0}'" -f $s)) > $null;
                        }
                    }
                    if($null -ne ($policy.UserClass)){
                        $hashdata.Add("    user_class:") > $null;;
                        foreach($s in ($policy.UserClass)){
                            $hashdata.Add(("      - '{0}'" -f $s)) > $null;
                        }
                    }
                    if($null -ne ($policy.MacAddress)){
                        $hashdata.Add("    mac_addresses:") > $null;;
                        foreach($s in ($policy.MacAddress)){
                            $hashdata.Add(("      - '{0}'" -f $s)) > $null;
                        }
                    }
                    if($null -ne ($policy.ClientId)){
                        $hashdata.Add("    client_id:") > $null;;
                        foreach($s in ($policy.ClientId)){
                            $hashdata.Add(("      - '{0}'" -f $s)) > $null;
                        }
                    }
                    if($null -ne ($policy.Fqdn)){
                        $hashdata.Add("    fqdn:") > $null;;
                        foreach($s in ($policy.Fqdn)){
                            $hashdata.Add(("      - '{0}'" -f $s)) > $null;
                        }
                    }
                    if($null -ne ($policy.RelayAgent)){
                        $hashdata.Add("    relay_agent:") > $null;;
                        foreach($s in ($policy.RelayAgent)){
                            $hashdata.Add(("      - '{0}'" -f $s)) > $null;
                        }
                    }
                    if($null -ne ($policy.CircuitId)){
                        $hashdata.Add("    circuit_id:") > $null;;
                        foreach($s in ($policy.CircuitId)){
                            $hashdata.Add(("      - '{0}'" -f $s)) > $null;
                        }
                    }
                    if($null -ne ($policy.RemoteId)){
                        $hashdata.Add("    remote_id:") > $null;;
                        foreach($s in ($policy.RemoteId)){
                            $hashdata.Add(("      - '{0}'" -f $s)) > $null;
                        }
                    }
                    if($null -ne ($policy.SubscriberId)){
                        $hashdata.Add("    subscriber_id:") > $null;;
                        foreach($s in ($policy.SubscriberId)){
                            $hashdata.Add(("      - '{0}'" -f $s)) > $null;
                        }
                    }
                    if($null -ne ($policy.LeaseDuration)){
                        $hashdata.Add(("    lease_duration: '{0}'" -f $policy.LeaseDuration)) > $null;
                    }

                    $policyData.Add($hashtitle) > $null;
                    $policyData.AddRange($hashdata) > $null;
                }
            }
        }
    }
    if($optionValuesData.Count -gt 0){
        $output.Add('win_dhcp_server::v4_policies:') > $null;
        $output.AddRange($policyData) > $null;
    }
    #policy ip range
    [System.Collections.ArrayList]$policyIPRangeData = [System.Collections.ArrayList]::new();
    if($null -ne (Get-DhcpServerv4Scope)){
        foreach($scope in (Get-DhcpServerv4Scope)){
            if($null -ne (Get-DhcpServerv4PolicyIPRange -ScopeId $scope.ScopeId)){
                write-host ("Gathering policy IP range yaml at scope id: {0}..." -f $scope.ScopeId);
                foreach($policyiprange in (Get-DhcpServerv4PolicyIPRange -ScopeId $scope.ScopeId)){
                    $hashtitle = ("  '{0}_{1} in s: {2}':" -f $policyiprange.StartRange, $policyiprange.EndRange, $scope.ScopeId);
                    [System.Collections.ArrayList]$hashdata = [System.Collections.ArrayList]::new();
                    $hashdata.Add(("    policy_name: '{0}'" -f $policyiprange.Name)) > $null;
                    $hashdata.Add(("    scope_id: '{0}'" -f $policyiprange.ScopeId)) > $null;
                    $hashdata.Add(("    start_range: '{0}'" -f $policyiprange.StartRange)) > $null;
                    $hashdata.Add(("    end_range: '{0}'" -f $policyiprange.EndRange)) > $null;

                    $policyIPRangeData.Add($hashtitle) > $null;
                    $policyIPRangeData.AddRange($hashdata) > $null;
                }
            }
        }
    }
    if($policyIPRangeData.Count -gt 0){
        $output.Add('win_dhcp_server::v4_policy_ipranges:') > $null;
        $output.AddRange($policyIPRangeData) > $null;
    }



    if ($null -ne (Get-DhcpServerv4DnsSetting)) {
        write-host 'Gathering DNS settings...Server level...';
        $output.Add('win_dhcp_server::v4_dns_settings:') > $null;
        $output.Add("  'server level settings':") > $null;
        #if($null -ne (Get-DhcpServerv4DnsSetting).DnsSuffix){$output.Add("    dns_suffix_for_registration: '{0}'" -f (Get-DhcpServerv4DnsSetting.DnsSuffix)) > $null;}
        if ($null -ne (Get-DhcpServerv4DnsSetting).DynamicUpdates) {$output.Add("    dynamic_updates: '{0}'" -f ((Get-DhcpServerv4DnsSetting).DynamicUpdates)) > $null; }
        if ($null -ne (Get-DhcpServerv4DnsSetting).DeleteDnsRROnLeaseExpiry) {$output.Add("    delete_dns_rr_onlease_expiry: {0}" -f "$((Get-DhcpServerv4DnsSetting).DeleteDnsRROnLeaseExpiry)".ToLower()) > $null; }
        if ($null -ne (Get-DhcpServerv4DnsSetting).UpdateDnsRRForOlderClients) {$output.Add("    update_dns_rr_for_old_clients: {0}" -f "$((Get-DhcpServerv4DnsSetting).UpdateDnsRRForOlderClients)".ToLower()) > $null; }
        if ($null -ne (Get-DhcpServerv4DnsSetting).DisableDnsPtrRRUpdate) {$output.Add("    disable_dns_ptr_rr_update: {0}" -f "$((Get-DhcpServerv4DnsSetting).DisableDnsPtrRRUpdate)".ToLower()) > $null; }
        if ($null -ne (Get-DhcpServerv4DnsSetting).NameProtection) {$output.Add("    name_protection: {0}" -f "$((Get-DhcpServerv4DnsSetting).NameProtection)".ToLower()) > $null; }
    }

    if ($null -ne (Get-DhcpServerv4Policy)) {
        write-host 'Gathering DNS settings...Global Policies level...';
        foreach ($policy in (Get-DhcpServerv4Policy)) {
            if ($null -ne (Get-DhcpServerv4DnsSetting -PolicyName $policy.Name)) {
                $output.Add("  'p: {0} in server policies':" -f $policy.Name) > $null;
                if ($null -ne ($policy.Name)) {$output.Add("    policy_name: '{0}'" -f ($policy.Name)) > $null; }
                if ($null -ne (Get-DhcpServerv4DnsSetting -PolicyName $policy.Name).DnsSuffix) {$output.Add("    dns_suffix_for_registration: '{0}'" -f ((Get-DhcpServerv4DnsSetting -PolicyName $policy.Name).DnsSuffix)) > $null; }
                if ($null -ne (Get-DhcpServerv4DnsSetting -PolicyName $policy.Name).DynamicUpdates) {$output.Add("    dynamic_updates: '{0}'" -f ((Get-DhcpServerv4DnsSetting -PolicyName $policy.Name).DynamicUpdates)) > $null; }
                if ($null -ne (Get-DhcpServerv4DnsSetting -PolicyName $policy.Name).DeleteDnsRROnLeaseExpiry) {$output.Add("    delete_dns_rr_onlease_expiry: {0}" -f "$((Get-DhcpServerv4DnsSetting -PolicyName $policy.Name).DeleteDnsRROnLeaseExpiry)".ToLower()) > $null; }
                if ($null -ne (Get-DhcpServerv4DnsSetting -PolicyName $policy.Name).UpdateDnsRRForOlderClients) {$output.Add("    update_dns_rr_for_old_clients: {0}" -f "$((Get-DhcpServerv4DnsSetting -PolicyName $policy.Name).UpdateDnsRRForOlderClients)".ToLower()) > $null; }
                if ($null -ne (Get-DhcpServerv4DnsSetting -PolicyName $policy.Name).DisableDnsPtrRRUpdate) {$output.Add("    disable_dns_ptr_rr_update: {0}" -f "$((Get-DhcpServerv4DnsSetting -PolicyName $policy.Name).DisableDnsPtrRRUpdate)".ToLower()) > $null; }
                if ($null -ne (Get-DhcpServerv4DnsSetting -PolicyName $policy.Name).NameProtection) {$output.Add("    name_protection: {0}" -f "$((Get-DhcpServerv4DnsSetting -PolicyName $policy.Name).NameProtection)".ToLower()) > $null; }
            }
        }
    }

    if ($null -ne (Get-DhcpServerv4Scope)) {
        write-host 'Gathering DNS settings...Scope level... (will NOT include all these in your data if they do not deviate from server level)';
        $ipv4Scopes = Get-DhcpServerv4Scope;
        foreach ($scope in $ipv4Scopes) {
            if ($null -ne (Compare-Object -ReferenceObject (Get-DhcpServerv4DnsSetting) -DifferenceObject (Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId) -Property $dnsCompareProps)) {
                $output.Add("  '{0} scope level dns':" -f $scope.ScopeId) > $null;
                if ($null -ne ($scope.ScopeId)) {$output.Add("    scope_id: '{0}'" -f ($scope.ScopeId)) > $null; }
                if ($null -ne (Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId).DynamicUpdates) {$output.Add("    dynamic_updates: '{0}'" -f ((Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId).DynamicUpdates)) > $null; }
                if ($null -ne (Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId).DeleteDnsRROnLeaseExpiry) {$output.Add("    delete_dns_rr_onlease_expiry: {0}" -f "$((Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId).DeleteDnsRROnLeaseExpiry)".ToLower()) > $null; }
                if ($null -ne (Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId).UpdateDnsRRForOlderClients) {$output.Add("    update_dns_rr_for_old_clients: {0}" -f "$((Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId).UpdateDnsRRForOlderClients)".ToLower()) > $null; }
                if ($null -ne (Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId).DisableDnsPtrRRUpdate) {$output.Add("    disable_dns_ptr_rr_update: {0}" -f "$((Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId).DisableDnsPtrRRUpdate)".ToLower()) > $null; }
                if ($null -ne (Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId).NameProtection) {$output.Add("    name_protection: {0}" -f "$((Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId).NameProtection)".ToLower()) > $null; }
            }
        }
    }

    if ($null -ne (Get-DhcpServerv4Scope)) {
        write-host 'Gathering DNS settings...IP Reservation level... (will NOT include all these in your data if they do not deviate from SCOPE level)';
        $ipv4Scopes = Get-DhcpServerv4Scope;
        foreach ($scope in $ipv4Scopes) {
            if ($null -ne (Get-DhcpServerv4Reservation -ScopeId $scope.ScopeId)) {
                $scopeReservations = Get-DhcpServerv4Reservation -ScopeId $scope.ScopeId;
                foreach ($reservation in $scopeReservations) {
                    if ($null -ne (Compare-Object -ReferenceObject (Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId) -DifferenceObject (Get-DhcpServerv4DnsSetting -ReservedIP $reservation.IPAddress) -Property $dnsCompareProps)) {
                        $output.Add(("  'r: {0} in s: {1} dns':" -f $reservation.IpAddress, $scope.ScopeId)) > $null;
                        #cannot target scopeid and reserved IP together
                        #if ($null -ne ($scope.ScopeId)) {$output.Add("    scope_id: '{0}'" -f ($scope.ScopeId)) > $null; }
                        if ($null -ne ($reservation.IpAddress)) {$output.Add("    reserved_ip: '{0}'" -f ($reservation.IpAddress)) > $null; }
                        if ($null -ne (Get-DhcpServerv4DnsSetting -ReservedIP $reservation.IPAddress).DynamicUpdates) {$output.Add("    dynamic_updates: '{0}'" -f ((Get-DhcpServerv4DnsSetting -ReservedIP $reservation.IPAddress).DynamicUpdates)) > $null; }
                        if ($null -ne (Get-DhcpServerv4DnsSetting -ReservedIP $reservation.IPAddress).DeleteDnsRROnLeaseExpiry) {$output.Add("    delete_dns_rr_onlease_expiry: {0}" -f "$((Get-DhcpServerv4DnsSetting -ReservedIP $reservation.IPAddress).DeleteDnsRROnLeaseExpiry)".ToLower()) > $null; }
                        if ($null -ne (Get-DhcpServerv4DnsSetting -ReservedIP $reservation.IPAddress).UpdateDnsRRForOlderClients) {$output.Add("    update_dns_rr_for_old_clients: {0}" -f "$((Get-DhcpServerv4DnsSetting -ReservedIP $reservation.IPAddress).UpdateDnsRRForOlderClients)".ToLower()) > $null; }
                        if ($null -ne (Get-DhcpServerv4DnsSetting -ReservedIP $reservation.IPAddress).DisableDnsPtrRRUpdate) {$output.Add("    disable_dns_ptr_rr_update: {0}" -f "$((Get-DhcpServerv4DnsSetting -ReservedIP $reservation.IPAddress).DisableDnsPtrRRUpdate)".ToLower()) > $null; }
                        #cannot target nape protection on a reserved ip for config mgmt, the below ending up in hiera data would cause win_dhcp_server module to reject this resource
                        #if ($null -ne (Get-DhcpServerv4DnsSetting -ReservedIP $reservation.IPAddress).NameProtection) {$output.Add("    name_protection: {0}" -f "$((Get-DhcpServerv4DnsSetting -ReservedIP $reservation.IPAddress).NameProtection)".ToLower()) > $null; }
                    }
                }
            }
        }
    }
    if($moduleMajorVersion -lt 2){Write-Warning ("skipping scope policy dns settings yaml generation as not supported in dhcpserver module majorversion {0}" -f $moduleMajorVersion)}
    if (($moduleMajorVersion -ge 2) -and ($null -ne (Get-DhcpServerv4Scope))) {
        write-host 'Gathering DNS settings...Scope Policy level... (WILL include all these in your data even if match server level, omit them from what you use if not care to)';
        $ipv4Scopes = Get-DhcpServerv4Scope;
        foreach ($scope in $ipv4Scopes) {
            if ($null -ne (Get-DhcpServerv4Policy -ScopeId $scope.ScopeId)) {
                $scopePolicies = Get-DhcpServerv4Policy -ScopeId $scope.ScopeId;
                foreach ($policyInScope in $scopePolicies) {
                    $output.Add(("  'p: {0} in s: {1} dns':" -f $policyInScope.Name, $scope.ScopeId)) > $null;
                    if ($null -ne ($policyInScope.Name)) {$output.Add("    policy_name: '{0}'" -f ($policyInScope.Name)) > $null; }
                    if ($null -ne ($scope.ScopeId)) {$output.Add("    scope_id: '{0}'" -f ($scope.ScopeId)) > $null; }
                    if ($null -ne (Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId -PolicyName $policyInScope.Name).DnsSuffix) {$output.Add("    dns_suffix_for_registration: '{0}'" -f ((Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId -PolicyName $policyInScope.Name).DnsSuffix)) > $null; }
                    if ($null -ne (Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId -PolicyName $policyInScope.Name).DynamicUpdates) {$output.Add("    dynamic_updates: '{0}'" -f ((Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId -PolicyName $policyInScope.Name).DynamicUpdates)) > $null; }
                    if ($null -ne (Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId -PolicyName $policyInScope.Name).DeleteDnsRROnLeaseExpiry) {$output.Add("    delete_dns_rr_onlease_expiry: {0}" -f "$((Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId -PolicyName $policyInScope.Name).DeleteDnsRROnLeaseExpiry)".ToLower()) > $null; }
                    if ($null -ne (Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId -PolicyName $policyInScope.Name).UpdateDnsRRForOlderClients) {$output.Add("    update_dns_rr_for_old_clients: {0}" -f "$((Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId -PolicyName $policyInScope.Name).UpdateDnsRRForOlderClients)".ToLower()) > $null; }
                    if ($null -ne (Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId -PolicyName $policyInScope.Name).DisableDnsPtrRRUpdate) {$output.Add("    disable_dns_ptr_rr_update: {0}" -f "$((Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId -PolicyName $policyInScope.Name).DisableDnsPtrRRUpdate)".ToLower()) > $null; }
                    if ($null -ne (Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId -PolicyName $policyInScope.Name).NameProtection) {$output.Add("    name_protection: {0}" -f "$((Get-DhcpServerv4DnsSetting -ScopeId $scope.ScopeId -PolicyName $policyInScope.Name).NameProtection)".ToLower()) > $null; }
                }
            }
        }
    }
    try {
        Set-Content -Path $outputpath -Value '---' -Force -Confirm:$false;

        write-host "writing output to '${outputpath}'...";
        foreach ($s in $output) {
            Add-Content -Path $outputpath -Value $s -Confirm:$false;
        }
    }
    catch [Exception] {
        Write-Host ("unable to output yaml to {0} - {1}" -f $outputpath, $_.Excpetion.Message);
    }
}