# Copyright (C) 2020 Huawei Technologies Co., Ltd. All rights reserved.	
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the MIT License		

# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# MIT License for more detail

<# NOTE: iBMC Memory module Cmdlets #>

function Get-iBMCMemory {
<#
.SYNOPSIS
Query information about the memory resource collection of a server.

.DESCRIPTION
Query information about the memory resource collection of a server.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[][]
Returns an array of PSObject indicates all memory resources if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $MemoriesArray = Get-iBMCMemory -Session $session
PS C:\> $MemoriesArray

Host                : 10.1.1.2
Id                  : mainboardDIMM000
CapacityMiB         : 16384
Manufacturer        : Samsung
OperatingSpeedMhz   : 2133
SerialNumber        : 0x177E9BFD
PartNumber          :
MemoryDeviceType    : DDR4
DataWidthBits       : 72
RankCount           : 2
DeviceLocator       : DIMM000
BaseModuleType      : RDIMM
Socket              : 0
Controller          : 0
Channel             : 0
Slot                : 0
MinVoltageMillivolt : 1200
Technology          : Synchronous| Registered (Buffered)
Position            : mainboard
Status              : @{Health=OK; State=Enabled}

Host                : 10.1.1.2
Id                  : mainboardDIMM001
CapacityMiB         : 16384
Manufacturer        : Samsung
OperatingSpeedMhz   : 2133
SerialNumber        : 0x177E9BFE
PartNumber          :
MemoryDeviceType    : DDR4
DataWidthBits       : 72
RankCount           : 2
DeviceLocator       : DIMM001
BaseModuleType      : RDIMM
Socket              : 0
Controller          : 0
Channel             : 0
Slot                : 1
MinVoltageMillivolt : 1200
Technology          : Synchronous| Registered (Buffered)
Position            : mainboard
Status              : @{Health=OK; State=Enabled}


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCMemoryHealth
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

    $Logger.info("Invoke Get iBMC Memory resources function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get iBMC Memory resources now"))

      $GetSystemPath = "/Systems/$($RedfishSession.Id)"
      $System = Invoke-RedfishRequest $RedfishSession $GetSystemPath | ConvertFrom-WebResponse

      # Use new memory view API
      if ($null -ne $System.Oem.huawei.MemoryView) {
        $Path = $System.Oem.huawei.MemoryView."@odata.id"
        $View = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
        $Memeries = $View.Information | Where-Object { $_.Status.State -ne $BMC.State.Absent}
        $Results = New-Object System.Collections.ArrayList
        $Memeries | ForEach-Object {
          [Void] $Results.add($(Update-SessionAddress $RedfishSession $_))
        }

        return , $Results.ToArray()
      } else {
        $GetMemoryMembersPath = $System.Memory."@odata.id"
        $Members = Invoke-RedfishRequest $RedfishSession $GetMemoryMembersPath | ConvertFrom-WebResponse
        $Properties = @(
          "Id",
          "CapacityMiB",
          "Manufacturer",
          "OperatingSpeedMhz",
          "SerialNumber",
          "PartNumber",
          "MemoryDeviceType",
          "DataWidthBits",
          "RankCount",
          "DeviceLocator",
          "BaseModuleType",
          "Socket",
          "Controller",
          "Channel",
          "Slot",
          "MinVoltageMillivolt",
          "Technology",
          "Position",
          "Status"
        )
        $Memories = New-Object System.Collections.ArrayList
        $Members.Members | ForEach-Object {
          $Path = $_."@odata.id"
          $Memory = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
          if ($Memory.Status.State -ne $BMC.State.Absent) {
            $Cleanup = $Memory | Clear-OdataProperties | Merge-OemProperties
            $Cleanup = Merge-NestProperties $Cleanup @("MemoryLocation")
            $Clone = Copy-ObjectProperties $Cleanup $Properties
            [Void] $Memories.Add($(Update-SessionAddress $RedfishSession $Clone))
          }
        }
        return ,$Memories.ToArray()
      }
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get iBMC Memory resources task"))
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


function Get-iBMCMemoryHealth {
<#
.SYNOPSIS
Query health information about the memory of a server.

.DESCRIPTION
Query health information about the memory of a server including summary health status and every memory health status.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[]
Returns PSObject indicates memory health status of server if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $health = Get-iBMCMemoryHealth -Session $session
PS C:\> $health | fl

Host                : 10.1.1.2
Summary             : @{HealthRollup=OK}
ID#mainboardDIMM000 : @{Health=OK; State=Enabled; DeviceLocator=DIMM000}
ID#mainboardDIMM010 : @{Health=OK; State=Enabled; DeviceLocator=DIMM010}
ID#mainboardDIMM030 : @{Health=OK; State=Enabled; DeviceLocator=DIMM030}
ID#mainboardDIMM040 : @{Health=OK; State=Enabled; DeviceLocator=DIMM040}
ID#mainboardDIMM100 : @{Health=OK; State=Enabled; DeviceLocator=DIMM100}
ID#mainboardDIMM110 : @{Health=OK; State=Enabled; DeviceLocator=DIMM110}
ID#mainboardDIMM130 : @{Health=OK; State=Enabled; DeviceLocator=DIMM130}
ID#mainboardDIMM140 : @{Health=OK; State=Enabled; DeviceLocator=DIMM140}

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCMemory
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

    $Logger.info("Invoke Get iBMC memory health function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get iBMC memory Health now"))

      $GetSystemPath = "/Systems/$($RedfishSession.Id)"
      $System = Invoke-RedfishRequest $RedfishSession $GetSystemPath | ConvertFrom-WebResponse

      $Health = New-Object PSObject -Property @{
        Host    = $RedfishSession.Address;
        Summary = $System.MemorySummary.Status;
      }

      $StatusPropertyOrder = @("Health", "State")
      if ($null -ne $System.Oem.huawei.MemoryView) {
        $Path = $System.Oem.huawei.MemoryView."@odata.id"
        $View = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
        $Memeries = $View.Information | Where-Object { $_.Status.State -ne $BMC.State.Absent}
        $Memeries | ForEach-Object {
          $Status = Copy-ObjectProperties $_.Status $StatusPropertyOrder
          $Status | Add-member Noteproperty "DeviceLocator" $_.DeviceLocator
          $Health | Add-member Noteproperty "ID#$($_.ID)" $Status
        }
      }
      else {
        $GetMemoryMembersPath = $System.Memory."@odata.id"
        $Members = Invoke-RedfishRequest $RedfishSession $GetMemoryMembersPath | ConvertFrom-WebResponse
        $Members.Members | ForEach-Object {
          $Path = $_."@odata.id"
          $Memory = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
          if ($Memory.Status.State -ne $BMC.State.Absent) {
            $Status = Copy-ObjectProperties $Memory.Status $StatusPropertyOrder
            $Status | Add-member Noteproperty "DeviceLocator" $Memory.DeviceLocator
            $Health | Add-member Noteproperty "ID#$($Memory.ID)" $Status
          }
        }
      }

      return $Health
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get iBMC memory Health task"))
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