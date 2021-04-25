# Copyright (C) 2021 Huawei Technologies Co., Ltd. All rights reserved.	
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the MIT License		

# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# MIT License for more detail

<# NOTE: iBMC diagnostic service module Cmdlets #>

function Get-iBMCDiagnosticService {
    <#
    .SYNOPSIS
    Query information about the diagnostics service resource.
    
    .DESCRIPTION
    Query information about the diagnostics service resource.
    Support Services:
      "VideoRecordingEnabled", "ScreenShotEnabled", "BlackBoxEnabled",
      "SerialPortDataEnabled", "VideoPlaybackConnNum", "VideoRecordInfo", "ScreenShotCreateTime"
    
    .PARAMETER Session
    iBMC redfish session object which is created by Connect-iBMC cmdlet.
    A session object identifies an iBMC server to which this cmdlet will be executed.
    
    .OUTPUTS
    PSObject[]
    Returns PSObject which contains all support services infomation if cmdlet executes successfully.
    In case of an error or warning, exception will be returned.
    
    .EXAMPLE
    
    PS C:\> $credential = Get-Credential
    PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
    PS C:\> $DiagnosticServices = Get-iBMCDiagnosticService $session
    PS C:\> $DiagnosticServices
    
    Host                  : 192.168.1.1
    VideoRecordingEnabled : True
    ScreenShotEnabled     : True
    BlackBoxEnabled       : True
    SerialPortDataEnabled : True
    VideoPlaybackConnNum  : 0
    VideoRecordInfo       : {$null, @{VideoSizeByte=324404; CreateTime=2021-02-23 13:22:21}, @{VideoSizeByte=606024; CreateTime=2021-02-26 07:21:07}}
    ScreenShotCreateTime  : {2021-02-26 07:20:44, 2021-02-26 07:08:48, 2021-02-26 07:09:11, $null}
    
    .LINK
    https://github.com/Huawei/Huawei-iBMC-Cmdlets
    
    Set-iBMCDiagnosticService
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
    
        $Logger.info("Invoke Get BMC Diagnostic Service function")
    
        $ScriptBlock = {
          param($RedfishSession)
          $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke get BMC Diagnostic Service now"))
          $Path = "/Managers/$($RedfishSession.Id)/DiagnosticService"
          $Response = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
    
          $Properties = @(
            "VideoRecordingEnabled", 
            "ScreenShotEnabled", 
            "BlackBoxEnabled", 
            "SerialPortDataEnabled", 
            "VideoPlaybackConnNum", 
            "VideoRecordInfo", 
            "ScreenShotCreateTime"
            )
          $Services = Copy-ObjectProperties $Response $Properties
          return $(Update-SessionAddress $RedfishSession $Services)
        }
    
        try {
          $tasks = New-Object System.Collections.ArrayList
          $pool = New-RunspacePool $Session.Count
          for ($idx = 0; $idx -lt $Session.Count; $idx++) {
            $RedfishSession = $Session[$idx]
            $Logger.info($(Trace-Session $RedfishSession "Submit get BMC Diagnostic Service task"))
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
    
    function Set-iBMCDiagnosticService {
    <#
    .SYNOPSIS
    Modify iBMC diagnostic service information.
    
    .DESCRIPTION
    Modify iBMC diagnostic service information.
    Support Services:
      "VideoRecordingEnabled", "ScreenShotEnabled", "BlackBoxEnabled", "SerialPortDataEnabled"
    
    .PARAMETER Session
    iBMC redfish session object which is created by Connect-iBMC cmdlet.
    A session object identifies an iBMC server to which this cmdlet will be executed.
    
    .PARAMETER VideoRecordingEnabled
    Indicates enabled the service or not.
    Support values are powershell boolean value: $true(1), $false(0).
    
    .PARAMETER ScreenShotEnabled
    Indicates enabled the service or not.
    Support values are powershell boolean value: $true(1), $false(0).
    
    .PARAMETER BlackBoxEnabled
    Indicates enabled the service or not.
    Support values are powershell boolean value: $true(1), $false(0).

    .PARAMETER SerialPortDataEnabled
    Indicates enabled the service or not.
    Support values are powershell boolean value: $true(1), $false(0).
    
    .OUTPUTS
    Null
    Returns Null if cmdlet executes successfully.
    In case of an error or warning, exception will be returned.
    
    .EXAMPLE
    
    PS C:\> $credential = Get-Credential
    PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
    PS C:\> Set-iBMCDiagnosticService -Session $session -VideoRecordingEnabled $true -ScreenShotEnabled $true -BlackBoxEnabled $true -SerialPortDataEnabled $true
    
    .LINK
    https://github.com/Huawei/Huawei-iBMC-Cmdlets
    
    Get-iBMCDiagnosticService
    Connect-iBMC
    Disconnect-iBMC
    
    #>
      [CmdletBinding()]
      param (
        [RedfishSession[]]
        [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        $Session,
    
        [Boolean[]]
        [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
        $VideoRecordingEnabled,
    
        [Boolean[]]
        [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 2)]
        $ScreenShotEnabled,
    
        [Boolean[]]
        [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 3)]
        $BlackBoxEnabled,

        [Boolean[]]
        [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 4)]
        $SerialPortDataEnabled
      )
    
      begin {
      }
    
      process {
        Assert-ArrayNotNull $Session 'Session'
    
        $VideoRecordingEnabledList = Get-OptionalMatchedSizeArray $Session $VideoRecordingEnabled
        $ScreenShotEnabledList = Get-OptionalMatchedSizeArray $Session $ScreenShotEnabled
        $BlackBoxEnabledList = Get-OptionalMatchedSizeArray $Session $BlackBoxEnabled
        $SerialPortDataEnabledList = Get-OptionalMatchedSizeArray $Session $SerialPortDataEnabled
    
        $Logger.info("Invoke Set BMC Diagnostic Service function")
    
        $ScriptBlock = {
          param($RedfishSession, $Payload)
          $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Set BMC Diagnostic Service now"))
          $Path = "/Managers/$($RedfishSession.Id)/DiagnosticService"
    
          $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Payload | ConvertTo-Json -Depth 5)"))
          Invoke-RedfishRequest $RedfishSession $Path 'Patch' $Payload | Out-Null
          return $null
        }
    
        try {
          $tasks = New-Object System.Collections.ArrayList
          $pool = New-RunspacePool $Session.Count
          for ($idx = 0; $idx -lt $Session.Count; $idx++) {
            $RedfishSession = $Session[$idx]
            $Payload = @{
                VideoRecordingEnabled = $VideoRecordingEnabledList[$idx];
                ScreenShotEnabled     = $ScreenShotEnabledList[$idx];
                BlackBoxEnabled       = $BlackBoxEnabledList[$idx];
                SerialPortDataEnabled = $SerialPortDataEnabledList[$idx]
            } | Remove-EmptyValues | Resolve-EnumValues

            if ($Payload.Count -eq 0) {
                throw $(Get-i18n ERROR_NO_UPDATE_PAYLOAD)
            }

            $Parameters = @($RedfishSession, $Payload)
            $Logger.info($(Trace-Session $RedfishSession "Submit Set BMC Diagnostic Service task"))
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
    
    