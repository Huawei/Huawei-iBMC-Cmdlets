# Copyright (C) 2020 Huawei Technologies Co., Ltd. All rights reserved.	
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the MIT License		

# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# MIT License for more detail

<# NOTE: iBMC Manager module Cmdlets #>

function Export-iBMCMaintenanceInfo {
<#
.SYNOPSIS
Collect maintenance information of all boards and export to local storage.

.DESCRIPTION
Collect maintenance information of all boards and export to local storage.
This cmdlet will cost up to 10 minutes to collection infomation and several minutes to download, please be patience.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER ExportTo
The dest export to file path:

Export to path examples:
1. export to ibmc local temporary path: /tmp/filename.tar.gz
2. export to remote path: protocol://username:password@hostname/directory/filename.tar.gz
   support protocol list: sftp, https, nfs, cifs, scp

.OUTPUTS
PSObject[][]
Returns iBMC System LinkUp Ethernet Interfaces if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $ExportTo = "nfs://192.168.10.3/data/nfs/collect.tar.gz"
PS C:\> $Tasks = Export-iBMCMaintenanceInfo -Session $session -ExportTo $ExportTo
PS C:\> $Tasks

Host         : 192.168.1.1
Id           : 1
Name         : Export Dump File Task
ActivityName : [192.168.1.1] Export Dump File Task
TaskState    : Completed
StartTime    : 2019-01-19T04:22:13+00:00
EndTime      : 2019-01-19T04:30:19+00:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to export collect tarball file to NFS.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $ExportTo = "sftp://192.168.1.2/data/collect.tar.gz"
PS C:\> $Tasks = Export-iBMCMaintenanceInfo -Session $session -ExportTo $ExportTo -SecureEnabled
PS C:\> $Tasks

Host         : 192.168.1.1
Id           : 1
Name         : Export Dump File Task
ActivityName : [192.168.1.1] Export Dump File Task
TaskState    : Completed
StartTime    : 2019-01-19T04:22:13+00:00
EndTime      : 2019-01-19T04:30:19+00:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to export collect tarball file to sftp with secure parameter.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1,192.168.1.3 -Credential $credential -TrustCert
PS C:\> $ExportTo = @("nfs://192.168.10.3/data/nfs/2.tar.gz", "nfs://192.168.10.3/data/nfs/3.tar.gz")
PS C:\> $Tasks = Export-iBMCMaintenanceInfo -Session $session -ExportTo $ExportTo
PS C:\> $Tasks

Host         : 192.168.1.1
Id           : 1
Name         : Export Dump File Task
ActivityName : [192.168.1.1] Export Dump File Task
TaskState    : Completed
StartTime    : 2019-01-19T04:22:13+00:00
EndTime      : 2019-01-19T04:30:19+00:00
TaskStatus   : OK
TaskPercent  : 100%

Host         : 192.168.1.3
Id           : 1
Name         : Export Dump File Task
ActivityName : [192.168.1.3] Export Dump File Task
TaskState    : Completed
StartTime    : 2019-01-19T04:22:13+00:00
EndTime      : 2019-01-19T04:30:19+00:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to export collect tarball file to NFS for multiply servers.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $ExportTo = "/tmp/collect.tar.gz"
PS C:\> $Tasks = Export-iBMCMaintenanceInfo -Session $session -ExportTo $ExportTo
PS C:\> $Tasks

Host         : 192.168.1.1
Id           : 1
Name         : Export Dump File Task
ActivityName : [192.168.1.1] Export Dump File Task
TaskState    : Completed
StartTime    : 2019-01-19T04:22:13+00:00
EndTime      : 2019-01-19T04:30:19+00:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to export collect tarball file to BMC temp storage.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $ExportTo = "/tmp/collect.tar.gz"
PS C:\> Export-iBMCMaintenanceInfo -Session $session -ExportTo $ExportTo
PS C:\> $LocalFilePath = 'C:\collect.tar.gz'
PS C:\> Invoke-iBMCFileDownload -Session $session `
          -BMCFileUri $ExportTo -LocalFileUri $LocalFilePath

This example shows how to export collect tarball file to BMC temp storage
  and then download the tarball file to local machine.

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
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
    $ExportTo,

    [switch]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $SecureEnabled
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $ExportTo 'ExportTo'

    $ExportToList = Get-MatchedSizeArray $Session $ExportTo

    if ($SecureEnabled) {
      $SensitiveInfo = @(Get-SensitiveInfo)
      $SensitiveInfoList = Get-OptionalMatchedSizeArray $Session $SensitiveInfo
    }
    
    if ($ExportTo.Count -eq 1 -and $Session.Count -gt 1) {
      if ($ExportTo[0] -notlike '/tmp/*') {
        throw $(Get-i18n ERROR_EXPORT_TO_SAME_NFS)
      }
    }

    $Logger.info("Invoke Collect maintenance infomation function")

    $ScriptBlock = {
      param($RedfishSession, $ExportTo)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Collect maintenance infomation now"))
      $Path = "/Managers/$($RedfishSession.Id)/Actions/Oem/Huawei/Manager.Dump"

      $CleanUpExportToPath = Resolve-NetworkUriSchema $ExportTo
      $Payload = @{
        'Type'    = "URI";
        'Content' = $CleanUpExportToPath;
      }

      $Clone = $Payload.clone()
      $Clone.Content = Protect-NetworkUriUserInfo $CleanUpExportToPath

      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Clone | ConvertTo-Json)"))
      $Task = Invoke-RedfishRequest $RedfishSession $Path 'POST' $Payload | ConvertFrom-WebResponse
      return ,$Task
    }

    try {
      $ParametersList = New-Object System.Collections.ArrayList
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Path = $ExportToList[$idx]
        if ($SecureEnabled) {
          $SensitiveInfo = $SensitiveInfoList[$idx]
          $Path = Get-CompleteUri $SensitiveInfo $Path
        }
        # validate network file schema
        Assert-NetworkUriInSchema $RedfishSession $Path $BMC.CollectFileSupportSchema | Out-Null
        $Parameters = @($RedfishSession, $Path)
        [Void] $ParametersList.Add($Parameters)
      }

      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Collect maintenance infomation task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $ParametersList[$idx]))
      }

      # Waiting for all task finished
      $RedfishTasks = Get-AsyncTaskResults $tasks
      $RedfishTasks = Wait-RedfishTasks $pool $Session $RedfishTasks -ShowProgress
      return ,$RedfishTasks
    }
    finally {
      Close-Pool $pool
    }
  }

  end {
  }
}


function Invoke-iBMCFileUpload {
<#
.SYNOPSIS
Upload local file to iBMC temp storage.

.DESCRIPTION
Upload local file to iBMC temp storage. The file will be put under '/tmp/web' folder.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER FileUri
Indicates the local file uri of firmware file.

File to be uploaded.
V3 servers support the following file formats: "hpm","cer","pem","cert","crt","pfx","p12","xml","keys","pub".
V5 servers support the following file formats: "hpm","zip","asc","cer","pem","cert","crt","pfx","p12", "xml","keys","pub".
The maximum file size is as follows:
- hpm file for V3 servers: 46 MB
- hpm, zip, or asc file for V5 servers: 60 MB
- cer, pem, cert, crt, xml, p12: 1 MB
- pfx or keys file: 2 MB
- pub file: 2 KB

FileUri examples:
- C:\2288H_V5_5288_V5-iBMC-V318.hpm
- \\192.168.1.2\2288H_V5_5288_V5-iBMC-V318.hpm

.OUTPUTS
PSObject[]
Returns the uploaded file path if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $Path = Invoke-iBMCFileUpload -Session $session -FileUri E:\2288H_V5_5288_V5-iBMC-V318.hpm
PS C:\> $Path

Path
----
/tmp/web/2288H_V5_5288_V5-iBMC-V318.hpm

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Invoke-iBMCFileDownload
Connect-iBMC
Disconnect-iBMC

#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session,

    [String[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 2)]
    $FileUri
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $FileUri 'FileUri'
    $FileUriList = Get-MatchedSizeArray $Session $FileUri 'Session' 'FileUri'

    $Logger.info("Invoke upload firmware file function")

    $ScriptBlock = {
      param($RedfishSession, $FilePath)

      $Logger.info($(Trace-Session $RedfishSession "Invoke upload firmware file now"))

      $FileUri = New-Object System.Uri($FilePath)
      $UploadFileName = $FileUri.Segments[-1]

      # upload image file to bmc
      Invoke-RedfishFirmwareUpload $RedfishSession $UploadFileName $FilePath | Out-Null
      $Logger.Info($(Trace-Session $RedfishSession "File uploaded as $UploadFileName success"))
      $Path = New-Object PSObject
      $Path | Add-Member -MemberType NoteProperty "Path" "/tmp/web/$UploadFileName"
      return $Path
    }

    try {
      $ParametersList = New-Object System.Collections.ArrayList
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $LocalFilePath = $FileUriList[$idx]
        try {
          $NetworkUri = New-Object System.Uri($LocalFilePath)
        } catch {
          throw "[$($RedfishSession.Address)] $(Get-i18n ERROR_FILE_URI_ILLEGAL)"
        }
        if ($NetworkUri.Scheme -eq 'file') {
          $Parameters = @($RedfishSession, $LocalFilePath)
          [Void] $ParametersList.add($Parameters)
        } else {
          $ErrorDetail = [String]::Format($(Get-i18n ERROR_FILE_NOT_LOCAL), $LocalFilePath)
          throw "[$($RedfishSession.Address)] $ErrorDetail"
        }
      }

      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $Logger.info($(Trace-Session $RedfishSession "Submit upload firmware file task"))
        $Parameters = $ParametersList[$idx]
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


function Invoke-iBMCFileDownload {
<#
.SYNOPSIS
Download a BMC file.

.DESCRIPTION
Download a BMC file to local storage.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER BMCFileUri
Indicates the BMC storage file uri.
BMCFileUri should start with "/tmp/"

.PARAMETER LocalFileUri
Indicates the local storage file uri.

LocalFileUri examples:
- C:\2288H_V5_5288_V5-iBMC-V318.hpm
- \\192.168.1.2\2288H_V5_5288_V5-iBMC-V318.hpm

.OUTPUTS
None
Returns None if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $BMCFilePath = "/tmp/web/2288H_V5_5288_V5-iBMC-V318.hpm"
PS C:\> $LocalFilePath = "E:\2288H_V5_5288_V5-iBMC-V318.hpm"
PS C:\> Invoke-iBMCFileDownload -Session $session `
          -BMCFileUri $BMCFilePath -LocalFileUri $LocalFilePath


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session,

    [String[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
    $BMCFileUri,

    [String[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 2)]
    $LocalFileUri
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $BMCFileUri 'BMCFileUri'
    Assert-ArrayNotNull $LocalFileUri 'LocalFileUri'

    $BMCFileUriList = Get-MatchedSizeArray $Session $BMCFileUri 'Session' 'BMCFileUri'
    $LocalFileUriList = Get-MatchedSizeArray $Session $LocalFileUri 'Session' 'LocalFileUri'

    $Logger.info("Invoke download BMC file function")

    $ScriptBlock = {
      param($RedfishSession, $BMCFilePath, $LocalFilePath)

      $Logger.info($(Trace-Session $RedfishSession "Invoke download BMC file now"))

      $Payload = @{
        TransferProtocol = "HTTPS";
        Path             = $BMCFilePath;
      }
      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Payload | ConvertTo-Json)"))
      $Path = "/Managers/$($RedfishSession.Id)/Actions/Oem/Huawei/Manager.GeneralDownload"

      # download bmc file
      $Response = Invoke-RedfishRequest $RedfishSession $Path 'POST' $Payload
      $ResponseStream = $Response.GetResponseStream()

      try {
        $bytesRead = 0
        $Buffer = New-Object byte[] 4096
        $FileOutputStream = New-Object IO.FileStream $LocalFilePath ,'OpenOrCreate','Write'
        while (($bytesRead = $ResponseStream.Read($Buffer, 0, $Buffer.Length)) -gt 0) {
          $FileOutputStream.Write($Buffer, 0, $bytesRead)
          $FileOutputStream.flush()
        }
        $FileOutputStream.Close()
      } finally {
        if ($null -ne $ResponseStream) {
          $ResponseStream.dispose()
        }
        if ($null -ne $FileOutputStream) {
          $FileOutputStream.dispose()
        }
      }

      return $null
    }

    try {
      $ParametersList = New-Object System.Collections.ArrayList
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $LocalFilePath = $LocalFileUriList[$idx]
        $BMCFilePath = $BMCFileUriList[$idx]

        if ($BMCFilePath -notlike '/tmp/*') {
          $ErrorDetail = [String]::Format($(Get-i18n ERROR_ILLEGAL_BMC_FILE_URI), $BMCFilePath)
          throw "[$($RedfishSession.Address)] $ErrorDetail"
        }

        try {
          $NetworkUri = New-Object System.Uri($LocalFilePath)
        } catch {
          throw "[$($RedfishSession.Address)] $(Get-i18n ERROR_FILE_URI_ILLEGAL)"
        }

        if ($NetworkUri.Scheme -eq 'file') {
          $Parameters = @($RedfishSession, $BMCFilePath, $LocalFilePath)
          [Void] $ParametersList.add($Parameters)
        } else {
          $ErrorDetail = [String]::Format($(Get-i18n ERROR_FILE_NOT_LOCAL), $LocalFilePath)
          throw "[$($RedfishSession.Address)] $ErrorDetail"
        }
      }

      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $Logger.info($(Trace-Session $RedfishSession "Submit download BMC file task"))
        $Parameters = $ParametersList[$idx]
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
