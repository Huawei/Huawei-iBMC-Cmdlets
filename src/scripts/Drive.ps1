<# NOTE: iBMC Drive module Cmdlets #>

function Get-iBMCDrives {
<#
.SYNOPSIS
Query information about the drive resource collection of a server.

.DESCRIPTION
Query information about the drive resource collection of a server.
This cmdlet works only after BIOS boot is complete when the RAID controller card supports out-of-band management or after iBMA 2.0 has been installed and started.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[][]
Returns an array of PSObject indicates all drive resources if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $Drives = Get-iBMCDrives -Session $Session
PS C:\> $Drives

Host                          : 10.1.1.2
Id                            : HDDPlaneDisk0
Name                          : Disk0
Model                         : MG04ACA400N
Revision                      : FJ3J
Status                        : @{State=Enabled; Health=OK}
CapacityBytes                 : 3999999721472
FailurePredicted              : False
Protocol                      : SATA
MediaType                     : HDD
Manufacturer                  : TOSHIBA
SerialNumber                  : 38DGK77LF77D
CapableSpeedGbs               : 6
NegotiatedSpeedGbs            : 12
PredictedMediaLifeLeftPercent :
IndicatorLED                  : Off
HotspareType                  : None
StatusIndicator               : OK
Location                      : {@{Info=Disk0; InfoFormat=DeviceName}}
DriveID                       : 0
FirmwareStatus                : Online
HoursOfPoweredUp              : 6056
PatrolState                   : DoneOrNotPatrolled
Position                      : HDDPlane
RebuildProgress               :
RebuildState                  : DoneOrNotRebuilt
SASAddress                    : {500e004aaaaaaa00, 0000000000000000}
SASSmartInformation           :
SATASmartInformation          : @{AttributeRevision=; AttributeRevisionNumber=; AttributeItemList=System.Object[]}
SpareforLogicalDrives         : {}
TemperatureCelsius            : 33
Type                          : Disk

Host                          : 10.1.1.2
Id                            : HDDPlaneDisk1
Name                          : Disk1
Model                         : MG04ACA400N
Revision                      : FJ3J
Status                        : @{State=Enabled; Health=OK}
CapacityBytes                 : 3999999721472
FailurePredicted              : False
Protocol                      : SATA
MediaType                     : HDD
Manufacturer                  : TOSHIBA
SerialNumber                  : 38DFK62PF77D
CapableSpeedGbs               : 6
NegotiatedSpeedGbs            : 12
PredictedMediaLifeLeftPercent :
IndicatorLED                  : Off
HotspareType                  : None
StatusIndicator               : OK
Location                      : {@{Info=Disk1; InfoFormat=DeviceName}}
DriveID                       : 1
FirmwareStatus                : UnconfiguredGood
HoursOfPoweredUp              : 6058
PatrolState                   : DoneOrNotPatrolled
Position                      : HDDPlane
RebuildProgress               :
RebuildState                  : DoneOrNotRebuilt
SASAddress                    : {500e004aaaaaaa01, 0000000000000000}
SASSmartInformation           :
SATASmartInformation          : @{AttributeRevision=; AttributeRevisionNumber=; AttributeItemList=System.Object[]}
SpareforLogicalDrives         : {}
TemperatureCelsius            : 33
Type                          : Disk

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCDrivesHealth
Set-iBMCDrive
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

    $Logger.info("Invoke Get iBMC drive resources function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get iBMC drive resources now"))

      $GetChassisPath = "/Chassis/$($RedfishSession.Id)"
      $Chassis = Invoke-RedfishRequest $RedfishSession $GetChassisPath | ConvertFrom-WebResponse

      $Drives = New-Object System.Collections.ArrayList
      $Chassis.Links.Drives | ForEach-Object {
        $OdataId = $_."@odata.id"
        $Drive = Invoke-RedfishRequest $RedfishSession $OdataId | ConvertFrom-WebResponse
        $CleanUp = $Drive | Clear-OdataProperties | Merge-OemProperties
        [Void] $Drives.Add($(Update-SessionAddress $RedfishSession $CleanUp))
      }
      return ,$Drives.ToArray()
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get iBMC drive resources task"))
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

function Get-iBMCDrivesHealth {
<#
.SYNOPSIS
Query health information about the Drive resources of a server.

.DESCRIPTION
Query health information about the Drive resources of a server including summary health status and every Drive controller health status.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[]
Returns PSObject indicates Drive health status of server if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $health = Get-iBMCDrivesHealth -Session $session
PS C:\> $health | fl

Host              : 10.1.1.2
Summary           : @{HealthRollup=OK}
ID#HDDPlaneDisk0  : @{Health=OK; State=; Name=Disk0}
ID#HDDPlaneDisk1  : @{Health=OK; State=; Name=Disk1}
ID#HDDPlaneDisk2  : @{Health=OK; State=; Name=Disk2}
ID#HDDPlaneDisk3  : @{Health=OK; State=; Name=Disk3}
ID#HDDPlaneDisk4  : @{Health=OK; State=; Name=Disk4}
ID#HDDPlaneDisk5  : @{Health=OK; State=; Name=Disk5}
ID#HDDPlaneDisk6  : @{Health=OK; State=; Name=Disk6}
ID#HDDPlaneDisk7  : @{Health=OK; State=; Name=Disk7}
ID#HDDPlaneDisk40 : @{Health=OK; State=; Name=Disk40}
ID#HDDPlaneDisk41 : @{Health=OK; State=; Name=Disk41}


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCDrives
Set-iBMCDrive
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

    $Logger.info("Invoke Get iBMC Drive health function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get iBMC Drive health now"))

      $GetChassisPath = "/Chassis/$($RedfishSession.Id)"
      $Chassis = Invoke-RedfishRequest $RedfishSession $GetChassisPath | ConvertFrom-WebResponse

      $Health = New-Object PSObject -Property @{
        Host    = $RedfishSession.Address;
        Summary = $Chassis.Oem.huawei.DriveSummary.Status;
      }

      $StatusPropertyOrder = @("Health", "State")
      $Chassis.Links.Drives | ForEach-Object {
        $OdataId = $_."@odata.id"
        $Drive = Invoke-RedfishRequest $RedfishSession $OdataId | ConvertFrom-WebResponse
        $Status = Copy-ObjectProperties $Drive.Status $StatusPropertyOrder
        $Status | Add-member Noteproperty "Name" $Drive.Name
        $Health | Add-Member Noteproperty "ID#$($Drive.ID)" $Status
      }

      return $Health
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get iBMC Drive health task"))
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


function Set-iBMCDrive {
<#
.SYNOPSIS
Modify properties of the specified drive of a server.

.DESCRIPTION
Modify properties of the specified drive of a server.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER DriveId
Indicates the identifier of the drive to modify.
The Id properties of "Get-iBMCDrives" cmdlet's return value represents Drive ID.

.PARAMETER State
Indicates the state of a drive.
NOTE: Before setting the drive status to JBOD, need to enable JBOD for the RAID controller first.
Drive state can be alternated between the following status:
- Online and Offline
- UnconfiguredGood and JBOD
- UnconfigureBad and UnconfiguredGood

.PARAMETER LEDState
Indicates the location indicator state of a drive.
Support value set: Off, Blinking.

.PARAMETER HotSpareType
Indicates the hot spare state of a drive.
Support value set:  None, Global, Dedicated.

.PARAMETER VolumeId
Indicates the ID of the associated volume if the drive is a dedicated hot spare drive.
The Id properties of "Get-iBMCLogicDrive" cmdlet's return value represents volume ID, example: LogicalDrive.
NOTE:
- When HotSpareType is None or Global, VolumeId is redundant.
- When HotSpareType is Dedicated, VolumeId is mandatory.

.OUTPUTS
Null
Returns null if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Set-iBMCDrive -Session $session -DriveId HDDPlaneDisk0 -State JBOD

This example shows how to set drive's state to "JBOD"

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Set-iBMCDrive -Session $session -DriveId HDDPlaneDisk0 -LEDState Blinking

This example shows how to blinking drive's led


.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Set-iBMCDrive -Session $session -DriveId HDDPlaneDisk0 -HotSpareType Dedicated -VolumeId LogicalDrive0

This example shows how to set drive's hot-spare type to "Dedicated" to volume "LogicalDrive0"

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Set-iBMCDrive -Session $session -DriveId HDDPlaneDisk0 -HotSpareType Global

This example shows how to set drive's hot-spare type to "Global"

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Set-iBMCDrive -Session $session -DriveId HDDPlaneDisk0 -HotSpareType None

This example shows how to set drive's hot-spare type to "None"


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCDrives
Get-iBMCDrivesHealth
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
    $DriveId,

    [DriveState[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $State,

    [DriveLEDState[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $LEDState,

    [HotSpareType[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $HotSpareType,

    [String[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $VolumeId
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $DriveId 'DriveId'
    $DriveIdList = Get-MatchedSizeArray $Session $DriveId

    $StateList = Get-OptionalMatchedSizeArray $Session $State
    $LEDStateList = Get-OptionalMatchedSizeArray $Session $LEDState
    $HotSpareTypeList = Get-OptionalMatchedSizeArray $Session $HotSpareType
    $VolumeIdList = Get-OptionalMatchedSizeArray $Session $VolumeId

    $Logger.info("Invoke Set iBMC drive resources function")

    $ScriptBlock = {
      param($RedfishSession, $DriveId, $Payload)

      $Logger.info($(Trace-Session $RedfishSession "Invoke Set iBMC drive now"))
      $Path = "/Chassis/$($RedfishSession.Id)/Drives/$DriveId"

      # fetch logical dirves
      if ($null -ne $Payload.Oem -and $null -ne $Payload.Oem.Huawei.SpareforLogicalDrives) {
        $VolumeOdataId = Get-VolumeOdataId $RedfishSession $Payload.Oem.Huawei.SpareforLogicalDrives
        if ($null -ne $VolumeOdataId) {
          $Payload.Oem.Huawei.SpareforLogicalDrives = @(
            @{
              "@odata.id" = $VolumeOdataId;
            }
          )
        }
      }

      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Payload | ConvertTo-Json -Depth 5)"))
      $Response = Invoke-RedfishRequest $RedfishSession $Path 'PATCH' $Payload
      Resolve-RedfishPartialSuccessResponse $RedfishSession $Response | Out-Null
      return $null
    }

    try {
      $ParametersList = New-Object System.Collections.ArrayList
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $_HotSpareType = $HotspareTypeList[$idx]
        $_VolumeId = $VolumeIdList[$idx]
        $_State = $StateList[$idx]
        $_LEDState = $LEDStateList[$idx]

        if ($_HotSpareType -eq [HotSpareType]::Dedicated -and $null -eq $_VolumeId) {
          throw $(Get-i18n ERROR_VOLUMEID_MANDATORY)
        }

        $Oem = @{
          "FirmwareStatus" = $_State;
          "SpareforLogicalDrives" = $_VolumeId;
        } | Remove-EmptyValues | Resolve-EnumValues

        $Payload = @{
          "IndicatorLED" = $_LEDState;
          "HotspareType" = $_HotSpareType;
        } | Remove-EmptyValues | Resolve-EnumValues

        if ($Oem.Count -gt 0) {
          $Payload.Oem = @{
            "Huawei" = $Oem;
          }
        }

        if ($Payload.Count -eq 0) {
          throw $(Get-i18n ERROR_NO_UPDATE_PAYLOAD)
        }

        $Parameters = @($RedfishSession, $DriveIdList[$idx], $Payload)
        [Void] $ParametersList.Add($Parameters)
      }

      $pool = New-RunspacePool $Session.Count
      $tasks = New-Object System.Collections.ArrayList
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $Logger.info($(Trace-Session $RedfishSession "Submit Set iBMC drive task"))
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
