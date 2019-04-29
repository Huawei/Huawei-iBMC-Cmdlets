<# NOTE: iBMC Service module Cmdlets #>

function Get-iBMCServices {
<#
.SYNOPSIS
Query information about the services and ports supported by the iBMC.

.DESCRIPTION
Query information about the services and ports supported by the iBMC.
Support Services:
  "HTTP", "HTTPS", "SNMP", "VirtualMedia",
  "IPMI", "SSH", "KVMIP", "VNC", "Video", "NAT", "SSDP"

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[]
Returns PSObject which contains all support services infomation if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $Services = Get-iBMCServices $session
PS C:\> $Services

Host          : 10.1.1.2
HTTP          : @{ProtocolEnabled=True; Port=80}
HTTPS         : @{ProtocolEnabled=True; Port=443}
SNMP          : @{ProtocolEnabled=True; Port=161}
VirtualMedia  : @{ProtocolEnabled=True; Port=8208}
IPMI          : @{ProtocolEnabled=True; Port=623}
SSH           : @{ProtocolEnabled=True; Port=22}
KVMIP         : @{ProtocolEnabled=True; Port=2198}
SSDP          : @{ProtocolEnabled=False; Port=1900; NotifyMulticastIntervalSeconds=600; NotifyTTL=2; NotifyIPv6Scope=Site}
VNC           : @{ProtocolEnabled=False; Port=5900}
Video         : @{ProtocolEnabled=True; Port=2199}
NAT           :

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Set-iBMCService
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

    $Logger.info("Invoke Get BMC Service function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke get BMC Service now"))
      $Path = "/Managers/$($RedfishSession.Id)/NetworkProtocol"
      $Response = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse

      $Properties = @("HTTP", "HTTPS", "SNMP", "VirtualMedia", "IPMI", "SSH", "KVMIP", "SSDP")
      $Services = Copy-ObjectProperties $Response $Properties
      $Services | Add-Member -MemberType NoteProperty "VNC" $Response.Oem.Huawei.VNC
      $Services | Add-Member -MemberType NoteProperty "Video" $Response.Oem.Huawei.Video
      $Services | Add-Member -MemberType NoteProperty "NAT" $Response.Oem.Huawei.NAT
      return $(Update-SessionAddress $RedfishSession $Services)
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit get BMC Service task"))
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

function Set-iBMCService {
<#
.SYNOPSIS
Modify iBMC service information, including the enablement state and port number.

.DESCRIPTION
Modify iBMC service information, including the enablement state and port number.
Support Services:
  "HTTP", "HTTPS", "SNMP", "VirtualMedia", "IPMI", "SSH", "KVMIP", "VNC", "Video", "NAT"

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER ServiceName
Indicates the type of service to be modified.
Support value set:
  "HTTP", "HTTPS", "SNMP", "VirtualMedia", "IPMI", "SSH", "KVMIP", "VNC", "Video", "NAT".

.PARAMETER Enabled
Indicates enabled the service or not.
Support values are powershell boolean value: $true(1), $false(0).

.PARAMETER Port
Indicates the network port which this service listen on.
Support integer value range: [1, 65535]

.OUTPUTS
Null
Returns Null if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Set-iBMCService -Session $session -ServiceName VNC -Enabled $true -Port 5900

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCServices
Connect-iBMC
Disconnect-iBMC

#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session,

    [ServiceName[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
    $ServiceName,

    [Boolean[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 2)]
    $Enabled,

    [int[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 3)]
    [ValidateRange(1, 65535)]
    $Port
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $ServiceName 'ServiceName'
    Assert-ArrayNotNull $Enabled 'Enabled'
    Assert-ArrayNotNull $Port 'Port'

    $ServiceNameList = Get-MatchedSizeArray $Session $ServiceName 'Session' 'ServiceName'
    $EnabledList = Get-MatchedSizeArray $Session $Enabled 'Session' 'Enabled'
    $PortList = Get-MatchedSizeArray $Session $Port 'Session' 'Port'

    $Logger.info("Invoke Set BMC Service function")

    $ScriptBlock = {
      param($RedfishSession, $ServiceName, $Enabled, $Port)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Set BMC Service now"))
      $Path = "/Managers/$($RedfishSession.Id)/NetworkProtocol"
      $Payload = @{
        "$($ServiceName.toString())" = @{
          "ProtocolEnabled" = $Enabled;
          "Port"            = $Port;
        }
      }
      if ($ServiceName -in @([ServiceName]::VNC, [ServiceName]::Video, [ServiceName]::NAT)) {
        $Payload = @{
          'Oem' = @{
            'Huawei' = $Payload;
          };
        }
      }

      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Payload | ConvertTo-Json -Depth 5)"))
      Invoke-RedfishRequest $RedfishSession $Path 'Patch' $Payload | Out-Null
      return $null
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Parameters = @($RedfishSession, $ServiceNameList[$idx], $EnabledList[$idx], $PortList[$idx])
        $Logger.info($(Trace-Session $RedfishSession "Submit Set BMC Service task"))
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

