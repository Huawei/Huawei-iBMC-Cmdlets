# Copyright (C) 2020 Huawei Technologies Co., Ltd. All rights reserved.	
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the MIT License		

# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# MIT License for more detail

<# NOTE: iBMC Setting module Cmdlets #>

function Reset-iBMC {
<#
.SYNOPSIS
Reset iBMC.

.DESCRIPTION
Reset iBMC.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
None
Returns None if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Reset-iBMC $session


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Connect-iBMC
Disconnect-iBMC

#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'

    $Logger.info("Invoke Reset iBMC function")

    $ScriptBlock = {
      param($RedfishSession, $Payload)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Reset iBMC now"))
      $Path = "/Managers/$($RedfishSession.Id)/Actions/Manager.Reset"
      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Payload | ConvertTo-Json)"))
      Invoke-RedfishRequest $RedfishSession $Path 'POST' $Payload | Out-Null
      return $null
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Payload = @{"ResetType" = "ForceRestart"; }
        $Parameters = @($RedfishSession, $Payload)
        $Logger.info($(Trace-Session $RedfishSession "Submit Reset iBMC task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $Parameters))
      }

      $Results = Get-AsyncTaskResults $tasks
      return ,$Results
    }
    finally {
      Close-Pool $pool
    }
  }

  end {
  }
}


function Restore-iBMCFactorySetting {
<#
.SYNOPSIS
Restore the factory settings.

.DESCRIPTION
Restore the factory settings.
Note: This cmdlet is a high-risk operation. It should be used with caution.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
None
Returns None if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

Restore factory settings

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Restore-iBMCFactorySetting $session


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Export-iBMCBIOSSetting
Import-iBMCBIOSSetting
Reset-iBMCBIOSSetting
Connect-iBMC
Disconnect-iBMC

#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'

    $Logger.info("Invoke Restore BIOS Factory function")

    $ScriptBlock = {
      param($RedfishSession)
      $Path = "/Managers/$($RedfishSession.Id)/Actions/Oem/Huawei/Manager.RestoreFactory"
      Invoke-RedfishRequest $RedfishSession $Path 'Post' | Out-Null
      return $null
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Restore BIOS Factory task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock @($RedfishSession)))
      }

      $Results = Get-AsyncTaskResults $tasks
      return ,$Results
    }
    finally {
      Close-Pool $pool
    }
  }

  end {
  }
}

function Get-iBMCIP {
<#
.SYNOPSIS
Querying an iBMC Network Port Resource.

.DESCRIPTION
Querying an iBMC Network Port Resource.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[]
Returns PSObject which contains all support services infomation if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $Credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 10.1.1.2 -Credential $Credential -TrustCert
PS C:\> $iBMCIP = Get-iBMCIP -Session $Session
PS C:\> $iBMCIP

Host                  : 10.1.1.2
Id                    : 04338932ede2
Name                  : Manager Ethernet Interface
PermanentMACAddress   : 04:33:89:32:ed:e2
HostName              : server2
FQDN                  : server2.plugin.com
VLAN                  : @{VLANEnable=False; VLANId=0}
IPv4Addresses         : {@{Address=10.1.1.2; SubnetMask=255.255.0.0; Gateway=10.1.0.1; AddressOrigin=Static}}
IPv6Addresses         : {@{Address=fc00:10::2; PrefixLength=64; AddressOrigin=Static}, @{Address=fe80::633:89ff:fe32:ede2; PrefixLength=64; AddressOrigin=LinkLocal}}
IPv6StaticAddresses   : {@{Address=fc00:10::2; PrefixLength=64}}
IPv6DefaultGateway    : fc00:10::1
NameServers           : {10.1.1.10, }
IPVersion             : IPv4AndIPv6
NetworkPortMode       : Fixed
ManagementNetworkPort : @{Type=Dedicated; PortNumber=1}

This example shows how to query the IP of a server

.EXAMPLE

PS C:\> $Credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 10.1.1.2-3 -Credential $Credential -TrustCert
PS C:\> $iBMCIP = Get-iBMCIP -Session $Session
PS C:\> $iBMCIP

Host                  : 10.1.1.2
Id                    : 04338932ede2
Name                  : Manager Ethernet Interface
PermanentMACAddress   : 04:33:89:32:ed:e2
HostName              : server2
FQDN                  : server2.plugin.com
VLAN                  : @{VLANEnable=False; VLANId=0}
IPv4Addresses         : {@{Address=10.1.1.2; SubnetMask=255.255.0.0; Gateway=10.1.0.1; AddressOrigin=Static}}
IPv6Addresses         : {@{Address=fc00:10::2; PrefixLength=64; AddressOrigin=Static}, @{Address=fe80::633:89ff:fe32:ede2; PrefixLength=64; AddressOrigin=LinkLocal}}
IPv6StaticAddresses   : {@{Address=fc00:10::2; PrefixLength=64}}
IPv6DefaultGateway    : fc00:10::1
NameServers           : {10.1.1.10, }
IPVersion             : IPv4AndIPv6
NetworkPortMode       : Fixed
ManagementNetworkPort : @{Type=Dedicated; PortNumber=1}

Host                  : 10.1.1.3
Id                    : 04885fd4c9d6
Name                  : Manager Ethernet Interface
PermanentMACAddress   : 04:88:5f:d4:c9:d6
HostName              : server3
FQDN                  : server3.plugin.com
VLAN                  : @{VLANEnable=False; VLANId=0}
IPv4Addresses         : {@{Address=10.1.1.3; SubnetMask=255.255.0.0; Gateway=10.1.0.1; AddressOrigin=Static}}
IPv6Addresses         : {@{Address=fc00:10::3; PrefixLength=64; AddressOrigin=Static}, @{Address=fe80::633:89ff:fe32:ede3; PrefixLength=64; AddressOrigin=LinkLocal}}
IPv6StaticAddresses   : {@{Address=fc00:10::3; PrefixLength=64}}
IPv6DefaultGateway    : fc00:10::1
NameServers           : {10.1.1.10, }
IPVersion             : IPv4AndIPv6
NetworkPortMode       : Fixed
ManagementNetworkPort : @{Type=Dedicated; PortNumber=1}

This example shows how to query the IP of multiple server

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Set-iBMCIP
Connect-iBMC
Disconnect-iBMC

#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'

    $Logger.info("Invoke Get BMC IP function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke get BMC IP now"))
      $EthernetInterfaces_ID = Get-EthernetInterfaces-ID $RedfishSession
      $Path = "/Managers/$($RedfishSession.Id)/EthernetInterfaces/$EthernetInterfaces_ID"
      $Response = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
      
      $Properties = @(
        "Id", 
        "Name", 
        "PermanentMACAddress", 
        "HostName", 
        "FQDN", 
        "VLAN", 
        "IPv4Addresses", 
        "IPv6Addresses",
        "IPv6StaticAddresses",
        "IPv6DefaultGateway",
        "NameServers"
        )
      $iBMCIP = Copy-ObjectProperties $Response $Properties
      $iBMCIP | Add-Member -MemberType NoteProperty "IPVersion" $Response.Oem.Huawei.IPVersion
      $iBMCIP | Add-Member -MemberType NoteProperty "NetworkPortMode" $Response.Oem.Huawei.NetworkPortMode
      $iBMCIP | Add-Member -MemberType NoteProperty "ManagementNetworkPort" $Response.Oem.Huawei.ManagementNetworkPort
      return $(Update-SessionAddress $RedfishSession $iBMCIP)
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit get BMC IP task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock @($RedfishSession)))
      }

      $Results = Get-AsyncTaskResults $tasks
      return ,$Results
    }
    finally {
      Close-Pool $pool
    }
  }

  end {
  }
}

function Set-iBMCIP {
<#
.SYNOPSIS
Modify iBMC network port information.

.DESCRIPTION
Modify iBMC network port information.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER IPVersion
Whether IPv4/IPv6 is enabled.
Available Value Set: ('IPv4', 'IPv6', 'IPv4AndIPv6')

.PARAMETER IPv4Address
Indicates the IPv4 address.

.PARAMETER IPv4SubnetMask
Indicates the subnet mask of the IPv4 address.

.PARAMETER IPv4Gateway
Indicates the gateway IP address.

.PARAMETER IPv4AddressOrigin
How the IPv4 address is allocated.
Available Value Set: ('Static', 'DHCP')

.PARAMETER IPv6Address
Indicates the IPv6 address.

.PARAMETER IPv6PrefixLength
Prefix length of the IPv6 address.
Available Value range: [0, 128]

.PARAMETER IPv6AddressOrigin
Specifies how IPv6 addresses are allocated.
Available Value Set: ('Static', 'DHCPv6')

.PARAMETER IPv6Gateway
IPv6 gateway address of the iBMC network port.

.OUTPUTS
Null
Returns Null if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $Credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 10.1.1.2 -Credential $Credential -TrustCert
PS C:\> Set-iBMCIP -Session $Session -IPVersion IPv4AndIPv6 `
          -IPv4Address 10.1.1.2 -IPv4SubnetMask 255.255.0.0 -IPv4Gateway 10.1.0.1 -IPv4AddressOrigin Static `
          -IPv6Address fc00:10:2 -IPv6PrefixLength 64 -IPv6Gateway fc00:10:1 -IPv6AddressOrigin Static

This example shows how to modify the IP of a server

.EXAMPLE

PS C:\> $Credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 10.1.1.2,10.1.1.3 -Credential $Credential -TrustCert
PS C:\> $IPVersion = @("IPv4AndIPv6", "IPv4")
PS C:\> $IPv4Address = @("10.1.1.12", "10.1.1.13")
PS C:\> $IPv6Address = @("fc00:10::12", "fc00:10:13")
PS C:\> Set-iBMCIP -Session $Session -IPVersion $IPVersion `
          -IPv4Address $IPv4Address -IPv4SubnetMask 255.255.0.0 -IPv4Gateway 10.1.0.1 -IPv4AddressOrigin Static `
          -IPv6Address $IPv6Address -IPv6PrefixLength 64 -IPv6Gateway fc00:10:1 -IPv6AddressOrigin Static

This example shows how to modify the IP of multiple servers

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCIP
Connect-iBMC
Disconnect-iBMC

#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session,

    [IPVersion[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $IPVersion,

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $IPv4Address,

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $IPv4SubnetMask,

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $IPv4Gateway,

    [IPv4AddressOrigin[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $IPv4AddressOrigin,

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $IPv6Address,

    [int32[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateRange(0, 128)]
    $IPv6PrefixLength,

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $IPv6Gateway,

    [IPv6AddressOrigin[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $IPv6AddressOrigin
  
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    $IPVersionList = Get-OptionalMatchedSizeArray $Session $IPVersion
    $IPv4AddressList = Get-OptionalMatchedSizeArray $Session $IPv4Address
    $IPv4GatewayList = Get-OptionalMatchedSizeArray $Session $IPv4Gateway
    $IPv4SubnetMaskList = Get-OptionalMatchedSizeArray $Session $IPv4SubnetMask
    $IPv4AddressOriginList = Get-OptionalMatchedSizeArray $Session $IPv4AddressOrigin
    $IPv6AddresseList = Get-OptionalMatchedSizeArray $Session $IPv6Address
    $IPv6PrefixLengthList = Get-OptionalMatchedSizeArray $Session $IPv6PrefixLength
    $IPv6AddressOriginList = Get-OptionalMatchedSizeArray $Session $IPv6AddressOrigin
    $IPv6GatewayList = Get-OptionalMatchedSizeArray $Session $IPv6Gateway

    $Logger.info("Invoke Set BMC IP function")

    $ScriptBlock = {
      param($RedfishSession, $Payload)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Set BMC IP now"))
      $EthernetInterfaces_ID = Get-EthernetInterfaces-ID $RedfishSession
      $Path = "/Managers/$($RedfishSession.Id)/EthernetInterfaces/$EthernetInterfaces_ID"
      
      $IPv4AddrDict = @{
        "Address" = $Payload.IPv4Address;
        "SubnetMask" = $Payload.IPv4SubnetMask;
        "Gateway" = $Payload.IPv4Gateway;
        "AddressOrigin" = $Payload.IPv4AddressOrigin
      }| Remove-EmptyValues
      $IPv4AddrList = New-Object System.Collections.ArrayList
      if ($IPv4AddrDict.Count -gt 0) {
        [Void] $IPv4AddrList.Add($IPv4AddrDict)
      } 

      $IPv6AddrDict = @{
        "Address" = $Payload.IPv6Address;
        "PrefixLength" = $Payload.IPv6PrefixLength;
        "AddressOrigin" = $Payload.IPv6AddressOrigin
      }| Remove-EmptyValues
      $IPv6AddrList = New-Object System.Collections.ArrayList
      if ($IPv6AddrDict.Count -gt 0) {
        [Void] $IPv6AddrList.Add($IPv6AddrDict)
      } 
      
      $CompletePlayload = @{}

      if ($Payload.IPVersion) {
        $Oem = @{
          "Huawei" = @{
            "IPVersion" = $Payload.IPVersion
          }
        }
        $CompletePlayload.Oem = $Oem 
      }

      if ($Payload.IPv6Gateway) {
        $CompletePlayload.IPv6DefaultGateway = $Payload.IPv6Gateway
      }

      if ($IPv4AddrList.Count -gt 0) {
        $CompletePlayload.IPv4Addresses = $IPv4AddrList
      }

      if ($IPv6AddrList.Count -gt 0) {
        $CompletePlayload.IPv6Addresses = $IPv6AddrList
      }

      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($CompletePlayload | ConvertTo-Json -Depth 5)"))
      $Response = Invoke-RedfishRequest $RedfishSession $Path 'Patch' $CompletePlayload
      Resolve-RedfishPartialSuccessResponse $RedfishSession $Response | Out-Null
      return $null
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Payload = @{
          IPVersion = $IPVersionList[$idx];
          IPv4Address = $IPv4AddressList[$idx];
          IPv4Gateway = $IPv4GatewayList[$idx];
          IPv4SubnetMask = $IPv4SubnetMaskList[$idx];
          IPv4AddressOrigin = $IPv4AddressOriginList[$idx];
          IPv6Address = $IPv6AddresseList[$idx];
          IPv6PrefixLength = $IPv6PrefixLengthList[$idx];
          IPv6AddressOrigin = $IPv6AddressOriginList[$idx];
          IPv6Gateway = $IPv6GatewayList[$idx]
        }| Remove-EmptyValues | Resolve-EnumValues

        if (-not (Assert-IPv4 $IPv4Address)) {
          throw $(Get-i18n ERROR_IPV4_ADDRESS_INVALID)
        }

        if (-not (Assert-IPv4 $IPv4Gateway)) {
          throw $(Get-i18n ERROR_IPV4_GATEWAY_INVALID)
        }

        if (-not (Assert-IPv4 $IPv4SubnetMask)) {
          throw $(Get-i18n ERROR_IPV4_SUBNETMASK_INVALID)
        }

        if (-not (Assert-IPv6 $IPv6Address)) {
          throw $(Get-i18n ERROR_IPV6_ADDRESS_INVALID)
        }

        if (-not (Assert-IPv6 $IPv6Gateway)) {
          throw $(Get-i18n ERROR_IPV6_GATEWAY_INVALID)
        }

        if ($Payload.Count -eq 0) {
          throw $(Get-i18n ERROR_NO_UPDATE_PAYLOAD)
        }

        $Parameters = @($RedfishSession, $Payload)
        $Logger.info($(Trace-Session $RedfishSession "Submit Set BMC IP task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $Parameters))
      }

      $Results = Get-AsyncTaskResults $tasks
      return ,$Results
    }
    finally {
      Close-Pool $pool
    }
  }

  end {
  }
}