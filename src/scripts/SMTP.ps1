<# NOTE: iBMC SMTP module Cmdlets #>

. $PSScriptRoot/../common/Types.ps1

function Get-iBMCSMTPSetting {
<#
.SYNOPSIS
Get iBMC SMTP Basic Settings.

.DESCRIPTION
Get iBMC SMTP Basic Settings.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[]
Returns PSObject indicates SMTP Basic Settings if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Get-iBMCSMTPSetting -Session $session

ServiceEnabled        : True
ServerAddress         : smtp.qq.com
TLSEnabled            : True
AnonymousLoginEnabled : False
SenderUserName        : smtp-sender@huawei.com
SenderAddress         : xmufive@qq.com
EmailSubject          : Server Alert
EmailSubjectContains  : {HostName, BoardSN, ProductAssetTag}
AlarmSeverity         : Major

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Set-iBMCSMTPSetting
Get-iBMCSMTPRecipients
Set-iBMCSMTPRecipient
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

    $Logger.info("Invoke Get iBMC SMTP Settings function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke get iBMC SMTP Settings now"))
      $Path = "/Managers/$($RedfishSession.Id)/SmtpService"
      $Response = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
      $Properties = @(
        "ServiceEnabled", "ServerAddress", "TLSEnabled", "AnonymousLoginEnabled",
        "SenderUserName", "SenderAddress", "EmailSubject", "EmailSubjectContains", "AlarmSeverity"
      )
      $SMTP = Copy-ObjectProperties $Response $Properties
      return $SMTP
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit get iBMC SMTP Settings task"))
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

function Set-iBMCSMTPSetting {
<#
.SYNOPSIS
Modify iBMC SMTP Basic Settings.

.DESCRIPTION
Modify iBMC SMTP Basic Settings.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER ServiceEnabled
Indicates whether SMTP is enabled.
Support values are powershell boolean value: $true, $false.

.PARAMETER ServerAddress
Indicates the SMTP server address.

.PARAMETER TLSEnabled
Indicates whether TLS is enabled in the SMTP server.
Support values are powershell boolean value: $true, $false.

.PARAMETER AnonymousLoginEnabled
Indicates whether anonymous login is enabled.
Support values are powershell boolean value: $true, $false.

.PARAMETER SenderUserName
Indicates the User name of the email sender.

.PARAMETER SenderAddress
Indicates the mailbox address of the email sender.

.PARAMETER SenderPassword
Indicates the User password of the email sender.

.PARAMETER EmailSubject
Indicates the subject of the email to be sent.

.PARAMETER EmailSubjectContains
Indicates the server identity injected in the email subject.
The subject can contain one or more of the following:
- HostName: Host name
- BoardSN: Board serial number
- ProductAssetTag: Product asset tab

.PARAMETER AlarmSeverity
Indicates the severity levels of the alarm to be sent
Available Value Set: Critical, Major, Minor, Normal
- Critical (critical)
- Major (major and higher)
- Minor (minor and higher)
- Normal (normal and higher)

.OUTPUTS
Null
Returns Null if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $pwd = ConvertTo-SecureString -String "pwd12#$%^" -AsPlainText -Force
PS C:\> $ServerIdentifer = ,@('HostName', 'BoardSN')
PS C:\> Set-iBMCSMTPSetting $session -ServiceEnabled $false -ServerAddress smtp.huawei.com `
          -TLSEnabled $false -AnonymousLoginEnabled $false `
          -SenderUserName 'Huawei-iBMC' -SenderAddress "powershell@huawei.com"  -SenderPassword $pwd `
          -EmailSubject 'iBMC Alarm Notification' -EmailSubjectContains $ServerIdentifer `
          -AlarmSeverity Critical


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCSMTPSetting
Get-iBMCSMTPRecipients
Set-iBMCSMTPRecipient
Connect-iBMC
Disconnect-iBMC

#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session,

    [Boolean[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $ServiceEnabled,

    [String[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $ServerAddress,

    [Boolean[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $TLSEnabled,

    [Boolean[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $AnonymousLoginEnabled,

    [String[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $SenderUserName,

    [String[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $SenderAddress,

    [SecureString[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $SenderPassword,

    [String[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $EmailSubject,

    [ServerIdentity[][]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $EmailSubjectContains,

    [AlarmSeverity[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $AlarmSeverity
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    $ServiceEnabledList = Get-OptionalMatchedSizeArray $Session $ServiceEnabled
    $ServerAddressList = Get-OptionalMatchedSizeArray $Session $ServerAddress
    $TLSEnabledList = Get-OptionalMatchedSizeArray $Session $TLSEnabled
    $AnonymousLoginEnabledList = Get-OptionalMatchedSizeArray $Session $AnonymousLoginEnabled
    $SenderUserNameList = Get-OptionalMatchedSizeArray $Session $SenderUserName
    $SenderAddressList = Get-OptionalMatchedSizeArray $Session $SenderAddress
    $SenderPasswordList = Get-OptionalMatchedSizeArray $Session $SenderPassword
    $EmailSubjectList = Get-OptionalMatchedSizeArray $Session $EmailSubject

    $ValidSet = Get-EnumNames "ServerIdentity"
    $EmailSubjectContainsList = Get-OptionalMatchedSizeMatrix $Session $EmailSubjectContains `
      $ValidSet 'Session' 'EmailSubjectContains'
    $AlarmSeverityList = Get-OptionalMatchedSizeArray $Session $AlarmSeverity

    $Logger.info("Invoke Set iBMC SMTP Settings function")

    $ScriptBlock = {
      param($RedfishSession, $Payload)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Set iBMC SMTP Settings now"))
      $Path = "/Managers/$($RedfishSession.Id)/SmtpService"
      if ($Payload.SenderPassword -is [securestring]) {
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Payload.SenderPassword)
        $PlainPasswd = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        $Payload.SenderPassword = $PlainPasswd
      }
      $Response = Invoke-RedfishRequest $RedfishSession $Path 'Patch' $Payload
      Resolve-RedfishPartialSuccessResponse $RedfishSession $Response | Out-Null
      return $null
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Payload = @{
          ServiceEnabled        = $ServiceEnabledList[$idx];
          ServerAddress         = $ServerAddressList[$idx];
          TLSEnabled            = $TLSEnabledList[$idx];
          AnonymousLoginEnabled = $AnonymousLoginEnabledList[$idx];
          SenderUserName        = $SenderUserNameList[$idx];
          SenderAddress         = $SenderAddressList[$idx];
          SenderPassword        = $SenderPasswordList[$idx];
          EmailSubject          = $EmailSubjectList[$idx];
          EmailSubjectContains  = $EmailSubjectContainsList[$idx];
          AlarmSeverity         = $AlarmSeverityList[$idx];
        } | Remove-EmptyValues | Resolve-EnumValues

        if ($Payload.Count -eq 0) {
          throw $(Get-i18n ERROR_NO_UPDATE_PAYLOAD)
        }

        $Parameters = @($RedfishSession, $Payload)
        $Logger.info($(Trace-Session $RedfishSession "Submit Set iBMC SMTP Settings task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $Parameters))
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


function Get-iBMCSMTPRecipients {
<#
.SYNOPSIS
Get iBMC SMTP notify recipients of alarm emails.

.DESCRIPTION
Get iBMC SMTP notify recipients of alarm emails.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[][]
Returns PSObject Array indicates SMTP notify recipients if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $recipients = Get-iBMCSMTPRecipients -Session $session
PS C:\> $recipients

MemberId Enabled EmailAddress    Description
-------- ------- ------------    -----------
0           True xmufive@qq.com  test 1
1           True test@huawei.com test
2          False
3          False

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCSMTPSetting
Set-iBMCSMTPSetting
Set-iBMCSMTPRecipient
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

    $Logger.info("Invoke Get iBMC SMTP Notification Recipients function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get iBMC SMTP Notification Recipients now"))
      $Path = "/Managers/$($RedfishSession.Id)/SmtpService"
      $Response = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
      return , $Response.RecipientAddresses
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get iBMC SMTP Notification Recipients task"))
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


function Set-iBMCSMTPRecipient {
<#
.SYNOPSIS
Modify iBMC SMTP notify recipient of alarm emails.

.DESCRIPTION
Modify iBMC SMTP notify recipient of alarm emails.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER MemberId
Indicates which notification recipient to modify.
MemberId is the unique primary ID for notification recipient.
Support integer value range: [0, 3]

.PARAMETER Enabled
Indicates Whether the notification recipient is enabled.
Support values are powershell boolean value: $true, $false.

.PARAMETER EmailAddress
Indicates the notificate recipient mailbox address.

.PARAMETER Description
Indicates the description of this recipient

.OUTPUTS
Null
Returns Null if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Set-iBMCSMTPRecipient $session -MemberId 1 -Enabled $true -EmailAddress r2@huawei.com -Description 'desc'


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCSMTPSetting
Set-iBMCSMTPSetting
Get-iBMCSMTPRecipients
Connect-iBMC
Disconnect-iBMC

#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session,

    [int32[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateRange(0, 3)]
    $MemberId,

    [Boolean[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $Enabled,

    [String[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $EmailAddress,

    [String[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $Description
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $MemberId 'MemberId'
    $MemberIdList = Get-MatchedSizeArray $Session $MemberId
    $EnabledList = Get-OptionalMatchedSizeArray $Session $Enabled
    $EmailAddressList = Get-OptionalMatchedSizeArray $Session $EmailAddress
    $DescriptionList = Get-OptionalMatchedSizeArray $Session $Description

    $Logger.info("Invoke Set BMC SMTP Recipient function")

    $ScriptBlock = {
      param($RedfishSession, $MemberId, $Payload)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Set BMC SMTP Recipient now"))
      $Path = "/Managers/$($RedfishSession.Id)/SmtpService"

      $Recipients = New-Object System.Collections.ArrayList
      for ($idx = 0; $idx -lt 4; $idx++) {
        if ($MemberId -eq $idx) {
          [Void] $Recipients.Add($Payload)
        }
        else {
          [Void] $Recipients.Add(@{})
        }
      }

      $CompletePlayload = @{ RecipientAddresses = $Recipients; }
      $Response = Invoke-RedfishRequest $RedfishSession $Path 'Patch' $CompletePlayload
      Resolve-RedfishPartialSuccessResponse $RedfishSession $Response | Out-Null
      return $null
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $MemberId = $MemberIdList[$idx];
        $Payload = Remove-NoneValues @{
          Enabled      = $EnabledList[$idx];
          EmailAddress = $EmailAddressList[$idx];
          Description  = $DescriptionList[$idx];
        }

        if ($Payload.Count -eq 0) {
          throw $(Get-i18n ERROR_NO_UPDATE_PAYLOAD)
        }

        $Parameters = @($RedfishSession, $MemberId, $Payload)
        $Logger.info($(Trace-Session $RedfishSession "Submit Set BMC SMTP Recipient task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $Parameters))
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
