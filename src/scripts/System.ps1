<# NOTE: iBMC Systems module Cmdlets #>

function Get-iBMCSystemInfo {
<#
.SYNOPSIS
Get system resource details of the server.

.DESCRIPTION
Get system resource details of the server.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
String
Returns iBMC Asset Tag if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $System = Get-iBMCSystemInfo $session
PS C:\> $System

Host             : 10.1.1.2
Id               : 1
Name             : Computer System
AssetTag         : my test
Manufacturer     : Huawei
Model            : 2288H V5
SerialNumber     : 2102311TYBN0J3000293
UUID             : 877AA970-58F9-8432-E811-80345C184638
HostName         :
PartNumber       : 02311TYB
HostingRole      : {ApplicationServer}
Status           : @{State=Disabled; Health=OK}
PowerState       : Off
Boot             : @{BootSourceOverrideTarget=Pxe; BootSourceOverrideEnabled=Continuous; BootSourceOverrideMode=Legacy; BootSourceOverride
                    Target@Redfish.AllowableValues=System.Object[]}
TrustedModules   :
BiosVersion      : 0.81
ProcessorSummary : @{Count=2; Model=Central Processor; Status=}
MemorySummary    : @{TotalSystemMemoryGiB=128; Status=}
PCIeDevices      : {}
PCIeFunctions    : {}
Oem              : @{Huawei=}

PS C:\> $System.Boot | fl

BootSourceOverrideTarget                         : Pxe
BootSourceOverrideEnabled                        : Continuous
BootSourceOverrideMode                           : Legacy
BootSourceOverrideTarget@Redfish.AllowableValues : {None, Pxe, Floppy, Cd...}


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

    $Logger.info("Invoke Get iBMC System function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get iBMC System now"))
      $Path = "/Systems/$($RedfishSession.Id)"
      $Response = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
      $Properties = @(
        "Id", "Name", "AssetTag", "Manufacturer", "Model", "SerialNumber", "UUID",
        "HostName", "PartNumber", "HostingRole", "Status", "PowerState", "Boot", "TrustedModules",
        "BiosVersion", "ProcessorSummary", "MemorySummary", "PCIeDevices", "PCIeFunctions",
        "Oem"
      )

      $System = Copy-ObjectProperties $Response $Properties

      $Excludes = @(
        "InfiniBandInterfaces", "NetworkBondings", "ProcessorView",
        "MemoryView", "ProcessorsHistoryUsageRate", "MemoryHistoryUsageRate",
        "NetworkHistoryUsageRate"
      )
      $Oem = Copy-ObjectExcludes $Response.Oem.Huawei $Excludes
      $System.Oem.Huawei = $Oem
      return Update-SessionAddress $RedfishSession $System
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get iBMC System task"))
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


function Get-iBMCSystemNetworkSettings {
<#
.SYNOPSIS
Get system resource details of the server.

.DESCRIPTION
Get system resource details of the server. Server OS system and iBMA should be installed to support this cmdlet.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[][]
Returns iBMC System LinkUp Ethernet Interfaces if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2-5 -Credential $credential -TrustCert
PS C:\> $Interfaces = Get-iBMCSystemNetworkSettings $session
PS C:\> $Interfaces

Host                : 10.1.1.2
Id                  : mainboardLOMPort1
Name                : System Ethernet Interface
PermanentMACAddress : 04:88:5F:D4:C6:52
MACAddress          : 04:88:5F:D4:C6:52
LinkStatus          : LinkUp
IPv4Addresses       : {@{Address=10.1.1.20; SubnetMask=255.255.0.0; Gateway=10.1.0.1; AddressOrigin=}}
IPv6Addresses       : {@{Address=2017::d5a; PrefixLength=64; AddressOrigin=SLAAC; AddressState=},
                      @{Address=2017::d5a;PrefixLength=64; AddressOrigin=SLAAC; AddressState=},
                      @{Address=fe80::4a57:2ff:feab:d5a; PrefixLength=64; AddressOrigin=Static; AddressState=}}
IPv6DefaultGateway  : fe80::525d:acff:feed:5c27
InterfaceType       : Physical
BandwidthUsage      : 0
BDF                 : 0000:1a:00.0

Host                : 10.1.1.3
Id                  : mainboardLOMPort2
Name                : System Ethernet Interface
PermanentMACAddress : 04:88:5F:D4:C6:53
MACAddress          : 04:88:5F:D4:C6:54
LinkStatus          : NoLink
IPv4Addresses       : {}
IPv6Addresses       : {}
IPv6DefaultGateway  :
InterfaceType       : Physical
BandwidthUsage      :
BDF                 : 0000:1a:00.1

Host                : 10.1.1.4
Id                  : mainboardLOMPort3
Name                : System Ethernet Interface
PermanentMACAddress : 04:88:5F:D4:C6:54
MACAddress          : 04:88:5F:D4:C6:54
LinkStatus          :
IPv4Addresses       : {}
IPv6Addresses       : {}
IPv6DefaultGateway  :
InterfaceType       : Physical
BandwidthUsage      :
BDF                 : 0000:1a:00.2

Host                : 10.1.1.5
Id                  : mainboardLOMPort4
Name                : System Ethernet Interface
PermanentMACAddress : 04:88:5F:D4:C6:55
MACAddress          : 04:88:5F:D4:C6:55
LinkStatus          : NoLink
IPv4Addresses       : {}
IPv6Addresses       : {}
IPv6DefaultGateway  :
InterfaceType       : Physical
BandwidthUsage      :
BDF                 : 0000:1a:00.3

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

    $Logger.info("Invoke Get iBMC System Networking Settings function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get iBMC System Networking Settings now"))
      $GetInterfacesPath = "/Systems/$($RedfishSession.Id)/EthernetInterfaces"
      $EthernetInterfaces = Invoke-RedfishRequest $RedfishSession $GetInterfacesPath | ConvertFrom-WebResponse
      $Results = New-Object System.Collections.ArrayList
      for ($idx=0; $idx -lt $EthernetInterfaces.Members.Count; $idx++) {
        $Member = $EthernetInterfaces.Members[$idx]
        $EthernetInterface = Invoke-RedfishRequest $RedfishSession $Member.'@odata.id' | ConvertFrom-WebResponse
        # $Logger.Debug($(Trace-Session $RedfishSession "Load EthernetInterface: $EthernetInterface"))
        # if ($BMC.LinkStatus.LinkUp -eq $EthernetInterface.LinkStatus) {
        $Properties = @(
          "Id", "Name", "PermanentMACAddress", "MACAddress", "LinkStatus",
          "IPv4Addresses", "IPv6Addresses", "IPv6DefaultGateway"
        )
        $Clone = Copy-ObjectProperties $EthernetInterface $Properties
        $Clone | Add-Member -MemberType NoteProperty "InterfaceType" $EthernetInterface.Oem.Huawei.InterfaceType
        $Clone | Add-Member -MemberType NoteProperty "BandwidthUsage" $EthernetInterface.Oem.Huawei.BandwidthUsage
        $Clone | Add-Member -MemberType NoteProperty "BDF" $EthernetInterface.Oem.Huawei.BDF
        $Clone = Update-SessionAddress $RedfishSession $Clone
        [Void] $Results.add($Clone)
        # }
      }

      if ($Results.Count -eq 0) {
        throw $(Get-i18n FAIL_NO_LINKUP_INTERFACE)
      }

      return ,$Results.ToArray()
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get iBMC System Networking Settings task"))
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
