# Copyright (C) 2020 Huawei Technologies Co., Ltd. All rights reserved.	
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the MIT License		

# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# MIT License for more detail

<# NOTE: iBMC NTP module Cmdlets #>

try { [NtpAddressOrigin] | Out-Null } catch {
Add-Type -TypeDefinition @'
    public enum NtpAddressOrigin {
      IPv4,
      IPv6,
      Static
    }
'@
}

try { [NtpKeyValueType] | Out-Null } catch {
Add-Type -TypeDefinition @'
    public enum NtpKeyValueType {
      Text,
      URI
    }
'@
}

function Get-iBMCNTPSetting {
<#
.SYNOPSIS
Get iBMC NTP Settings.

.DESCRIPTION
Get iBMC NTP Settings.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[]
Returns PSObject indicates iBMC NTP Settings if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Get-iBMCNTPSetting -Session $session

Host                        : 10.1.1.2
ServiceEnabled              : True
PreferredNtpServer          : pre.huawei.com
AlternateNtpServer          : alt.huawei.com
NtpAddressOrigin            : Static
MinPollingInterval          : 10
MaxPollingInterval          : 12
ServerAuthenticationEnabled : False

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Set-iBMCNTPSetting
Import-iBMCNTPKey
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

    $Logger.info("Invoke Get iBMC NTP Settings function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get iBMC NTP Settings now"))
      $Path = "/Managers/$($RedfishSession.Id)/NtpService"
      $Response = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse

      $Properties = @(
        "ServiceEnabled", "PreferredNtpServer", "AlternateNtpServer", "NtpAddressOrigin",
        "MinPollingInterval", "MaxPollingInterval", "ServerAuthenticationEnabled"
      )
      $Settings = Copy-ObjectProperties $Response $Properties
      return $(Update-SessionAddress $RedfishSession $Settings)
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get iBMC NTP Settings task"))
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

function Set-iBMCNTPSetting {
<#
.SYNOPSIS
Modify iBMC NTP Settings.

.DESCRIPTION
Modify iBMC NTP Settings.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER ServiceEnabled
Indicates whether NTP is enabled.
Support values are powershell boolean value: $true(1), $false(0).

.PARAMETER PreferredNtpServer
Indicates the address of the preferred NTP server.
A character string that meets the following requirements:
- IPv4, IPv6 address or domain name
- Contains 1 to 67 characters

.PARAMETER AlternateNtpServer
Indicates the address of the alternate NTP server.
A character string that meets the following requirements:
- IPv4, IPv6 address or domain name
- Contains 1 to 67 characters

.PARAMETER NtpAddressOrigin
Indicates the NTP Address mode.
Available Value Set: IPV4, IPV6, Static

.PARAMETER MinPollingInterval
Minimum NTP polling interval.
It can be a value from 3 to 17. The value cannot be greater than MaxPollingInterval.

.PARAMETER MaxPollingInterval
Maximum NTP polling interval.
It can be a value from 3 to 17. The value cannot be less than MinPollingInterval.

.PARAMETER ServerAuthenticationEnabled
Indicates Whether server authentication is enabled.
Support values are powershell boolean value: $true(1), $false(0).

.OUTPUTS
Null
Returns Null if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Set-iBMCNTPSetting $session -ServiceEnabled $true
          -PreferredNtpServer 'pre.huawei.com' -AlternateNtpServer 'alt.huawei.com' `
          -NtpAddressOrigin Static -ServerAuthenticationEnabled $false `
          -MinPollingInterval 10 -MaxPollingInterval 12

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCNTPSetting
Import-iBMCNTPKey
Connect-iBMC
Disconnect-iBMC

#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session,

    [Boolean[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $ServiceEnabled,

    [String[]]
    [ValidateLength(0, 67)]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $PreferredNtpServer,

    [String[]]
    [ValidateLength(0, 67)]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $AlternateNtpServer,

    [NtpAddressOrigin[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $NtpAddressOrigin,

    [int32[]]
    [ValidateRange(3, 17)]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $MinPollingInterval,

    [int32[]]
    [ValidateRange(3, 17)]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $MaxPollingInterval,

    [Boolean[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $ServerAuthenticationEnabled
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    $ServiceEnabledList = Get-OptionalMatchedSizeArray $Session $ServiceEnabled
    $PreferredNtpServerList = Get-OptionalMatchedSizeArray $Session $PreferredNtpServer
    $AlternateNtpServerList = Get-OptionalMatchedSizeArray $Session $AlternateNtpServer
    $NtpAddressOriginList = Get-OptionalMatchedSizeArray $Session $NtpAddressOrigin
    $MinPollingIntervalList = Get-OptionalMatchedSizeArray $Session $MinPollingInterval
    $MaxPollingIntervalList = Get-OptionalMatchedSizeArray $Session $MaxPollingInterval
    $ServerAuthenticationEnabledList = Get-OptionalMatchedSizeArray $Session $ServerAuthenticationEnabled

    $Logger.info("Invoke Set iBMC NTP Settings function")

    $ScriptBlock = {
      param($RedfishSession, $Payload)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Set iBMC NTP Settings now"))
      $Path = "/Managers/$($RedfishSession.Id)/NtpService"
      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Payload | ConvertTo-Json)"))
      $Response = Invoke-RedfishRequest $RedfishSession $Path 'Patch' $Payload
      Resolve-RedfishPartialSuccessResponse $RedfishSession $Response | Out-Null
      return $null
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Payload = @{
          ServiceEnabled=$ServiceEnabledList[$idx];
          PreferredNtpServer=$PreferredNtpServerList[$idx];
          AlternateNtpServer=$AlternateNtpServerList[$idx];
          NtpAddressOrigin=$NtpAddressOriginList[$idx];
          MinPollingInterval=$MinPollingIntervalList[$idx];
          MaxPollingInterval=$MaxPollingIntervalList[$idx];
          ServerAuthenticationEnabled=$ServerAuthenticationEnabledList[$idx];
        } | Remove-EmptyValues | Resolve-EnumValues

        if ($null -ne $Payload.MinPollingInterval -and $null -ne $Payload.MaxPollingInterval) {
          if ($Payload.MinPollingInterval -gt $Payload.MaxPollingInterval) {
            throw $(Get-i18n ERROR_NTP_MIN_GT_MAX)
          }
        }

        if ($Payload.Count -eq 0) {
          throw $(Get-i18n ERROR_NO_UPDATE_PAYLOAD)
        }

        $Parameters = @($RedfishSession, $Payload)
        $Logger.info($(Trace-Session $RedfishSession "Submit Set iBMC NTP Settings task"))
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

function Import-iBMCNTPGroupKey {
<#
.SYNOPSIS
Import the iBMC NTP group key

.DESCRIPTION
Import the iBMC NTP group key

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER KeyFileUri
Indicates the path of NTP group key certificate file

It supports HTTPS, SFTP, NFS, SCP, and CIFS and FILE file transfer protocols.

For examples:
- local path: C:\ntp.keys or \\192.168.1.2\ntp.keys
- ibmc local temporary path: /tmp/ntp.keys
- remote path: protocol://username:password@hostname/directory/ntp.keys


.OUTPUTS
PSObject[]
Returns the import group key task details if cmdlet executes successfully.
In case of an error or warning, exception will be returned.


.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Import-iBMCNTPGroupKey -Session $session -KeyFileUri "E:\ntp.keys"

Host         : 10.1.1.2
Id           : 1
Name         : ntp certificate import
ActivityName : [10.1.1.2] ntp certificate import
TaskState    : Completed
StartTime    : 2018-12-21T05:51:46+00:00
EndTime      : 2018-12-21T05:51:49+00:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to import NTP group key from local file


.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Import-iBMCNTPGroupKey -Session $session -KeyFileUri "/tmp/ntp.keys"

Host         : 10.1.1.2
Id           : 1
Name         : ntp certificate import
ActivityName : [10.1.1.2] ntp certificate import
TaskState    : Completed
StartTime    : 2018-12-21T05:51:46+00:00
EndTime      : 2018-12-21T05:51:49+00:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to import NTP group key from ibmc temp file

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Import-iBMCNTPGroupKey -Session $session -KeyFileUri "nfs://10.10.10.2/data/nfs/ntp.keys"

Host         : 10.1.1.2
Id           : 1
Name         : ntp certificate import
ActivityName : [10.1.1.2] ntp certificate import
TaskState    : Completed
StartTime    : 2018-12-21T05:51:46+00:00
EndTime      : 2018-12-21T05:51:49+00:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to import NTP group key from NFS network file


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCNTPSetting
Set-iBMCNTPSetting
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
    $KeyFileUri
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $KeyFileUri 'KeyFileUri'
    $KeyFileUriList = Get-MatchedSizeArray $Session $KeyFileUri 'Session' 'KeyFileUri'

    $Logger.info("Invoke Import iBMC NTP Group Key function")

    $ScriptBlock = {
      param($RedfishSession, $KeyFileUri)

      $Logger.info($(Trace-Session $RedfishSession "Invoke Import iBMC NTP Group Key now"))

      $StartTime = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
      $KeyFilePath = Invoke-FileUploadIfNeccessary $RedfishSession $KeyFileUri $BMC.NTPKeyFileSupportSchema
      # try submit import ntp key task
      $Path = "/Managers/$($RedfishSession.Id)/NtpService/Actions/NtpService.ImportNtpKey"
      $Payload = @{
        Type= "URI";
        Content=$KeyFilePath;
      }

      $Clone = $Payload.clone()
      $Clone.Content = Protect-NetworkUriUserInfo $KeyFilePath
      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Clone | ConvertTo-Json)"))

      # if a remote URI is provided, will return:
      #
      # {
      #   "error": {
      #     "code": "Base.1.0.GeneralError",
      #     "message": "A general error has occurred. See ExtendedInfo for more information.",
      #     "@Message.ExtendedInfo": [
      #       {
      #         "@odata.context": "/redfish/v1/$metadata#TaskService/Tasks/Members/$entity",
      #         "@odata.type": "#Task.v1_0_2.Task",
      #         "@odata.id": "/redfish/v1/TaskService/Tasks/1",
      #         "Id": "1",
      #         "Name": "ntp certificate import ",
      #         "TaskState": "Running",
      #         "StartTime": "2018-12-21T04:10:32+00:00",
      #         "Messages": [],
      #         "Oem": {
      #           "Huawei": {
      #             "TaskPercentage": null
      #           }
      #         }
      #       }
      #     ]
      #   }
      # }

      # if ibmc temp file uri is provided, will return:
      # {
      #   "error": {
      #     "code": "Base.1.0.GeneralError",
      #     "message": "A general error has occurred. See ExtendedInfo for more information.",
      #     "@Message.ExtendedInfo": [
      #       {
      #         "@odata.type": "/redfish/v1/$metadata#MessageRegistry.1.0.0.MessageRegistry",
      #         "MessageId": "iBMC.1.0.UploadNTPSecureGroupKeysuccessfully",
      #         "RelatedProperties": [],
      #         "Message": "The NTP group key is uploaded successfully.",
      #         "MessageArgs": [],
      #         "Severity": "OK",
      #         "Resolution": "None"
      #       }
      #     ]
      #   }
      # }

      # {
      #   "error": {
      #     "code": "Base.1.0.GeneralError",
      #     "message": "A general error has occurred. See ExtendedInfo for more information.",
      #     "@Message.ExtendedInfo": [
      #       {
      #         "@odata.type": "/redfish/v1/$metadata#MessageRegistry.1.0.0.MessageRegistry",
      #         "MessageId": "iBMC.1.0.UploadNTPSecureGroupKeyFailed",
      #         "RelatedProperties": [],
      #         "Message": "Failed to upload the NTP group key.",
      #         "MessageArgs": [],
      #         "Severity": "Warning",
      #         "Resolution": "Make sure that the content or URI of the NTP group key specified in the request body is valid."
      #       }
      #     ]
      #   }
      # }

      # {
      #   "@odata.context": "/redfish/v1/$metadata#TaskService/Tasks/Members/$entity",
      #   "@odata.type": "#Task.v1_0_2.Task",
      #   "@odata.id": "/redfish/v1/TaskService/Tasks/3",
      #   "Id": "3",
      #   "Name": "ntp certificate import ",
      #   "TaskState": "Exception",
      #   "StartTime": "2018-12-22T01:28:15+08:00",
      #   "EndTime": "2018-12-22T01:28:16+08:00",
      #   "TaskStatus": "Warning",
      #   "Messages": {
      #     "@odata.type": "/redfish/v1/$metadata#MessageRegistry.1.0.0.MessageRegistry",
      #     "MessageId": "iBMC.1.0.UploadNTPSecureGroupKeyFailed",
      #     "RelatedProperties": [],
      #     "Message": "Failed to upload the NTP group key.",
      #     "MessageArgs": [],
      #     "Severity": "Warning",
      #     "Resolution": "Make sure that the content or URI of the NTP group key specified in the request body is valid."
      #   },
      #   "Oem": {
      #     "Huawei": {
      #       "TaskPercentage": null
      #     }
      #   }
      # }

      $Response = Invoke-RedfishRequest $RedfishSession $Path 'POST' $Payload -ContinueEvenFailed | ConvertFrom-WebResponse
      $ExtendInfo = $Response.error.'@Message.ExtendedInfo'[0]
      if ($ExtendInfo.'@odata.id' -like '/redfish/v1/TaskService/Tasks/*') {
        return $ExtendInfo
      } else {
        $FakeTask = @{
          "Id"= "0";
          "Name"= "ntp certificate import ";
          "TaskState"= "Completed";
          "StartTime"= $StartTime;
          "EndTime"= $(Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz');
          "TaskStatus"= "OK";
          "Oem"= @{
            "Huawei"= @{
              "TaskPercentage"= "100%";
            }
          }
        }
        if ($ExtendInfo.Severity -ne $BMC.Severity.OK.ToString()) {
          $FakeTask.TaskState = $BMC.TaskState.Exception
          $FakeTask.TaskStatus = $ExtendInfo.Severity
          $FakeTask.Oem.Huawei.TaskPercentage = $null
          $FakeTask.Messages = $ExtendInfo
        }
        return $FakeTask
      }
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Parameters = @($RedfishSession, $KeyFileUriList[$idx])
        $Logger.info($(Trace-Session $RedfishSession "Submit Import iBMC NTP Group Key task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $Parameters))
      }

      $RedfishTasks = Get-AsyncTaskResults $tasks
      $Logger.Info("Import NTP group key tasks: " + $RedfishTasks)
      return Wait-RedfishTasks $pool $Session $RedfishTasks -ShowProgress
    }
    finally {
      Close-Pool $pool
    }
  }

  end {
  }
}
