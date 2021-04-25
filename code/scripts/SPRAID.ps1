# Copyright (C) 2020 Huawei Technologies Co., Ltd. All rights reserved.	
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the MIT License		

# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# MIT License for more detail

<# NOTE: iBMC SP RAID Storage module Cmdlets #>

function Get-iBMCSPRAIDSetting {
<#
.SYNOPSIS
Query the current RAID setting resource collection of the SP service.

.DESCRIPTION
Query the current RAID setting resource collection of the SP service.
This cmdlet only supports manage server with single "LSI3008" RAID card.
Note: Only the V5 servers with the BIOS version later than 0.39 and the SP version 113 or later support this function.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[][]
Returns an array of PSObject indicates current RAID setting resources of SP Service if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> Export-iBMCSPRAIDSetting -Session $Session
PS C:\> Set-iBMCSPService -Session $Session -StartEnabled $true -SysRestartDelaySeconds 60
PS C:\> Set-iBMCServerPower -Session $Session -ResetType ForceRestart
PS C:\> $Setting = Get-iBMCSPRAIDSetting -Session $Session
PS C:\> $Setting

Host           : 192.168.1.1
Id             : mainboardRaidCard1
Name           : SP RAID Current Configuration
CardModel      : LSI3008
DeviceName     : RAIDCard1
GlobalHotSpare : {5, 6}
Location       : mainboard
DriveGroupList : {@{VolumeList=System.Object[]; VolumeRaidLevel=RAID1; Drives=System.Object[]}}

This example shows how to get SP-RAID setting from startup.
It contains several steps:
1. Export SP-RAID setting
2. Enable SP-Service
3. Restart Server (may take a long time, please be patience)
4. Get SP-RAID setting

If step 1,2,3 has be executed before, "Get-iBMCSPRAIDSetting" could be executed directly.

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Export-iBMCSPRAIDSetting
Set-iBMCSPRAIDSetting
Clear-iBMCSPRAIDSetting
Add-iBMCSPRAIDVolume
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

    $Logger.info("Invoke Get iBMC RAID setting resources of SPService function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get iBMC RAID setting resources of SPService now"))

      $GetSPRAIDPath = "/Managers/$($RedfishSession.Id)/SPService/SPRAIDCurrentConfigurations"
      $Collection = Invoke-RedfishRequest $RedfishSession $GetSPRAIDPath | ConvertFrom-WebResponse
      $Setting = New-Object System.Collections.ArrayList
      $Collection.Members | ForEach-Object {
        $Path = $_."@odata.id"
        $Config = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
        $CleanUp = $Config | Clear-OdataProperties
        [Void] $Setting.Add($(Update-SessionAddress $RedfishSession $CleanUp))
      }
      return , $Setting.ToArray()
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get iBMC RAID setting resources of SPService task"))
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


function Export-iBMCSPRAIDSetting {
<#
.SYNOPSIS
Triggering the Export of the current RAID setting of the SP service.

.DESCRIPTION
Triggering the Export of the current RAID setting of the SP service.
This cmdlet only supports manage server with single "LSI3008" RAID card.
Note: Only the V5 servers with the BIOS version later than 0.39 and the SP version 113 or later support this function.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
Null
Returns null if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> Export-iBMCSPRAIDSetting -Session $Session


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCSPRAIDSetting
Set-iBMCSPRAIDSetting
Clear-iBMCSPRAIDSetting
Add-iBMCSPRAIDVolume
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

    $Logger.info("Invoke Export current SP RAID setting of SPService function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Export current SP RAID setting of SPService now"))
      $Path = "/Managers/$($RedfishSession.Id)/SPService/Actions/SPService.ExportSPRAIDConfigurations"
      Invoke-RedfishRequest $RedfishSession $Path 'POST' $null | Out-Null
      return $null
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Export current SP RAID setting of SPService task"))
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


function Clear-iBMCSPRAIDSetting {
<#
.SYNOPSIS
Clear current RAID setting of the SP service.

.DESCRIPTION
Clear current RAID setting of the SP service.
This cmdlet only supports manage server with single "LSI3008" RAID card.
Note: Only the V5 servers with the BIOS version later than 0.39 and the SP version 113 or later support this function.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER Location
Indicates the location information of the RAID controller card. For example: mainboard.

.PARAMETER DeviceName
Indicates the Silkscreen of the RAID controller card. For example: RAIDStorage0.

.PARAMETER CardModel
Indicates the RAID controller card mode.
Currently, Only 'LSI3008' is support.


.OUTPUTS
Null
Returns null if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> Clear-iBMCSPRAIDSetting $session -Location mainboard -DeviceName RAIDStorage1
PS C:\>
PS C:\> Export-iBMCSPRAIDSetting -Session $Session
PS C:\> Set-iBMCSPService -Session $Session -StartEnabled $true -SysRestartDelaySeconds 60
PS C:\> Set-iBMCServerPower -Session $Session -ResetType ForceRestart


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCSPRAIDSetting
Export-iBMCSPRAIDSetting
Set-iBMCSPRAIDSetting
Add-iBMCSPRAIDVolume
Connect-iBMC
Disconnect-iBMC
#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session,

    [String[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $Location,

    [String[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $DeviceName,

    [RAIDCardModel[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $CardModel = [RAIDCardModel]::LSI3008
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $Location 'Location'
    Assert-ArrayNotNull $DeviceName 'DeviceName'
    Assert-ArrayNotNull $CardModel 'CardModel'

    $LocationList = Get-MatchedSizeArray $Session $Location "Session" "Location"
    $DeviceNameList = Get-MatchedSizeArray $Session $DeviceName "Session" "DeviceName"
    $CardModelList = Get-MatchedSizeArray $Session $CardModel "Session" "CardModel"

    $Logger.info("Invoke Clear current SP RAID setting of SPService function")

    $ScriptBlock = {
      param($RedfishSession, $Payload)

      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Clear current SP RAID setting of SPService now"))
      $Path = "/Managers/$($RedfishSession.Id)/SPService/SPRAID"
      $Payload.ClearConfig = $true
      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Payload | ConvertTo-Json)"))
      Invoke-RedfishRequest $RedfishSession $Path 'POST' $Payload | Out-Null
      return $null
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Id = "$($LocationList[$idx])$($DeviceNameList[$idx])"
        $Payload = @{
          "Id"         = $Id;
          "CardModel"  = $CardModelList[$idx];
          "Location"   = $LocationList[$idx];
          "DeviceName" = $DeviceNameList[$idx];
        } | Resolve-EnumValues
        $Logger.info($(Trace-Session $RedfishSession "Submit Clear current SP RAID setting of SPService task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock @($RedfishSession, $Payload)))
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

function Set-iBMCSPRAIDSetting {
<#
.SYNOPSIS
Modify current RAID setting of the SP service.

.DESCRIPTION
Modify current RAID setting of the SP service.
This cmdlet only supports manage server with single "LSI3008" RAID card.
Note: Only the V5 servers with the BIOS version later than 0.39 and the SP version 113 or later support this function.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER Location
Indicates the location information of the RAID controller card. For example: mainboard.

.PARAMETER DeviceName
Indicates the Silkscreen of the RAID controller card. For example: RAIDStorage0.

.PARAMETER HotSpareDrives
Indicates the member disk list.
example: $HotSpareDrives = ,@(DriveID-1, DriveID-2, ..)

Notes:
- All the member disks must have the same type of interfaces and storage media.
- When adding a volume to an existing drive group, enter the ID of any drive of the drive group.
- The DriveID is represented by the Id properties of "Get-iBMCDrives" cmdlet's return value.

.PARAMETER CardModel
Indicates the RAID controller card model.
Currently, Only 'LSI3008' is support.


.OUTPUTS
Null
Returns null if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $HotSpareDrives = ,@(5, 6)
PS C:\> Set-iBMCSPRAIDSetting $session -Location mainboard -DeviceName RAIDStorage1 `
          -HotSpareDrives $HotSpareDrives
PS C:\>
PS C:\> Export-iBMCSPRAIDSetting -Session $Session
PS C:\> Set-iBMCSPService -Session $Session -StartEnabled $true -SysRestartDelaySeconds 60
PS C:\> Set-iBMCServerPower -Session $Session -ResetType ForceRestart

Host           : 192.168.1.1
Id             : mainboardRaidCard1
Name           : SP RAID Current Configuration
CardModel      : LSI3008
DeviceName     : RAIDCard1
GlobalHotSpare : {5, 6}
Location       : mainboard
DriveGroupList : {@{VolumeList=System.Object[]; VolumeRaidLevel=RAID1; Drives=System.Object[]}}

This example shows how to modify SP-RAID setting.
It contains several steps:
1. Modify SP-RAID setting
2. Export SP-RAID setting
3. Enable SP-Service
4. Restart Server (may take a long time, please be patience)

Step 1 will update SP-RAID setting, while step 2,3,4 will make it effect.


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Connect-iBMC
Disconnect-iBMC
#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session,

    [String[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $Location,

    [String[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $DeviceName,

    [RAIDCardModel[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $CardModel = @([RAIDCardModel]::LSI3008),

    [int[][]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $HotSpareDrives
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $Location 'Location'
    Assert-ArrayNotNull $DeviceName 'DeviceName'
    Assert-ArrayNotNull $CardModel 'CardModel'
    Assert-ArrayNotNull $HotSpareDrives 'HotSpareDrives'

    $LocationList = Get-MatchedSizeArray $Session $Location "Session" "Location"
    $DeviceNameList = Get-MatchedSizeArray $Session $DeviceName "Session" "DeviceName"
    $CardModelList = Get-MatchedSizeArray $Session $CardModel "Session" "CardModel"
    $HotSpareDrivesList = Get-OptionalMatchedSizeMatrix $Session $HotSpareDrives $null 'Session' 'HotSpareDrives'

    $Logger.info("Invoke Clear current SP RAID setting of SPService function")

    $ScriptBlock = {
      param($RedfishSession, $Payload)

      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Clear current SP RAID setting of SPService now"))
      $Path = "/Managers/$($RedfishSession.Id)/SPService/SPRAID"
      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Payload | ConvertTo-Json)"))
      Invoke-RedfishRequest $RedfishSession $Path 'POST' $Payload | Out-Null
      return $null
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Id = "$($LocationList[$idx])$($DeviceNameList[$idx])"
        $Payload = @{
          "Id"         = $Id;
          "CardModel"  = $CardModelList[$idx];
          "Location"   = $LocationList[$idx];
          "DeviceName" = $DeviceNameList[$idx];
          "GlobalHotSpare" = $HotSpareDrivesList[$idx];
        } | Resolve-EnumValues
        $Logger.info($(Trace-Session $RedfishSession "Submit Clear current SP RAID setting of SPService task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock @($RedfishSession, $Payload)))
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

function Add-iBMCSPRAIDVolume {
<#
.SYNOPSIS
Add new volume for current RAID setting of the SP service.

.DESCRIPTION
Add new volume for current RAID setting of the SP service.
This cmdlet only supports manage server with single "LSI3008" RAID card.
Note: Only the V5 servers with the version BIOS>=0.39, SP>=113, BMC>=3.20 support this function.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER Location
Indicates the location information of the RAID controller card. For example: mainboard.

.PARAMETER DeviceName
Indicates the Silkscreen of the RAID controller card. For example: RAIDStorage0.

.PARAMETER CardModel
Indicates the RAID controller card mode.
Currently, Only 'LSI3008' is support.

.PARAMETER RAIDLevel
Indicates the RAID level of volume.
Available Value Set: RAID0, RAID1, RAID10, RAID1E.

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

.PARAMETER BootEnabled
Indicates whether the volume is the boot device.
Support values are powershell boolean value: $true(1), $false(0).

.PARAMETER VolumeName
Indicates the Volume name.
It is a string of up to 15 bytes.
Value range: ASCII code corresponding to 0x20 to 0x7E.

.PARAMETER CapacityMB
Indicates the Capacity size of volume. The size unit is MB.

Note: This parameter is redundant when creating a CacheCade volume.


.OUTPUTS
Null
Returns null if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $Drives = ,@(0, 1)
PS C:\> $VolumeName = "Volume1"
PS C:\> Add-iBMCSPRAIDVolume $session -Location mainboard -DeviceName RAIDCard1 `
         -VolumeName $VolumeName -CapacityMB 1048576 -BootEnabled $true `
         -RAIDLevel RAID1 -Drives $Drives
PS C:\>
PS C:\> Export-iBMCSPRAIDSetting -Session $Session
PS C:\> Set-iBMCSPService -Session $Session -StartEnabled $true -SysRestartDelaySeconds 60
PS C:\> Set-iBMCServerPower -Session $Session -ResetType ForceRestart

Host           : 192.168.1.1
Id             : mainboardRaidCard1
Name           : SP RAID Current Configuration
CardModel      : LSI3008
DeviceName     : RAIDCard1
GlobalHotSpare : {5, 6}
Location       : mainboard
DriveGroupList : {@{VolumeList=System.Object[]; VolumeRaidLevel=RAID1; Drives=System.Object[]}}

This example shows how to add a volume for SP-RAID.
It contains several steps:
1. Add a new volume
2. Export SP-RAID setting
3. Enable SP-Service
4. Restart Server (may take a long time, please be patience)

Step 1 will config a new volume (not effect), while step 2,3,4 will make it effect.

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCSPRAIDSetting
Export-iBMCSPRAIDSetting
Set-iBMCSPRAIDSetting
Clear-iBMCSPRAIDSetting
Connect-iBMC
Disconnect-iBMC
#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session,

    [String[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $Location,

    [String[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $DeviceName,

    [RAIDCardModel[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $CardModel = @([RAIDCardModel]::LSI3008),

    [SPRAIDLevel[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $RAIDLevel,

    [int[][]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $Drives,

    [bool[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $BootEnabled,

    [int[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $CapacityMB,

    [string[]]
    [ValidateLength(1, 15)]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $VolumeName
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $Location 'Location'
    Assert-ArrayNotNull $DeviceName 'DeviceName'
    Assert-ArrayNotNull $CardModel 'CardModel'

    $LocationList = Get-MatchedSizeArray $Session $Location "Session" "Location"
    $DeviceNameList = Get-MatchedSizeArray $Session $DeviceName "Session" "DeviceName"
    $CardModelList = Get-MatchedSizeArray $Session $CardModel "Session" "CardModel"

    $RAIDLevelList = Get-MatchedSizeArray $Session $RAIDLevel
    $DrivesList = Get-OptionalMatchedSizeMatrix $Session $Drives $null 'Session' 'Drives'
    $BootEnabledList = Get-OptionalMatchedSizeArray $Session $BootEnabled

    $VolumeNameList = Get-OptionalMatchedSizeArray $Session $VolumeName
    $CapacityMBList = Get-OptionalMatchedSizeArray $Session $CapacityMB

    $Logger.info("Invoke add volume for current SP RAID setting of SPService function")

    $ScriptBlock = {
      param($RedfishSession, $Payload)

      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke add volume for current SP RAID setting of SPService now"))
      $Path = "/Managers/$($RedfishSession.Id)/SPService/SPRAID"
      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Payload | ConvertTo-Json -Depth 5)"))
      Invoke-RedfishRequest $RedfishSession $Path 'POST' $Payload | Out-Null
      return $null
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Id = "$($LocationList[$idx])$($DeviceNameList[$idx])"

        $Volume = @{
          "VolumeName" = $VolumeNameList[$idx];
          "BootEnable" = $BootEnabledList[$idx];
        } | Remove-EmptyValues
        if ($null -ne $CapacityMBList[$idx]) {
          $Volume.CapacityBytes = $CapacityMBList[$idx] * 1024 * 1024
        }

        $DriveGroup = @{
          "VolumeRaidLevel" = $RAIDLevelList[$idx];
          "Drives" = $DrivesList[$idx];
          "VolumeList" = @($Volume)
        } | Resolve-EnumValues

        $Payload = @{
          "Id"         = $Id;
          "CardModel"  = $CardModelList[$idx];
          "Location"   = $LocationList[$idx];
          "DeviceName" = $DeviceNameList[$idx];
          "DriveGroupList" = @($DriveGroup);
        } | Resolve-EnumValues
        $Logger.info($(Trace-Session $RedfishSession "Submit add volume for current SP RAID setting of SPService task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock @($RedfishSession, $Payload)))
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
