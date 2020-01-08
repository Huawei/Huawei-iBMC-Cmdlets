# Copyright (C) 2020 Huawei Technologies Co., Ltd. All rights reserved.	
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the MIT License		

# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# MIT License for more detail

<# NOTE: iBMC License module Cmdlets #>

function Get-iBMCLicense {
<#
.SYNOPSIS
Get iBMC License Service infomation.

.DESCRIPTION
Get iBMC License Service infomation.
V3 servers and some V5 servers do not support this function. For details, see the iBMC User Guide.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject
Returns iBMC License Object if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $License = Get-iBMCLicense -Session $session
PS C:\> $License

Host            : 10.1.1.2
Id              : LicenseService
Name            : License Service
Capability      : {Local, Remote}
DeviceESN       : A5A7D970F13580158FBBCA5009F17234D1A6C5CB
InstalledStatus : Installed
RevokeTicket    :
LicenseClass    : Advanced
LicenseStatus   : Normal
LicenseInfo     : @{FileFormatVersion=3.10; GeneralInfo=; CustomerInfo=; NodeInfo=; SaleInfo=}
AlarmInfo       : @{RemainGraceDay=0; RemainCommissioningDay=0; ProductESNValidState=Valid; FileState=Normal; ProductESNMatchState=Matched; ProductVersionM
                  atchState=Matched}

PS C:\> $License.LicenseInfo.GeneralInfo

CopyRight   : Huawei Technologies Co., Ltd. All rights reserved.
LSN         : LIC20180911LXWZ5C
LicenseType : Commercial
GraceDay    : 60
Creator     : Huawei Technologies Co., Ltd.
Issuer      : License Distribution Center
CreateTime  : 2018-09-11 11:42:02


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCLicense
Install-iBMCLicense
Export-iBMCLicense
Delete-iBMCLicense
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

    $Logger.info("Invoke Get iBMC License function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get iBMC License now"))
      $Path = "/Managers/$($RedfishSession.Id)/LicenseService"
      $Response = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse

      $License = Clear-OdataProperties $Response
      return $(Update-SessionAddress $RedfishSession $License)
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get iBMC License task"))
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

function Install-iBMCLicense {
<#
.SYNOPSIS
Install iBMC License.

.DESCRIPTION
Install iBMC License.
V3 servers and some V5 servers do not support this function. For details, see the iBMC User Guide.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER LicenseFileURI
Indicates the file path of license file.

It supports HTTPS, SFTP, NFS, SCP, CIFS and FILE file transfer protocols.

For examples:
- local path: C:\LIC2288H_V5_2_20180905LTM65C.xml or \\192.168.1.2\LIC2288H_V5_2_20180905LTM65C.xml
- ibmc local temporary path: /tmp/LIC2288H_V5_2_20180905LTM65C.xml
- remote path: protocol://username:password@hostname/directory/LIC2288H_V5_2_20180905LTM65C.xml

.PARAMETER LicenseSource
Indicates the source of the license file.
Support value set: "iBMC", "FusionDirector", "eSight".
If not configured, iBMC is used by default.


.OUTPUTS
PSObject[]
Returns null if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Install-iBMCLicense -Session $session `
          -LicenseFileURI "E:\huawei\PowerShell\LIC2288H_V5_2_20180905LTM65C.xml" `
          -LicenseSource iBMC

This example shows how to install iBMC license from local file

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Install-iBMCLicense -Session $session `
          -LicenseFileURI "/tmp/LIC2288H_V5_2_20180905LTM65C.xml"

This example shows how to install iBMC license from ibmc temp file

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Install-iBMCLicense -Session $session `
          -LicenseFileURI "nfs://10.10.10.2/data/nfs/LIC2288H_V5_2_20180905LTM65C.xml"

This example shows how to install iBMC license from NFS network file

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCLicense
Install-iBMCLicense
Export-iBMCLicense
Delete-iBMCLicense
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
    $LicenseFileURI,

    [LicenseSource[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 2)]
    $LicenseSource = [LicenseSource]::iBMC
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $LicenseFileURI 'LicenseFileURI'
    $LicenseFileURIList = Get-MatchedSizeArray $Session $LicenseFileURI 'Session' 'LicenseFileURI'
    $LicenseSourceList = Get-OptionalMatchedSizeArray $Session $LicenseSource

    $Logger.info("Invoke install iBMC license function")

    $ScriptBlock = {
      param($RedfishSession, $LicenseFileURI, $LicenseSource)

      $Logger.info($(Trace-Session $RedfishSession "Invoke install iBMC license now"))

      $LicenseFilePath = Invoke-FileUploadIfNeccessary $RedfishSession $LicenseFileURI $BMC.LicenseFileSupportSchema
      $Payload = @{
        FileSource=$LicenseSource;
        Type= "URI";
        Content=$LicenseFilePath;
      } | Resolve-EnumValues

      $Clone = $Payload.clone()
      $Clone.Content = Protect-NetworkUriUserInfo $LicenseFilePath
      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Clone | ConvertTo-Json)"))

      $Path = "/Managers/$($RedfishSession.Id)/LicenseService/Actions/LicenseService.InstallLicense"
      Invoke-RedfishRequest $RedfishSession $Path 'Post' $Payload | Out-Null
      return $null
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $_LicenseFileURI = $LicenseFileURIList[$idx]
        $_LicenseSource = $LicenseSourceList[$idx]
        $Parameters = @($RedfishSession, $_LicenseFileURI, $_LicenseSource)
        $Logger.info($(Trace-Session $RedfishSession "Submit install iBMC license task"))
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

function Export-iBMCLicense {
<#
.SYNOPSIS
Export iBMC License

.DESCRIPTION
Export iBMC License.
V3 servers and some V5 servers do not support this function. For details, see the iBMC User Guide.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER ExportTo
Indicates the dest export to file path of license file.
It supports HTTPS, SFTP, NFS, SCP, CIFS and FILE file transfer protocols.

For examples:
- export to ibmc local temporary path: /tmp/License.xml
- export to remote path: protocol://username:password@hostname/directory/License.xml
  support protocol list: HTTPS, SFTP, NFS, SCP, CIFS

.OUTPUTS
null
Returns null if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Export-iBMCLicense -Session $session -ExportTo "/tmp/License.xml"

This example shows how to export iBMC license to ibmc temp file

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Export-iBMCLicense -Session $session -ExportTo "NFS://10.1.1.3/data/nfs/License.xml"

This example shows how to export iBMC license to NFS network file

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCLicense
Install-iBMCLicense
Export-iBMCLicense
Delete-iBMCLicense
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
    $ExportTo
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $ExportTo 'ExportTo'

    $ExportToList = Get-MatchedSizeArray $Session $ExportTo

    # assert export to a same NFS file for mulitiple server
    if ($ExportTo.Count -eq 1 -and $Session.Count -gt 1) {
      if ($ExportTo[0] -notlike '/tmp/*') {
        throw $(Get-i18n ERROR_EXPORT_TO_SAME_NFS)
      }
    }

    $Logger.info("Invoke export iBMC license function")

    $ScriptBlock = {
      param($RedfishSession, $ExportTo)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke export iBMC license now"))

      $CleanUpExportToPath = Resolve-NetworkUriSchema $ExportTo
      $Payload = @{
        'Type'    = "URI";
        'Content' = $CleanUpExportToPath;
      }

      $Clone = $Payload.clone()
      $Clone.Content = Protect-NetworkUriUserInfo $CleanUpExportToPath

      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Clone | ConvertTo-Json)"))
      $Path = "/Managers/$($RedfishSession.Id)/LicenseService/Actions/LicenseService.ExportLicense"
      Invoke-RedfishRequest $RedfishSession $Path 'POST' $Payload | Out-Null
      return $Null
    }

    try {
      $ParametersList = New-Object System.Collections.ArrayList
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Path = $ExportToList[$idx]

        # validate network file schema
        Assert-NetworkUriInSchema $RedfishSession $Path $BMC.LicenseFileSupportSchema | Out-Null
        $Parameters = @($RedfishSession, $Path)
        [Void] $ParametersList.Add($Parameters)
      }

      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit export iBMC license task"))
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
function Remove-iBMCLicense {
<#
.SYNOPSIS
Delete iBMC License.

.DESCRIPTION
Delete iBMC License.
V3 servers and some V5 servers do not support this function. For details, see the iBMC User Guide.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
null
Returns null if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Delete-iBMCLicense -Session $session

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCLicense
Install-iBMCLicense
Export-iBMCLicense
Delete-iBMCLicense
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

    $Logger.info("Invoke delete iBMC license function")

    $ScriptBlock = {
      param($RedfishSession, $ExportTo)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke delete iBMC license now"))
      $Payload = @{}
      $Path = "/Managers/$($RedfishSession.Id)/LicenseService/Actions/LicenseService.DeleteLicense"
      Invoke-RedfishRequest $RedfishSession $Path 'POST' $Payload | Out-Null
      return $Null
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit delete iBMC license task"))
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