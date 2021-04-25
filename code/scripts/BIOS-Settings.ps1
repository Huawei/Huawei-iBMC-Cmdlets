# Copyright (C) 2020-2021 Huawei Technologies Co., Ltd. All rights reserved.
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the MIT License		

# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# MIT License for more detail

<# NOTE: iBMC BIOS Setting Module Cmdlets #>

function Export-iBMCBIOSSetting {
<#
.SYNOPSIS
Export iBMC BIOS and BMC Settings

.DESCRIPTION
Export iBMC BIOS and BMC Settings

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER DestFilePath
The dest settings file path:

Dest path examples:
1. export to ibmc local temporary path: /tmp/filename.xml
2. export to remote path: protocol://username:password@hostname/directory/filename.xml
   support protocol list: sftp, https, nfs, cifs, scp

.OUTPUTS
PSObject[]
Returns the export configuration task array if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $Tasks = Export-iBMCBIOSSetting $session 'nfs://192.168.10.3/data/nfs/bios.xml'

This example shows how to export bios setting file to remote NFS storage

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1,192.168.1.3 -Credential $credential -TrustCert
PS C:\> $ExportToPath = @('nfs://192.168.10.3/data/nfs/2.xml', 'nfs://192.168.10.3/data/nfs/3.xml')
PS C:\> $Tasks = Export-iBMCBIOSSetting $session $ExportToPath

This example shows how to export bios setting file to remote NFS storage for multiply servers

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1  -Credential $credential -TrustCert
PS C:\> $Tasks = Export-iBMCBIOSSetting $session '/tmp/bios.xml'
PS C:\> $Tasks

Id           : 4
Name         : Export Config File Task
ActivityName : [192.168.1.1] Export Config File Task
TaskState    : Completed
StartTime    : 2018-11-14T17:52:01+08:00
EndTime      : 2018-11-14T17:53:20+08:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to export bios setting file to iBMC local storage

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $LocalFilePath = 'c:\bios.xml'
PS C:\> $BMCFilePath = '/tmp/bios.xml'
PS C:\> $Tasks = Export-iBMCBIOSSetting $session $BMCFilePath
PS C:\> $Tasks
PS C:\> Invoke-iBMCFileDownload -Session $session `
          -BMCFileUri $BMCFilePath -LocalFileUri $LocalFilePath

Host         : 192.168.1.1
Id           : 4
Name         : Export Config File Task
ActivityName : [192.168.1.1] Export Config File Task
TaskState    : Completed
StartTime    : 2018-11-14T17:52:01+08:00
EndTime      : 2018-11-14T17:53:20+08:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to export bios setting file to iBMC local storage and download the file to local


.EXAMPLE
PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\Users\Test> Export-iBMCBIOSSetting -Session $session -DestFilePath "sftp://192.168.1.2/data/bios.xml" -SecureEnabled


Host         : 192.168.1.1
Id           : 1
Guid         : 1855080
Name         : Export Config File Task
ActivityName : [192.168.1.1] Export Config File Task
TaskState    : Completed
StartTime    : 2021-01-12T10:20:08+08:00
EndTime      : 2021-01-12T10:21:39+08:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to export bios setting file to iBMC local storage and download the file to local with secure parameter

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Import-iBMCBIOSSetting
Reset-iBMCBIOSSetting
Restore-iBMCFactorySetting
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
    $DestFilePath,

    [switch]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $SecureEnabled
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $DestFilePath 'DestFilePath'
    $DestFilePathList = Get-MatchedSizeArray $Session $DestFilePath 'Session' 'DestFilePath'
    
    if ($SecureEnabled) {
      $SensitiveInfo = @(Get-SensitiveInfo)
      $SensitiveInfoList = Get-OptionalMatchedSizeArray $Session $SensitiveInfo
    }

    if ($DestFilePath.Count -eq 1 -and $Session.Count -gt 1) {
      if ($DestFilePath[0] -notlike '/tmp/*') {
        throw $(Get-i18n ERROR_EXPORT_TO_SAME_NFS)
      }
    }

    $Logger.info("Invoke Export BIOS Configurations function")

    $ScriptBlock = {
      param($RedfishSession, $DestFilePath)
      $CleanUpDestFilePath = Resolve-NetworkUriSchema $DestFilePath
      $Payload = @{
        'Type'    = "URI";
        'Content' = $CleanUpDestFilePath;
      }

      $Clone = $Payload.clone()
      $Clone.Content = Protect-NetworkUriUserInfo $CleanUpDestFilePath
      $Path = "/redfish/v1/Managers/$($RedfishSession.Id)/Actions/Oem/Huawei/Manager.ExportConfiguration"
      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Clone | ConvertTo-Json)"))
      $Response = Invoke-RedfishRequest $RedfishSession $Path 'Post' $Payload
      return $Response | ConvertFrom-WebResponse
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count

      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $FilePath = $DestFilePathList[$idx]
        if ($FilePath -like '/tmp/*' -and $Secure) {
          throw $(Get-i18n ERROR_INVALID_PARAMETERS)
        }
        if ($SecureEnabled) {
          $SensitiveInfo = $SensitiveInfoList[$idx]
          $FilePath = Get-CompleteUri $SensitiveInfo $FilePath
        }
        $Logger.info($(Trace-Session $RedfishSession "Submit export BIOS configs task"))
        $Parameters = @($RedfishSession, $FilePath)
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $Parameters))
      }

      $RedfishTasks = Get-AsyncTaskResults $tasks
      $Logger.Info("Export configuration task: $RedfishTasks")
      return Wait-RedfishTasks $pool $Session $RedfishTasks -ShowProgress
    }
    finally {
      Close-Pool $pool
    }
  }

  end {

  }
}

function Import-iBMCBIOSSetting {
<#
.SYNOPSIS
Import iBMC BIOS and BMC configuration

.DESCRIPTION
Import iBMC BIOS and BMC configuration. The BIOS setup configuration takes effect upon the next restart of the system.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER ConfigFilePath
The bios&bmc configuration file path

File path support:
1. import from local storage, example: C:\config.xml or \\192.168.1.2\config.xml
2. import from ibmc local temporary storage, example: /tmp/filename.xml
3. import from remote storage, example: protocol://username:password@hostname/directory/filename.xml
   support protocol list: sftp, https, nfs, cifs, scp


.OUTPUTS
PSObject[]
Returns the import configuration task array if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $Tasks = Import-iBMCBIOSSetting $session 'C:\192.168.10.2.xml'
PS C:\> $Tasks

Host         : 192.168.1.1
Id           : 2
Name         : Import Config File Task
ActivityName : [192.168.1.1] Import Config File Task
TaskState    : Completed
StartTime    : 2018-11-14T17:54:54+08:00
EndTime      : 2018-11-14T17:56:06+08:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to import bios settings from local file

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $Tasks = Import-iBMCBIOSSetting $session '/tmp/bios.xml'
PS C:\> $Tasks

Id           : 2
Name         : Import Config File Task
ActivityName : [192.168.1.1] Import Config File Task
TaskState    : Completed
StartTime    : 2018-11-14T17:54:54+08:00
EndTime      : 2018-11-14T17:56:06+08:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to import bios settings from ibmc temp file

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $LocalFilePath = 'c:\bios.xml'
PS C:\> $Upload = Invoke-iBMCFileUpload -Session $session -FileUri $LocalFilePath
PS C:\> $Tasks = Import-iBMCBIOSSetting $session $Upload.Path
PS C:\> $Tasks

Id           : 2
Name         : Import Config File Task
ActivityName : [192.168.1.1] Import Config File Task
TaskState    : Completed
StartTime    : 2018-11-14T17:54:54+08:00
EndTime      : 2018-11-14T17:56:06+08:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to upload local file to BMC and then import bios settings from the upload bmc file


.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $Tasks = Import-iBMCBIOSSetting $session 'nfs://192.168.10.3/data/nfs/bios.xml'
PS C:\> $Tasks

Id           : 2
Name         : Import Config File Task
ActivityName : [192.168.1.1] Import Config File Task
TaskState    : Completed
StartTime    : 2018-11-14T17:54:54+08:00
EndTime      : 2018-11-14T17:56:06+08:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to import bios settings from NFS file

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $Tasks = Import-iBMCBIOSSetting $session 'sftp://192.168.1.2/data/bios.xml' -SecureEnabled


Id           : 2
Name         : Import Config File Task
ActivityName : [192.168.1.1] Import Config File Task
TaskState    : Completed
StartTime    : 2018-11-14T17:54:54+08:00
EndTime      : 2018-11-14T17:56:06+08:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to import bios settings from SFTP file with secure parameter

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Export-iBMCBIOSSetting
Reset-iBMCBIOSSetting
Restore-iBMCFactorySetting
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
    $ConfigFilePath,

    [switch]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $SecureEnabled
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $ConfigFilePath 'ConfigFilePath'
    $ConfigFilePathList = Get-MatchedSizeArray $Session $ConfigFilePath 'Session' 'ConfigFilePath'

    if ($SecureEnabled) {
      $SensitiveInfo = @(Get-SensitiveInfo)
      $SensitiveInfoList = Get-OptionalMatchedSizeArray $Session $SensitiveInfo
    }
    
    $Logger.info("Invoke Import BIOS Configurations function, batch size: $($Session.Count)")

    $ScriptBlock = {
      param($RedfishSession, $ConfigFilePath)

      $payload = @{'Type' = "URI";}
      if ($ConfigFilePath.StartsWith("/tmp")) {
        $payload.Content = $ConfigFilePath
      } else {
        $ContentURI = Invoke-FileUploadIfNeccessary $RedfishSession $ConfigFilePath $BMC.BIOSConfigFileSupportSchema
        $Payload.Content = $ContentURI
        # old implementation: it seems upload xml file is not support?
        # $UploadFileName = "$(Get-RandomIntGuid).hpm"
        # Invoke-RedfishFirmwareUpload $Session $UploadFileName $ConfigFilePath | Out-Null
        # $payload.Content = "/tmp/web/$UploadFileName"
      }

      $Clone = $Payload.clone()
      $Clone.Content = Protect-NetworkUriUserInfo $Payload.Content
      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Clone | ConvertTo-Json)"))
      $Path = "/redfish/v1/Managers/$($RedfishSession.Id)/Actions/Oem/Huawei/Manager.ImportConfiguration"
      $Response = Invoke-RedfishRequest $RedfishSession $Path 'Post' $payload
      return $Response | ConvertFrom-WebResponse
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $ImportConfigFilePath = $ConfigFilePathList[$idx];
        if ($SecureEnabled) {
          $SensitiveInfo = $SensitiveInfoList[$idx]
          $ImportConfigFilePath = Get-CompleteUri $SensitiveInfo $ImportConfigFilePath
        }
        $Logger.info($(Trace-Session $RedfishSession "Submit import BIOS config task"))
        $Parameters = @($RedfishSession, $ImportConfigFilePath)
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $Parameters))
      }

      $RedfishTasks = Get-AsyncTaskResults $tasks
      $Logger.Info("Import configuration task: " + $RedfishTasks)
      return Wait-RedfishTasks $pool $Session $RedfishTasks -ShowProgress
    }
    finally {
      Close-Pool $pool
    }
  }

  end {
  }
}


function Reset-iBMCBIOSSetting {
<#
.SYNOPSIS
Restore BIOS default settings.

.DESCRIPTION
Restore BIOS default settings.
The BIOS setup configuration takes effect upon the next restart of the system.
Note: This cmdlet may affect the normal operation of system. It should be used with caution.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
None
Returns none if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

Restore BIOS default settings

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> Reset-iBMCBIOSSetting $session


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets
Export-iBMCBIOSSetting
Import-iBMCBIOSSetting
Restore-iBMCFactorySetting
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

    $Logger.info("Invoke Reset BIOS configuration function")

    $ScriptBlock = {
      param($RedfishSession)
      $Path = "/Systems/$($RedfishSession.Id)/Bios/Actions/Bios.ResetBios"
      Invoke-RedfishRequest $RedfishSession $Path 'Post' | Out-Null
      return $null
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Reset BIOS configuration task"))
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


function Get-iBMCBIOSSetting {
<#
.SYNOPSIS
get BIOS settings.

.DESCRIPTION
get BIOS settings.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER Attributes
Indicates the Bios attributes.

.OUTPUTS
Object[]
Returns object arrays contain iBMC BIOS setting infomation if cmdlet executes successfully.
In case of an error or warning, exception will be returned.
  
.EXAMPLE
PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $System = Get-iBMCBIOSSetting $session -Attributes "TcoTimeout"
PS C:\> $System

Host              : 192.168.1.1
Id                : Bios
Name              : BIOS Configuration Current Settings
AttributeRegistry : BiosAttributeRegistry.7.6.2
Attributes        : @{TcoTimeout=2}

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

#>

  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session,

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $Attributes
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    $AttributesList = Get-OptionalMatchedSizeArray $Session $Attributes

    $Logger.info("Invoke Get BIOS Setting function")

    $ScriptBlock = {
      param($RedfishSession, $Attribute)
      $Path = "/Systems/$($RedfishSession.Id)/Bios"
      $Response = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
      $Properties = @(
        "^Id$", "^Name$", "^AttributeRegistry$", "^Attributes$"
      )
      $System = Copy-ObjectProperties $Response $Properties

      if ($null -ne $Attribute -and $Attribute.length -gt 0) {
        $Logger.info("Attributes parameter is not null, going to filter out the result")
        $temp = $Attribute.Split(",")
        $System.Attributes = Copy-ObjectProperties $System.Attributes $temp
      }
      
      return Update-SessionAddress $RedfishSession $System
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Attribute = $AttributesList[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit get BIOS setting task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock @($RedfishSession, $Attribute)))
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


function Set-iBMCBIOSSetting {
<#
.SYNOPSIS
set BIOS settings.

.DESCRIPTION
set BIOS settings.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER Attributes
Indicates the Bios attributes.

.OUTPUTS
Returns object arrays contain iBMC BIOS setting information if cmdlet executes successfully.
In case of an error or warning, exception will be returned.
    
.EXAMPLE
PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> Set-iBMCBIOSSetting $session -Attributes @(@{"BMCWDTTimeout"=18})

Host              : 192.168.1.1
Id                : Settings
Name              : BIOS Configuration Pending Settings
AttributeRegistry : BiosAttributeRegistry.7.6.2
Attributes        : @{BMCWDTTimeout=20}
Oem               : @{Huawei=}


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets
  
#>

  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session,

    [hashtable[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $Attributes,

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $Files
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'

    $AttributesList = Get-OptionalMatchedSizeArray $Session $Attributes
    $FilesList = Get-OptionalMatchedSizeArray $Session $Files

    $Logger.info("Invoke Set BIOS Setting function")

    $ScriptBlock = {
        param($RedfishSession, $Attribute, $File)
        $Logger.info($(Trace-Session $RedfishSession "Invoke set iBMC BIOS setting now"))
      
        $Path = "/Systems/$($RedfishSession.Id)/Bios/Settings"

        $Payload = @{"Attributes"=@{}}

        if ($null -ne $Attribute) {
            $Payload.Attributes = $Attribute
        } else {
            $Payload = Get-Content $File | ConvertFrom-Json
        }

        $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Payload | ConvertTo-Json)"))

        $Response = Invoke-RedfishRequest $RedfishSession $Path 'Patch' $Payload | ConvertFrom-WebResponse
        $Properties = @(
        "^Id$", "^Name$", "^AttributeRegistry$", "^Attributes$", "^Oem$"
        )
        $System = Copy-ObjectProperties $Response $Properties

        return Update-SessionAddress $RedfishSession $System
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Attribute = $AttributesList[$idx]
        $File = $FilesList[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit set BIOS setting task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock @($RedfishSession, $Attribute, $File)))
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
