# Copyright (C) 2020 Huawei Technologies Co., Ltd. All rights reserved.	
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the MIT License		

# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# MIT License for more detail

<# NOTE: iBMC LDAP module Cmdlets #>

function Get-iBMCLDAP {
<#
.SYNOPSIS
Get all iBMC LDAP Controls infomation or specific LDAP domain information.

.DESCRIPTION
Get all iBMC LDAP Controls infomation or specific LDAP domain information.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER LDAPID
LDAP ID specifies the LDAP to be modified.
Optional parameter, if not specified, all domain controller information will be queried
Support integer value range: [1, 6]

.OUTPUTS
PSObject[]
Returns Array of PSObject indicates all iBMC LDAP Controls Reading infomation or specific LDAP domain information if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $Credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 192.168.1.1 -Credential $Credential -TrustCert
PS C:\> $Result = Get-iBMCLDAP -Session $Session
PS C:\> $Result | fl

Host                           : 192.168.1.1
Id                             : LdapService
Name                           : Ldap Service
LdapServiceEnabled             : True

Id                             : 1
Name                           : Ldap Controller
LdapServerAddress              : 192.168.1.10
LdapPort                       : 666
UserDomain                     : CN,DC=DD
BindDN                         : 
BindPassword                   : 
CertificateVerificationEnabled : False
CertificateVerificationLevel   : Demand

Id                             : 2
Name                           : Ldap Controller
LdapServerAddress              : 
LdapPort                       : 636
UserDomain                     : ,DC=
BindDN                         : 
BindPassword                   : 
CertificateVerificationEnabled : False
CertificateVerificationLevel   : Demand

Id                             : 3
Name                           : Ldap Controller
LdapServerAddress              : 
LdapPort                       : 636
UserDomain                     : ,DC=
BindDN                         : 
BindPassword                   : 
CertificateVerificationEnabled : False
CertificateVerificationLevel   : Demand

Id                             : 4
Name                           : Ldap Controller
LdapServerAddress              : 
LdapPort                       : 636
UserDomain                     : ,DC=
BindDN                         : 
BindPassword                   : 
CertificateVerificationEnabled : False
CertificateVerificationLevel   : Demand

Id                             : 5
Name                           : Ldap Controller
LdapServerAddress              : 
LdapPort                       : 636
UserDomain                     : ,DC=
BindDN                         : 
BindPassword                   : 
CertificateVerificationEnabled : False
CertificateVerificationLevel   : Demand

Id                             : 6
Name                           : Ldap Controller
LdapServerAddress              : 
LdapPort                       : 636
UserDomain                     : ,DC=
BindDN                         : 
BindPassword                   : 
CertificateVerificationEnabled : False
CertificateVerificationLevel   : Demand

This example shows how to query the LDAP information of multiple server

.EXAMPLE

PS C:\> $Credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 192.168.1.1 -Credential $Credential -TrustCert
PS C:\> $LDAPID = 1
PS C:\> Get-iBMCLDAP -Session $Session -LDAPID $LDAPID

Host                           : 192.168.1.1
Id                             : 1
Name                           : Ldap Controller
LdapServerAddress              : 
LdapPort                       : 636
UserDomain                     : ,DC=
BindDN                         : 
BindPassword                   : 
CertificateVerificationEnabled : False
CertificateVerificationLevel   : 
CertificateInformation         : 
CertificateChainInformation    : 
LdapGroups                     : {@{MemberId=0; GroupName=; GroupDomain=CN=,OU=,DC=; GroupRole=No Access; GroupLoginRule=System.Object[]; 
                                 GroupLoginInterface=System.Object[]}, @{MemberId=1; GroupName=; GroupDomain=CN=,OU=,DC=; GroupRole=No Access; 
                                 GroupLoginRule=System.Object[]; GroupLoginInterface=System.Object[]}, @{MemberId=2; GroupName=; GroupDomain=CN=,OU=,DC=; 
                                 GroupRole=No Access; GroupLoginRule=System.Object[]; GroupLoginInterface=System.Object[]}, @{MemberId=3; GroupName=; 
                                 GroupDomain=CN=,OU=,DC=; GroupRole=No Access; GroupLoginRule=System.Object[]; GroupLoginInterface=System.Object[]}...}

This example shows how to query information about the specified domain controller

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Set-iBMCLDAPServiceEnabled
Set-iBMCLDAP
Import-iBMCLDAPCert
Connect-iBMC
Disconnect-iBMC

#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $Session,

    [int32[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateRange(1, 6)]
    $LDAPID
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    $LDAPIDList = Get-OptionalMatchedSizeArray $Session $LDAPID
    $Logger.info("Invoke Get All LDAP Domain Information Or Specific LDAP Domain Information function")

    $GetLDAPBlock = {
      param($Session, $LDAPID)
      $(Get-Logger).info($(Trace-Session $Session "Invoke Get All LDAP Domain Information Or Specific LDAP Domain Information function now"))

      if ($LDAPID) {
        $LDAPDetailsPath = "/AccountService/LdapService/LdapControllers/$LDAPID"
        $LDAPDetailsResponse = Invoke-RedfishRequest $Session $LDAPDetailsPath | ConvertFrom-WebResponse
        $LDAPDetailsResults = New-Object System.Collections.ArrayList
        $Properties = @("Id", "Name", "LdapServerAddress", "LdapPort", "UserDomain", "BindDN", "BindPassword",
                        "CertificateVerificationEnabled", "CertificateVerificationLevel", "CertificateInformation",
                        "CertificateChainInformation", "LdapGroups")
        $LDAPDetailsInfo = Copy-ObjectProperties $LDAPDetailsResponse $Properties
        [Void] $LDAPDetailsResults.Add($(Update-SessionAddress $Session $LDAPDetailsInfo))
        return , $LDAPDetailsResults.ToArray()
      }
      else {
        $Results = New-Object System.Collections.ArrayList

        $LDAPEnablePath = "/AccountService/LdapService/"
        $LDAPEnableResponse = Invoke-RedfishRequest $Session $LDAPEnablePath | ConvertFrom-WebResponse
        $LDAPEnableInfo = New-Object PSObject
        $LDAPEnableInfo | Add-Member -MemberType NoteProperty "Id" $LDAPEnableResponse.Id
        $LDAPEnableInfo | Add-Member -MemberType NoteProperty "Name" $LDAPEnableResponse.Name
        $LDAPEnableInfo | Add-Member -MemberType NoteProperty "LdapServiceEnabled" $LDAPEnableResponse.LdapServiceEnabled
        $LDAPEnableInfo = $(Update-SessionAddress $Session $LDAPEnableInfo)
        [Void] $Results.Add($LDAPEnableInfo)

        $Path = "/AccountService/LdapService/LdapControllers/"
        $Response = Invoke-RedfishRequest $Session $Path | ConvertFrom-WebResponse
        $LDAPControllers = $Response.Members
        $LDAPControllers | ForEach-Object {
          $LDAPResponse = Invoke-RedfishRequest $Session $_.'@odata.id' | ConvertFrom-WebResponse
          $LDAPInfo = New-Object PSObject
          $LDAPInfo | Add-Member -MemberType NoteProperty "Id" $LDAPResponse.Id
          $LDAPInfo | Add-Member -MemberType NoteProperty "Name" $LDAPResponse.Name
          $LDAPInfo | Add-Member -MemberType NoteProperty "LdapServerAddress" $LDAPResponse.LdapServerAddress
          $LDAPInfo | Add-Member -MemberType NoteProperty "LdapPort" $LDAPResponse.LdapPort
          $LDAPInfo | Add-Member -MemberType NoteProperty "UserDomain" $LDAPResponse.UserDomain
          $LDAPInfo | Add-Member -MemberType NoteProperty "BindDN" $LDAPResponse.BindDN
          $LDAPInfo | Add-Member -MemberType NoteProperty "BindPassword" $LDAPResponse.BindPassword
          $LDAPInfo | Add-Member -MemberType NoteProperty "CertificateVerificationEnabled" $LDAPResponse.CertificateVerificationEnabled
          $LDAPInfo | Add-Member -MemberType NoteProperty "CertificateVerificationLevel" $LDAPResponse.CertificateVerificationLevel
        
          [Void] $Results.Add($LDAPInfo)
        }
        return , $Results.ToArray()
      }
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $LDAP = $LDAPIDList[$idx]
        $Parameters = @($RedfishSession, $LDAP)
        $Logger.info($(Trace-Session $RedfishSession "Submit get all LDAP information task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $GetLDAPBlock $Parameters))
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

function Set-iBMCLDAPServiceEnabled {
<#
.SYNOPSIS
Modify the enabling status of the LDAP service.

.DESCRIPTION
Modify the enabling status of the LDAP service.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER LdapServiceEnabled
Ldap function enable. This parameter controls the enabling status of all domain controllers.
Support values are powershell boolean value: $true(1), $false(0).

.OUTPUTS
PSObject[]
Returns the modified LDAP service object array if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $Credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 192.168.1.1 -Credential $Credential -TrustCert
PS C:\> $Result = Set-iBMCLDAPServiceEnabled -Session $Session -LdapServiceEnabled $true
PS C:\> $Result

Host               : 192.168.1.1
Id                 : LdapService
Name               : Ldap Service
LdapServiceEnabled : true

Modify LDAP service enabled properties of a server.

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCLDAP
Import-iBMCLDAPCert
Set-iBMCLDAP
Connect-iBMC
Disconnect-iBMC

#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position=0)]
    $Session,

    [Boolean[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $LdapServiceEnabled
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $LdapServiceEnabled 'LdapServiceEnabled'
    $Enableds = Get-OptionalMatchedSizeArray $Session $LdapServiceEnabled

    $SetLdapServiceEnabledBlock = {
      param($Session, $LdapServiceEnabled)
      $Payload = @{LdapServiceEnabled=$LdapServiceEnabled;}
      # Get Ldap service resources
      $LdapServicePath = '/AccountService/LdapService/'
      $LdapServiceResponse = Invoke-RedfishRequest $Session $LdapServicePath
      $Headers = @{'If-Match'=$LdapServiceResponse.Headers['Etag'];}
      $Response = Invoke-RedfishRequest $Session $LdapServicePath 'Patch' $Payload $Headers
      $SetLdapServiceEnabled = Resolve-RedfishPartialSuccessResponse $Session $Response
      $Properties = @("Id", "Name", "LdapServiceEnabled")
      $PrettyLdapService = Copy-ObjectProperties $SetLdapServiceEnabled $Properties
      return $(Update-SessionAddress $Session $PrettyLdapService)
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx=0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Parameters = @($RedfishSession, $Enableds[$idx])
        $Logger.info($(Trace-Session $RedfishSession "Submit set LDAP service enabled task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $SetLdapServiceEnabledBlock $Parameters))
      }
      return Get-AsyncTaskResults -AsyncTasks $tasks
    }
    finally {
      Close-Pool $pool
    }
  }

  end {
  }
}

function Import-iBMCLDAPCert {
<#
.SYNOPSIS
Import iBMC LDAP Certificate.

.DESCRIPTION
Import iBMC LDAP Certificate.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER LDAPID
LDAP ID specifies the LDAP to be modified.
Support integer value range: [1, 6]

.PARAMETER LDAPCertPath
The LDAP certificate file path

File path support:
1. import from local storage, example: c:\ca.cer or \\192.168.1.2\ca.cer
2. import from ibmc local temporary storage, example: /tmp/ca.cer
3. import from remote storage, example: protocol://username:password@hostname/directory/ca.cer
   support protocol list: sftp, https, nfs, cifs, scp


.OUTPUTS
PSObject[]
Returns the import The LDAP certificate task array if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $Credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 192.168.1.1 -Credential $Credential -TrustCert
PS C:\> $Result = Import-iBMCLDAPCert -Session $Session -LDAPID 1 -LDAPCertPath 'c:\ca.cer'
PS C:\> $Result

Host              : 192.168.1.1
MessageId         : iBMC.1.0.LDAPCertImportSuccess
RelatedProperties : 
Message           : The LDAP certificate is imported successfully.
MessageArgs       : 
Severity          : OK
Resolution        : None

This example shows how to import LDAP certificate from local file

.EXAMPLE

PS C:\> $Credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 192.168.1.1 -Credential $Credential -TrustCert
PS C:\> $Result = Import-iBMCLDAPCert -Session $Session -LDAPID 1 -LDAPCertPath "nfs://192.168.1.100/data/ldap.cer"
PS C:\> $Result

Host         : 192.168.1.1
Id           : 1
Name         : ldap root cert import
ActivityName : [192.168.1.1] ldap root cert import
TaskState    : Completed
StartTime    : 2019-11-28T16:44:46+08:00
EndTime      : 2019-11-28T16:44:47+08:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to import LDAP certificate from remote file

.EXAMPLE

PS C:\> $Credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 192.168.1.1 -Credential $Credential -TrustCert
PS C:\> $LocalFilePath = 'c:\ca.cer'
PS C:\> $Upload = Invoke-iBMCFileUpload -Session $Session -FileUri $LocalFilePath
PS C:\> $Result = Import-iBMCLDAPCert -Session $session -LDAPID 1 -LDAPCertPath $Upload.Path
PS C:\> $Result

Host              : 192.168.1.1
MessageId         : iBMC.1.0.LDAPCertImportSuccess
RelatedProperties : 
Message           : The LDAP certificate is imported successfully.
MessageArgs       : 
Severity          : OK
Resolution        : None

This example shows how to upload local file to BMC and then import LDAP certificate from the upload bmc file


.EXAMPLE

PS C:\> $Credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 192.168.1.1-3 -Credential $Credential -TrustCert
PS C:\> $LDAPID = @(1, 2)
PS C:\> $LDAPCertPath = @("c:\ldap.cer", "nfs://192.168.1.100/data/ldap.cer")
PS C:\> $Result = Import-iBMCLDAPCert -Session $Session -LDAPID $LDAPID -LDAPCertPath $LDAPCertPath
PS C:\> $Result

Host              : 192.168.1.1
MessageId         : iBMC.1.0.LDAPCertImportSuccess
RelatedProperties : 
Message           : The LDAP certificate is imported successfully.
MessageArgs       : 
Severity          : OK
Resolution        : None

Host         : 192.168.1.3
Id           : 2
Name         : ldap root cert import
ActivityName : [192.168.1.3] ldap root cert import
TaskState    : Completed
StartTime    : 2019-11-29T00:38:07+08:00
EndTime      : 2019-11-29T00:38:08+08:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to import LDAP certificate to different servers

.EXAMPLE

PS C:\> $Credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 192.168.1.1-2 -Credential $Credential -TrustCert
PS C:\> $LDAPID = @(1, 2)
PS C:\> $LDAPCertPath = @("c:\ldap.cer", "sftp://192.168.1.3/data/ldap.cer")
PS C:\> $Result = Import-iBMCLDAPCert -Session $Session -LDAPID $LDAPID -LDAPCertPath $LDAPCertPath -SecureEnabled
PS C:\> $Result

Host              : 192.168.1.1
MessageId         : iBMC.1.0.LDAPCertImportSuccess
RelatedProperties : 
Message           : The LDAP certificate is imported successfully.
MessageArgs       : 
Severity          : OK
Resolution        : None

Host         : 192.168.1.2
Id           : 2
Name         : ldap root cert import
ActivityName : [192.168.1.3] ldap root cert import
TaskState    : Completed
StartTime    : 2019-11-29T00:38:07+08:00
EndTime      : 2019-11-29T00:38:08+08:00
TaskStatus   : OK
TaskPercent  : 100%

This example shows how to import LDAP certificate to different servers with secure parameter


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCLDAP
Set-iBMCLDAPServiceEnabled
Set-iBMCLDAP
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
    [ValidateRange(1, 6)]
    $LDAPID,

    [string[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 2)]
    $LDAPCertPath,

    [switch]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $SecureEnabled
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $LDAPID 'LDAPID'
    Assert-ArrayNotNull $LDAPCertPath 'LDAPCertPath'
    $LDAPIDList = Get-MatchedSizeArray $Session $LDAPID 'Session' 'LDAPID'
    $LDAPCertPathList = Get-MatchedSizeArray $Session $LDAPCertPath 'Session' 'LDAPCertPath'

    if ($SecureEnabled) {
      $SensitiveInfo = @(Get-SensitiveInfo)
      $SensitiveInfoList = Get-OptionalMatchedSizeArray $Session $SensitiveInfo
    }

    $Logger.info("Invoke Import LDAP certificates function, batch size: $($Session.Count)")

    $ImportLDAPCertBlock = {
      param($RedfishSession, $LDAPID, $CertificateFilePath)
      
      $payload = @{'Type' = "URI";}
      if ($CertificateFilePath.StartsWith("/tmp")) {
        $payload.Content = $CertificateFilePath
      } else {
        $ContentURI = Invoke-FileUploadIfNeccessary $RedfishSession $CertificateFilePath $BMC.LDAPCertSupportSchema
        $Payload.Content = $ContentURI
      }

      $Clone = $Payload.clone()
      $Clone.Content = Protect-NetworkUriUserInfo $Payload.Content
      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Clone | ConvertTo-Json)"))
      $Path = "/redfish/v1/AccountService/LdapService/LdapControllers/$LDAPID/Actions/HwLdapController.ImportCert"
      $Response = Invoke-RedfishRequest $RedfishSession $Path 'Post' $payload | ConvertFrom-WebResponse
      if ($Response.error) {
        $LDAPLocalImportResults = $Response.error.'@Message.ExtendedInfo'
        $ImportResult = New-Object PSObject
        $ImportResult | Add-Member -MemberType NoteProperty "MessageId" $LDAPLocalImportResults.MessageId
        $ImportResult | Add-Member -MemberType NoteProperty "RelatedProperties" $LDAPLocalImportResults.RelatedProperties
        $ImportResult | Add-Member -MemberType NoteProperty "Message" $LDAPLocalImportResults.Message
        $ImportResult | Add-Member -MemberType NoteProperty "MessageArgs" $LDAPLocalImportResults.MessageArgs
        $ImportResult | Add-Member -MemberType NoteProperty "Severity" $LDAPLocalImportResults.Severity
        $ImportResult | Add-Member -MemberType NoteProperty "Resolution" $LDAPLocalImportResults.Resolution
        return $(Update-SessionAddress $RedfishSession $ImportResult)
      }
      return $Response
    }

    try {
      $Results = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      $LocalTasks = New-Object System.Collections.ArrayList
      $RemoteTasks = New-Object System.Collections.ArrayList
      $RemoteSession = New-Object System.Collections.ArrayList
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $CertificateFilePath = $LDAPCertPathList[$idx]
        $_LDAPID = $LDAPIDList[$idx]
        if ($SecureEnabled) {
          $SensitiveInfo = $SensitiveInfoList[$idx]
          $CertificateFilePath = Get-CompleteUri $SensitiveInfo $CertificateFilePath
        }
        $Logger.info($(Trace-Session $RedfishSession "Submit import LDAP certificate task"))
        $Parameters = @($RedfishSession, $_LDAPID, $CertificateFilePath)

        if ($CertificateFilePath.StartsWith("/tmp")) {
          [Void] $LocalTasks.Add($(Start-ScriptBlockThread $pool $ImportLDAPCertBlock $Parameters))
        }
        else{
          $Schema = ""
          try {
            $CertFileUri = New-Object System.Uri($CertificateFilePath)
            $Schema = $CertFileUri.Scheme
          } catch {
            $Logger.info("LDAP cert file path can not convert into system uri")
            $Schema = $CertificateFilePath.Substring(0, $CertificateFilePath.IndexOf("://"))
          }
          if ($Schema -notin $BMC.LDAPCertRemoteImportSupportSchema) {
            [Void] $LocalTasks.Add($(Start-ScriptBlockThread $pool $ImportLDAPCertBlock $Parameters))
          }
          else {
            [Void] $RemoteSession.Add($RedfishSession)
            [Void] $RemoteTasks.Add($(Start-ScriptBlockThread $pool $ImportLDAPCertBlock $Parameters))
          }
        }
      }
      # Get local import result
      if ($LocalTasks.Count -gt 0) {
        $LocalResult = Get-AsyncTaskResults $LocalTasks
        [Void] $Results.Add($LocalResult)
      }  
      # Get remote import result
      if ($RemoteTasks.Count -gt 0) {
        $RemoteResult = Get-AsyncTaskResults $RemoteTasks
        $RemoteWaitResult = Wait-RedfishTasks $pool $RemoteSession $RemoteResult -ShowProgress
        [Void] $Results.Add($RemoteWaitResult)
      }
      
      return , $Results
    }
    finally {
      Close-Pool $pool
    }
  }

  end {
  }
}

function Set-iBMCLDAP {
<#
.SYNOPSIS
Modify an existing iBMC LDAP infomation.

.DESCRIPTION
Modify an existing iBMC LDAP infomation. Specifies an existing LDAP sequence number.

Modify the following properties of a LDAP:
- LDAP Address
- LDAP Port
- User Domain
- Bind DN
- Bind Password
- Certificate Verification Enabled
- Certificate Verification Level
- LDAP Group Name
- LDAP Group Domain
- LDAP Group Role
- LDAP Group LoginRole
- LDAP Group LoginInterface

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER LDAPID
LDAP ID specifies the LDAP to be modified.
Support integer value range: [1, 6]

.PARAMETER LDAPAddress
LDAPAddress specifies the new LDAP address of the modified LDAP.

.PARAMETER LDAPPort
LDAPPort specifies the new LDAP port of the modified LDAP.
Support integer value range: [0, 65535]

.PARAMETER UserDomain
UserDomain specifies the new LDAP domain of the modified LDAP.
In the format of CN=A,OU=B,DC=C, the CN and DC values must be included. For example:
CN=1,DC=2.

.PARAMETER BindDN
BindDN specifies the new LDAP bindDN of the modified LDAP.
A string of 0 to 255 characters.

.PARAMETER BindPassword
BindPassword specifies the new LDAP bind password of the modified LDAP.
A string of 0 to 20 characters.

.PARAMETER CertificateVerificationEnabled
Enabled specifies Whether the certificate verification is enabled. A power shell bool($true|$false) value is accept.

.PARAMETER CertificateVerificationLevel
CertificateVerificationLevel specifies the new LDAP certificate verification level of the modified LDAP.
This parameter is used when the certificate is enabled.
Available CertificateVerificationLevel value set is:
- "Demand"
- "Allow"

.PARAMETER GroupID
Add an LDAP group ID or modify an existing group ID.
Support integer value range: [0, 4]

.PARAMETER GroupName
GroupName specifies the new LDAP group name of the modified LDAP group.
When the group_name value is null, the group configuration information is deleted.

.PARAMETER GroupDomain
GroupDomain specifies the new LDAP group group domain of the modified LDAP group.
Character string type. The format is as follows:
CN=qwert,OU=admin,DC=huawei,DC=com

.PARAMETER GroupRole
GroupRole specifies the new LDAP group role of the modified LDAP group.
Available role value set is:
- "Administrator"
- "Operator"
- "Commonuser"
- "CustomRole1"
- "CustomRole2"
- "CustomRole3"
- "CustomRole4"

.PARAMETER GroupLoginRole
GroupLoginRole specifies the new LDAP group login role of the modified LDAP group.
Available role value set is:
- "Rule1"
- "Rule2"
- "Rule3"

.PARAMETER GroupLoginInterface
GroupLoginInterface specifies the new LDAP group login interface of the modified LDAP group.
Available role value set is:
- "Web"
- "SSH"
- "Redfish"

.OUTPUTS
PSObject[]
Returns the modified LDAP object array if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $Credential = Get-Credential
PS C:\> $Session = Connect-iBMC -Address 192.168.1.1 -Credential $Credential -TrustCert
PS C:\> $BindPwd = ConvertTo-SecureString -String bind-password -AsPlainText -Force
PS C:\> $GroupLoginRule = ,@("Rule1", "Rule2", "Rule3")
PS C:\> $GroupLoginInterface = ,@("Web","SSH","Redfish")
PS C:\> $result = Set-iBMCLDAP -Session $Session -LDAPID 1 -LDAPAddress "ldap.huawei.com" -LDAPPort 635 `
          -UserDomain 'CN=test,,DC=huawei,DC=com' -BindDN test -BindPassword $BindPwd `
          -CertificateVerificationEnabled $true -CertificateVerificationLevel Allow `
          -GroupID 0 -GroupName qwert -GroupDomain 'CN=qwert,OU=admin,DC=huawei,DC=com' `
          -GroupRole Administrator -GroupLoginRule $GroupLoginRule -GroupLoginInterface $GroupLoginInterface

Modify information about the specified domain controller.

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCLDAP
Import-iBMCLDAPCert
Import-iBMCLDAPCert
Connect-iBMC
Disconnect-iBMC

#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position=0)]
    $Session,

    [int32[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateRange(1, 6)]
    $LDAPID,

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $LDAPAddress,

    [int32[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateRange(1, 65535)]
    $LDAPPort,

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $UserDomain,

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $BindDN,

    [System.Object[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $BindPassword,

    [Boolean[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $CertificateVerificationEnabled,

    [CertificateVerificationLevel[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $CertificateVerificationLevel,

    [int32[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateRange(0, 4)]
    $GroupID,

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $GroupName,

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $GroupDomain,

    [LDAPGroupRole[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $GroupRole,

    [GroupLoginRole[][]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $GroupLoginRule,

    [GroupLoginInterface[][]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $GroupLoginInterface
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $LDAPID 'LDAPID'
    $LdapIDs = Get-MatchedSizeArray $Session $LDAPID 'Session' 'LDAPID'
    $LDAPAddresses = Get-OptionalMatchedSizeArray $Session $LDAPAddress
    $LDAPPorts = Get-OptionalMatchedSizeArray $Session $LDAPPort
    $UserDomains = Get-OptionalMatchedSizeArray $Session $UserDomain
    $BindDNs = Get-OptionalMatchedSizeArray $Session $BindDN
    $BindPasswords = Get-OptionalMatchedSizeArray $Session $BindPassword
    $CertificateVerificationEnableds = Get-OptionalMatchedSizeArray $Session $CertificateVerificationEnabled
    $CertificateVerificationLevels = Get-OptionalMatchedSizeArray $Session $CertificateVerificationLevel
    $GroupIDs = Get-OptionalMatchedSizeArray $Session $GroupID
    $GroupNames = Get-OptionalMatchedSizeArray $Session $GroupName
    $GroupDomains = Get-OptionalMatchedSizeArray $Session $GroupDomain
    $GroupRoles = Get-OptionalMatchedSizeArray $Session $GroupRole
    $ValidGroupLoginroles = Get-EnumNames "GroupLoginRole"
    $GroupLoginRules = Get-OptionalMatchedSizeMatrix $Session $GroupLoginRule $ValidGroupLoginroles 'Session' 'GroupLoginRule'
    $ValidGroupLoginInterfaces = Get-EnumNames "GroupLoginInterface"
    $GroupLoginInterfaces = Get-OptionalMatchedSizeMatrix $Session $GroupLoginInterface $ValidGroupLoginInterfaces 'Session' 'GroupLoginInterface'

    $SetLDAPBlock = {
      param($RedfishSession, $ldapID, $Payload)
      
      $LDAPInfoPath = "/AccountService/LdapService/LdapControllers/$ldapID"   
      $Logger.info($(Trace-Session $RedfishSession "LDAP $ldapID found, will patch ldap now"))

      $Clone = $Payload.clone()
      if ($null -ne $Payload.BindPassword) {
            $PlainPasswd = ConvertTo-PlainString $Payload.BindPassword "BindPassword"
            $Payload.BindPassword = $PlainPasswd
            $Clone.BindPassword = "******"
      }

      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Clone | ConvertTo-Json -Depth 5)"))
      $Response = Invoke-RedfishRequest $RedfishSession $LDAPInfoPath 'Patch' $Payload
      Resolve-RedfishPartialSuccessResponse $RedfishSession $Response | Out-Null
      return $null
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx=0; $idx -lt $Session.Count; $idx++) {     
        $RedfishSession = $Session[$idx]
        $_LDAPID = $LdapIDs[$idx]
        $Payload = @{
          "LdapServerAddress" = $LDAPAddresses[$idx];
          "LdapPort" = $LDAPPorts[$idx];
          "UserDomain" = $UserDomains[$idx];
          "BindDN" = $BindDNs[$idx];
          "BindPassword" = $BindPasswords[$idx];
          "CertificateVerificationEnabled" = $CertificateVerificationEnableds[$idx];
          "CertificateVerificationLevel" = $CertificateVerificationLevels[$idx]
        } | Resolve-EnumValues

        $GroupInfo = @{
          "GroupName" = $GroupNames[$idx];
          "GroupDomain" = $GroupDomains[$idx];
          "GroupRole" = $GroupRoles[$idx];
          "GroupLoginRule" = $GroupLoginRules[$idx];
          "GroupLoginInterface" = $GroupLoginInterfaces[$idx]
        } | Remove-EmptyValues | Resolve-EnumValues
                
        $LDAPGroupID = $GroupIDs[$idx]
        $GroupList = New-Object System.Collections.ArrayList
        $flag = $false
        for ($i = 0; $i -lt 5; $i++) {
          if ($LDAPGroupID -eq $i) {
            [Void] $GroupList.Add($GroupInfo)
            if ($GroupInfo.Count -ne 0) {
              $flag = $true
            }
            else {
              # Group ID exists, but group info is null
              throw $(Get-i18n ERROR_LDAP_GROUPINFO_INVALID)
            }
          } else {
            [Void] $GroupList.Add(@{})
          }
        }

        # Group info exists, but group ID is null
        if ((-not $flag) -and ($GroupInfo.Count -ne 0)) {
          throw $(Get-i18n ERROR_LDAP_GROUPID_INVALID)
        }

        if ($flag) {
          # When group name is null, delete this group info
          if ($GroupList[$LDAPGroupID].GroupName -eq 'null') {
            $GroupList[$LDAPGroupID].GroupName = $null
          }

          # Covert group role
          if ($GroupList[$LDAPGroupID].GroupRole) {
            if ($GroupList[$LDAPGroupID].GroupRole -eq "Commonuser") {
              $GroupList[$LDAPGroupID].GroupRole = "Common User"
            }
            if ($GroupList[$LDAPGroupID].GroupRole -eq "CustomRole1") {
              $GroupList[$LDAPGroupID].GroupRole = "Custom Role 1"
            }
            if ($GroupList[$LDAPGroupID].GroupRole -eq "CustomRole2") {
              $GroupList[$LDAPGroupID].GroupRole = "Custom Role 2"
            }
            if ($GroupList[$LDAPGroupID].GroupRole -eq "CustomRole3") {
              $GroupList[$LDAPGroupID].GroupRole = "Custom Role 3"
            }
            if ($GroupList[$LDAPGroupID].GroupRole -eq "CustomRole4") {
              $GroupList[$LDAPGroupID].GroupRole = "Custom Role 4"
            }
          }

          $Payload.LdapGroups = $GroupList
        }
                
        $Payload_ = Remove-EmptyValues $Payload
        if ($Payload_.Count -eq 0) {
          throw $(Get-i18n FAIL_NO_UPDATE_PARAMETER)
        }

        $Parameters = @($RedfishSession, $_LDAPID, $Payload_)
        $Logger.info($(Trace-Session $RedfishSession "Submit set LDAP information task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $SetLDAPBlock $Parameters)) 
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