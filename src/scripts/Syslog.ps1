<# NOTE: iBMC Syslog Module Cmdlets #>

function Get-iBMCSyslogSetting {
<#
.SYNOPSIS
Query information about the services and ports supported by the iBMC.

.DESCRIPTION
Query information about the services and ports supported by the iBMC.
Support Services: "HTTP", "HTTPS", "SNMP", "VirtualMedia", "IPMI", "SSH", "KVMIP", "VNC

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[]
Returns PSObject indicates the Syslog-Settings if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $syslog = Get-iBMCSyslogSetting $session
PS C:\> $syslog

ServiceEnabled       : True
ServerIdentitySource : BoardSN
AlarmSeverity        : Normal
TransmissionProtocol : UDP


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Set-iBMCSyslogSetting
Get-iBMCSyslogServer
Set-iBMCSyslogServer
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

    $Logger.info("Invoke Get BMC Syslog function")

    $ScriptBlock = {
      param($RedfishSession)

      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get BMC Syslog now"))
      $Path = "/Managers/$($RedfishSession.Id)/SyslogService"
      $Response = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
      $Properties = @(
        "ServiceEnabled", "ServerIdentitySource", "AlarmSeverity", "TransmissionProtocol"
      )
      $Syslog = Copy-ObjectProperties $Response $Properties
      return $Syslog
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get BMC Syslog task"))
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

function Set-iBMCSyslogSetting {
<#
.SYNOPSIS
Modify iBMC Syslog Notification Settings.

.DESCRIPTION
Modify iBMC Syslog Notification Settings.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER ServiceEnabled
Indicates whether syslog is enabled.
Support values are powershell boolean value: $true(1), $false(0).

.PARAMETER ServerIdentitySource
Indicates the notification server host identifier.
Available Value Set: BoardSN, ProductAssetTag, HostName.

.PARAMETER AlarmSeverity
Indicates which severity level alarm should be notified
Available Value Set: Critical, Major, Minor, Normal

.PARAMETER TransmissionProtocol
Indicates the transmission protocol of syslog.
Available Value Set: UDP, TCP, TLS

.OUTPUTS
Null
Returns Null if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Set-iBMCSyslogSetting $session -ServiceEnabled $true -ServerIdentitySource HostName `
          -AlarmSeverity Major -TransmissionProtocol UDP

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCSyslogSetting
Get-iBMCSyslogServer
Set-iBMCSyslogServer
Connect-iBMC
Disconnect-iBMC

#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session,

    [Boolean[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
    $ServiceEnabled,

    [ServerIdentity[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 2)]
    $ServerIdentitySource,

    [AlarmSeverity[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 3)]
    $AlarmSeverity,

    [TransmissionProtocol[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 4)]
    $TransmissionProtocol
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'

    $ServiceEnabledList = Get-OptionalMatchedSizeArray $Session $ServiceEnabled
    $ServerIdentitySourceList = Get-OptionalMatchedSizeArray $Session $ServerIdentitySource
    $AlarmSeverityList = Get-OptionalMatchedSizeArray $Session $AlarmSeverity
    $TransmissionProtocolList = Get-OptionalMatchedSizeArray $Session $TransmissionProtocol

    $Logger.info("Invoke Set iBMC Syslog settings function")

    $ScriptBlock = {
      param($RedfishSession, $Payload)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Set iBMC Syslog settings now"))
      $Path = "/Managers/$($RedfishSession.Id)/SyslogService"
      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Payload | ConvertTo-Json)"))
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
          ServiceEnabled       = $ServiceEnabledList[$idx];
          ServerIdentitySource = $ServerIdentitySourceList[$idx];
          AlarmSeverity        = $AlarmSeverityList[$idx];
          TransmissionProtocol = $TransmissionProtocolList[$idx];
        } | Remove-EmptyValues | Resolve-EnumValues

        if ($Payload.Count -eq 0) {
          throw $(Get-i18n ERROR_NO_UPDATE_PAYLOAD)
        }

        $Parameters = @($RedfishSession, $Payload)
        $Logger.info($(Trace-Session $RedfishSession "Submit Set iBMC Syslog settings task"))
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


function Get-iBMCSyslogServer {
<#
.SYNOPSIS
Get iBMC Syslog Notification Servers.

.DESCRIPTION
Get iBMC Syslog Notification Servers.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[][]
Returns PSObject Array indicates Syslog Notification Servers if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $Servers = Get-iBMCSyslogServer $session
PS C:\> $Servers

MemberId : 0
Enabled  : False
Address  :
Port     : 0
LogType  : {OperationLog, SecurityLog, EventLog}

MemberId : 1
Enabled  : False
Address  :
Port     : 0
LogType  : {OperationLog, SecurityLog, EventLog}

MemberId : 2
Enabled  : False
Address  :
Port     : 0
LogType  : {OperationLog, SecurityLog, EventLog}

MemberId : 3
Enabled  : False
Address  :
Port     : 0
LogType  : {OperationLog, SecurityLog, EventLog}


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCSyslogSetting
Set-iBMCSyslogSetting
Set-iBMCSyslogServer
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

    $Logger.info("Invoke Get BMC Syslog Notification Server function")

    $ScriptBlock = {
      param($RedfishSession)

      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get BMC Syslog Notification Server now"))
      $Path = "/Managers/$($RedfishSession.Id)/SyslogService"
      $Response = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
      # $Properties = @("MemberId", "Enabled", "Address", "Port", "LogType")
      # $Syslog = Copy-ObjectProperties $Response.SyslogServers $Properties
      return ,$Response.SyslogServers
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Get BMC Syslog Notification Server"))
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


function Set-iBMCSyslogServer {
<#
.SYNOPSIS
Modify iBMC Syslog Notification Server.

.DESCRIPTION
Modify iBMC Syslog Notification Server.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER MemberId
Indicates which Syslog notification server to modify.
MemberId is the unique primary ID for Syslog Notification Server.
Support integer value range: [0, 3]

.PARAMETER Enabled
Indicates Whether this server's syslog notification is enabled.
Support values are powershell boolean value: $true(1), $false(0).

.PARAMETER Address
Indicates the Notificate Server address.
Available values: IPv4, IPv6 address or domain name.

.PARAMETER Port
Indicates the Notificate Server port.
Support integer value range: [1, 65535]

.PARAMETER LogType
Indicates the Log type that should be notificated.
Available combined value set: OperationLog, SecurityLog, EventLog.


.OUTPUTS
Null
Returns Null if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $LogType = ,@("OperationLog", "SecurityLog", "EventLog")
PS C:\> Set-ibmcSyslogServer $session -MemberId 1 -Enabled $true -Address 192.168.14.9 -Port 515 -LogType $LogType

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCSyslogSetting
Set-iBMCSyslogSetting
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
    $Address,

    [int32[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateRange(1, 65535)]
    $Port,

    [LogType[][]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [AllowEmptyCollection()]
    $LogType
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $MemberId 'MemberId'
    $MemberIds = Get-MatchedSizeArray $Session $MemberId

    $Enableds = Get-OptionalMatchedSizeArray $Session $Enabled
    $Addresses = Get-OptionalMatchedSizeArray $Session $Address
    $Ports = Get-OptionalMatchedSizeArray $Session $Port

    $ValidLogTypes = Get-EnumNames "LogType"
    $LogTypes = Get-OptionalMatchedSizeMatrix $Session $LogType $ValidLogTypes 'Session' 'LogType'

    $Logger.info("Invoke Set BMC Syslog Notification Server function")

    $ScriptBlock = {
      param($RedfishSession, $MemberId, $Payload)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Set BMC Syslog Notification Server now"))
      $Path = "/Managers/$($RedfishSession.Id)/SyslogService"

      $Members = New-Object System.Collections.ArrayList
      for ($idx = 0; $idx -lt 4; $idx++) {
        if ($MemberId -eq $idx) {
          [Void] $Members.Add($Payload)
        }
        else {
          [Void] $Members.Add(@{})
        }
      }

      $CompletePlayload = @{
        "SyslogServers" = $Members;
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
        $MemberId = $MemberIds[$idx];
        $Payload = @{
          Enabled = $Enableds[$idx];
          Address = $Addresses[$idx];
          Port    = $Ports[$idx];
          LogType = $LogTypes[$idx];
        } | Remove-NoneValues | Resolve-EnumValues

        if ($Payload.Count -eq 0) {
          throw $(Get-i18n ERROR_NO_UPDATE_PAYLOAD)
        }

        $Parameters = @($RedfishSession, $MemberId, $Payload)
        $Logger.info($(Trace-Session $RedfishSession "Submit Set BMC Syslog Notification Server task"))
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
