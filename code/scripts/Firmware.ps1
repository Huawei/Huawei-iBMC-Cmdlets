# Copyright (C) 2020-2021 Huawei Technologies Co., Ltd. All rights reserved.
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the MIT License		

# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# MIT License for more detail

<# NOTE: iBMC Firmware module Cmdlets #>

function Get-iBMCInbandFirmware {
<#
.SYNOPSIS
Query information about the updatable inband firmware resource collection of a server.

.DESCRIPTION
Query information about the updatable firmware resources of a server.
Include SPService and all inband firmwares.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[]
Returns PSObject which contains all updatable firmware infomation if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $Firmwares = Get-iBMCInbandFirmware $session
PS C:\> $Firmwares | fl

Host                               : 192.168.1.1
SR430C-M 1G (SAS3108)@[RAID Card1] : 4.270.00-4382
LOM (X722)@[LOM]                   : 3.33 0x80000f09 255.65535.255
SPService                          : @{APPVersion=1.09; OSVersion=1.09; DataVersion=1.09}

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCOutbandFirmware
Update-iBMCInbandFirmware
Update-iBMCOutbandFirmware
Invoke-iBMCFileUpload
Get-iBMCSPTaskResult
Set-iBMCSPService
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

    $Logger.info("Invoke Get BMC updatable inband firmware function")

    $ScriptBlock = {
      param($RedfishSession)
      $Logger.info($(Trace-Session $RedfishSession "Invoke Get BMC updatable inband firmware now"))

      $Output = New-Object PSObject

      # in-band
      try {
        $Logger.info($(Trace-Session $RedfishSession "Invoke Get BMC updatable inband firmware now"))
        $Path = "/Managers/$($RedfishSession.Id)/SPService/DeviceInfo"
        $DeviceInfo = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
        for ($idx = 0; $idx -lt $BMC.InBandFirmwares.Count; $idx++) {
          $DeviceName = $BMC.InBandFirmwares[$idx];
          $Devices = $DeviceInfo."$DeviceName";
          if ($null -ne $Devices -and $Devices -is [Array] -and $Devices.Count -gt 0) {
            $Devices | ForEach-Object {
              $Name = $_.DeviceName
              $Model = $_.Controllers[0].Model
              $Position = $_.Position
              $Version = $_.Controllers[0].FirmwareVersion
              $Key = "$($Name) ($($Model))@[$($Position)]"
              $Output |  Add-Member -MemberType NoteProperty $Key $Version
            }
          }
        }
      }
      catch {
        $Logger.warn($(Trace-Session $RedfishSession "Failed to load inband firmwares, reason: $_"))
      }

      # SP
      try {
        $Logger.info($(Trace-Session $RedfishSession "Invoke Get SPService version now"))
        $Path = "/Managers/$($RedfishSession.Id)/SPService"
        $SPService = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
        $Output |  Add-Member -MemberType NoteProperty "SPService" $SPService.Version
      }
      catch {
        $Logger.warn($(Trace-Session $RedfishSession "Failed to get SPService, reason: $_"))
        throw $(Get-i18n FAIL_SP_NOT_SUPPORT)
      }
      return $(Update-SessionAddress $RedfishSession $Output)
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get BMC updatable inband firmware task"))
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

function Get-iBMCOutbandFirmware {
<#
.SYNOPSIS
Query information about the updatable outband firmware resource collection of a server.

.DESCRIPTION
Query information about the updatable firmware resources of a server.
Only those out-band firmwares is included:
- ActiveBMC
- BackupBMC
- Bios
- all CPLD, example: MainBoardCPLD, chassisDiskBP1CPLD

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[]
Returns PSObject which contains all updatable firmware infomation if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $Firmwares = Get-iBMCOutbandFirmware $session
PS C:\> $Firmwares | fl

Host                               : 192.168.1.1
ActiveBMC                          : 3.18
BackupBMC                          : 3.18
Bios                               : 0.81
MainBoardCPLD                      : 2.02
chassisDiskBP1CPLD                 : 1.10

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCInbandFirmware
Update-iBMCInbandFirmware
Update-iBMCOutbandFirmware
Invoke-iBMCFileUpload
Get-iBMCSPTaskResult
Set-iBMCSPService
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

    $Logger.info("Invoke Get BMC updatable outband firmware function")

    $ScriptBlock = {
      param($RedfishSession)
      $Logger.info($(Trace-Session $RedfishSession "Invoke Get BMC updatable outband firmware now"))

      $Output = New-Object PSObject

      # out-band
      $Logger.info($(Trace-Session $RedfishSession "Invoke Get BMC updatable outband firmware now"))
      $Path = "/UpdateService/FirmwareInventory"
      $GetMembersResponse = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
      $Members = $GetMembersResponse.Members
      for ($idx = 0; $idx -lt $Members.Count; $idx++) {
        $Member = $Members[$idx]
        $OdataId = $Member.'@odata.id'
        $InventoryName = $OdataId.Split("/")[-1]
        if ($InventoryName -in $BMC.OutBandFirmwares -or $InventoryName -like '*CPLD') {
          $Inventory = Invoke-RedfishRequest $RedfishSession $OdataId | ConvertFrom-WebResponse
          $Output |  Add-Member -MemberType NoteProperty $Inventory.Name $Inventory.Version
        }
      }

      return $(Update-SessionAddress $RedfishSession $Output)
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get BMC updatable outband firmware task"))
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

function Update-iBMCInbandFirmware {
<#
.SYNOPSIS
Updata iBMC Inband firmware.

.DESCRIPTION
Updata iBMC Inband firmware. This function transfers firmware to SP service.
Those transfered firmwares takes effect upon next system restart when SP Service start is enabled (Set-iBMCSPService function is provided for this).
Tips: Only V5 servers used with BIOS version later than 0.39 support this function.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER Type
Indicates the firmware type to be updated.
Support value set: "Firmware", "SP".
- Firmware: NIC, Raid
- SP: Smart Provisioning Service

.PARAMETER FileUri
Indicates the file uri of firmware update image file.

- When "Type" is Firmware:
The firmware upgrade file is in .zip format.
It supports HTTPS, SFTP, NFS, CIFS, SCP file transfer protocols.
The URI cannot contain the following special characters: ||, ;, &&, $, |, >>, >, <

For examples:
- remote path: protocol://username:password@hostname/directory/Firmware.zip

- When "Type" is SP:
The firmware upgrade file is in .ISO format. support only the CIFS and NFS protocols.
The URI cannot contain the following special characters: ||, ;, &&, $, |, >>, >, <

For examples:
- remote path: nfs://username:password@hostname/directory/Firmware.ISO

.PARAMETER SignalFileUri
Indicates the file path of the certificate file of the upgrade file.
It is mandatory when upgrade Firmware while it is redundant when upgrade SP.
- Signal file should be in .asc format
- it supports HTTPS, SFTP, NFS, CIFS, SCP file transfer protocols.
- The URI cannot contain the following special characters: ||, ;, &&, $, |, >>, >, <

For examples:
- remote path: protocol://username:password@hostname/directory/Firmware.zip.asc

.OUTPUTS
Return task information

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> Update-iBMCInbandFirmware -Session $session -Type Firmware `
          -FileUri "nfs://192.168.10.2/data/nfs/NIC(X722)-Electrical-05022FTM-FW(3.33).zip" `
          -SignalFileUri "nfs://192.168.10.2/data/nfs/NIC(X722)-Electrical-05022FTM-FW(3.33).zip.asc" `
          -UpgradeMode Recover

Host                    : 192.168.1.1
Name                    : SP Framework Update
ActivityName            : [192.168.1.1] SP Framework Update
TransferState           : Success
TransferFileName        : NIC(X722)-Electrical-05022FTM-FW(3.33).zip
TransferProgressPercent : 100
FileList                : {}
Messages                : {@{@odata.type=/redfish/v1/$metadata#MessageRegistry.1.0.0.MessageRegistry; MessageId=iBMC.1.
                          0.SPTransferSuccess; RelatedProperties=System.Object[]; Message=File downloaded successfully.
                           Start SP for the file to take effect.; MessageArgs=System.Object[]; Severity=OK; Resolution=
                          Start SP for the file to take effect.}}


PS C:\> Set-iBMCSPService -Session $session -StartEnabled $true -SysRestartDelaySeconds 60
PS C:\> Set-iBMCServerPower -Session $session -ResetType ForceRestart

This example shows how to update inband firmware with remote file, enabled SP service and restart server


.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> Update-iBMCInbandFirmware -Session $session -Type SP `
          -FileUri "nfs://192.168.10.2/data/nfs/Firmware.ISO" `
          -UpgradeMode Recover

Host                    : 192.168.1.1
Name                    : SP Framework Update
ActivityName            : [192.168.1.1] SP Framework Update
TransferState           : Success
TransferFileName        : Firmware.ISO
TransferProgressPercent : 100
FileList                : {}
Messages                : {@{@odata.type=/redfish/v1/$metadata#MessageRegistry.1.0.0.MessageRegistry; MessageId=iBMC.1.
                          0.SPTransferSuccess; RelatedProperties=System.Object[]; Message=File downloaded successfully.
                           Start SP for the file to take effect.; MessageArgs=System.Object[]; Severity=OK; Resolution=
                          Start SP for the file to take effect.}}

This example shows how to update SP with remote file.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> Update-iBMCInbandFirmware -Session $session -Type SP `
          -FileUri "sftp://192.168.1.2/data/Firmware.ISO" `
          -UpgradeMode Recover 
          -SecureEnabled

Host                    : 192.168.1.1
Name                    : SP Framework Update
ActivityName            : [192.168.1.1] SP Framework Update
TransferState           : Success
TransferFileName        : Firmware.ISO
TransferProgressPercent : 100
FileList                : {}
Messages                : {@{@odata.type=/redfish/v1/$metadata#MessageRegistry.1.0.0.MessageRegistry; MessageId=iBMC.1.
                          0.SPTransferSuccess; RelatedProperties=System.Object[]; Message=File downloaded successfully.
                           Start SP for the file to take effect.; MessageArgs=System.Object[]; Severity=OK; Resolution=
                          Start SP for the file to take effect.}}

This example shows how to update SP with remote file with secure parameter

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCInbandFirmware
Get-iBMCOutbandFirmware
Update-iBMCOutbandFirmware
Invoke-iBMCFileUpload
Get-iBMCSPTaskResult
Set-iBMCSPService
Connect-iBMC
Disconnect-iBMC

#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session,

    [String[]]
    [ValidateSet("Firmware", "SP")]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $Type,

    [String[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $FileUri,

    [String[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $SignalFileUri,

    [UpgradeMode[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $UpgradeMode = [UpgradeMode]::Recover,

    [switch]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $SecureEnabled
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $Type 'Type'
    Assert-ArrayNotNull $FileUri 'FileUri'
    Assert-ArrayNotNull $UpgradeMode 'UpgradeMode'

    $FirmwareTypeList = Get-MatchedSizeArray $Session $Type 'Session' 'Type'
    $FileUriList = Get-MatchedSizeArray $Session $FileUri 'Session' 'FileUri'
    $UpgradeModeList = Get-MatchedSizeArray $Session $UpgradeMode 'Session' 'UpgradeMode'
    $SignalFileUriList = Get-OptionalMatchedSizeArray $Session $SignalFileUri
    
    if ($SecureEnabled) {
      $SensitiveInfo = @(Get-SensitiveInfo)
      $SensitiveInfoList = Get-OptionalMatchedSizeArray $Session $SensitiveInfo
    }

    $Logger.info("Invoke upgrade BMC inband firmware function")

    $ScriptBlock = {
      param($RedfishSession, $InbandFirmwareType, $ImageFilePath, $SignalFilePath, $UpgradeMode)

      $Logger.info($(Trace-Session $RedfishSession "Invoke upgrade $InbandFirmwareType now"))

      # transfer firmware image file
      $GetSPUpdateService = "/Managers/$($RedfishSession.Id)/SPService/SPFWUpdate"
      $SPServices = Invoke-RedfishRequest $RedfishSession $GetSPUpdateService | ConvertFrom-WebResponse
      if ($SPServices.Members.Count -le 0) {
        throw $(Get-i18n "FAIL_SP_NOT_SUPPORT")
      }
      $Payload = @{
        "Parameter" = "all";
        "UpgradeMode" = $UpgradeMode;
        "ActiveMethod" = "RestarOS";
      } | Resolve-EnumValues

      if ($InbandFirmwareType -eq "Firmware") {
        $ImageURI = Invoke-FileUploadIfNeccessary $RedfishSession $ImageFilePath $BMC.InBandImageFileSupportSchema
        $SignalURI = Invoke-FileUploadIfNeccessary $RedfishSession $SignalFilePath $BMC.SignalFileSupportSchema
        $Payload.ImageURI = $ImageURI
        $Payload.SignalURI = $SignalURI
        $Payload.ImageType = "Firmware"
      } else {
        $ImageURI = Invoke-FileUploadIfNeccessary $RedfishSession $ImageFilePath $BMC.SPImageFileSupportSchema
        if ($null -ne $SignalURI) {
          $Payload.SignalURI = Invoke-FileUploadIfNeccessary $RedfishSession $SignalFilePath $BMC.SignalFileSupportSchema
        } else {
          $Payload.SignalURI = ""
        }
        $Payload.ImageURI = $ImageURI
        $Payload.ImageType = "SP"
      }

      if ($Payload.ImageURI.StartsWith('/tmp', "CurrentCultureIgnoreCase")) {
        $Payload.ImageURI = "file://$($Payload.ImageURI)"
      }
      if ($Payload.SignalURI.StartsWith('/tmp', "CurrentCultureIgnoreCase")) {
        $Payload.SignalURI = "file://$($Payload.SignalURI)"
      }
      $LogPayload = $Payload.Clone()
      $LogPayload.ImageURI = Protect-NetworkUriUserInfo $LogPayload.ImageURI
      $LogPayload.SignalURI = Protect-NetworkUriUserInfo $LogPayload.SignalURI
      $Logger.Info($(Trace-Session $RedfishSession "Sending payload: $($LogPayload | ConvertTo-Json)"))
      $SPServiceOdataId = $SPServices.Members[0].'@odata.id'
      $SPFWUpdateUri = "$SPServiceOdataId/Actions/SPFWUpdate.SimpleUpdate"
      Invoke-RedfishRequest $RedfishSession $SPFWUpdateUri 'POST' $Payload | Out-Null

      # this sleep is needed, two api request has to be apart
      Start-Sleep -Seconds 3
      $Transfer = Invoke-RedfishRequest $RedfishSession $SPServiceOdataId | ConvertFrom-WebResponse
      # for unknonw reason the spservice odata id get the previous transfer file name
      # here is the work around way to modify it
      $FileName = $ImageURI.split("/")[-1]
      $Transfer.TransferFileName = $FileName
      return $Transfer
    }

    try {
      $ScriptBlockParameters = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $FirmwareType = $FirmwareTypeList[$idx];
        $ImageFilePath = $FileUriList[$idx]
        $SignalFilePath = $SignalFileUriList[$idx]
        $UpgradeMode_ = $UpgradeModeList[$idx]
        if ($SecureEnabled) {
          $SensitiveInfo = $SensitiveInfoList[$idx]
          $ImageFilePath = Get-CompleteUri $SensitiveInfo $ImageFilePath
        }
        if ($FirmwareType -eq "Firmware" -and $null -eq $SignalFilePath) {
          throw $(Get-i18n "FAIL_SIGNAL_URI_REQUIRED")
        }
        if ($FirmwareType -eq "Firmware" -and $SecureEnabled) {
          $SignalFileInfo = $SensitiveInfoList[$idx]
          $SignalFilePath = Get-CompleteUri $SignalFileInfo $SignalFilePath
        }
        $Parameters = @($RedfishSession, $FirmwareType, $ImageFilePath, $SignalFilePath, $UpgradeMode_)
        [Void] $ScriptBlockParameters.Add($Parameters)
      }

      $tasks = New-Object System.Collections.ArrayList
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $Logger.info($(Trace-Session $RedfishSession "Submit upgrade BMC inband firmware task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $ScriptBlockParameters[$idx]))
      }
      $TransferResults = Get-AsyncTaskResults $tasks
      return $(Wait-SPFileTransfer $pool $Session $TransferResults -ShowProgress)
    }
    finally {
      Close-Pool $pool
    }
  }

  end {
  }
}


function Set-iBMCSPService {
<#
.SYNOPSIS
Modify properties of the SP service resource.

.DESCRIPTION
Modify properties of the SP(Smart Provisioning) service resource.
Tips: only V5 servers used with BIOS version later than 0.39 support this function.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER StartEnabled
Indicates Whether SP start is enabled.
Support values are powershell boolean value: $true(1), $false(0).

.PARAMETER SysRestartDelaySeconds
Indicates Maximum time allowed for the restart of the OS.
A positive integer value is accept.

.OUTPUTS
Null
Returns Null if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> Set-iBMCSPService -Session $session -StartEnabled $true -SysRestartDelaySeconds 60


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCInbandFirmware
Get-iBMCOutbandFirmware
Update-iBMCInbandFirmware
Update-iBMCOutbandFirmware
Invoke-iBMCFileUpload
Get-iBMCSPTaskResult
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
    $StartEnabled,

    [int[]]
    [ValidateRange(1, [int]::MaxValue)]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 2)]
    $SysRestartDelaySeconds
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'

    $StartEnabledList = Get-OptionalMatchedSizeArray $Session $StartEnabled
    $SysRestartDelaySecondsList = Get-OptionalMatchedSizeArray $Session $SysRestartDelaySeconds

    $Logger.info("Invoke set SP Service function")

    $ScriptBlock = {
      param($RedfishSession, $Enabled, $SysRestartDelaySeconds)

      $Logger.info($(Trace-Session $RedfishSession "Invoke set SP Service function now"))
      # Enable SP Service
      $SPServicePath = "/Managers/$($RedfishSession.Id)/SPService"
      $EnableSpServicePayload = @{
        "SPStartEnabled"= $Enabled;
        "SysRestartDelaySeconds"= $SysRestartDelaySeconds;
        "SPTimeout"= 7200;
        "SPFinished"= $false;
      } | Remove-EmptyValues

      $Logger.Info($(Trace-Session $RedfishSession "Sending payload: $($EnableSpServicePayload | ConvertTo-Json)"))
      Invoke-RedfishRequest $RedfishSession $SPServicePath 'PATCH' $EnableSpServicePayload | Out-Null
      return $null
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $ParametersList = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Parameters = @($RedfishSession, $StartEnabledList[$idx], $SysRestartDelaySecondsList[$idx])
        if ($null -eq $StartEnabledList[$idx] -and $null -eq $SysRestartDelaySecondsList[$idx]) {
          throw $(Get-i18n FAIL_NO_UPDATE_PARAMETER)
        }
        [Void] $ParametersList.Add($Parameters)
      }

      for ($idx = 0; $idx -lt $ParametersList.Count; $idx++) {
        $Logger.info($(Trace-Session $RedfishSession "Submit set SP Service task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $ParametersList[$idx]))
      }

      return Get-AsyncTaskResults $tasks
    }
    finally {
      Close-Pool $pool
    }
  }

  end {
  }
}


function Get-iBMCSPTaskResult {
<#
.SYNOPSIS
Query information about the configuration result resource of the SP service.

.DESCRIPTION
Query information about the configuration result resource of the SP service.
Tips: only V5 servers used with BIOS version later than 0.39 support this function.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[]
Returns PSObject indicates configuration result resource of SP Service if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $Result = Get-iBMCSPTaskResult -Session $session
PS C:\> $Result

Host      : 192.168.1.1
Id        : 1
Name      : SP Result
Status    : Idle
OSInstall :
Clone     :
Recover   :


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCInbandFirmware
Get-iBMCOutbandFirmware
Update-iBMCInbandFirmware
Update-iBMCOutbandFirmware
Invoke-iBMCFileUpload
Set-iBMCSPService
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

    $Logger.info("Invoke Get SP Result function")

    $ScriptBlock = {
      param($RedfishSession)

      $Logger.info($(Trace-Session $RedfishSession "Invoke Get SP Result function now"))
      $SPResultMemberPath = "/Managers/$($RedfishSession.Id)/SPService/SPResult"
      $Collection = Invoke-RedfishRequest $RedfishSession $SPResultMemberPath | ConvertFrom-WebResponse
      $Members = $Collection.Members
      if ($Members.Count -ge 1) {
        $GetSPResultPath = $Members[0].'@odata.id'
        $Result = Invoke-RedfishRequest $RedfishSession $GetSPResultPath | ConvertFrom-WebResponse
        $CleanUp = $Result | Clear-OdataProperties
        return $(Update-SessionAddress $RedfishSession $CleanUp)
      } else {
        return $null
      }
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get SP Result task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock @($RedfishSession)))
      }
      return Get-AsyncTaskResults $tasks
    }
    finally {
      Close-Pool $pool
    }
  }

  end {
  }
}



function Update-iBMCOutbandFirmware {
<#
.SYNOPSIS
Updata iBMC Outband firmware.

.DESCRIPTION
Updata iBMC Outband firmware.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER FileUri
Indicates the file uri of firmware update image file.

File Uri should be a string of up to 256 characters.
It supports HTTPS, SCP, SFTP, CIFS, TFTP, NFS and FILE file transfer protocols.

For examples:
- local path: C:\2288H_V5_5288_V5-iBMC-V318.hpm or \\192.168.1.2\2288H_V5_5288_V5-iBMC-V318.hpm
- ibmc local temporary path: /tmp/2288H_V5_5288_V5-iBMC-V318.hpm
- remote path: protocol://username:password@hostname/directory/2288H_V5_5288_V5-iBMC-V318.hpm

.OUTPUTS
PSObject[]
Returns the update firmware task details if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> Update-iBMCOutbandFirmware -Session $session -FileUri E:\2288H_V5_5288_V5-iBMC-V318.hpm

Host         : 192.168.1.1
Id           : 1
Name         : Upgarde Task
ActivityName : [192.168.1.1] Upgarde Task
TaskState    : Completed
StartTime    : 2018-11-23T08:57:45+08:00
EndTime      : 2018-11-23T09:01:24+08:00
TaskStatus   : OK
TaskPercent  : 100%


This example shows how to update outband firmware with local file


.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> Update-iBMCOutbandFirmware -Session $session -FileUri '/tmp/2288H_V5_5288_V5-iBMC-V318.hpm'

Host         : 192.168.1.1
Id           : 1
Name         : Upgarde Task
ActivityName : [192.168.1.1] Upgarde Task
TaskState    : Completed
StartTime    : 2018-11-23T08:57:45+08:00
EndTime      : 2018-11-23T09:01:24+08:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to update outband firmware with ibmc temp file

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> Update-iBMCOutbandFirmware -Session $session `
          -FileUri nfs://192.168.10.2/data/nfs/2288H_V5_5288_V5-iBMC-V318.hpm

Host         : 192.168.1.1
Id           : 1
Name         : Upgarde Task
ActivityName : [192.168.1.1] Upgarde Task
TaskState    : Completed
StartTime    : 2018-11-23T08:57:45+08:00
EndTime      : 2018-11-23T09:01:24+08:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to update outband firmware with NFS network file

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCInbandFirmware
Get-iBMCOutbandFirmware
Update-iBMCInbandFirmware
Invoke-iBMCFileUpload
Get-iBMCSPTaskResult
Set-iBMCSPService
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
    $FileUri,

    [switch]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $SecureEnabled
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $FileUri 'FileUri'
    $FileUriList = Get-MatchedSizeArray $Session $FileUri 'Session' 'FileUri'

    if ($SecureEnabled) {
      $SensitiveInfo = @(Get-SensitiveInfo)
      $SensitiveInfoList = Get-OptionalMatchedSizeArray $Session $SensitiveInfo
    }

    $Logger.info("Invoke upgrade BMC outband firmware function")

    $ScriptBlock = {
      param($RedfishSession, $ImageFilePath)

      $Logger.info($(Trace-Session $RedfishSession "Invoke upgrade outband firmware now"))
      $ImageFilePath = Invoke-FileUploadIfNeccessary $RedfishSession $ImageFilePath $BMC.OutBandImageFileSupportSchema
      $Payload = @{'ImageURI' = $ImageFilePath;}
      $ImageFileUri = $ImageFilePath
      if (-not $ImageFilePath.StartsWith('/tmp', "CurrentCultureIgnoreCase")) {
        try {
          $ImageFileUri = New-Object System.Uri($ImageFilePath)
          if ($ImageFileUri.Scheme -ne 'file') {
            $Payload."TransferProtocol" = $ImageFileUri.Scheme.ToUpper();
          }
        } catch {
          $Logger.info("can not turn image file path into system uri, going to use substring to get transfer protocol")
          $Schema = $ImageFilePath.Substring(0, $ImageFilePath.IndexOf("://"))
          $Payload."TransferProtocol" = $Schema.ToUpper();
        }
      }

      $Clone = $Payload.clone()
      $Clone.ImageURI = Protect-NetworkUriUserInfo $ImageFilePath
      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Clone | ConvertTo-Json)"))

      # try submit upgrade outband firmware task
      $Path = "/UpdateService/Actions/UpdateService.SimpleUpdate"
      $Response = Invoke-RedfishRequest $RedfishSession $Path 'Post' $Payload
      return $Response | ConvertFrom-WebResponse
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $ImageFilePath = $FileUriList[$idx]
        if ($SecureEnabled) {
          $SensitiveInfo = $SensitiveInfoList[$idx]
          $ImageFilePath = Get-CompleteUri $SensitiveInfo $ImageFilePath
        }
        $Parameters = @($RedfishSession, $ImageFilePath)
        $Logger.info($(Trace-Session $RedfishSession "Submit upgrade BMC outband firmware task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $Parameters))
      }

      $RedfishTasks = Get-AsyncTaskResults $tasks
      $Logger.Info("Upgrade outband firmware tasks: " + $RedfishTasks)
      return Wait-RedfishTasks $pool $Session $RedfishTasks -ShowProgress
    }
    finally {
      Close-Pool $pool
    }
  }

  end {
  }
}
