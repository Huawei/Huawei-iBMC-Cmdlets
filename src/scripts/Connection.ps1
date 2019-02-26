<# NOTE: iBMC Connect module Cmdlets #>

function Connect-iBMC {
<#
.SYNOPSIS
Connect to iBMC Servers and initialize sessions used by other cmdlets.

.DESCRIPTION
Initialize sessions for one or multiple iBMC servers and. This cmdlet has following parameters:

- Address - Holds the iBMC server IP/hostname.
- Username - Holds  the iBMC server username.
- Password - Holds  the iBMC server password.
- Credential - Holds the iBMC server Credential.
- TrustCert - Using this bypasses the server certificate authentication.

.PARAMETER Address
IP address or Hostname of the iBMC server.

.PARAMETER Username
Username of iBMC account to access the iBMC server.

.PARAMETER Password
Password of iBMC account to access the iBMC server.

.PARAMETER Credential
PowerShell PSCredential object having username and passwword of iBMC account to access the iBMC.

.PARAMETER TrustCert
If this switch parameter is present then server certificate authentication is disabled for this iBMC session.
If not present, server certificate is enabled by default.


.OUTPUTS
RedfishSession[]
Returns the created RedfishSession if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE
PS C:\> $sessions = Connect-iBMC -Address 10.1.1.2 -Username root -Password password
PS C:\> $sessions

.EXAMPLE
PS C:\> $credential = Get-Credential
PS C:\> $sessions = Connect-iBMC -Address 10.1.1.2 -Credential $credential
PS C:\> $sessions

.EXAMPLE
PS C:\> $sessions = Connect-iBMC -Address "10.1.1.2,5,8" -Username root -Password password
PS C:\> $sessions

.EXAMPLE
PS C:\> $sessions = Connect-iBMC -Address 10.1.1.2-10 -Username root -Password password
PS C:\> $sessions


.EXAMPLE
PS C:\> $sessions = Connect-iBMC -Address 10.1.1.2,10.1.1.3 -Username root -Password password
PS C:\> $sessions

.EXAMPLE
PS C:\> $sessions = Connect-iBMC -Address 10.1.1.2,10.1.1.3 -Username user1,user2 -Password password1,password2
PS C:\> $sessions



.EXAMPLE
PS C:\> $sessions = Connect-iBMC -Address 2018::2018 -Username root -Password password
PS C:\> $sessions

This example shows how to connect to a bmc server using ipv6

.EXAMPLE
PS C:\> $sessions = Connect-iBMC -Address "[2018::2018]:8080" -Username root -Password password
PS C:\> $sessions

This example shows how to connect to a bmc server using ipv6 and port

.EXAMPLE
PS C:\> $sessions = Connect-iBMC -Address "2018::2018,201A" -Username root -Password password
PS C:\> $sessions

This example shows how to connect to multiple bmc server using "," seperated ipv6 addresses

.EXAMPLE
PS C:\> $sessions = Connect-iBMC -Address "2018::2018-201A" -Username root -Password password
PS C:\> $sessions

This example shows how to connect to multiple bmc server using "-" seperated ipv6 addresses


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCSessionTimeout
Set-iBMCSessionTimeout
Connect-iBMC
Disconnect-iBMC
Test-iBMCConnect
#>
  [cmdletbinding(DefaultParameterSetName = 'AccountSet')]
  param
  (
    [System.String[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Address,

    [System.String[]]
    [parameter(ParameterSetName = "AccountSet", Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
    $Username,

    [System.Object[]]
    [parameter(ParameterSetName = "AccountSet", Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 2)]
    $Password,

    [PSCredential[]]
    [parameter(ParameterSetName = "CredentialSet", Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
    $Credential,

    [switch]
    [parameter(Mandatory = $false)]
    $TrustCert
  )

  $useCredential = $($null -ne $Credential)
  if ($useCredential) {
    Assert-ArrayNotNull $Credential 'Credential'
    $Credential = Get-MatchedSizeArray $Address $Credential 'Address' 'Credential'
  }
  else {
    # $null -ne $Username -and $null -ne $Password
    Assert-ArrayNotNull $Username 'Username'
    Assert-ArrayNotNull $Password 'Password'
    $Username = Get-MatchedSizeArray $Address $Username 'Address' 'Username'
    $Password = Get-MatchedSizeArray $Address $Password 'Address' 'Password'
    # Assert-IsSensitiveString $Password "Password"
  }

  $ParametersArray = New-Object System.Collections.ArrayList
  for ($index=0; $index -lt $Address.Count; $index++) {
    $IpList = ConvertFrom-IPRangeString $Address[$index]
    $IpList | ForEach-Object {
      $Parameters = New-Object System.Collections.ArrayList
      [Void] $Parameters.Add($_)
      if ($useCredential) {
        [Void] $Parameters.Add($Credential[$index])
      } else {
        [Void] $Parameters.Add($Username[$index])
        [Void] $Parameters.Add($Password[$index])
      }
      [Void] $Parameters.Add($($TrustCert -eq $true))

      [Void] $ParametersArray.Add($Parameters)
    }
  }

  try {
    $tasks = New-Object System.Collections.ArrayList
    $pool = New-RunspacePool $ParametersArray.Count
    # $ScriptBlock = {
    #   param($p)
    #   $Logger.info($p.Count)
    #   if ($p.Count -eq 3) {
    #     $Logger.info("receive parameter length 3")
    #     New-RedfishSession -Address $($p[0]) -Credential $($p[1]) -TrustCert $($p[2])
    #   } else {
    #     $Logger.info("receive parameter length 4")
    #     New-RedfishSession -Address $($p[0]) -Username $($p[1]) -Password $($p[2]) -TrustCert $($p[3])
    #   }
    # }

    if ($useCredential) {
      $ScriptBlock = {
        param($Address, $Credential, $TrustCert)
        New-RedfishSession -Address $Address -Credential $Credential -TrustCert:$TrustCert
      }
    } else {
      $ScriptBlock = {
        param($Address, $Username, $Password, $TrustCert)
        $Plain = ConvertTo-PlainString $Password "Password"
        New-RedfishSession -Address $Address -Username $Username -Password $Plain -TrustCert:$TrustCert
      }
    }

    $ParametersArray | ForEach-Object {
      [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $_))
    }

    return Get-AsyncTaskResults -AsyncTasks $tasks
  } finally {
    Close-Pool $pool
  }
}


function Disconnect-iBMC {
<#
.SYNOPSIS
Disconnects specified session[s] of iBMC Redfish Server.

.DESCRIPTION
Disconnects specified session[s] of iBMC Redfish Server by sending HTTP Delete request to location holds by "Location" property in RedfishSession Object passed as parameter.

.PARAMETER Connection
RedfishSession array that created by Connect-iBMC cmdlet.

.NOTES
The RedfishSession object will be detached from iBMC Redfish Server. And the Session can not be used by cmdlets which required Session parameter again.

.INPUTS
You can pipe the RedfishSession object array to Disconnect-iBMC. The RedfishSession array is obtained from executing Connect-iBMC cmdlet.

.OUTPUTS
This cmdlet does not generate any output.


.EXAMPLE
PS C:\> Disconnect-iBMC -Session $session
PS C:\>

.EXAMPLE
PS C:\> $session | Disconnect-iBMC
PS C:\>

This will disconnect the sessions given in the variable $Session

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCSessionTimeout
Set-iBMCSessionTimeout
Connect-iBMC
Disconnect-iBMC
Test-iBMCConnect
#>
  param
  (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $Session
  )

  Assert-ArrayNotNull $Session 'Session'
  try {
    $tasks = New-Object System.Collections.ArrayList
    $pool = New-RunspacePool $Session.Count
    $ScriptBlock = {
      param($RedfishSession)
      return $(Close-RedfishSession $RedfishSession)
    }
    $Session | ForEach-Object {
      [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock @($_)))
    }
    return Get-AsyncTaskResults -AsyncTasks $tasks
  } finally {
    Close-Pool $pool
  }
}

function Set-iBMCSessionTimeout {
<#
.SYNOPSIS
Modify the iBMC session timeout period.

.DESCRIPTION
Modify the iBMC session timeout period.

.PARAMETER Session
RedfishSession object that returned by Connect-iBMC cmdlet.

.INPUTS
You can pipe the RedfishSession array to Set-iBMCSessionTimeout.
The RedfishSession array is obtained from executing Connect-iBMC cmdlet.

.OUTPUTS
Null
Returns Null if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE
PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Set-iBMCSessionTimeout -Session $session -Timeout 600

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCSessionTimeout
Set-iBMCSessionTimeout
Connect-iBMC
Disconnect-iBMC
Test-iBMCConnect
#>
  param
  (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position=0)]
    $Session,

    [int[]]
    [ValidateRange(30, 86400)]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position=1)]
    $Timeout
  )

  Assert-ArrayNotNull $Session 'Session'
  Assert-ArrayNotNull $Timeout 'Timeout'
  $TimeoutList = Get-MatchedSizeArray $Session $Timeout 'Session' 'Timeout'

  $Logger.info("Invoke set iBMC session timeout function")

  $ScriptBlock = {
    param($RedfishSession, $timeout)
    $Logger.info($(Trace-Session $RedfishSession "Invoke set iBMC session timeout now"))

    $Path = "/SessionService"
    $Payload = @{
      SessionTimeout=$timeout;
    }
    $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Payload | ConvertTo-Json)"))
    Invoke-RedfishRequest $RedfishSession $Path 'Patch' $Payload | Out-Null
    return $null
  }

  try {
    $tasks = New-Object System.Collections.ArrayList
    $pool = New-RunspacePool $Session.Count
    for ($idx = 0; $idx -lt $Session.Count; $idx++) {
      $RedfishSession = $Session[$idx]
      $Parameters = @($RedfishSession, $TimeoutList[$idx])
      $Logger.info($(Trace-Session $RedfishSession "Submit set iBMC session timeout task"))
      [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $Parameters))
    }

    $Results = Get-AsyncTaskResults $tasks
    return ,$Results
  }
  finally {
    Close-Pool $pool
  }
}

function Get-iBMCSessionTimeout {
<#
.SYNOPSIS
Get the iBMC session timeout period.

.DESCRIPTION
Get the iBMC session timeout period.

.PARAMETER Session
RedfishSession object that returned by Connect-iBMC cmdlet.

.INPUTS
You can pipe the RedfishSession array to Set-iBMCSessionTimeout.
The RedfishSession array is obtained from executing Connect-iBMC cmdlet.

.OUTPUTS
PSObject[]
Returns PSObject indicates session timeout informations if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE
PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Get-iBMCSessionTimeout -Session $session

SessionTimeout
--------------
           600

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCSessionTimeout
Set-iBMCSessionTimeout
Connect-iBMC
Disconnect-iBMC
Test-iBMCConnect
#>
  param
  (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position=0)]
    $Session
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'

    $Logger.info("Invoke Get iBMC session timeout function")

    $ScriptBlock = {
      param($RedfishSession)
      $Logger.info($(Trace-Session $RedfishSession "Invoke Get iBMC session timeout now"))
      $Path = "/SessionService"
      $Response = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
      return Copy-ObjectProperties $Response @('SessionTimeout')
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get iBMC session timeout task"))
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

function Test-iBMCConnect {
<#
.SYNOPSIS
Test whether specified session[s] of iBMC Redfish Server is still alive

.DESCRIPTION
Test whether specified session[s] of iBMC Redfish Server is still alive by sending a HTTP get request to Session Location Uri.

.PARAMETER Session
RedfishSession array that created by Connect-iBMC cmdlet.

.INPUTS
You can pipe the RedfishSession array to Test-iBMCConnect. The RedfishSession array is obtained from executing Connect-iBMC cmdlet.

.OUTPUTS
RedfishSession Object with field Alive identified whether session is still alive


.EXAMPLE
PS C:\> Test-iBMCConnect -Session $Session

Id                  : 1
Name                : Manager
ManagerType         : BMC
FirmwareVersion     : 3.00
UUID                : 877AA970-58F9-8432-E811-80345C184638
Model               : iBMC
Health              : OK
State               : Enabled
DateTime            : 2018-10-16T17:50:05+08:00
DateTimeLocalOffset : Asia/Chongqing
BaseUri             : https://10.1.1.2
Location            : /redfish/v1/SessionService/Sessions/8c2790fbef51b40c
Alive               : False
AuthToken           : eac9b1d6be37f69fd783355ece67f2f2
TrustCert           : True

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCSessionTimeout
Set-iBMCSessionTimeout
Connect-iBMC
Disconnect-iBMC
Test-iBMCConnect
#>
  param
  (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position=0)]
    $Session
  )
  Assert-ArrayNotNull $Session 'Session'
  try {
    $tasks = New-Object System.Collections.ArrayList
    $pool = New-RunspacePool $Session.Count
    $ScriptBlock = {
      param($RedfishSession)
      return $(Test-RedfishSession $RedfishSession)
    }
    $Session | ForEach-Object {
      [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock @($_)))
    }
    return Get-AsyncTaskResults -AsyncTasks $tasks
  } finally {
    Close-Pool $pool
  }
}