# Copyright (C) 2020 Huawei Technologies Co., Ltd. All rights reserved.	
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the MIT License		

# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# MIT License for more detail

<# NOTE: iBMC Power module Cmdlets #>

function Get-iBMCPowerInfo {
<#
.SYNOPSIS
Get all iBMC Power Controls consumed infomation.

.DESCRIPTION
Get all iBMC Power Controls consumed infomation.
Including Id, Name, Consumed Watts, Min Consumed Watts, Max Consumed Watts, Avg Consumed Watts.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[][]
Returns Array of PSObject indicates all iBMC Power Controls Reading infomation if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> Get-iBMCPowerInfo -Session $session

Host                 : 192.168.1.1
Id                   : 0
Name                 : System Power Control 1
PowerConsumedWatts   : 222 Watts
MaxConsumedWatts     : 432 Watts
MinConsumedWatts     : 18 Watts
AverageConsumedWatts : 183 Watts


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

    $Logger.info("Invoke Get All iBMC Power Controls Readings function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get All iBMC Power Controls Readings  now"))
      $Path = "/Chassis/$($RedfishSession.Id)/Power"
      $Response = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
      $PowerControls = $Response.PowerControl

      $Results = New-Object System.Collections.ArrayList
      $PowerControls | ForEach-Object {
        $Metrics = $_.PowerMetrics
        $PowerInfo = New-Object PSObject
        $PowerInfo | Add-Member -MemberType NoteProperty "Id" $_.MemberId
        $PowerInfo | Add-Member -MemberType NoteProperty "Name" $_.Name
        $PowerInfo | Add-Member -MemberType NoteProperty "PowerConsumedWatts" "$($_.PowerConsumedWatts) Watts"
        $PowerInfo | Add-Member -MemberType NoteProperty "MaxConsumedWatts" "$($Metrics.MaxConsumedWatts) Watts"
        $PowerInfo | Add-Member -MemberType NoteProperty "MinConsumedWatts" "$($Metrics.MinConsumedWatts) Watts"
        $PowerInfo | Add-Member -MemberType NoteProperty "AverageConsumedWatts" "$($Metrics.AverageConsumedWatts) Watts"
        $PowerInfo = $(Update-SessionAddress $RedfishSession $PowerInfo)
        [Void] $Results.Add($PowerInfo)
      }
      return , $Results.ToArray()
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get All iBMC Power Controls Readings  task"))
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


function Get-iBMCPowerSupplies {
<#
.SYNOPSIS
Query information about the power supply resource collection of a server.

.DESCRIPTION
Query information about the power supply resource collection of a server.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[][]
Returns an array of PSObject indicates all power supply resources if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $PowerSuppliesArray = Get-iBMCPowerSupplies -Session $session
PS C:\> $PowerSuppliesArray

Host               : 192.168.1.1
FirmwareVersion    : DC:108 PFC:107
LineInputVoltage   : 0
Manufacturer       : LITEON
MemberId           : 0
Model              : PS-2152-2H
Name               : PS1
PartNumber         : 02131336
PowerCapacityWatts : 1500
PowerSupplyType    :
Redundancy         : {@{@odata.id=/redfish/v1/Chassis/1/Power#/Redundancy/0}}
SerialNumber       : 2102131336CSJ3005736
Status             : @{State=Enabled; Health=OK}
ActiveStandby      : Active
DeviceLocator      : PS1
InputAmperage      : 0
OutputAmperage     : 0
OutputVoltage      : 0
Position           : chassis
PowerInputWatts    : 0
PowerOutputWatts   : 0
Protocol           : PSU

Host               : 192.168.1.1
FirmwareVersion    : DC:108 PFC:107
LineInputVoltage   : 225
Manufacturer       : LITEON
MemberId           : 1
Model              : PS-2152-2H
Name               : PS2
PartNumber         : 02131336
PowerCapacityWatts : 1500
PowerSupplyType    : AC
Redundancy         : {@{@odata.id=/redfish/v1/Chassis/1/Power#/Redundancy/0}}
SerialNumber       : 2102131336CSJ3001326
Status             : @{State=Enabled; Health=OK}
ActiveStandby      : Active
DeviceLocator      : PS2
InputAmperage      : 0
OutputAmperage     : 0.234375
OutputVoltage      : 0.046875
Position           : chassis
PowerInputWatts    : 204
PowerOutputWatts   : 188
Protocol           : PSU


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCPowerSuppliesHealth
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

    $Logger.info("Invoke Get iBMC power supply resources function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get iBMC power supply resources now"))

      $GetPowerPath = "/Chassis/$($RedfishSession.Id)/Power"
      $Power = Invoke-RedfishRequest $RedfishSession $GetPowerPath | ConvertFrom-WebResponse

      $PowerSupplies = New-Object System.Collections.ArrayList
      $Power.PowerSupplies | ForEach-Object {
        $Cleanup = $_ | Clear-OdataProperties | Merge-OemProperties
        [Void] $PowerSupplies.Add($(Update-SessionAddress $RedfishSession $Cleanup))
      }
      return , $PowerSupplies.ToArray()
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get iBMC power supply resources task"))
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


function Get-iBMCPowerSuppliesHealth {
<#
.SYNOPSIS
Query health information about the power supply resources of a server.

.DESCRIPTION
Query health information about the power supply resources of a server including summary health status and every power supply health status.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[]
Returns PSObject indicates power supply health status of server if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $health = Get-iBMCPowerSuppliesHealth -Session $session
PS C:\> $health | fl

Host       : 192.168.1.1
Summary    : @{HealthRollup=Critical}
MemberId#0 : @{Health=OK; State=Enabled; Name=PS1}
MemberId#1 : @{Health=Critical; State=Enabled; Name=PS2}

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCPowerSupplies
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

    $Logger.info("Invoke Get iBMC power supply health function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get iBMC power supply Health now"))

      $GetChassisPath = "/Chassis/$($RedfishSession.Id)"
      $Chassis = Invoke-RedfishRequest $RedfishSession $GetChassisPath | ConvertFrom-WebResponse

      $Health = New-Object PSObject -Property @{
        Host    = $RedfishSession.Address;
        Summary = $Chassis.Oem.huawei.PowerSupplySummary.Status;
      }

      $StatusPropertyOrder = @("Health", "State")
      $GetPowerPath = "/Chassis/$($RedfishSession.Id)/Power"
      $Chassis = Invoke-RedfishRequest $RedfishSession $GetPowerPath | ConvertFrom-WebResponse

      $Chassis.PowerSupplies | ForEach-Object {
        $Status = Copy-ObjectProperties $_.Status $StatusPropertyOrder
        $Status | Add-member Noteproperty "Name" $_.Name
        $Health | Add-Member Noteproperty "MemberId#$($_.MemberId)" $Status
      }

      return $Health
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get iBMC power supply Health task"))
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