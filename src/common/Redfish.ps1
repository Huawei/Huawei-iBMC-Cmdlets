<# NOTE: A Redfish Client PowerShell scripts. #>

# . $PSScriptRoot/Common.ps1

try { [RedfishSession] | Out-Null } catch {
Add-Type @'
  public class RedfishSession
  {
    public System.String Id ;
    public System.String Name ;
    public System.String ManagerType ;
    public System.String FirmwareVersion ;
    public System.String UUID ;
    public System.String Model ;
    public System.String Health ;
    public System.String State ;
    public System.String DateTime ;
    public System.String DateTimeLocalOffset ;

    public System.String Address ;
    public System.String BaseUri ;
    public System.String Location ;
    public System.Boolean Alive ;
    public System.String AuthToken ;
    public System.Boolean TrustCert ;
  }
'@
}

function New-RedfishSession {
<#
.SYNOPSIS
Create sessions for iBMC Redfish REST API.

.DESCRIPTION
Creates sessions for iBMC Redfish REST API. The session object returned which has members:
1. 'AuthToken' to identify the session
2. 'BaseUri' of the Redfish API
3. 'Location' which is used for logging out of the session.
4. 'TrustCert' to identify trust all SSL Certification or not
5. 'Alive' to identify whether the session is alive or not

.PARAMETER Address
IP address or Hostname of the target iBMC Redfish API.

.PARAMETER Username
Username of iBMC account to access the iBMC Redfish API.

.PARAMETER Password
Password of iBMC account to access the iBMC Redfish API.

.PARAMETER Credential
PowerShell PSCredential object having username and passwword of iBMC account to access the iBMC.

.PARAMETER TrustCert
If this switch parameter is present then server certificate authentication is disabled for this iBMC connection.
If not present, server certificate is enabled by default.

.NOTES
See typical usage examples in the Redfish.ps1 file installed with this module.

.INPUTS
System.String
You can pipe the Address i.e. the hostname or IP address to New-RedfishSession.

.OUTPUTS
System.Management.Automation.PSCustomObject
New-RedfishSession returns a RedfishSession Object which contains - AuthToken, BaseUri, Location, TrustCert and Alive.

.EXAMPLE
PS C:\> $session = New-RedfishSession -Address 10.1.1.2 -Username root -Password password


PS C:\> $session | fl


RootUri      : https://10.1.1.2/redfish/v1/
X-Auth-Token : this-is-a-sample-token
Location     : https://10.1.1.2/redfish/v1/Sessions/{session-id}/
RootData     : @{@odata.context=/redfish/v1/$metadata#ServiceRoot/; @odata.id=/redfish/v1/; @odata.type=#ServiceRoot.1.0.0.ServiceRoot; AccountService=; Chassis=; EventService=; Id=v1; JsonSchemas=; Links=; Managers=; Name=HP RESTful Root Service; Oem=; RedfishVersion=1.0.0; Registries=; SessionService=; Systems=; UUID=8dea7372-23f9-565f-9396-2cd07febbe29}

.EXAMPLE
PS C:\> $credential = Get-Credential
PS C:\> $session = New-RedfishSession -Address 192.184.217.212 -Credential $credential
PS C:\> $session | fl

RootUri      : https://10.1.1.2/redfish/v1/
X-Auth-Token : this-is-a-sample-token
Location     : https://10.1.1.2/redfish/v1/Sessions/{session-id}/
RootData     : @{@odata.context=/redfish/v1/$metadata#ServiceRoot/; @odata.id=/redfish/v1/; @odata.type=#ServiceRoot.1.0.0.ServiceRoot; AccountService=; Chassis=; EventService=; Id=v1; JsonSchemas=; Links=; Managers=; Name=HP RESTful Root Service; Oem=; RedfishVersion=1.0.0; Registries=; SessionService=; Systems=; UUID=8dea7372-23f9-565f-9396-2cd07febbe29}

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

#>
  [cmdletbinding(DefaultParameterSetName = 'AccountSet')]
  param
  (
    [System.String]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Address,

    [System.String]
    [parameter(ParameterSetName = "AccountSet", Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
    $Username,

    [System.String]
    [parameter(ParameterSetName = "AccountSet", Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 2)]
    $Password,

    [PSCredential]
    [parameter(ParameterSetName = "CredentialSet", Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
    $Credential,

    [switch]
    [parameter(Mandatory = $false)]
    $TrustCert
  )

  # Fetch session with Credential by default if `Credential` is set
  if ($null -ne $Credential) {
    $username = $Credential.UserName
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password)
    $passwd = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  }
  elseif ($Username -ne '' -and $Password -ne '') {
    $username = $username
    $passwd = $password
  }
  else {
    throw $i18n.ERROR_INVALID_CREDENTIALS
  }

  # create a new session object for redfish server of $address
  $session = New-Object RedfishSession
  $session.Address = $Address
  $session.TrustCert = $TrustCert

  [IPAddress]$ipAddress = $null
  if ([IPAddress]::TryParse($Address, [ref]$ipAddress)) {
    if (([IPAddress]$Address).AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6 -and $Address.IndexOf('[') -eq -1) {
      $Address = '[' + $Address + ']'
    }
  }

  $session.BaseUri = "https://$Address"


  $Logger.info("Create Redfish session For $($session.BaseUri) now")

  # New session
  $path = "/SessionService/Sessions"
  $method = "POST"
  $payload = @{'UserName' = $username; 'Password' = $passwd; }
  $response = Invoke-RedfishRequest -Session $session -Path $path -Method $method -Payload $payload
  $response.close()

  # set session properties
  $session.Location = $response.Headers['Location']
  $session.AuthToken = $response.Headers['X-Auth-Token']
  $session.Alive = $true

  # get bmc resource Id (BladeN, SwiN, N)
  $managers = Invoke-RedfishRequest -Session $session -Path "/Managers" | ConvertFrom-WebResponse
  $managerOdataId = $managers.Members[0].'@odata.id'
  # $session.resourceId = $($managerOdataId -split '/')[-1]

  # get bmc manager
  $manager = Invoke-RedfishRequest -Session $session -Path $managerOdataId | ConvertFrom-WebResponse

  $session.Id = $manager.Id
  $session.Name = $manager.Name
  $session.ManagerType = $manager.ManagerType
  $session.FirmwareVersion = $manager.FirmwareVersion
  $session.UUID = $manager.UUID
  $session.Model = $manager.Model
  $session.DateTime = $manager.DateTime
  $session.DateTimeLocalOffset = $manager.DateTimeLocalOffset
  $session.State = $manager.Status.State
  $session.Health = $manager.Status.Health
  return $session
}


function Close-RedfishSession {
<#
.SYNOPSIS
Close a specified session of iBMC Redfish Server.

.DESCRIPTION
Close a specified session of iBMC Redfish Server by sending HTTP Delete request to location holds by "Location" property in Session object passed as parameter.

.PARAMETER Session
Session object that created by New-RedfishSession cmdlet.

.NOTES
The Session object will be detached from iBMC Redfish Server. And the Session can not be used by cmdlets which required Session parameter again.

.INPUTS
You can pipe the session object to Close-RedfishSession. The session object is obtained from executing New-RedfishSession cmdlet.

.OUTPUTS
This cmdlet does not generate any output.


.EXAMPLE
PS C:\> Close-RedfishSession -Session $session
PS C:\>

This will disconnect the session given in the variable $session

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

#>
  param
  (
    [RedfishSession]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position=0)]
    $session
  )

  if ($null -eq $session -or $session -isnot [RedfishSession]) {
    throw $([string]::Format($(Get-i18n ERROR_PARAMETER_ILLEGAL), 'Session'))
  }

  $method = "DELETE"
  $path = $session.Location
  $response = Invoke-RedfishRequest -Session $session -Path $path -Method $method
  $response.close()

  $success = $response.StatusCode.value__ -lt 400
  $session.Alive = !$success
  return $session
}


function Test-RedfishSession {
<#
.SYNOPSIS
Test whether a specified session of iBMC Redfish Server is still alive

.DESCRIPTION
Test whether a specified session of iBMC Redfish Server is still alive by sending a HTTP get request to Session Location Uri.

.PARAMETER Session
Session object that created by New-RedfishSession cmdlet.

.INPUTS
You can pipe the session object to Test-RedfishSession. The session object is obtained from executing New-RedfishSession cmdlet.

.OUTPUTS
true if still alive else false


.EXAMPLE
PS C:\> Test-RedfishSession -Session $session
PS C:\>

true

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

#>
  param
  (
    [RedfishSession]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position=0)]
    $Session
  )

  if ($null -eq $session -or $session -isnot [RedfishSession]) {
    throw $([string]::Format($(Get-i18n ERROR_PARAMETER_ILLEGAL), 'Session'))
  }

  try {
    $method = "GET"
    $path = $session.Location
    Invoke-RedfishRequest -Session $session -Path $path -Method $method | Out-Null
  } catch {
    # we do not care about the reason of failure.
    # if any exception is thrown, we treat it as session timeout
    $session.Alive = $false
  }

  return $session
}

function Wait-RedfishTasks {
<#
.SYNOPSIS
Wait redfish tasks util success or failed

.DESCRIPTION
Wait redfish tasks util success or failed

.PARAMETER Session
Session array that created by New-RedfishSession cmdlet.

.PARAMETER Task
Task array that return by redfish async job API

.OUTPUTS

.EXAMPLE
PS C:\> Wait-RedfishTasks $Sessions $Tasks
PS C:\>

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

#>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true, Position = 0)]
    $ThreadPool,

    [RedfishSession[]]
    [parameter(Mandatory = $true, Position=1)]
    $Sessions,

    [PSObject[]]
    [parameter(Mandatory = $true, Position=2)]
    $Tasks,

    [Parameter(Mandatory = $false, Position = 3)]
    [switch]
    $ShowProgress
  )

  begin {
    Assert-NotNull $ThreadPool
    Assert-ArrayNotNull $Sessions
    Assert-ArrayNotNull $Tasks
  }

  process {
    function Write-TaskProgress($RedfishSession, $Task) {
      if ($ShowProgress) {
        if ($Task -isnot [Exception]) {
          $TaskState = $Task.TaskState
          if ($TaskState -eq 'Running') {
            $TaskPercent = $Task.Oem.Huawei.TaskPercentage
            if ($null -eq $TaskPercent) {
              $TaskPercent = 0
            } else {
              $TaskPercent = [int]$TaskPercent.replace('%', '')
            }

            $Logger.Info($(Trace-Session $RedfishSession "Task percent: $TaskPercent"))
            Write-Progress -Id $Task.Guid -Activity $Task.ActivityName -PercentComplete $TaskPercent `
              -Status "$($TaskPercent)% $(Get-i18n MSG_PROGRESS_PERCENT)"
          }
          elseif ($TaskState -eq 'Completed') {
            $Logger.Info($(Trace-Session $RedfishSession "Task Completed"))
            Write-Progress -Id $Task.Guid -Activity $Task.ActivityName -Completed -Status $(Get-i18n MSG_PROGRESS_COMPLETE)
          }
          elseif ($TaskState -eq 'Exception') {
            $ToJson = $Task | ConvertTo-Json
            $Logger.Info($(Trace-Session $RedfishSession "Task failed. Response: $ToJson"))
            Write-Progress -Id $Task.Guid -Activity $Task.ActivityName -Completed -Status $(Get-i18n MSG_PROGRESS_FAILED)
          }
        }
      }
    }

    $Logger.info("Start wait for all redfish tasks done")

    $GuidPrefix = [string] $(Get-RandomIntGuid)
    # initialize tasks
    for ($idx=0; $idx -lt $Tasks.Count; $idx++) {
      $Task = $Tasks[$idx]
      $Session = $Sessions[$idx]
      if ($Task -isnot [Exception] -and $null -ne $Task) {
        $TaskGuid = [int]$($GuidPrefix + $idx)
        $Task | Add-Member -MemberType NoteProperty 'index' $idx
        $Task | Add-Member -MemberType NoteProperty 'Guid' $TaskGuid
        $Task | Add-Member -MemberType NoteProperty 'ActivityName' "[$($Session.Address)] $($Task.Name)"
        Write-TaskProgress $Session $Task
      }
    }

    while ($true) {
      $RunningTasks = @($($Tasks | Where-Object {$_ -isnot [Exception]} | Where-Object TaskState -in @('Running', 'New')))
      $Logger.info("Remain running task count: $($RunningTasks.Count)")
      # $Logger.info("Remain running tasks: $RunningTasks")
      if ($RunningTasks.Count -eq 0) {
        break
      }
      Start-Sleep -Seconds 1
      # filter running task and fetch task new status
      $AsyncTasks = New-Object System.Collections.ArrayList
      for ($idx=0; $idx -lt $RunningTasks.Count; $idx++) {
        $RunningTask = $RunningTasks[$idx]
        $Parameters = @($Sessions[$RunningTask.index], $RunningTask)
        $ScriptBlock = {
          param($RedfishSession, $RunningTask)
          return $(Get-RedfishTask $RedfishSession $RunningTask)
        }
        [Void] $AsyncTasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $Parameters))
      }
      # new updated task list
      $ProcessedTasks = @($(Get-AsyncTaskResults $AsyncTasks))
      for ($idx=0; $idx -lt $ProcessedTasks.Count; $idx++) {
        $ProcessedTask = $ProcessedTasks[$idx]
        $RedfishSession = $Sessions[$ProcessedTask.index]
        $Tasks[$ProcessedTask.index] = $ProcessedTask # update task
        Write-TaskProgress $RedfishSession $ProcessedTask
      }
    }

    $FinishedTasks = @($($Tasks | Where-Object {$_ -isnot [Exception]}))
    for ($idx=0; $idx -lt $FinishedTasks.Count; $idx++) {
      $FinishedTask = $FinishedTasks[$idx]
      $RedfishSession = $Sessions[$FinishedTask.index]
      $Properties = @(
        "Id", "Name", "ActivityName", "TaskState",
        "StartTime", "EndTime", "TaskStatus"
      )

      $CleanTask = Copy-ObjectProperties $FinishedTask $Properties
      $CleanTask | Add-Member -MemberType NoteProperty "TaskPercent" $FinishedTask.Oem.Huawei.TaskPercentage
      if ($FinishedTask.TaskState -ne $BMC.TaskState.Completed) {
        $CleanTask | Add-Member -MemberType NoteProperty "Messages" $FinishedTask.Messages
      }
      $CleanTask = $(Update-SessionAddress $RedfishSession $CleanTask)
      $Tasks[$FinishedTask.index] = $CleanTask # update task
    }




    $Logger.info("All redfish tasks done")
    return ,$Tasks
  }

  end {
  }
}


function Wait-SPFileTransfer {
<#
.SYNOPSIS
Wait SP file transfer util success or failed

.DESCRIPTION
Wait SP file transfer util success or failed

.PARAMETER Session
Session array that created by New-RedfishSession cmdlet.

.PARAMETER Task
Task array that return by redfish async job API

.OUTPUTS

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

#>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true, Position = 0)]
    $ThreadPool,

    [RedfishSession[]]
    [parameter(Mandatory = $true, Position=1)]
    $Sessions,

    [PSObject[]]
    [parameter(Mandatory = $true, Position=2)]
    $SPFWUpdates,

    [Parameter(Mandatory = $false, Position = 3)]
    [switch]
    $ShowProgress
  )

  begin {
    Assert-NotNull $ThreadPool
    Assert-ArrayNotNull $Sessions
    Assert-ArrayNotNull $SPFWUpdates
  }

  process {
    function Write-SPTransferProgress($RedfishSession, $SPFWUpdate) {
      if ($ShowProgress) {
        if ($SPFWUpdate -isnot [Exception]) {
          if ($SPFWUpdate.TransferFileName -eq $SPFWUpdate.TargetFileName) {
            $FileName = $SPFWUpdate.TargetFileName
            $TransferState = $SPFWUpdate.TransferState
            if ($TransferState -eq 'Processing') {
              $Percent = $SPFWUpdate.TransferProgressPercent
              $Logger.Info($(Trace-Session $RedfishSession "File $($SPFWUpdate.TransferFileName) transfer $($Percent)%"))
              if ($null -eq $Percent) {
                $Percent = 0
              }
              Write-Progress -Id $SPFWUpdate.Guid -Activity $SPFWUpdate.ActivityName -PercentComplete $Percent `
                -Status "$($Percent)% $(Get-i18n MSG_PROGRESS_PERCENT)"
            }
            elseif ($TransferState -in @('Completed', 'Success')) {
              $Logger.Info($(Trace-Session $RedfishSession "File $FileName transfer finished."))
              Write-Progress -Id $SPFWUpdate.Guid -Activity $SPFWUpdate.ActivityName -Completed -Status $(Get-i18n MSG_PROGRESS_COMPLETE)
            }
            elseif ($TransferState -eq 'Failure') {
              $ToJson = $SPFWUpdate | ConvertTo-Json
              $Logger.Info($(Trace-Session $RedfishSession "File $FileName transfer Failure. Response: $ToJson"))
              Write-Progress -Id $SPFWUpdate.Guid -Activity $SPFWUpdate.ActivityName -Completed -Status $(Get-i18n MSG_PROGRESS_FAILED)
            }
          } else {
            $Logger.Info($(Trace-Session $RedfishSession "File $($SPFWUpdate.TransferFileName) not equal $($SPFWUpdate.TargetFileName)"))
            # if file name changed, treat it as success
            Write-Progress -Id $SPFWUpdate.Guid -Activity $SPFWUpdate.ActivityName -Completed -Status $(Get-i18n MSG_PROGRESS_COMPLETE)
          }
        }
      }
    }

    $Logger.info("Start wait for all SPFW Update files transfer done")

    $GuidPrefix = [string] $(Get-RandomIntGuid)
    # initialize tasks
    for ($idx=0; $idx -lt $SPFWUpdates.Count; $idx++) {
      $SPFWUpdate = $SPFWUpdates[$idx]
      $Session = $Sessions[$idx]
      if ($SPFWUpdate -isnot [Exception]) {
        $Guid = [int]$($GuidPrefix + $idx)
        $SPFWUpdate | Add-Member -MemberType NoteProperty 'index' $idx
        $SPFWUpdate | Add-Member -MemberType NoteProperty 'Guid' $Guid
        $SPFWUpdate | Add-Member -MemberType NoteProperty 'ActivityName' "[$($Session.Address)] $($SPFWUpdate.Name)"
        $SPFWUpdate | Add-Member -MemberType NoteProperty 'TargetFileName' $SPFWUpdate.TransferFileName
        Write-SPTransferProgress $Session $SPFWUpdate
      }
    }

    $FirstRound = $true
    while ($true) {
      if ($FirstRound) {
        $FirstRound = $false
        $Transfering = @($($SPFWUpdates | Where-Object {$_ -isnot [Exception]} | Where-Object TransferState -ne 'Failure'))
      } else {
        $Transfering = @($($SPFWUpdates | Where-Object {$_ -isnot [Exception]} | Where-Object TransferState -eq 'Processing'))
      }
      $Logger.info("Remain Transfering task count: $($Transfering.Count)")
      # $Logger.info("Remain running tasks: $Transfering")
      if ($Transfering.Count -eq 0) {
        break
      }
      Start-Sleep -Milliseconds 300
      # filter running task and fetch task new status
      $AsyncTasks = New-Object System.Collections.ArrayList
      for ($idx=0; $idx -lt $Transfering.Count; $idx++) {
        $Pending = $Transfering[$idx]
        $Parameters = @($Sessions[$Pending.index], $Pending)
        $ScriptBlock = {
          param($RedfishSession, $Pending)
          $SPFWUpdate = Get-SPFWUpdate $RedfishSession $Pending
          return $SPFWUpdate
        }
        [Void] $AsyncTasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $Parameters))
      }
      # new updated task list
      $Processed = @($(Get-AsyncTaskResults $AsyncTasks))
      for ($idx=0; $idx -lt $Processed.Count; $idx++) {
        $ProcessedTask = $Processed[$idx]
        $RedfishSession = $Sessions[$ProcessedTask.index]
        $SPFWUpdates[$ProcessedTask.index] = $ProcessedTask # update task
        Write-SPTransferProgress $RedfishSession $ProcessedTask
      }
    }

    $FinishedFiles = @($($SPFWUpdates | Where-Object {$_ -isnot [Exception]}))
    for ($idx=0; $idx -lt $FinishedFiles.Count; $idx++) {
      $Finished = $FinishedFiles[$idx]
      $RedfishSession = $Sessions[$Finished.index]
      $Properties = @(
        "Name", "ActivityName", "TransferState", "TransferFileName",
        "TransferProgressPercent", "FileList", "Messages"
      )

      $Clone = Copy-ObjectProperties $Finished $Properties
      $SPFWUpdates[$Finished.index] = Update-SessionAddress $RedfishSession $Clone
    }

    $Logger.info("All SPFW Update file transfer done")
    return $SPFWUpdates
  }

  end {
  }
}

function Get-SPFWUpdate {
  [CmdletBinding()]
  param (
    [RedfishSession]
    [parameter(Mandatory = $true, Position=0)]
    $Session,

    [PSObject]
    [parameter(Mandatory = $true, Position=1)]
    $SPFWUpdate
  )

  begin {
    Assert-NotNull $Session
    Assert-NotNull $SPFWUpdate
  }

  process {

    function Update-FileListIfNeccess($Session, $SPFWUpdate) {
      $SuccessStatus = @('Completed', 'Success')
      if ($SPFWUpdate.TransferState -in $SuccessStatus) {
        # try to get new FileList after success
        Start-Sleep -Seconds 3
        $TryTimes = 20
        while ($TryTimes -gt 0) {
          $GetSPFileList = Invoke-RedfishRequest $Session $OdataId | ConvertFrom-WebResponse
          if ($null -ne $GetSPFileList.FileList -and $GetSPFileList.FileList.Count -gt 0) {
            $SPFWUpdate.FileList = $GetSPFileList.FileList
            break
          }
          $TryTimes = $TryTimes - 1
          Start-Sleep -Seconds 1
        }
      }
      return $SPFWUpdate
    }

    $OdataId = $SPFWUpdate.'@odata.id'
    $SuccessStatus = @('Completed', 'Success')
    if ($SPFWUpdate.TransferState -in $SuccessStatus) {
      return Update-FileListIfNeccess $Session $SPFWUpdate
    } else {
      $NewSPFWUpdate = Invoke-RedfishRequest $Session $OdataId | ConvertFrom-WebResponse
      $NewSPFWUpdate | Add-Member -MemberType NoteProperty 'index' $SPFWUpdate.index
      $NewSPFWUpdate | Add-Member -MemberType NoteProperty 'Guid' $SPFWUpdate.Guid
      $NewSPFWUpdate | Add-Member -MemberType NoteProperty 'ActivityName' $SPFWUpdate.ActivityName
      $NewSPFWUpdate | Add-Member -MemberType NoteProperty 'TargetFileName' $SPFWUpdate.TargetFileName
      return Update-FileListIfNeccess $Session $NewSPFWUpdate
    }
  }

  end {
  }
}

function Get-RedfishTask {
<#
.SYNOPSIS
Wait a redfish task util success or failed

.DESCRIPTION
Wait a redfish task util success or failed

.PARAMETER Session
Session object that created by New-RedfishSession cmdlet.

.PARAMETER Task
Task object that return by redfish async job API

Completed Task object sample:
{
    "@odata.context": "/redfish/v1/$metadata#TaskService/Tasks/Members/$entity",
    "@odata.type": "#Task.v1_0_2.Task",
    "@odata.id": "/redfish/v1/TaskService/Tasks/1",
    "Id": "1",
    "Name": "Export Config File Task",
    "TaskState": "Completed",
    "StartTime": "2018-10-25T13:31:52+08:00",
    "EndTime": "2018-10-25T13:32:28+08:00",
    "TaskStatus": "OK",
    "Messages": {
        "@odata.type": "/redfish/v1/$metadata#MessageRegistry.1.0.0.MessageRegistry",
        "MessageId": "iBMC.1.0.CollectingConfigurationOK",
        "RelatedProperties": [],
        "Message": "Successfully collected the configuration file.",
        "MessageArgs": [],
        "Severity": "OK",
        "Resolution": "None"
    },
    "Oem": {
        "Huawei": {
            "TaskPercentage": "100%"
        }
    }
}


Exception Task object sample:

{
    "@odata.context": "/redfish/v1/$metadata#TaskService/Tasks/Members/$entity",
    "@odata.type": "#Task.v1_0_2.Task",
    "@odata.id": "/redfish/v1/TaskService/Tasks/1",
    "Id": "1",
    "Name": "Export Config File Task",
    "TaskState": "Exception",
    "StartTime": "2018-10-25T15:19:40+08:00",
    "EndTime": "2018-10-25T15:20:26+08:00",
    "TaskStatus": "Warning",
    "Messages": {
        "@odata.type": "/redfish/v1/$metadata#MessageRegistry.1.0.0.MessageRegistry",
        "MessageId": "iBMC.1.0.FileTransferErrorDesc",
        "RelatedProperties": [],
        "Message": "An error occurred during the file transfer process. Details: unknown error.",
        "MessageArgs": [
            "unknown error"
        ],
        "Severity": "Warning",
        "Resolution": "Rectify the fault and submit the request again."
    },
    "Oem": {
        "Huawei": {
            "TaskPercentage": "10%"
        }
    }
}

.OUTPUTS

.EXAMPLE
PS C:\> Wait-RedfishTask $session $task
PS C:\>

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

#>
  [CmdletBinding()]
  param (
    [RedfishSession]
    [parameter(Mandatory = $true, Position=0)]
    $Session,

    [PSObject]
    [parameter(Mandatory = $true, Position=1)]
    $Task
  )

  begin {
    Assert-NotNull $Session
    Assert-NotNull $Task
  }

  process {
    $TaskOdataId = $Task.'@odata.id'
    $NewTask = Invoke-RedfishRequest $Session $TaskOdataId | ConvertFrom-WebResponse
    $NewTask | Add-Member -MemberType NoteProperty 'index' $Task.index
    $NewTask | Add-Member -MemberType NoteProperty 'Guid' $Task.Guid
    $NewTask | Add-Member -MemberType NoteProperty 'ActivityName' $Task.ActivityName
    return $NewTask
  }

  end {
  }
}

function Invoke-RedfishFirmwareUpload {
  [cmdletbinding()]
  param (
    [RedfishSession]
    [parameter(Mandatory = $true, Position=0)]
    $Session,

    [System.String]
    [parameter(Mandatory = $true, Position=1)]
    $FileName,

    [System.String]
    [parameter(Mandatory = $true, Position=2)]
    $FilePath,

    [Switch]
    [parameter(Mandatory = $false, Position=3)]
    $ContinueEvenFailed
  )

  $Logger.info($(Trace-Session $Session "Uploading $FilePath as $FileName to ibmc"))
  $Request = New-RedfishRequest $Session '/UpdateService/FirmwareInventory' 'POST'
  $Request.Timeout = 300 * 1000
  $Request.ReadWriteTimeout = 300 * 1000
  try {
    # $ASCIIEncoder = [System.Text.Encoding]::ASCII
    $UTF8Encoder = [System.Text.Encoding]::UTF8
    $Boundary = "---------------------------$($(Get-Date).Ticks)"
    $BoundaryAsBytes = $UTF8Encoder.GetBytes("`r`n--$Boundary`r`n")

    $Request.ContentType = "multipart/form-data; boundary=$Boundary"
    $Request.KeepAlive = $true

    $RequestStream = $Request.GetRequestStream()
    $RequestStream.Write($BoundaryAsBytes, 0, $BoundaryAsBytes.Length)

    $Header = "Content-Disposition: form-data; name=`"imgfile`"; filename=`"$($FileName)`"`
      \r\nContent-Type: application/octet-stream`r`n`r`n"
    $HeaderAsBytes = $UTF8Encoder.GetBytes($Header)
    $RequestStream.Write($HeaderAsBytes, 0, $HeaderAsBytes.Length)

    $bytesRead = 0
    $Buffer = New-Object byte[] 4096
    $FileStream = New-Object IO.FileStream $FilePath ,'Open','Read'
    while (($bytesRead = $FileStream.Read($Buffer, 0, $Buffer.Length)) -gt 0) {
      $RequestStream.Write($Buffer, 0, $bytesRead)
    }
    $FileStream.Close()

    $Trailer = $UTF8Encoder.GetBytes("`r`n--$boundary--`r`n")
    $RequestStream.Write($Trailer, 0, $Trailer.Length)
    $RequestStream.Close()

    # https://docs.microsoft.com/en-us/dotnet/framework/network-programming/how-to-request-data-using-the-webrequest-class
    $Response = $Request.GetResponse() | ConvertFrom-WebResponse
    return $Response.success
  }
  catch {
    # .Net HttpWebRequest will throw Exception if response is not success (status code is great than 400)
    # https://stackoverflow.com/questions/10081726/why-does-httpwebrequest-throw-an-exception-instead-returning-httpstatuscode-notf
    # [System.Net.HttpWebResponse] $response = $_.Exception.InnerException.Response
    Resolve-RedfishFailureResponse $Session $Request $_ $ContinueEvenFailed
  }
  finally {
    if ($null -ne $RequestStream -and $RequestStream -is [System.IDisposable]) {
      $RequestStream.Dispose()
    }
  }
}

function Invoke-FileUploadIfNeccessary ($RedfishSession, $ImageFilePath, $SupportSchema) {
  # iBMC local storage protocol handle
  $IsBMCFileProtocol = ($ImageFilePath.StartsWith("file:///tmp", "CurrentCultureIgnoreCase") `
                          -or $ImageFilePath.StartsWith("/tmp", "CurrentCultureIgnoreCase"))
  if ($IsBMCFileProtocol -and 'file' -in $SupportSchema) {
    return $ImageFilePath
  }

  $SupportSchemaString = $SupportSchema -join ", "
  try {
    $ImageFileUri = New-Object System.Uri($ImageFilePath)
  } catch {
    throw $(Get-i18n ERROR_FILE_URI_ILLEGAL)
  }
  $SecureFileUri = $ImageFilePath
  if($ImageFileUri.UserInfo.Length -gt 0) {
    $SecureFileUri = $ImageFileUri.AbsoluteUri -replace $ImageFileUri.UserInfo, "***:***"
  }

  if ($ImageFileUri.Scheme -notin $SupportSchema) {
    $Logger.warn($(Trace-Session $RedfishSession "File $SecureFileUri is not in support schema: $SupportSchemaString"))
    throw $([string]::Format($(Get-i18n ERROR_FILE_URI_NOT_SUPPORT), $ImageFileUri, $SupportSchemaString))
  }

  if ($ImageFileUri.Scheme -eq 'file') {
    $Logger.info($(Trace-Session $RedfishSession"File $SecureFileUri is a local file, upload to bmc now"))
    $Ext = [System.IO.Path]::GetExtension($ImageFilePath)
    if ($null -eq $Ext -or $Ext -eq '') {
      $UploadFileName = "$(Get-RandomIntGuid).hpm"
    } else {
      $UploadFileName = $ImageFileUri.Segments[-1]
    }

    # upload image file to bmc
    $Logger.Info($(Trace-Session $RedfishSession "$SecureFileUri is a local file, upload to iBMC now"))
    Invoke-RedfishFirmwareUpload $RedfishSession $UploadFileName $ImageFilePath | Out-Null
    $Logger.Info($(Trace-Session $RedfishSession "File uploaded as $UploadFileName success"))
    return "/tmp/web/$UploadFileName"
  }

  $Logger.info($(Trace-Session $RedfishSession "File $SecureFileUri is 'network' file, it's support directly."))
  return Resolve-NetworkUriSchema $ImageFilePath
}


function Invoke-RedfishRequest {
  [cmdletbinding()]
  param (
    [RedfishSession]
    [parameter(Mandatory = $true, Position=0)]
    $Session,

    [System.String]
    [parameter(Mandatory = $true, Position=1)]
    $Path,

    [System.String]
    [parameter(Mandatory = $false, Position=2)]
    [ValidateSet('Get', 'Delete', 'Put', 'Post', 'Patch')]
    $Method = 'Get',

    [System.Object]
    [parameter(Mandatory = $false, Position=3)]
    $Payload,

    [System.Object]
    [parameter(Mandatory = $false, Position=4)]
    $Headers,

    [Switch]
    [parameter(Mandatory = $false, Position=5)]
    $ContinueEvenFailed
  )

  $Request = New-RedfishRequest $Session $Path $Method $Headers

  try {
    if ($method -in @('Put', 'Post', 'Patch')) {
      if ($null -eq $Payload -or '' -eq $Payload) {
        $PayloadString = '{}'
      } elseif ($Payload -is [string]) {
        $PayloadString = $Payload
      } else {
        $PayloadString = $Payload | ConvertTo-Json -Depth 5
      }

      $Encoder = [System.Text.Encoding]::ASCII
      $PayloadAsBytes = $Encoder.GetBytes($PayloadString)

      $Request.ContentType = 'application/json'
      $Request.ContentLength = $PayloadAsBytes.length

      $RequestStream = $Request.GetRequestStream()
      $RequestStream.Write($PayloadAsBytes, 0, $PayloadAsBytes.length)
      $RequestStream.Flush()
      $RequestStream.close()

      # $StreamWriter = New-Object System.IO.StreamWriter($RequestStream, [System.Text.Encoding]::ASCII)
      # $StreamWriter.Write($PayloadString)
      # $StreamWriter.Flush()
      # $StreamWriter.Close()
      # $RequestStream.close()
      # $Logger.debug($(Trace-Session $Session "Send request payload: $PayloadString"))
    }

    # https://docs.microsoft.com/en-us/dotnet/framework/network-programming/how-to-request-data-using-the-webrequest-class
    return $Request.GetResponse()
  }
  catch {
    # .Net HttpWebRequest will throw Exception if response is not success (status code is great than 400)
    # https://stackoverflow.com/questions/10081726/why-does-httpwebrequest-throw-an-exception-instead-returning-httpstatuscode-notf
    # [System.Net.HttpWebResponse] $response = $_.Exception.InnerException.Response
    # $Logger.info($Request)
    # $Request.Headers | ForEach-Object {
    #   $value = $Request.Headers.Item($_)
    #   $Logger.info("$_ : $value")
    # }
    Resolve-RedfishFailureResponse $Session $Request $_ $ContinueEvenFailed
  }
  finally {
    # if ($null -ne $StreamWriter -and $StreamWriter -is [System.IDisposable]) {
    #   $StreamWriter.Dispose()
    # }
  }
}

function New-RedfishRequest {
  [cmdletbinding()]
  param (
    [RedfishSession]
    [parameter(Mandatory = $true, Position=0)]
    $Session,

    [System.String]
    [parameter(Mandatory = $true, Position=1)]
    $Path,

    [System.String]
    [parameter(Mandatory = $false, Position=2)]
    [ValidateSet('Get', 'Delete', 'Put', 'Post', 'Patch')]
    $Method = 'Get',

    [System.Object]
    [parameter(Mandatory = $false, Position=3)]
    $Headers
  )

  if ($Path.StartsWith("https://", "CurrentCultureIgnoreCase")) {
    $OdataId = $Path
  }
  elseif ($Path.StartsWith("/redfish/v1", "CurrentCultureIgnoreCase")) {
    $OdataId = "$($session.BaseUri)$($Path)"
  }
  else {
    $OdataId = "$($session.BaseUri)/redfish/v1$($Path)"
  }

  $IfMatchMissing = ($null -eq $Headers -or 'If-Match' -notin $Headers.Keys)
  if ($IfMatchMissing -and $method -in @('Put', 'Patch')) {
    $Logger.Info($(Trace-Session $Session "No if-match present, will auto load etag now"))
    $Response = Invoke-RedfishRequest -Session $Session -Path $Path
    $OdataEtag = $Response.Headers.get('ETag')
    # $Logger.info($(Trace-Session $Session "Etag of Odata $Path -> $OdataEtag"))
    $Response.close()
  }

  $Logger.info($(Trace-Session $Session "Invoke [$Method] $Path"))

  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  [System.Net.HttpWebRequest] $Request = [System.Net.WebRequest]::Create($OdataId)
  $Request.Timeout = 120 * 1000
  $Request.ReadWriteTimeout = 90 * 1000

  # $cert = Get-ChildItem -Path cert:\CurrentUser\My | where-object Thumbprint -eq B2536A31C7A7462BBA542B4A8B0C34E315D16AB9
  # Write-Host $cert
  # $Store = New-Object System.Security.Cryptography.X509Certificates.X509Store(
  #         [System.Security.Cryptography.X509Certificates.StoreName]::My, "CurrentUser")
  # $Store.Open("MaxAllowed")
  # $Certificate = $Store.Certificates |  Where-Object Thumbprint -Eq "B2536A31C7A7462BBA542B4A8B0C34E315D16AB9"
  # Write-Host $Certificate
  # # $Request.ClientCertificates.Add($Certificate)
  # $Request.ClientCertificates.AddRange($Certificate)

  $Request.ServerCertificateValidationCallback = {
    param($sender, $certificate, $chain, $errors)
    if ($errors -eq 'None') {
      return $true
    }

    if ($true -eq $session.TrustCert) {
      # $Logger.debug("TrustCert present, Ignore HTTPS certification")
      return $true
    }

    # enable fingerprint match testing
    # if ($Request -eq $sender) {
    #   $Certificates = $(Get-ChildItem -Path cert:\ -Recurse | where-object Thumbprint -eq $certificate.Thumbprint)
    #   if ($null -ne $Certificates -and $Certificates.count -gt 0) {
    #     return $true
    #   }
    # }

    return $false
  }

  # $Logger.info("The 'ProtocolVersion' of the protocol used is $($Request.ProtocolVersion)")
  $Request.Method = $Method.ToUpper()
  $Request.UserAgent = "PowerShell Huawei iBMC Cmdlet"
  # $Request.KeepAlive = $true
  # $Request.Accept = "text/html, application/xhtml+xml, application/pdf, */*"
  # $Request.Headers.Add("Accept-Language", "en-US,en;q=0.9")
  # $Request.Headers.Add("Cache-Control", "no-cache")
  # $Request.Headers.Add("Upgrade-Insecure-Requests", "1")
  # $Request.Headers.Add("Origin", $OdataId)
  # $Request.ServicePoint.Expect100Continue = $false
  $Request.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
  $Request.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip

  if ($null -ne $session.AuthToken) {
    $Request.Headers.Add('X-Auth-Token', $session.AuthToken)
  }

  if ($null -ne $Headers) {
    $Headers.Keys | ForEach-Object {
      $Request.Headers.Add($_, $Headers.Item($_))
    }
  }

  if ($null -ne $OdataEtag) {
    $Request.Headers.Add('If-Match', $OdataEtag)
  }

  return $Request
}


function Resolve-RedfishFailureResponse ($Session, $Request, $Ex, $ContinueEvenFailed) {
  try {
    $Logger.Warn(($(Trace-Session $Session $Ex)))
    $response = $Ex.Exception.InnerException.Response
    if ($null -ne $response) {
      $StatusCode = $response.StatusCode.value__
      if ($StatusCode -eq 403){
        throw $(Get-i18n "FAIL_NO_PRIVILEGE")
      }
      elseif ($StatusCode -eq 500) {
        throw $(Get-i18n "FAIL_INTERNAL_SERVICE")
      }
      elseif ($StatusCode -eq 501) {
        throw $(Get-i18n "FAIL_NOT_SUPPORT")
      }

      if ($ContinueEvenFailed -and $StatusCode -ne 401) {
        return $response
      }

      $Content = Get-WebResponseContent $response
      $Message = "[$($Request.Method)] $($response.ResponseUri) -> code: $StatusCode; content: $Content"
      $Logger.warn($(Trace-Session $Session $Message))

      $Failures = Get-RedfishResponseFailures $Content
      if ($null -ne $Failures -and $Failures.Count -gt 0) {
        throw $($Failures -join "`n")
      }

      throw $Ex.Exception
    } else {
      throw $Ex.Exception
    }
  } catch {
    # $Logger.info("rethrow exceptions [$($Session.Address)] $($_.Exception)")
    throw "[$($Session.Address)] $($_.Exception.Message)"
  }
}


function Resolve-RedfishPartialSuccessResponse($RedfishSession, $Response) {
  $Uri = $Response.ResponseUri
  $StatusCode = $Response.StatusCode.value__
  $ResponseContent = Get-WebResponseContent $Response
  $Failures = Get-RedfishResponseFailures $ResponseContent
  if ($null -ne $Failures -and $Failures.Count -gt 0) {
    $Message = "[$($Response.Method)] $Uri -> code: $StatusCode; content: $ResponseContent"
    $Logger.warn($(Trace-Session $RedfishSession $Message))
    $FailuresToString = $($Failures -join "`n")
    throw "[$($RedfishSession.Address)] $($FailuresToString)"
  } else {
    return $ResponseContent | ConvertFrom-Json
  }
}


function ConvertFrom-WebResponse {
  param (
    [System.Net.HttpWebResponse]
    [parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $Response
  )
  return Get-WebResponseContent $Response | ConvertFrom-Json
}

function Get-WebResponseContent {
  param (
    [System.Net.HttpWebResponse]
    [parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $Response
  )
  try {
    $stream = $response.GetResponseStream()
    $streamReader = New-Object System.IO.StreamReader($stream)
    $content = $streamReader.ReadToEnd()
    # $Logger.debug("Redfish API Response: [$($response.StatusCode.value__)] $content")
    return $content
  }
  finally {
    $streamReader.close()
    $stream.close()
    $response.close()
  }
}

function Get-RedfishResponseFailures {
  param (
    [String]
    $ResponseContent
  )
  $result = $ResponseContent | ConvertFrom-Json

  $Partial = $false
  $ExtendedInfo = $result.error.'@Message.ExtendedInfo'
  if ($ExtendedInfo.Count -eq 0) {
    $Partial = $true
    $ExtendedInfo = $result.'@Message.ExtendedInfo'
  }

  if ($ExtendedInfo.Count -eq 1) {
    $Severity = $ExtendedInfo[0].Severity
    if ($Severity -eq $BMC.Severity.OK) {
      return $null
    }
  }

  if ($ExtendedInfo.Count -gt 0) {
    $Prefix = "Failure:"
    $indent = " " * $Prefix.Length
    $Failures = New-Object System.Collections.ArrayList

    if ($Partial) {
      [Void] $Failures.Add($(Get-i18n FAIL_TO_MODIFY_ALL))
    }

    for ($idx = 0; $idx -lt $ExtendedInfo.Count; $idx++) {
      $Failure = $ExtendedInfo[$idx]
      $Resolution = "Resolution: $($Failure.Resolution)"
      if ($idx -eq 0 -and -not $Partial) {
        [Void] $Failures.Add("$Prefix [$($Failure.Severity)] $($Failure.Message) $Resolution")
      } else {
        [Void] $Failures.Add("$indent [$($Failure.Severity)] $($Failure.Message) $Resolution")
      }
    }

    return $Failures
  }

  return $null
}

function Get-StoragePathCollection {
<#
.SYNOPSIS
Get the path of RAID storage collection

.DESCRIPTION

.PARAMETER Session
Get the path of RAID storage collection

.OUTPUTS
String[]
RAID storage odata id array

#>
  [CmdletBinding()]
  param (
    [RedfishSession]
    [parameter(Mandatory = $true, Position=0)]
    $RedfishSession
  )

  $GetStoragesPath = "/Systems/$($RedfishSession.Id)/Storages"
  $Storages = Invoke-RedfishRequest $RedfishSession $GetStoragesPath | ConvertFrom-WebResponse

  $OdataIdList = New-Object System.Collections.ArrayList
  for ($idx = 0; $idx -lt $Storages.Members.Count; $idx++) {
    $StoragePath = $Storages.Members[$idx]."@odata.id"
    if ($StoragePath -like '*/RAIDStorage*') {
      [Void] $OdataIdList.Add($StoragePath)
    } else {
      continue
    }
  }

  return ,$OdataIdList.ToArray()
}


function Get-VolumeOdataId {
  <#
  .DESCRIPTION
  Fetch logical drive odata-id by Id
  #>
  [CmdletBinding()]
  param (
    [RedfishSession]
    [parameter(Mandatory = $true, Position=0)]
    $RedfishSession,

    [String]
    [parameter(Mandatory = $true, Position=1)]
    $VolumeId
  )

  $StoragePaths = Get-StoragePathCollection $RedfishSession
  for ($idx = 0; $idx -lt $StoragePaths.Count; $idx++) {
    $StoragePath = $StoragePaths[$idx]
    $GetVolumesPath = "$StoragePath/Volumes"
    $Volumes = Invoke-RedfishRequest $RedfishSession $GetVolumesPath | ConvertFrom-WebResponse
    for ($i = 0; $i -lt $Volumes.Members.Count; $i++) {
      $Volume = $Volumes.Members[$i]
      if ($Volume."@odata.id" -eq "$GetVolumesPath/$VolumeId") {
        return $Volume."@odata.id"
      }
    }
  }

  return $null
}

function Assert-VolumeExistence {
  <#
  .DESCRIPTION
  Assert StorageId and VolumeId Existence
  #>
  [CmdletBinding()]
  param (
    [RedfishSession]
    [parameter(Mandatory = $true, Position=0)]
    $RedfishSession,

    [String]
    [parameter(Mandatory = $true, Position=1)]
    $StorageId,

    [String]
    [parameter(Mandatory = $true, Position=2)]
    $VolumeId
  )

  Assert-StorageExistence $RedfishSession $StorageId

  $GetVolumesPath = "/Systems/$($RedfishSession.Id)/Storages/$StorageId/Volumes"
  $Volumes = Invoke-RedfishRequest $RedfishSession $GetVolumesPath | ConvertFrom-WebResponse
  for ($i = 0; $i -lt $Volumes.Members.Count; $i++) {
    $Volume = $Volumes.Members[$i]
    # $Logger.info("$($Volume | ConvertTo-Json)")
    if ($Volume."@odata.id".EndsWith("$GetVolumesPath/$VolumeId")) {
      $VolumeIdExists = $true
      break
    }
  }

  if (-not $VolumeIdExists) {
    $ErrorDetail = [String]::Format($(Get-i18n ERROR_VOLUMEID_NOT_EXISTS), $VolumeId)
    throw "[$($RedfishSession.Address)] $ErrorDetail"
  }
}

function Assert-StorageExistence {
  <#
  .DESCRIPTION
  Assert StorageId Existence
  #>
  [CmdletBinding()]
  param (
    [RedfishSession]
    [parameter(Mandatory = $true, Position=0)]
    $RedfishSession,

    [String]
    [parameter(Mandatory = $true, Position=1)]
    $StorageId
  )

  $GetStoragesPath = "/Systems/$($RedfishSession.Id)/Storages/$StorageId"
  $Response = Invoke-RedfishRequest $RedfishSession $GetStoragesPath -ContinueEvenFailed
  $StatusCode = $Response.StatusCode.value__
  if ($StatusCode -eq 404) {
    $ErrorDetail = [String]::Format($(Get-i18n ERROR_STORAGE_ID_NOT_EXISTS), $StorageId)
    throw "[$($RedfishSession.Address)] $ErrorDetail"
  }
}
