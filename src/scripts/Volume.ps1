<# NOTE: iBMC Storage module Cmdlets #>

function Get-iBMCVolume {
<#
.SYNOPSIS
Query information about the volume resource collection of a server.

.DESCRIPTION
Query information about the volume resource collection of a server.
This cmdlet works only after BIOS boot is complete when the RAID controller card supports out-of-band management or after iBMA 2.0 has been installed and started.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER StorageId
Indicates the identifier of the storage which the volume belongs to.
The Id properties of "Get-iBMCRAIDControllers" cmdlet's return value represents Storage ID.

.OUTPUTS
PSObject[][]
Returns an array of PSObject indicates all volume resources if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $Volumes = Get-iBMCVolume -Session $Session -StorageId RAIDStorage0
PS C:\> $Volumes

Host                      : 10.1.1.2
Id                        : LogicalDrive0
Name                      : LogicalDrive0
CapacityBytes             : 1099511627776
VolumeType                : Mirrored
OptimumIOSizeBytes        : 1048576
Status                    : @{State=Enabled; Health=OK}
VolumeName                : Volume-ps
RaidControllerID          : 0
VolumeRaidLevel           : RAID1
DefaultReadPolicy         : NoReadAhead
DefaultWritePolicy        : WriteBackWithBBU
DefaultCachePolicy        : DirectIO
ConsistencyCheck          : False
SpanNumber                : 1
NumDrivePerSpan           : 2
Spans                     : {@{SpanName=Span0; Drives=System.Object[]}}
CurrentReadPolicy         : NoReadAhead
CurrentWritePolicy        : WriteBackWithBBU
CurrentCachePolicy        : DirectIO
AccessPolicy              : ReadWrite
BootEnable                : True
BGIEnable                 : True
SSDCachecadeVolume        : False
SSDCachingEnable          : False
AssociatedCacheCadeVolume : {}
DriveCachePolicy          : Unchanged
OSDriveName               :
InitializationMode        : UnInit



.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Set-iBMCVolume
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
    $StorageId
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $StorageId 'StorageId'

    $StorageIdList = Get-MatchedSizeArray $Session $StorageId

    $Logger.info("Invoke Get iBMC volume resources function")

    $ScriptBlock = {
      param($RedfishSession, $StorageId)
      $Logger.info($(Trace-Session $RedfishSession "Invoke Get iBMC volume resources now"))

      $Volumes = New-Object System.Collections.ArrayList

      Assert-StorageExistence $RedfishSession $StorageId

      $GetVolumesPath = "/Systems/$($RedfishSession.Id)/Storages/$StorageId/Volumes"
      $VolumeCollection = Invoke-RedfishRequest $RedfishSession $GetVolumesPath | ConvertFrom-WebResponse

      $ExcludeProperties = @("Operations")
      for ($i = 0; $i -lt $VolumeCollection.Members.Count; $i++) {
        $Odata = $VolumeCollection.Members[$i]
        $Path = $Odata."@odata.id"
        $Volume = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
        $CleanUp = $Volume | Clear-OdataProperties
        $Excluded = Copy-ObjectExcludes $CleanUp $ExcludeProperties
        $Merged = $Excluded | Merge-OemProperties
        [Void] $Volumes.Add($(Update-SessionAddress $RedfishSession $Merged))
      }
      return ,$Volumes.ToArray()
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $_StorageId = $StorageIdList[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get iBMC volume resources task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock @($RedfishSession, $_StorageId)))
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


function Initialize-iBMCVolume {
<#
.SYNOPSIS
Modify properties of the specified volume of a server.

.DESCRIPTION
Modify properties of the specified volume of a server.
This cmdlet works only after BIOS boot is complete when the RAID controller card supports out-of-band management or after iBMA 2.0 has been installed and started.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER StorageId
Indicates the identifier of the storage which the volume belongs to.
The Id properties of "Get-iBMCRAIDControllers" cmdlet's return value represents Storage ID.

.PARAMETER VolumeId
Indicates the identifier of the Volume to initialize.
The Id properties of "Get-iBMCVolume" cmdlet's return value represents Volume ID.

.PARAMETER InitAction
Indicates the initialization action of volume.
Available Value Set:  QuickInit, FullInit, CancelInit.
- QuickInit: perform quick initialization. No task will be created.
- FullInit: perform complete initialization. A task will be created.
- CancelInit: cancel the initialization. No task will be created.

.OUTPUTS
PSObject[]
Returns null when InitAction is "QuickInit" or "CancelInit"
while returns a async Task when InitAction is "FullInit" if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Initialize-iBMCVolume -Session $session -StorageId RAIDStorage0 `
          -VolumeId LogicalDrive0 -InitAction QuickInit

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCVolume
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
    $StorageId,

    [String[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
    $VolumeId,

    [VolumeInitAction[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 2)]
    $InitAction
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $StorageId 'StorageId'
    Assert-ArrayNotNull $VolumeId 'VolumeId'
    Assert-ArrayNotNull $InitAction 'InitAction'

    $StorageIdList = Get-MatchedSizeArray $Session $StorageId
    $VolumeIdList = Get-MatchedSizeArray $Session $VolumeId
    $InitActionList = Get-MatchedSizeArray $Session $InitAction


    $Logger.info("Invoke Set Init Mode of iBMC volume resources function")

    $ScriptBlock = {
      param($RedfishSession, $StorageId, $VolumeId, $InitAction)
      $Logger.info($(Trace-Session $RedfishSession "Invoke Set Init Mode for iBMC volume $VolumeId now"))

      Assert-VolumeExistence $RedfishSession $StorageId $VolumeId
      $VolumeOdataId = "/Systems/$($RedfishSession.Id)/Storages/$StorageId/Volumes/$VolumeId"
      $Path = "$VolumeOdataId/Actions/Volume.Initialize"
      $Payload = @{
        "Type" = $InitAction;
      } | Resolve-EnumValues

      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Payload | ConvertTo-Json)"))
      $Response = Invoke-RedfishRequest $RedfishSession $Path 'POST' $Payload | ConvertFrom-WebResponse
      if ($InitAction -eq [VolumeInitAction]::FullInit) {
        $ExtendInfo = $Response.error.'@Message.ExtendedInfo'[0]
        # if ($ExtendInfo.'@odata.id' -like '/redfish/v1/TaskService/Tasks/*') {
          return $ExtendInfo
        # }
      } else {
        return $null
      }
    }

    try {
      $ParametersList = New-Object System.Collections.ArrayList
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $_StorageId = $StorageIdList[$idx]
        $_VolumeId = $VolumeIdList[$idx]
        $_InitAction = $InitActionList[$idx]
        $Parameters = @($RedfishSession, $_StorageId, $_VolumeId, $_InitAction)
        [Void] $ParametersList.Add($Parameters)
      }

      $pool = New-RunspacePool $Session.Count
      $tasks = New-Object System.Collections.ArrayList
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $Logger.info($(Trace-Session $RedfishSession "Submit Set Init Mode of iBMC volume task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $ParametersList[$idx]))
      }

      # Only when InitAction is "FullInit", a task is returned
      $RedfishTasks = Get-AsyncTaskResults $tasks
      $PendingTasks = $RedfishTasks | Where-Object { $_ -ne $null }
      if ($null -ne $PendingTasks -and $PendingTasks.Count -gt 0) {
        $Results = New-Object System.Collections.ArrayList
        $Processed = Wait-RedfishTasks $pool $Session $PendingTasks -ShowProgress
        $index = 0
        $RedfishTasks | ForEach-Object {
          if ($null -eq $_) {
            [Void] $Results.Add($null)
          } else {
            [Void] $Results.Add($Processed[$index])
            $index = $index + 1
          }
        }
        return ,$Results.ToArray()
      } else {
        return ,$RedfishTasks
      }
    }
    finally {
      Close-Pool $pool
    }
  }

  end {
  }
}

function Remove-iBMCVolume {
<#
.SYNOPSIS
Delete a specified volume of a server.

.DESCRIPTION
Delete a specified volume of a server.
This cmdlet works only after BIOS boot is complete when the RAID controller card supports out-of-band management or after iBMA 2.0 has been installed and started.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER StorageId
Indicates the identifier of the storage which the volume belongs to.
The Id properties of "Get-iBMCRAIDControllers" cmdlet's return value represents Storage ID.

.PARAMETER VolumeId
Indicates the identifier of the volume to remove.
The Id properties of "Get-iBMCVolume" cmdlet's return value represents Storage ID.

.OUTPUTS
PSObject[]
Returns the remove volume task array if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Remove-iBMCVolume -Session $session -StorageId RAIDStorage0 -VolumeId LogicDrive0

Host         : 10.1.1.2
Id           : 3
Name         : volume deletion task
ActivityName : [10.1.1.2] volume deletion task
TaskState    : Completed
StartTime    : 2019-01-06T22:48:09+00:00
EndTime      : 2019-01-06T22:48:13+00:00
TaskStatus   : OK
TaskPercent  :


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCVolume
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
    $StorageId,

    [String[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
    $VolumeId
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $StorageId 'StorageId'
    Assert-ArrayNotNull $VolumeId 'VolumeId'

    $VolumeIdList = Get-MatchedSizeArray $Session $VolumeId
    $StorageIdList = Get-MatchedSizeArray $Session $StorageId

    $Logger.info("Invoke Delete iBMC volume resources function")

    $ScriptBlock = {
      param($RedfishSession, $StorageId, $VolumeId)
      $Logger.info($(Trace-Session $RedfishSession "Invoke Delete iBMC volume '$VolumeId' now"))

      Assert-VolumeExistence $RedfishSession $StorageId $VolumeId
      $VolumeOdataId = "/Systems/$($RedfishSession.Id)/Storages/$StorageId/Volumes/$VolumeId"
      $Task = Invoke-RedfishRequest $RedfishSession $VolumeOdataId 'DELETE' | ConvertFrom-WebResponse
      return $Task
    }

    try {
      $pool = New-RunspacePool $Session.Count
      $tasks = New-Object System.Collections.ArrayList
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $_StorageId = $StorageIdList[$idx]
        $_VolumeId = $VolumeIdList[$idx]
        $Parameters = @($RedfishSession, $_StorageId, $_VolumeId)
        $Logger.info($(Trace-Session $RedfishSession "Submit Delete iBMC volume task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $Parameters))
      }

      $RedfishTasks = Get-AsyncTaskResults $tasks
      return ,$(Wait-RedfishTasks $pool $Session $RedfishTasks -ShowProgress)
    }
    finally {
      Close-Pool $pool
    }
  }

  end {
  }
}

function Add-iBMCVolume {
<#
.SYNOPSIS
Create a new volume for a server.

.DESCRIPTION
Create a new volume for a server.
This cmdlet works only after BIOS boot is complete when the RAID controller card supports out-of-band management or after iBMA 2.0 has been installed and started.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER StorageId
Indicates the identifier of the storage which the volume will be attached to.
The Id properties of "Get-iBMCRAIDControllers" cmdlet's return value represents Storage ID.

.PARAMETER RAIDLevel
Indicates the RAID level of volume.
Available Value Set: RAID0, RAID1, RAID5, RAID6, RAID10, RAID50, RAID60.

Notes:
- This parameter must be RAID0 or RAID1 when creating a CacheCade volume.
- You do not need to set this parameter when adding a volume to an existing drive group

.PARAMETER Drives
Indicates the member disk list.
example: $Drives = ,@(DriveID-1, DriveID-2, ..)

Notes:
- All the member disks must have the same type of interfaces and storage media.
- When adding a volume to an existing drive group, enter the ID of any drive of the drive group.
- The DriveID is represented by the Id properties of "Get-iBMCDrives" cmdlet's return value.
- The FirmwareStatus property of the drive should be "UnconfiguredGood".

.PARAMETER CacheCade
Indicates whether it is a CacheCade volume.
Support values are powershell boolean value: $true(1), $false(0).
- Set it to $true when creating a CacheCad volume.
- Set it to $false when the volume to be created is not a CacheCade volume

.PARAMETER VolumeName
Indicates the Volume name.
It is a string of up to 15 bytes.
Value range: ASCII code corresponding to 0x20 to 0x7E.

.PARAMETER StripSize
Indicates the stripe size of volume.

Note: This parameter is redundant when creating a CacheCade volume.

.PARAMETER CapacityMB
Indicates the Capacity size of volume. The size unit is MB.

Note: This parameter is redundant when creating a CacheCade volume.

.PARAMETER DefaultReadPolicy
Indicates the default read policy of the volume.
Available Value Set: NoReadAhead, ReadAhead.
- ReadAhead: The RAID controller pre-reads sequential data or the data predicted to be used and saves it in the cache.
- NoReadAhead: disables the Read Ahead feature.

Note: This parameter is redundant when creating a CacheCade volume.

.PARAMETER DefaultWritePolicy
Indicates the default write policy of the volume.
Available Value Set: WriteThrough, WriteBackWithBBU, WriteBack.
- WriteThrough: After the drive receives all data, the controller sends the host a message indicating that data transmission is complete.
- WriteBackWithBBU: When no battery backup unit (BBU) is configured or the configured BBU is faulty, the RAID controller automatically switches to the WriteThrough mode.
- WriteBack: After the controller cache receives all data, the controller sends the host a message indicating that data transmission is complete.

NOTE: This parameter cannot be WriteBack when a CacheCade volume is created.

.PARAMETER DefaultCachePolicy
Indicates the default cache policy of the volume.
- CachedIO: All the read and write requests are processed by the cache of the RAID controller.
            Select this value only when CacheCade 1.1 is configured.
- DirectIO: This value has different meanings in read and write scenarios.
  * In read scenarios, data is directly read from physical drives.
    (If Read Policy is set to Read Ahead, data read requests are processed by the cache of the RAID controller.)
  * In write scenarios, data write requests are processed by the cache of the RAID controller.
    (If Write Policy is set to WriteThrough, data is directly written to physical drives.)

Note: This parameter is redundant when creating a CacheCade volume.

.PARAMETER AccessPolicy
Indicates the volume access policy.
Available Value Set: ReadWrite, ReadOnly, Blocked.
- ReadWrite: Read and write operations are allowed.
- ReadOnly: It is read-only.
- Blocked: Access is denied.

Note: This parameter is redundant when creating a CacheCade volume.

.PARAMETER DriveCachePolicy
Indicates the cache policy for member disks.
Available Value Set: Unchanged, Enabled, Disabled.
- Unchanged: uses the default cache policy.
- Enabled: writes data to the cache before writing data to the hard drive.
           This option improves data write performance.
           However, data will be lost if there is no protection mechanism against power failures.
- Disabled: writes data to a hard drive without caching the data.
            Data is not lost if power failures occur.

Note: This parameter is redundant when creating a CacheCade volume.

.PARAMETER InitMode
Indicates the volume initialization mode.
Available Value Set: UnInit, FullInit, CancelInit.
- UnInit: Initialization is not performed.
- QuickInit: writes zeros to the first and last 10 MB of the logical drive.
             Then, the logical drive status changes to Optimal.
- FullInit: initializes the logical drive. Before the initialization is complete,
            the logical drive status is initialization.

Note: This parameter is redundant when creating a CacheCade volume.

.PARAMETER SpanNumber
Indicates the number of spans of the volume.
- Set this parameter to 1 when creating a RAID0, RAID1, RAID5, or RAID6 array.
- Set this parameter to a value from 2 to 8 when creating a RAID10, RAID50, or RAID60 array.

NOTE: You do not need to set this parameter when creating a CacheCade volume or adding a volume to an existing drive group.

.OUTPUTS
PSObject[]
Returns the add volume task array if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $Drives = ,@(0, 1)
PS C:\> $Volumes = Add-iBMCVolume -Session $session -StorageId RAIDStorage0 `
          -CacheCade $false -RAIDLevel RAID1 -Drives $Drives

Host         : 10.1.1.2
Id           : 4
Name         : volume creation task
ActivityName : [10.1.1.2] volume creation task
TaskState    : Completed
StartTime    : 2019-01-07T09:37:15+00:00
EndTime      : 2019-01-07T09:37:29+00:00
TaskStatus   : OK
TaskPercent  :

This example show how to create a none CacheCade volume with only required options

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $Drives = ,@(0, 1)
PS C:\> $Volumes = Add-iBMCVolume -Session $session -StorageId RAIDStorage0 `
          -CacheCade $false -RAIDLevel RAID1 -Drives $Drives `
          -VolumeName Volume2 -StripSize Size1MB -CapacityMB 1048576 -DefaultCachePolicy DirectIO `
          -AccessPolicy ReadWrite -InitMode QuickInit -SpanNumber 1 -DriveCachePolicy Unchanged `
          -DefaultWritePolicy WriteBackWithBBU -DefaultReadPolicy NoReadAhead

Host         : 10.1.1.2
Id           : 4
Name         : volume creation task
ActivityName : [10.1.1.2] volume creation task
TaskState    : Completed
StartTime    : 2019-01-07T09:37:15+00:00
EndTime      : 2019-01-07T09:37:29+00:00
TaskStatus   : OK
TaskPercent  :

This example show how to create a none CacheCade volume with all options

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $Drives = ,@(0, 1)
PS C:\> $Volumes = Add-iBMCVolume -Session $session -StorageId RAIDStorage0 `
          -CacheCade $true -RAIDLevel RAID1 -Drives $Drives -DefaultWritePolicy WriteBackWithBBU

Host         : 10.1.1.2
Id           : 4
Name         : volume creation task
ActivityName : [10.1.1.2] volume creation task
TaskState    : Completed
StartTime    : 2019-01-07T09:37:15+00:00
EndTime      : 2019-01-07T09:37:29+00:00
TaskStatus   : OK
TaskPercent  :

This example show how to create a CacheCade volume


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCVolume
Connect-iBMC
Disconnect-iBMC
#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $Session,

    [String[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $StorageId,

    [RAIDLevel[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $RAIDLevel,

    [int[][]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $Drives,

    [bool[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $CacheCade,

    [string[]]
    [ValidateLength(1, 15)]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $VolumeName,

    [StripSize[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $StripSize,

    [int[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $CapacityMB,

    [DefaultReadPolicy[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $DefaultReadPolicy,

    [DefaultWritePolicy[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $DefaultWritePolicy,

    [DefaultCachePolicy[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $DefaultCachePolicy,

    [AccessPolicy[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $AccessPolicy,

    [DriveCachePolicy[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $DriveCachePolicy,

    [VolumeInitMode[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $InitMode,

    [int[]]
    [ValidateRange(1, 8)]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $SpanNumber
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $StorageId 'StorageId'
    Assert-ArrayNotNull $RAIDLevel 'RAIDLevel'
    Assert-ArrayNotNull $Drives 'Drives'

    $StorageIdList = Get-MatchedSizeArray $Session $StorageId
    $RAIDLevelList = Get-MatchedSizeArray $Session $RAIDLevel
    $DrivesList = Get-OptionalMatchedSizeMatrix $Session $Drives $null 'Session' 'Drives'
    $CacheCadeList = Get-OptionalMatchedSizeArray $Session $CacheCade

    $VolumeNameList = Get-OptionalMatchedSizeArray $Session $VolumeName
    $StripSizeList = Get-OptionalMatchedSizeArray $Session $StripSize
    $CapacityMBList = Get-OptionalMatchedSizeArray $Session $CapacityMB
    $DefaultReadPolicyList = Get-OptionalMatchedSizeArray $Session $DefaultReadPolicy
    $DefaultWritePolicyList = Get-OptionalMatchedSizeArray $Session $DefaultWritePolicy
    $DefaultCachePolicyList = Get-OptionalMatchedSizeArray $Session $DefaultCachePolicy
    $AccessPolicyList = Get-OptionalMatchedSizeArray $Session $AccessPolicy
    $DriveCachePolicyList = Get-OptionalMatchedSizeArray $Session $DriveCachePolicy
    $InitModeList = Get-OptionalMatchedSizeArray $Session $InitMode
    $SpanNumberList = Get-OptionalMatchedSizeArray $Session $SpanNumber

    $Logger.info("Invoke Create new iBMC volume resources function")

    $ScriptBlock = {
      param($RedfishSession, $StorageId, $Payload)
      $Logger.info($(Trace-Session $RedfishSession "Invoke Create new iBMC volume for '$StorageId' now"))
      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Payload | ConvertTo-Json -Depth 3)"))
      $Path = "/Systems/$($RedfishSession.Id)/Storages/$StorageId/Volumes"
      $Task = Invoke-RedfishRequest $RedfishSession $Path 'POST' $Payload | ConvertFrom-WebResponse
      return $Task
    }

    try {
      $ParametersList = New-Object System.Collections.ArrayList
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $_StorageId = $StorageIdList[$idx]

        $Oem = @{
          "CreateCacheCadeFlag" = $CacheCadeList[$idx];
          "VolumeRaidLevel" = $RAIDLevelList[$idx];
          "Drives" = $DrivesList[$idx];
          "VolumeName" = $VolumeNameList[$idx];
          "DefaultReadPolicy" = $DefaultReadPolicyList[$idx];
          "DefaultWritePolicy" = $DefaultWritePolicyList[$idx];
          "DefaultCachePolicy" = $DefaultCachePolicyList[$idx];
          "SpanNumber" = $SpanNumberList[$idx];
          "AccessPolicy" = $AccessPolicyList[$idx];
          "DriveCachePolicy" = $DriveCachePolicyList[$idx];
          "InitializationMode" = $InitModeList[$idx];
        } | Resolve-EnumValues | Remove-EmptyValues

        $Payload = @{
          "Oem" = @{
            "Huawei" = $Oem;
          };
        }

        if ($null -ne $CapacityMBList[$idx]) {
          $Payload.CapacityBytes = $CapacityMBList[$idx] * 1024 * 1024
        }

        if ($null -ne $StripSizeList[$idx]) {
          $Payload.OptimumIOSizeBytes = $StripSizeList[$idx]
        }

        $Parameters = @($RedfishSession, $_StorageId, $Payload)
        [Void] $ParametersList.Add($Parameters)
      }


      $pool = New-RunspacePool $Session.Count
      $tasks = New-Object System.Collections.ArrayList
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $Logger.info($(Trace-Session $RedfishSession "Submit Create new iBMC volume task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $ParametersList[$idx]))
      }

      $RedfishTasks = Get-AsyncTaskResults $tasks
      return ,$(Wait-RedfishTasks $pool $Session $RedfishTasks -ShowProgress)
    }
    finally {
      Close-Pool $pool
    }
  }

  end {
  }
}


function Set-iBMCVolume {
<#
.SYNOPSIS
Modify properties of the specified volume.

.DESCRIPTION
Modify properties of the specified volume.
This cmdlet works only after BIOS boot is complete when the RAID controller card supports out-of-band management or after iBMA 2.0 has been installed and started.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER StorageId
Indicates the identifier of the storage which the volume belongs to.
The Id properties of "Get-iBMCRAIDControllers" cmdlet's return value represents Storage ID.

.PARAMETER VolumeId
Indicates the identifier of the volume to be modified.
The Id properties of "Get-iBMCRAIDControllers" cmdlet's return value represents Storage ID.

.PARAMETER VolumeName
Indicates the Volume name.
It is a string of up to 15 bytes.
Value range: ASCII code corresponding to 0x20 to 0x7E.

.PARAMETER DefaultReadPolicy
Indicates the default read policy of the volume.
Available Value Set: NoReadAhead, ReadAhead.
- ReadAhead: The RAID controller pre-reads sequential data or the data predicted to be used and saves it in the cache.
- NoReadAhead: disables the Read Ahead feature.

.PARAMETER DefaultWritePolicy
Indicates the default write policy of the volume.
Available Value Set: WriteThrough, WriteBackWithBBU, WriteBack.
- WriteThrough: After the drive receives all data, the controller sends the host a message indicating that data transmission is complete.
- WriteBackWithBBU: When no battery backup unit (BBU) is configured or the configured BBU is faulty, the RAID controller automatically switches to the WriteThrough mode.
- WriteBack: After the controller cache receives all data, the controller sends the host a message indicating that data transmission is complete.

.PARAMETER DefaultCachePolicy
Indicates the default cache policy of the volume.
- CachedIO: All the read and write requests are processed by the cache of the RAID controller.
            Select this value only when CacheCade 1.1 is configured.
- DirectIO: This value has different meanings in read and write scenarios.
  * In read scenarios, data is directly read from physical drives.
    (If Read Policy is set to Read Ahead, data read requests are processed by the cache of the RAID controller.)
  * In write scenarios, data write requests are processed by the cache of the RAID controller.
    (If Write Policy is set to WriteThrough, data is directly written to physical drives.)

.PARAMETER AccessPolicy
Indicates the volume access policy.
Available Value Set: ReadWrite, ReadOnly, Blocked.
- ReadWrite: Read and write operations are allowed.
- ReadOnly: It is read-only.
- Blocked: Access is denied.

.PARAMETER DriveCachePolicy
Indicates the cache policy for member disks.
Available Value Set: Unchanged, Enabled, Disabled.
- Unchanged: uses the default cache policy.
- Enabled: writes data to the cache before writing data to the hard drive.
            This option improves data write performance.
            However, data will be lost if there is no protection mechanism against power failures.
- Disabled: writes data to a hard drive without caching the data.
            Data is not lost if power failures occur.

.PARAMETER BootEnabled
Indicates whether the volume is the boot device.
Support values are powershell boolean value: $true(1), $false(0).

.PARAMETER BGIEnabled
Indicates whether background initialization is enabled.
Support values are powershell boolean value: $true(1), $false(0).

.PARAMETER SSDCachingEnabled
Indicates whether the CacheCade volume is used as the cache.
Support values are powershell boolean value: $true(1), $false(0).

.OUTPUTS
Null
Returns null if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Set-iBMCVolume -Session $session -StorageId RAIDStorage0 -VolumeId LogicalDrive0 -VolumeName Volume1 `
          -DefaultCachePolicy CachedIO -DefaultWritePolicy WriteBack -DefaultReadPolicy ReadAhead `
          -AccessPolicy ReadOnly -DriveCachePolicy Enabled `
          -BootEnabled $true -BGIEnabled $true


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCVolume
Connect-iBMC
Disconnect-iBMC
#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $Session,

    [String[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $StorageId,

    [String[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $VolumeId,

    [string[]]
    [ValidateLength(1, 15)]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $VolumeName,

    [DefaultReadPolicy[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $DefaultReadPolicy,

    [DefaultWritePolicy[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $DefaultWritePolicy,

    [DefaultCachePolicy[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $DefaultCachePolicy,

    [AccessPolicy[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $AccessPolicy,

    [DriveCachePolicy[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $DriveCachePolicy,

    [bool[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $BootEnabled,

    [bool[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $BGIEnabled,

    [bool[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $SSDCachingEnabled
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $StorageId 'StorageId'
    Assert-ArrayNotNull $VolumeId 'VolumeId'

    $StorageIdList = Get-MatchedSizeArray $Session $StorageId
    $VolumeIdList = Get-MatchedSizeArray $Session $VolumeId

    $VolumeNameList = Get-OptionalMatchedSizeArray $Session $VolumeName
    $DefaultReadPolicyList = Get-OptionalMatchedSizeArray $Session $DefaultReadPolicy
    $DefaultWritePolicyList = Get-OptionalMatchedSizeArray $Session $DefaultWritePolicy
    $DefaultCachePolicyList = Get-OptionalMatchedSizeArray $Session $DefaultCachePolicy
    $AccessPolicyList = Get-OptionalMatchedSizeArray $Session $AccessPolicy
    $DriveCachePolicyList = Get-OptionalMatchedSizeArray $Session $DriveCachePolicy
    $BootEnabledList = Get-OptionalMatchedSizeArray $Session $BootEnabled
    $BGIEnabledList = Get-OptionalMatchedSizeArray $Session $BGIEnabled
    $SSDCachingEnabledList = Get-OptionalMatchedSizeArray $Session $SSDCachingEnabled

    $Logger.info("Invoke Set iBMC volume resources function")

    $ScriptBlock = {
      param($RedfishSession, $StorageId, $VolumeId, $Payload)
      $Logger.info($(Trace-Session $RedfishSession "Invoke Set iBMC volume for '$StorageId' now"))

      Assert-VolumeExistence $RedfishSession $StorageId $VolumeId
      $VolumeOdataId = "/Systems/$($RedfishSession.Id)/Storages/$StorageId/Volumes/$VolumeId"
      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Payload | ConvertTo-Json -Depth 3)"))
      $Response = Invoke-RedfishRequest $RedfishSession $VolumeOdataId 'PATCH' $Payload
      Resolve-RedfishPartialSuccessResponse $RedfishSession $Response | Out-Null
      return $null
      # $TaskOdataId = $Response.Operations[0].AssociatedTask."@odata.id"
      # return $(Invoke-RedfishRequest $RedfishSession $TaskOdataId | ConvertFrom-WebResponse)
    }

    try {
      $ParametersList = New-Object System.Collections.ArrayList
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $_StorageId = $StorageIdList[$idx]
        $_VolumeId = $VolumeIdList[$idx]

        $Oem = @{
          "VolumeName" = $VolumeNameList[$idx];
          "DefaultReadPolicy" = $DefaultReadPolicyList[$idx];
          "DefaultWritePolicy" = $DefaultWritePolicyList[$idx];
          "DefaultCachePolicy" = $DefaultCachePolicyList[$idx];
          "AccessPolicy" = $AccessPolicyList[$idx];
          "DriveCachePolicy" = $DriveCachePolicyList[$idx];
          "BootEnable" = $BootEnabledList[$idx];
          "BGIEnable" = $BGIEnabledList[$idx];
          "SSDCachingEnable" = $SSDCachingEnabledList[$idx];
        } | Remove-EmptyValues | Resolve-EnumValues

        if ($Oem.Count -eq 0) {
          throw $(Get-i18n ERROR_NO_UPDATE_PAYLOAD)
        }

        $Payload = @{
          "Oem" = @{
            "Huawei" = $Oem;
          };
        }

        $Parameters = @($RedfishSession, $_StorageId, $_VolumeId, $Payload)
        [Void] $ParametersList.Add($Parameters)
      }

      $pool = New-RunspacePool $Session.Count
      $tasks = New-Object System.Collections.ArrayList
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $Logger.info($(Trace-Session $RedfishSession "Submit Set iBMC volume task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $ParametersList[$idx]))
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
