# Copyright (C) 2020 Huawei Technologies Co., Ltd. All rights reserved.	
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the MIT License		

# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# MIT License for more detail

<# NOTE: iBMC Network Adapter module Cmdlets #>

function Get-iBMCNetworkAdapters {
<#
.SYNOPSIS
Query information about the network adapter resource collection of a server.

.DESCRIPTION
Query information about the network adapter resource collection of a server.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[][]
Returns an array of PSObject indicates all network adapter resources if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $NetworkAdaptersArray = Get-iBMCNetworkAdapters -Session $session
PS C:\> $NetworkAdaptersArray

Host              : 10.1.1.2
Id                : mainboardLOM
Manufacturer      : Intel
Model             : X722
Status            : @{State=Enabled; Health=OK}
Name              : LOM
DriverName        :
DriverVersion     :
CardManufacturer  : Huawei
CardModel         : 2*10GE+2*GE
DeviceLocator     : LOM
Position          : mainboard
NetworkTechnology : {Ethernet}
RootBDF           : 0000:19:03.0
Configuration     :
NetworkPorts      : {@{Name=1; Id=1; PhysicalPortNumber=1; LinkStatus=Down; AssociatedNetworkAddresses=System.Object[]; PortType=OpticalPort; BDF=0000:1a:0
                    0.0; FirmwarePackageVersion=; DriverVersion=; DriverName=}, @{Name=2; Id=2; PhysicalPortNumber=2; LinkStatus=Down; AssociatedNetworkAdd
                    resses=System.Object[]; PortType=OpticalPort; BDF=0000:1a:00.1; FirmwarePackageVersion=; DriverVersion=; DriverName=}, @{Name=3; Id=3;
                    PhysicalPortNumber=3; LinkStatus=Up; AssociatedNetworkAddresses=System.Object[]; PortType=ElectricalPort; BDF=0000:1a:00.2; FirmwarePac
                    kageVersion=; DriverVersion=; DriverName=}, @{Name=4; Id=4; PhysicalPortNumber=4; LinkStatus=Down; AssociatedNetworkAddresses=System.Ob
                    ject[]; PortType=ElectricalPort; BDF=0000:1a:00.3; FirmwarePackageVersion=; DriverVersion=; DriverName=}}

Host              : 10.1.1.2
Id                : mainboardMEZZ1
Manufacturer      : Intel
Model             : 2*82599
Status            : @{Health=OK; State=Enabled}
Name              : MZ312
DriverName        :
DriverVersion     :
CardManufacturer  : Huawei
CardModel         : 4*10G Mezzanine Card
DeviceLocator     : mainboard
Position          : MEZZ1
NetworkTechnology : {Ethernet}
NetworkPorts      : {@{Name=1; Id=1; PhysicalPortNumber=1; LinkStatus=; AssociatedNetworkAddresses=System.Object[]; PortType=}, @{Name=2; Id=2; PhysicalPor
                    tNumber=2; LinkStatus=; AssociatedNetworkAddresses=System.Object[]; PortType=}, @{Name=3; Id=3; PhysicalPortNumber=3; LinkStatus=; Asso
                    ciatedNetworkAddresses=System.Object[]; PortType=}, @{Name=4; Id=4; PhysicalPortNumber=4; LinkStatus=; AssociatedNetworkAddresses=Syste
                    m.Object[]; PortType=}}

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCNetworkAdaptersHealth
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

    $Logger.info("Invoke Get iBMC network adapter resources function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get iBMC network adapter resources now"))

      $GetChassisPath = "/Chassis/$($RedfishSession.Id)/NetworkAdapters"
      $Collection = Invoke-RedfishRequest $RedfishSession $GetChassisPath | ConvertFrom-WebResponse

      $NetworkAdatperProperties = @("Id", "Manufacturer", "Model", "Status", "Oem")
      $NetworkAdapters = New-Object System.Collections.ArrayList
      $Collection.Members | ForEach-Object {
        $OdataId = $_."@odata.id"
        $NetworkAdapter = Invoke-RedfishRequest $RedfishSession $OdataId | ConvertFrom-WebResponse
        $Clone = Copy-ObjectProperties $NetworkAdapter $NetworkAdatperProperties
        $Merged = $Clone | Merge-OemProperties

        $NetworkPorts = New-Object System.Collections.ArrayList
        $GetPortsPath = $NetworkAdapter.NetworkPorts."@odata.id"
        $NetworkPortCollection = Invoke-RedfishRequest $RedfishSession $GetPortsPath | ConvertFrom-WebResponse
        $NetworkPortCollection.Members | ForEach-Object {
          $NetworkPort = Invoke-RedfishRequest $RedfishSession $_."@odata.id" | ConvertFrom-WebResponse
          $CleanUp = $NetworkPort | Clear-OdataProperties | Merge-OemProperties
          [Void] $NetworkPorts.add($CleanUp)
        }

        $Merged | Add-Member -MemberType NoteProperty -Name "NetworkPorts" -Value $NetworkPorts.ToArray()
        [Void] $NetworkAdapters.Add($(Update-SessionAddress $RedfishSession $Merged))
      }
      return ,$NetworkAdapters.ToArray()
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get iBMC network adapter resources task"))
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

function Get-iBMCNetworkAdaptersHealth {
<#
.SYNOPSIS
Query health information about the network adapter resources of a server.

.DESCRIPTION
Query health information about the network adapter resources of a server including summary health status and every network adapter health status.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[]
Returns PSObject indicates network adapter health status of server if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $health = Get-iBMCNetworkAdaptersHealth -Session $session
PS C:\> $health | fl

Host            : 10.1.1.2
Summary         : @{HealthRollup=OK}
ID#mainboardLOM : @{Health=OK; State=Enabled; Name=mainboardLOM}

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCNetworkAdapters
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

    $Logger.info("Invoke Get iBMC network adapter health function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get iBMC network adapter health now"))

      $GetChassisPath = "/Chassis/$($RedfishSession.Id)"
      $Chassis = Invoke-RedfishRequest $RedfishSession $GetChassisPath | ConvertFrom-WebResponse

      $Health = New-Object PSObject -Property @{
        Host    = $RedfishSession.Address;
        Summary = $Chassis.Oem.huawei.NetworkAdaptersSummary.Status;
      }

      $GetCollectionPath = "/Chassis/$($RedfishSession.Id)/NetworkAdapters"
      $Collection = Invoke-RedfishRequest $RedfishSession $GetCollectionPath | ConvertFrom-WebResponse
      $StatusPropertyOrder = @("Health", "State")
      $Collection.Members | ForEach-Object {
        $OdataId = $_."@odata.id"
        $NetworkAdapter = Invoke-RedfishRequest $RedfishSession $OdataId | ConvertFrom-WebResponse
        $Status = Copy-ObjectProperties $NetworkAdapter.Status $StatusPropertyOrder
        $Status | Add-member Noteproperty "Name" $NetworkAdapter.Oem.Huawei.Name
        $Health | Add-Member Noteproperty "ID#$($NetworkAdapter.ID)" $Status
      }

      return $Health
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get iBMC network adapter health task"))
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