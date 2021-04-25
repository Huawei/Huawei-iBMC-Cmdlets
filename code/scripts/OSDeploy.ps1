# Copyright (C) 2020 Huawei Technologies Co., Ltd. All rights reserved.	
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the MIT License		

# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# MIT License for more detail

<# NOTE: SP OS deploy config module Cmdlets #>

function Get-iBMCOSDeployConfig {
<#
.SYNOPSIS
Get Smart Provisioning OS deploy configuration.

.DESCRIPTION
Get Smart Provisioning OS deploy configuration.
Tips:
- This function only supports V5 servers with BIOS version later than 0.39.
- This function can only be used with a valid license.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject
Returns Smart Provisioning OS deploy configuration if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $DeployConfig = Get-ibmcOSDeployConfig $session
PS C:\> $DeployConfig

Host            : 10.10.1.2
Id              : 1
Name            : SP OS Install Parameter
InstallMode     : Recommended
OSType          : Win2016
BootType        : UEFIBoot
CDKey           : *****-*****-*****-*****-*****
RootPwd         : *******
HostName        : huawei
Autopart        : False
AutoPosition    : True
Language        : en-US
TimeZone        : Eastern Standard Time
Keyboard        : 0x00000409
CheckFirmware   : False
Partition       : {@{Name=C; FileSystem=swap; Size=32}}
Software        : {@{FileName=iBMA }}
NetCfg          : {@{Device=; IPv4Addresses=System.Object[]; IPv6Addresses=System.Object[]; NameServers=System.Object[]}}
Packages        : {@{PackageName=System.Object[]; PatternName=System.Object[]}}


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCOSDeployConfig
Set-iBMCOSDeployConfig
Set-iBMCSPService
Connect-iBMCVirtualMedia
Disconnect-iBMCVirtualMedia
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

    $Logger.info("Invoke Get SP OS deploy config function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get SP OS deploy config now"))
      $GetMembersPath = "/Managers/$($RedfishSession.Id)/SPService/SPOSInstallPara"
      $Members = Invoke-RedfishRequest $RedfishSession $GetMembersPath | ConvertFrom-WebResponse
      if ($Members."Members@odata.count" -gt 0) {
        # only one single member indeed
        $Member = $Members."Members"[0]
        $Response = Invoke-RedfishRequest $RedfishSession $Member."@odata.id" | ConvertFrom-WebResponse
        $DeployConfig = Clear-OdataProperties $Response
        return $(Update-SessionAddress $RedfishSession $DeployConfig)
      }
      else {
        # raise an exception if no data
        throw $(Get-i18n "FAIL_SP_DEPLOY_NO_DATA")
      }
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get SP OS deploy config task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock @($RedfishSession)))
      }

      $Results = Get-AsyncTaskResults $tasks
      return , $Results
    }
    finally {
      Close-Pool $pool
    }
  }

  end {
  }
}

function Set-iBMCOSDeployConfig {
<#
.SYNOPSIS
Update Smart Provisioning OS deploy configuration.

.DESCRIPTION
Update Smart Provisioning OS deploy configuration.
Tips:
- This function only supports V5 servers with BIOS version later than 0.39.
- This function can only be used with a valid license.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER ConfigFileURI
Indicates the configuration file path of Smart Provisioning OS deployment.
The URI should be a local file with JSON format that could be read directly.
For examples:
- local: C:\ibmc-os-deploy-config-centos.json
- CIFS: \\192.168.1.2\ibmc-os-deploy-config-centos.json

You can get the specification of OS deployment configuration file at segment 2.2.64 in document
https://support.huawei.com/enterprise/en/doc/DOC1000126992/?idPath=7919749%7C9856522%7C21782478%7C21782482%7C21149487

One simple example for deploy CentOS:

  {
    "InstallMode": "Recommended",
    "OSType": "CentOS7U3",
    "BootType": "UEFIBoot",
    "RootPwd": "Chajian12#$",
    "HostName": "puppet",
    "Language": "en_US.UTF-8",
    "TimeZone": "Asia/Shanghai",
    "Keyboard": "us",
    "CheckFirmware": false,
    "AutoPosition": true,
    "Autopart": true,
    "Software": [
      {
        "FileName": "iBMA"
      }
    ],
    "Partition": [],
    "NetCfg": [],
    "Packages": []
  }


.OUTPUTS
PSObject
Returns current Smart Provisioning OS deploy configuration if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $ConfigFileURI = 'C:\ibmc-os-deploy-config-centos.json'
PS C:\> $DeployConfig = Set-ibmcOSDeployConfig -Session $session -ConfigFileURI
PS C:\> $DeployConfig

Host          : 192.168.1.1
Id            : 1
Name          : SP OS Install Parameter
InstallMode   : Recommended
OSType        : CentOS7U3
BootType      : UEFIBoot
RootPwd       : This1sNotSecure
HostName      : SP-OS-deploy
Autopart      : True
AutoPosition  : True
Language      : en_US.UTF-8
TimeZone      : Asia/Shanghai
Keyboard      : us
CheckFirmware : False
Partition     : {}
Software      : {@{FileName=iBMA}}
NetCfg        : {}
Packages      : {@{PackageName=System.Object[]; PatternName=System.Object[]}}


this example shows how to update the OS deploy config

.EXAMPLE

# update iBMC OS deploy configuration
PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $ConfigFileURI = 'C:\ibmc-os-deploy-config-centos.json'
PS C:\> Set-iBMCOSDeployConfig -Session $session -ConfigFileURI

# connect virtual media to a CentOS 7.3 image
PS C:\> Disconnect-iBMCVirtualMedia $session
PS C:\> $OSImageFileURI = 'nfs://192.168.10.3/CentOS-7-x86_64-Minimal-1611.iso'
PS C:\> Connect-iBMCVirtualMedia $session -ImageFilePath $OSImageFileURI

# Enable Smart Provisioning service
PS C:\> Set-iBMCSPService -Session $session -StartEnabled $true -SysRestartDelaySeconds 60

# Restart OS
PS C:\> Set-iBMCServerPower -Session $session -ResetType ForceRestart


This example shows the workflow of the OS deployment

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCOSDeployConfig
Set-iBMCOSDeployConfig
Set-iBMCSPService
Connect-iBMCVirtualMedia
Disconnect-iBMCVirtualMedia
Connect-iBMC
Disconnect-iBMC
#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session,

    [String[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
    $ConfigFileURI
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'

    $ConfigFileURIList = Get-MatchedSizeArray $Session $ConfigFileURI 'Session' 'ConfigFileURI'

    $Logger.info("Invoke Set SP OS deploy config function")

    $ScriptBlock = {
      param($RedfishSession, $ConfigFileURI)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Set SP OS deploy config now"))

      $PATH = "/Managers/$($RedfishSession.Id)/SPService/SPOSInstallPara"
      $Content = Get-Content -Path $ConfigFileURI -Raw
      $Payload = ConvertFrom-Json $Content

      if ($Null -ne $Payload.RootPwd) {
        $Payload.RootPwd = "******"
      }
      if ($Null -ne $Payload.CDKey) {
        $Payload.CDKey = "******"
      }

      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Payload | ConvertTo-Json -Depth 5)"))
      $Response = Invoke-RedfishRequest $RedfishSession $Path 'POST' $Content | ConvertFrom-WebResponse
      $DeployConfig = Clear-OdataProperties $Response
      return $(Update-SessionAddress $RedfishSession $DeployConfig)
    }

    try {
      for ($idx = 0; $idx -lt $ConfigFileURIList.Count; $idx++) {
        $FileURI = $ConfigFileURIList[$idx]
        # assert file exists and is in JSON format
        $Exists = Test-Path -path $FileURI -PathType Leaf
        if ($Exists) {
          $FileContent = Get-Content -Path $FileURI -Raw
          try {
            ConvertFrom-Json $FileContent -ErrorAction Stop | Out-Null
          }
          catch {
            throw [String]::Format($(Get-i18n ERROR_FILE_NOT_JSON_FORMAT), $FileURI)
          }
        }
        else {
          throw [String]::Format($(Get-i18n ERROR_FILE_NOT_EXISTS), $FileURI)
        }
      }

      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Parameters = @($RedfishSession, $ConfigFileURIList[$idx])
        $Logger.info($(Trace-Session $RedfishSession "Submit Set SP OS deploy config task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $Parameters))
      }

      $Results = Get-AsyncTaskResults $tasks
      return , $Results
    }
    finally {
      Close-Pool $pool
    }
  }

  end {
  }
}
