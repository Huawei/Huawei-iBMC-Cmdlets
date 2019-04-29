<# NOTE: iBMC SNMP module Cmdlets #>

function Get-iBMCSNMPSetting {
<#
.SYNOPSIS
Get iBMC SNMP Basic Settings.

.DESCRIPTION
Get iBMC SNMP Basic Settings.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[]
Returns PSObject indicates SNMP Basic Settings if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Get-iBMCSNMPSetting -Session $session

Host                : 10.1.1.2
SnmpV1Enabled       : False
SnmpV2CEnabled      : False
SnmpV3Enabled       : True
LongPasswordEnabled : True
RWCommunityEnabled  : True
SnmpV3AuthProtocol  : MD5
SnmpV3PrivProtocol  : DES

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Set-iBMCSNMPSetting
Get-iBMCSNMPTrapSetting
Set-iBMCSNMPTrapSetting
Get-iBMCSNMPTrapServer
Set-iBMCSNMPTrapServer
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

    $Logger.info("Invoke Get iBMC SNMP Settings function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke get iBMC SNMP Settings now"))
      $Path = "/Managers/$($RedfishSession.Id)/SnmpService"
      $Response = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
      $Properties = @(
        "SnmpV1Enabled", "SnmpV2CEnabled", "SnmpV3Enabled", "LongPasswordEnabled",
        "RWCommunityEnabled", "SnmpV3AuthProtocol", "SnmpV3PrivProtocol"
      )
      $Settings = Copy-ObjectProperties $Response $Properties
      return $(Update-SessionAddress $RedfishSession $Settings)
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit get iBMC SNMP Settings task"))
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

function Set-iBMCSNMPSetting {
<#
.SYNOPSIS
Modify iBMC SNMP Basic Settings.

.DESCRIPTION
Modify iBMC SNMP Basic Settings.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER SnmpV1Enabled
Indicates whether SNMPV1 is enabled.
Support values are powershell boolean value: $true(1), $false(0).

.PARAMETER SnmpV2CEnabled
Indicates whether SNMPV2C is enabled.
Support values are powershell boolean value: $true(1), $false(0).

.PARAMETER LongPasswordEnabled
Indicates whether long password is enabled.
Support values are powershell boolean value: $true(1), $false(0).

.PARAMETER RWCommunityEnabled
Indicates whether read-write community name is enabled.
Support values are powershell boolean value: $true(1), $false(0).

.PARAMETER ReadOnlyCommunity
Indicates the read only community name.
A character string that meets the following requirements:
- Cannot contain spaces.
- Contain 1 to 32 bytes by default or 16 to 32 bytes for long passwords.
- If password complexity check is enabled, the password must contain at least 8 bytes and contain at least two types of uppercase letters, lowercase letters, digits, and special characters.
- Have at least two new characters when compared with the previous community name.
- Read-only community name and Read-write community name must be different.

.PARAMETER ReadWriteCommunity
Indicates the read write community name.
A character string that meets the following requirements:
- Cannot contain spaces.
- Contain 1 to 32 bytes by default or 16 to 32 bytes for long passwords.
- If password complexity check is enabled, the password must contain at least 8 bytes and contain at least two types of uppercase letters, lowercase letters, digits, and special characters.
- Have at least two new characters when compared with the previous community name.
- Read-only community name and Read-write community name must be different.

.PARAMETER SnmpV3AuthProtocol
Indicates the SNMPv3 authentication algorithm.
Available Value Set: ('MD5', 'SHA')

.PARAMETER SnmpV3PrivProtocol
Indicates the SNMPv3 encryption algorithm.
Available Value Set: ('DES', 'AES')

.OUTPUTS
Null
Returns Null if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $ReadOnlyCommunity = ConvertTo-SecureString -String "SomeP@ssw0rd1" -AsPlainText -Force
PS C:\> $ReadWriteCommunity = ConvertTo-SecureString -String "SomeP@ssw0rd2" -AsPlainText -Force
PS C:\> Set-iBMCSNMPSetting $session -SnmpV1Enabled $false -SnmpV2CEnabled $false `
        -LongPasswordEnabled $true -RWCommunityEnabled $true `
        -ReadOnlyCommunity $ReadOnlyCommunity -ReadWriteCommunity $ReadWriteCommunity `
        -SnmpV3AuthProtocol MD5 -SnmpV3PrivProtocol DES


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCSNMPSetting
Get-iBMCSNMPTrapSetting
Set-iBMCSNMPTrapSetting
Get-iBMCSNMPTrapServer
Set-iBMCSNMPTrapServer
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
    $SnmpV1Enabled,

    [Boolean[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $SnmpV2CEnabled,

    [Boolean[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $LongPasswordEnabled,

    [Boolean[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $RWCommunityEnabled,

    [System.Object[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $ReadOnlyCommunity,

    [System.Object[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $ReadWriteCommunity,

    [SnmpV3AuthProtocol[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $SnmpV3AuthProtocol,

    [SnmpV3PrivProtocol[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $SnmpV3PrivProtocol
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    $SnmpV1EnabledList = Get-OptionalMatchedSizeArray $Session $SnmpV1Enabled
    $SnmpV2CEnabledList = Get-OptionalMatchedSizeArray $Session $SnmpV2CEnabled
    $LongPasswordEnabledList = Get-OptionalMatchedSizeArray $Session $LongPasswordEnabled
    $RWCommunityEnabledList = Get-OptionalMatchedSizeArray $Session $RWCommunityEnabled
    $ReadOnlyCommunityList = Get-OptionalMatchedSizeArray $Session $ReadOnlyCommunity
    $ReadWriteCommunityList = Get-OptionalMatchedSizeArray $Session $ReadWriteCommunity
    $SnmpV3AuthProtocolList = Get-OptionalMatchedSizeArray $Session $SnmpV3AuthProtocol
    $SnmpV3PrivProtocolList = Get-OptionalMatchedSizeArray $Session $SnmpV3PrivProtocol

    $Logger.info("Invoke Set iBMC SNMP Settings function")

    $ScriptBlock = {
      param($RedfishSession, $Payload)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Set iBMC SNMP Settings now"))

      $Clone = $Payload.clone()
      if ($null -ne $Payload.ReadOnlyCommunity) {
        $Plain = ConvertTo-PlainString $Payload.ReadOnlyCommunity "ReadOnlyCommunity"
        $Payload.ReadOnlyCommunity = $Plain
        $Clone.ReadOnlyCommunity = "******"
      }

      if ($null -ne $Payload.ReadWriteCommunity) {
        $Plain = ConvertTo-PlainString $Payload.ReadWriteCommunity "ReadWriteCommunity"
        $Payload.ReadWriteCommunity = $Plain
        $Clone.ReadWriteCommunity = "******"
      }

      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Clone | ConvertTo-Json)"))
      $Path = "/Managers/$($RedfishSession.Id)/SnmpService"
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
          SnmpV1Enabled=$SnmpV1EnabledList[$idx];
          SnmpV2CEnabled=$SnmpV2CEnabledList[$idx];
          LongPasswordEnabled=$LongPasswordEnabledList[$idx];
          RWCommunityEnabled=$RWCommunityEnabledList[$idx];
          ReadOnlyCommunity=$ReadOnlyCommunityList[$idx];
          ReadWriteCommunity=$ReadWriteCommunityList[$idx];
          SnmpV3AuthProtocol=$SnmpV3AuthProtocolList[$idx];
          SnmpV3PrivProtocol=$SnmpV3PrivProtocolList[$idx];
        } | Remove-EmptyValues | Resolve-EnumValues

        if ($Payload.Count -eq 0) {
          throw $(Get-i18n ERROR_NO_UPDATE_PAYLOAD)
        }

        $Parameters = @($RedfishSession, $Payload)
        $Logger.info($(Trace-Session $RedfishSession "Submit Set iBMC SNMP Settings task"))
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


function Get-iBMCSNMPTrapSetting {
<#
.SYNOPSIS
Get iBMC SNMP Trap Notification Settings.

.DESCRIPTION
Get iBMC SNMP Trap Notification Settings.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[]
Returns PSObject indicates SNMP Trap Notification Settings if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Get-iBMCSNMPTrapSetting -Session $session

Host               : 10.1.1.2
ServiceEnabled     : True
TrapVersion        : V2C
TrapV3User         : UserName
TrapMode           : EventCode
TrapServerIdentity : BoardSN
AlarmSeverity      : Critical

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCSNMPSetting
Set-iBMCSNMPSetting
Set-iBMCSNMPTrapSetting
Get-iBMCSNMPTrapServer
Set-iBMCSNMPTrapServer
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

    $Logger.info("Invoke Get iBMC SNMP Trap Settings function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get iBMC SNMP Trap Settings now"))
      $Path = "/Managers/$($RedfishSession.Id)/SnmpService"
      $Response = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
      $Properties = @(
        "ServiceEnabled", "TrapVersion", "TrapV3User", "TrapMode",
        "TrapServerIdentity", "AlarmSeverity"
      )
      $TrapSettings = Copy-ObjectProperties $Response.SnmpTrapNotification $Properties
      $TrapSettings | Add-Member -MemberType NoteProperty "CommunityName" "******"
      return $(Update-SessionAddress $RedfishSession $TrapSettings)
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get iBMC SNMP Trap Settings task"))
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

function Set-iBMCSNMPTrapSetting {
<#
.SYNOPSIS
Modify iBMC SNMP Trap Notification Settings.

.DESCRIPTION
Modify iBMC SNMP Trap Notification Settings.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER ServiceEnabled
Indicates whether trap is enabled.
Support values are powershell boolean value: $true(1), $false(0).

.PARAMETER TrapVersion
Indicates the SNMP trap version
Available Value Set: V1, V2C, V3

.PARAMETER TrapV3User
Indicates the SNMPV3 user name. User name should be an exists iBMC user account's login name.

.PARAMETER TrapMode
Indicates the SNMP trap mode.
Available Value Set: OID, EventCode, PreciseAlarm.

.PARAMETER TrapServerIdentity
Indicates the trap server host identifier.
Available Value Set: BoardSN, ProductAssetTag, HostName.

This parameter is valid only when TrapMode is OID or PreciseAlarm.

.PARAMETER CommunityName
Indicates the Community name. Community name is invalid if SNMPv3 trap is used.
A character string that meets the following requirements:
- Cannot contain spaces.
- Contain 8 to 18 bytes and contain at least two types of uppercase letters, lowercase letters, digits, and special characters if password complexity check is enabled.
- Contain 1 to 18 password complexity check is disabled.
- Have at least two new characters when compared with the previous community name.

.PARAMETER AlarmSeverity
Indicates which severity level alarm should be notified
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
PS C:\> $CommunityName = ConvertTo-SecureString -String "SomeP@ssw0rd" -AsPlainText -Force
PS C:\> Set-iBMCSNMPTrapSetting -Session $session -ServiceEnabled $true -TrapVersion V2C `
          -TrapV3User chajian -TrapMode EventCode -TrapServerIdentity BoardSN `
          -CommunityName $CommunityName -AlarmSeverity Critical


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCSNMPSetting
Set-iBMCSNMPSetting
Get-iBMCSNMPTrapSetting
Get-iBMCSNMPTrapServer
Set-iBMCSNMPTrapServer
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

    [TrapVersion[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $TrapVersion,

    [String[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $TrapV3User,

    [TrapMode[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $TrapMode,

    [ServerIdentity[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $TrapServerIdentity,

    [System.Object[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $CommunityName,

    [AlarmSeverity[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $AlarmSeverity
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    $ServiceEnabledList = Get-OptionalMatchedSizeArray $Session $ServiceEnabled
    $TrapVersionList = Get-OptionalMatchedSizeArray $Session $TrapVersion
    $TrapV3UserList = Get-OptionalMatchedSizeArray $Session $TrapV3User
    $TrapModeList = Get-OptionalMatchedSizeArray $Session $TrapMode
    $TrapServerIdentityList = Get-OptionalMatchedSizeArray $Session $TrapServerIdentity
    $CommunityNameList = Get-OptionalMatchedSizeArray $Session $CommunityName
    $AlarmSeverityList = Get-OptionalMatchedSizeArray $Session $AlarmSeverity

    $Logger.info("Invoke Set BMC SNMP Settings function")

    $ScriptBlock = {
      param($RedfishSession, $Payload)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Set BMC SNMP Settings now"))
      $Path = "/Managers/$($RedfishSession.Id)/SnmpService"
      $Clone = $Payload.clone()
      if ($null -ne $Payload.CommunityName) {
        $Plain = ConvertTo-PlainString $Payload.CommunityName "CommunityName"
        $Payload.CommunityName = $Plain
        $Clone.CommunityName = "******"
      }
      $Payload = @{ "SnmpTrapNotification"=$Payload; }
      $SecurePayload = @{ "SnmpTrapNotification"=$Clone; }
      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($SecurePayload | ConvertTo-Json)"))
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
          ServiceEnabled=$ServiceEnabledList[$idx];
          TrapVersion=$TrapVersionList[$idx];
          TrapV3User=$TrapV3UserList[$idx];
          TrapMode=$TrapModeList[$idx];
          TrapServerIdentity=$TrapServerIdentityList[$idx];
          CommunityName=$CommunityNameList[$idx];
          AlarmSeverity=$AlarmSeverityList[$idx];
        } | Remove-EmptyValues | Resolve-EnumValues

        if ($Payload.Count -eq 0) {
          throw $(Get-i18n ERROR_NO_UPDATE_PAYLOAD)
        }

        $Parameters = @($RedfishSession, $Payload)
        $Logger.info($(Trace-Session $RedfishSession "Submit Set iBMC SNMP Trap Settings task"))
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


function Get-iBMCSNMPTrapServer {
<#
.SYNOPSIS
Get iBMC SNMP Trap Notification Servers.

.DESCRIPTION
Get iBMC SNMP Trap Notification Servers.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[][]
Returns PSObject Array indicates SNMP Trap Notification Servers if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Get-iBMCSNMPTrapServer -Session $session

Host              : 10.1.1.2
MemberId          : 0
BobEnabled        : False
Enabled           : False
TrapServerAddress :
TrapServerPort    : 300

Host              : 10.1.1.2
MemberId          : 1
BobEnabled        : False
Enabled           : True
TrapServerAddress : 192.168.2.8
TrapServerPort    : 310

Host              : 10.1.1.2
MemberId          : 2
BobEnabled        : False
Enabled           : False
TrapServerAddress : 192.168.2.7
TrapServerPort    : 163

Host              : 10.1.1.2
MemberId          : 3
BobEnabled        : True
Enabled           : True
TrapServerAddress : 10.10.10.2
TrapServerPort    : 202

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCSNMPSetting
Set-iBMCSNMPSetting
Get-iBMCSNMPTrapSetting
Set-iBMCSNMPTrapSetting
Set-iBMCSNMPTrapServer
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

    $Logger.info("Invoke Get iBMC SNMP Trap Servers function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get iBMC SNMP Trap Servers now"))
      $Path = "/Managers/$($RedfishSession.Id)/SnmpService"
      $Response = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse

      $Results = New-Object System.Collections.ArrayList
      for ($idx = 0; $idx -lt $Response.SnmpTrapNotification.TrapServer.Count; $idx++) {
        $TrapServer = $Response.SnmpTrapNotification.TrapServer[$idx]
        $TrapServer = Update-SessionAddress $RedfishSession $TrapServer
        [Void]  $Results.Add($TrapServer)
      }
      return , $Results.ToArray()
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get iBMC SNMP Trap Servers task"))
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


function Set-iBMCSNMPTrapServer {
<#
.SYNOPSIS
Modify iBMC SNMP Trap Notification Server.

.DESCRIPTION
Modify iBMC SNMP Trap Notification Server.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER MemberId
Indicates which trap notification server to modify.
MemberId is the unique primary ID for Trap Notification Server.
Support integer value range: [0, 3]

.PARAMETER Enabled
Indicates Whether the trap server is enabled.
Support values are powershell boolean value: $true(1), $false(0).

.PARAMETER TrapServerAddress
Indicates the Notificate Server address.
Available values: IPv4, IPv6 address or domain name.

.PARAMETER TrapServerPort
Indicates the Notificate Server port.
Available Value range: [1, 65535]

.OUTPUTS
Null
Returns Null if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Set-iBMCSNMPTrapServer $session -MemberId 1 -Enabled $true -TrapServerAddress 192.168.2.8 -TrapServerPort 1024


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCSNMPSetting
Set-iBMCSNMPSetting
Get-iBMCSNMPTrapSetting
Set-iBMCSNMPTrapSetting
Get-iBMCSNMPTrapServer
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
    $TrapServerAddress,

    [int32[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateRange(1, 65535)]
    $TrapServerPort
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $MemberId 'MemberId'
    $MemberIds = Get-MatchedSizeArray $Session $MemberId
    $Enableds = Get-OptionalMatchedSizeArray $Session $Enabled
    $TrapServerAddresses = Get-OptionalMatchedSizeArray $Session $TrapServerAddress
    $TrapServerPorts = Get-OptionalMatchedSizeArray $Session $TrapServerPort

    $Logger.info("Invoke Set BMC SNMP Trap Server function")

    $ScriptBlock = {
      param($RedfishSession, $MemberId, $Payload)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Set BMC SNMP Trap Server now"))
      $Path = "/Managers/$($RedfishSession.Id)/SnmpService"

      $Members = New-Object System.Collections.ArrayList
      for ($idx = 0; $idx -lt 4; $idx++) {
        if ($MemberId -eq $idx) {
          [Void] $Members.Add($Payload)
        } else {
          [Void] $Members.Add(@{})
        }
      }

      $CompletePlayload = @{
        "SnmpTrapNotification"=@{
          TrapServer=$Members;
        }
      }

      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($CompletePlayload | ConvertTo-Json -Depth 5)"))
      $Response = Invoke-RedfishRequest $RedfishSession $Path 'Patch' $CompletePlayload
      Resolve-RedfishPartialSuccessResponse $RedfishSession $Response | Out-Null
      return $null
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $MemberId=$MemberIds[$idx];
        $Payload = Remove-NoneValues @{
          Enabled=$Enableds[$idx];
          TrapServerAddress=$TrapServerAddresses[$idx];
          TrapServerPort=$TrapServerPorts[$idx];
        }

        if ($Payload.Count -eq 0) {
          throw $(Get-i18n ERROR_NO_UPDATE_PAYLOAD)
        }

        $Parameters = @($RedfishSession, $MemberId, $Payload)
        $Logger.info($(Trace-Session $RedfishSession "Submit Set BMC SNMP Trap Server task"))
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
