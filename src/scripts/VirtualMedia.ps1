# Copyright (C) 2020 Huawei Technologies Co., Ltd. All rights reserved.	
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the MIT License		

# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# MIT License for more detail

<# NOTE: iBMC virtual media module Cmdlets #>

function Get-iBMCVirtualMedia {
<#
.SYNOPSIS
Query information about a specified virtual media resource.

.DESCRIPTION
Query information about a specified virtual media resource.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[]
Returns PSObject which identifies VirtualMedia if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $VirtualMedia = Get-iBMCVirtualMedia $session
PS C:\> $VirtualMedia

Host           : 10.1.1.2
Id             : CD
Name           : VirtualMedia
MediaTypes     : {}
Image          :
ImageName      :
ConnectedVia   : NotConnected
Inserted       : False

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

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

    $Logger.info("Invoke Get Virtual Media infomation function")

    $ScriptBlock = {
      param($RedfishSession)
      $Path = "/Managers/$($RedfishSession.Id)/VirtualMedia/CD"
      $Response = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
      $Properties = @(
        "Id", "Name", "MediaTypes", "Image", "ImageName",
        "ConnectedVia", "Inserted"
      )
      $VirtualMedia = Copy-ObjectProperties $Response $Properties
      return $(Update-SessionAddress $RedfishSession $VirtualMedia)
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get Virtual Media task"))
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


function Connect-iBMCVirtualMedia {
<#
.SYNOPSIS
Connect to virtual media.

.DESCRIPTION
Connect to virtual media.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER ImageFilePath
VRI of the virtual media image
Only the URI connections using the Network File System (NFS), Common Internet File System (CIFS) or HTTPS protocols are supported.

.OUTPUTS
PSObject[]
Returns the Connect Virtual Media task details if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $Tasks = Connect-iBMCVirtualMedia $session 'nfs://10.10.10.10/usr/SLE-12-Server-DVD-x86_64-GM-DVD1.ISO'
PS C:\> $Tasks

Host         : 10.1.1.2
Id           : 1
Name         : vmm connect task
ActivityName : [10.1.1.2] vmm connect task
TaskState    : Completed
StartTime    : 2018-11-14T18:04:07+08:00
EndTime      : 2018-11-14T18:04:08+08:00
TaskStatus   : OK
TaskPercent  :

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCVirtualMedia
Disconnect-iBMCVirtualMedia
Connect-iBMC
Disconnect-iBMC

#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session,

    [string[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
    $ImageFilePath
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $ImageFilePath 'ImageFilePath'
    $ImageFilePath = Get-MatchedSizeArray $Session $ImageFilePath 'Session' 'ImageFilePath'

    $Logger.info("Invoke Connect Virtual Media function")

    $ScriptBlock = {
      param($RedfishSession, $ImageFilePath)
      $CleanUpImageFilePath = Resolve-NetworkUriSchema $ImageFilePath
      $Payload = @{
        "VmmControlType" = "Connect";
        "Image"          = $CleanUpImageFilePath;
      }

      $Clone = $Payload.clone()
      $Clone.Image = Protect-NetworkUriUserInfo $CleanUpImageFilePath
      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Clone | ConvertTo-Json)"))

      $Path = "/Managers/$($RedfishSession.Id)/VirtualMedia/CD/Oem/Huawei/Actions/VirtualMedia.VmmControl"
      $Response = Invoke-RedfishRequest $RedfishSession $Path 'POST' $Payload
      return $Response | ConvertFrom-WebResponse
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Parameters = @($RedfishSession, $ImageFilePath[$idx])
        $Logger.info($(Trace-Session $RedfishSession "Submit Connect Virtual Media task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $Parameters))
      }

      $RedfishTasks = Get-AsyncTaskResults $tasks
      $Results = Wait-RedfishTasks $pool $Session $RedfishTasks -ShowProgress
      return ,$Results
    }
    finally {
      Close-Pool $pool
    }
  }

  end {
  }
}


function Disconnect-iBMCVirtualMedia {
<#
.SYNOPSIS
Disconnect virtual media.

.DESCRIPTION
Disconnect virtual media.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[]
Returns the Disconnect Virtual Media task details if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $Tasks = Disconnect-iBMCVirtualMedia $session
PS C:\> $Tasks

Host         : 10.1.1.2
Id           : 4
Name         : vmm disconnect status task
ActivityName : [10.1.1.2] vmm disconnect status task
TaskState    : Completed
StartTime    : 2018-11-14T18:05:20+08:00
EndTime      : 2018-11-14T18:05:20+08:00
TaskStatus   : OK
TaskPercent  :

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCVirtualMedia
Connect-iBMCVirtualMedia
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

    $Logger.info("Invoke Disconnect Virtual Media function")

    $ScriptBlock = {
      param($RedfishSession)
      $Payload = @{
        "VmmControlType" = "Disconnect";
      }

      $Path = "/Managers/$($RedfishSession.Id)/VirtualMedia/CD/Oem/Huawei/Actions/VirtualMedia.VmmControl"
      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Payload | ConvertTo-Json)"))
      $Response = Invoke-RedfishRequest $RedfishSession $Path 'POST' $Payload
      return $Response | ConvertFrom-WebResponse
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Parameters = @($RedfishSession)
        $Logger.info($(Trace-Session $RedfishSession "Submit Disconnect Virtual Media task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $Parameters))
      }

      $RedfishTasks = Get-AsyncTaskResults $tasks
      $Results = Wait-RedfishTasks $pool $Session $RedfishTasks -ShowProgress
      return ,$Results
    }
    finally {
      Close-Pool $pool
    }
  }

  end {
  }
}
