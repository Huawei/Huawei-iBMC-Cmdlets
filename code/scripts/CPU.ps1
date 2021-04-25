# Copyright (C) 2020 Huawei Technologies Co., Ltd. All rights reserved.	
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the MIT License		

# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# MIT License for more detail

<# NOTE: iBMC CPU module Cmdlets #>

function Get-iBMCProcessors {
  <#
.SYNOPSIS
Query information about the Processor resources collection of a server.

.DESCRIPTION
Query information about the Processor resources collection of a server.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[][]
Returns an array of PSObject indicates all Processor resources if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $ProcessorsArray = Get-iBMCProcessors -Session $session
PS C:\> $ProcessorsArray

Host                    : 192.168.1.1
Id                      : 1
ProcessorType           : CPU
ProcessorArchitecture   : x86
InstructionSet          : x86-64
Manufacturer            : Intel(R) Corporation
Model                   : Intel(R) Xeon(R) Silver 4110 CPU @ 2.10GHz
IdentificationRegisters : 54-06-05-00-FF-FB-EB-BF
MaxSpeedMHz             : 4000
TotalCores              : 8
TotalThreads            : 16
Socket                  : 0
L1CacheKiB              : 512
L2CacheKiB              : 8192
L3CacheKiB              : 11264
DeviceLocator           : CPU1
Position                : mainboard
PartNumber              : 41020679
Temperature             : 30
EnabledSetting          : True
FrequencyMHz            : 2100
OtherParameters         : 64-bit Capable| Multi-Core| Hardware Thread| Execute Protection| Enhanced Virtualization| Power/Performance Control
Status                  : @{State=Enabled; Health=Warning}

Host                    : 192.168.1.1
Id                      : 2
ProcessorType           : CPU
ProcessorArchitecture   : x86
InstructionSet          : x86-64
Manufacturer            : Intel(R) Corporation
Model                   : Intel(R) Xeon(R) Silver 4110 CPU @ 2.10GHz
IdentificationRegisters : 54-06-05-00-FF-FB-EB-BF
MaxSpeedMHz             : 4000
TotalCores              : 8
TotalThreads            : 16
Socket                  : 1
L1CacheKiB              : 512
L2CacheKiB              : 8192
L3CacheKiB              : 11264
DeviceLocator           : CPU2
Position                : mainboard
PartNumber              : 41020679
Temperature             : 31
EnabledSetting          : True
FrequencyMHz            : 2100
OtherParameters         : 64-bit Capable| Multi-Core| Hardware Thread| Execute Protection| Enhanced Virtualization| Power/Performance Control
Status                  : @{State=Enabled; Health=OK}


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCProcessorsHealth
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

    $Logger.info("Invoke Get iBMC CPU resources function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get iBMC CPU resources now"))

      $GetSystemPath = "/Systems/$($RedfishSession.Id)"
      $System = Invoke-RedfishRequest $RedfishSession $GetSystemPath | ConvertFrom-WebResponse

      # Use new processor view API
      if ($null -ne $System.Oem.huawei.ProcessorView) {
        $Path = $System.Oem.huawei.ProcessorView."@odata.id"
        $View = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
        $Processors = New-Object System.Collections.ArrayList
        $View.Information | ForEach-Object {
          [Void] $Processors.add($(Update-SessionAddress $RedfishSession $_))
        }

        return , $Processors.ToArray()
      }
      else {
        $GetProcessorsPath = $System.Processors."@odata.id"
        $Members = Invoke-RedfishRequest $RedfishSession $GetProcessorsPath | ConvertFrom-WebResponse

        $Properties = @(
          "Id",
          "ProcessorType",
          "ProcessorArchitecture",
          "InstructionSet",
          "Manufacturer",
          "Model",
          "IdentificationRegisters",
          "MaxSpeedMHz",
          "TotalCores",
          "TotalThreads",
          "Socket",
          "L1CacheKiB",
          "L2CacheKiB",
          "L3CacheKiB",
          "DeviceLocator",
          "Position",
          "PartNumber",
          "Temperature",
          "EnabledSetting",
          "FrequencyMHz",
          "OtherParameters",
          "Status"
        )
        $Processors = New-Object System.Collections.ArrayList
        $Members.Members | ForEach-Object {
          $Path = $_."@odata.id"
          $Processor = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
          $Cleanup = $Processor | Clear-OdataProperties | Merge-OemProperties
          $ReOrder = Copy-ObjectProperties $Cleanup $Properties
          [Void] $Processors.Add($(Update-SessionAddress $RedfishSession $ReOrder))
        }
        return , $Processors.ToArray()
      }
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get iBMC CPU resources task"))
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


function Get-iBMCProcessorsHealth {
<#
.SYNOPSIS
Query health information about the Processors of a server.

.DESCRIPTION
Query health information about the Processors of a server including summary health status and every CPU health status.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[]
Returns PSObject indicates Processor health status of server if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $health = Get-iBMCProcessorsHealth -Session $session
PS C:\> $health | fl

Host    : 192.168.1.1
Summary : @{HealthRollup=OK}
ID#1    : @{Health=OK; State=Enabled; DeviceLocator=CPU1}
ID#2    : @{Health=OK; State=Enabled; DeviceLocator=CPU2}

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCProcessors
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

    $Logger.info("Invoke Get iBMC CPU health function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get iBMC CPU Health now"))

      $GetSystemPath = "/Systems/$($RedfishSession.Id)"
      $System = Invoke-RedfishRequest $RedfishSession $GetSystemPath | ConvertFrom-WebResponse


      $Health = New-Object PSObject -Property @{
        Host    = $RedfishSession.Address;
        Summary = $System.ProcessorSummary.Status;
      }

      $StatusPropertyOrder = @("Health", "State")
      # Use new processor view API
      if ($null -ne $System.Oem.huawei.ProcessorView) {
        $Path = $System.Oem.huawei.ProcessorView."@odata.id"
        $View = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
        $View.Information | ForEach-Object {
          $Status = Copy-ObjectProperties $_.Status $StatusPropertyOrder
          $Status | Add-member Noteproperty "DeviceLocator" $_.DeviceLocator
          $Health | Add-member Noteproperty "ID#$($_.ID)" $Status
        }
      }
      else {
        $GetProcessorsPath = $System.Processors."@odata.id"
        $Members = Invoke-RedfishRequest $RedfishSession $GetProcessorsPath | ConvertFrom-WebResponse
        $Members.Members | ForEach-Object {
          $Path = $_."@odata.id"
          $Processor = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
          $Status = Copy-ObjectProperties $Processor.Status $StatusPropertyOrder
          $Status | Add-member Noteproperty "DeviceLocator" $Processor.Oem.Huawei.DeviceLocator
          $Health | Add-member Noteproperty "ID#$($Processor.ID)" $Status
        }
      }

      return $Health
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get iBMC CPU Health task"))
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