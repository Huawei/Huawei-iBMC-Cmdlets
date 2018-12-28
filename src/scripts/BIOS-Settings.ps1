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
1. export to ibmc local temporary storage: /tmp/filename.xml
2. export to remote storage: protocol://username:password@hostname/directory/filename.xml
   support protocol list: sftp, https, nfs, cifs, scp

.OUTPUTS
PSObject[]
Returns the export configuration task array if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $Tasks = Export-iBMCBIOSSetting $session 'nfs://10.10.10.3/data/nfs/bios.xml'

This example shows how to export bios setting file to remote NFS storage

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $Tasks = Export-iBMCBIOSSetting $session '/tmp/bios.xml'
PS C:\> $Tasks

Id           : 4
Name         : Export Config File Task
ActivityName : [10.1.1.2] Export Config File Task
TaskState    : Completed
StartTime    : 2018-11-14T17:52:01+08:00
EndTime      : 2018-11-14T17:53:20+08:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to export bios setting file to iBMC local storage


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Import-iBMCBIOSSetting
Reset-iBMCBIOS
Restore-iBMCFactory
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
    $DestFilePath
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $DestFilePath 'DestFilePath'
    $DestFilePath = Get-MatchedSizeArray $Session $DestFilePath 'Session' 'DestFilePath'

    $Logger.info("Invoke Export BIOS Configurations function")

    $ScriptBlock = {
      param($RedfishSession, $DestFilePath)
      $payload = @{
        'Type'    = "URI";
        'Content' = $DestFilePath;
      }
      $Path = "/redfish/v1/Managers/$($RedfishSession.Id)/Actions/Oem/Huawei/Manager.ExportConfiguration"
      $Response = Invoke-RedfishRequest $RedfishSession $Path 'Post' $payload
      return $Response | ConvertFrom-WebResponse
      # Wait-RedfishTask $Session $Task
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit export BIOS configs to $DestFilePath[$idx] task"))
        $Parameters = @($RedfishSession, $DestFilePath[$idx])
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $Parameters))
      }

      $RedfishTasks = Get-AsyncTaskResults $tasks
      $Logger.Info("Export configuration task: $RedfishTasks")
      return Wait-RedfishTasks $pool $Session $RedfishTasks -ShowProgress
    }
    finally {
      $pool.close()
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
1. export to local storage, example: C:\config.xml or \\192.168.1.2\config.xml
2. export to ibmc local temporary storage, example: /tmp/filename.xml
3. export to remote storage, example: protocol://username:password@hostname/directory/filename.xml
   support protocol list: sftp, https, nfs, cifs, scp


.OUTPUTS
PSObject[]
Returns the import configuration task array if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $Tasks = Import-iBMCBIOSSetting $session 'C:\10.10.10.2.xml'
PS C:\> $Tasks

Id           : 2
Name         : Import Config File Task
ActivityName : [10.1.1.2] Import Config File Task
TaskState    : Completed
StartTime    : 2018-11-14T17:54:54+08:00
EndTime      : 2018-11-14T17:56:06+08:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to import bios settings from local file

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $Tasks = Import-iBMCBIOSSetting $session '/tmp/bios.xml'
PS C:\> $Tasks

Id           : 2
Name         : Import Config File Task
ActivityName : [10.1.1.2] Import Config File Task
TaskState    : Completed
StartTime    : 2018-11-14T17:54:54+08:00
EndTime      : 2018-11-14T17:56:06+08:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to import bios settings from ibmc temp file


.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $Tasks = Import-iBMCBIOSSetting $session 'nfs://10.10.10.3/data/nfs/bios.xml'
PS C:\> $Tasks

Id           : 2
Name         : Import Config File Task
ActivityName : [10.1.1.2] Import Config File Task
TaskState    : Completed
StartTime    : 2018-11-14T17:54:54+08:00
EndTime      : 2018-11-14T17:56:06+08:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to import bios settings from NFS file


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Export-iBMCBIOSSetting
Reset-iBMCBIOS
Restore-iBMCFactory
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
    $ConfigFilePath
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $ConfigFilePath 'ConfigFilePath'
    $ConfigFilePathList = Get-MatchedSizeArray $Session $ConfigFilePath 'Session' 'ConfigFilePath'

    $Logger.info("Invoke Import BIOS Configurations function, batch size: $($Session.Count)")

    $ScriptBlock = {
      param($RedfishSession, $ConfigFilePath)

      $Logger.Info($(Trace-Session $RedfishSession "schemas: $($BMC.BIOSConfigFileSupportSchema)"))
      $payload = @{'Type' = "URI";}
      if ($ConfigFilePath.StartsWith("/tmp")) {
        $payload.Content = $ConfigFilePath
      } else {
        $ContentURI = Invoke-FileUploadIfNeccessary $RedfishSession $ConfigFilePath $BMC.BIOSConfigFileSupportSchema
        $Logger.Info($(Trace-Session $RedfishSession "upload file result: $ContentURI"))
        $Payload.Content = $ContentURI
        # old implementation: it seems upload xml file is not support?
        # $UploadFileName = "$(Get-RandomIntGuid).hpm"
        # Invoke-RedfishFirmwareUpload $Session $UploadFileName $ConfigFilePath | Out-Null
        # $payload.Content = "/tmp/web/$UploadFileName"
      }
      $Logger.Info($(Trace-Session $RedfishSession "get here"))
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
        $Logger.info($(Trace-Session $RedfishSession "Submit import BIOS config from $ImportConfigFilePath task"))
        $Parameters = @($RedfishSession, $ImportConfigFilePath)
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $Parameters))
      }

      $RedfishTasks = Get-AsyncTaskResults $tasks
      $Logger.Info("Import configuration task: " + $RedfishTasks)
      return Wait-RedfishTasks $pool $Session $RedfishTasks -ShowProgress
    }
    finally {
      $pool.close()
    }
  }

  end {
  }
}


function Reset-iBMCBIOS {
<#
.SYNOPSIS
Restore BIOS default settings.

.DESCRIPTION
Restore BIOS default settings. The BIOS setup configuration takes effect upon the next restart of the system.

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
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Reset-iBMCBIOS $session


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets
Export-iBMCBIOSSetting
Import-iBMCBIOSSetting
Restore-iBMCFactory
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
      return $Results
    }
    finally {
      $pool.close()
    }
  }

  end {
  }
}

function Restore-iBMCFactory {
<#
.SYNOPSIS
Restore the factory settings.

.DESCRIPTION
Restore the factory settings.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
None
Returns None if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

Restore factory settings

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Restore-iBMCFactory $session


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Export-iBMCBIOSSetting
Import-iBMCBIOSSetting
Reset-iBMCBIOS
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

    $Logger.info("Invoke Restore BIOS Factory function")

    $ScriptBlock = {
      param($RedfishSession)
      $Path = "/Managers/$($RedfishSession.Id)/Actions/Oem/Huawei/Manager.RestoreFactory"
      Invoke-RedfishRequest $RedfishSession $Path 'Post' | Out-Null
      return $null
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Restore BIOS Factory task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock @($RedfishSession)))
      }

      $Results = Get-AsyncTaskResults $tasks
      return $Results
    }
    finally {
      $pool.close()
    }
  }

  end {
  }
}