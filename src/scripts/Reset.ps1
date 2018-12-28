<# NOTE: iBMC Reset module Cmdlets #>

try { [ResetType] | Out-Null } catch {
Add-Type -TypeDefinition @'
    public enum ResetType {
      On,
      ForceOff,
      GracefulShutdown,
      ForceRestart,
      Nmi,
      ForcePowerCycle
    }
'@
}
function Reset-iBMC {
<#
.SYNOPSIS
Reset iBMC.

.DESCRIPTION
Reset iBMC.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
None
Returns None if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Reset-iBMC $session


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

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

    $Logger.info("Invoke Reset iBMC function")

    $ScriptBlock = {
      param($RedfishSession, $Payload)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Reset iBMC now"))
      $Path = "/Managers/$($RedfishSession.Id)/Actions/Manager.Reset"
      Invoke-RedfishRequest $RedfishSession $Path 'POST' $Payload | Out-Null
      return $null
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Payload = @{"ResetType" = "ForceRestart"; }
        $Parameters = @($RedfishSession, $Payload)
        $Logger.info($(Trace-Session $RedfishSession "Submit Reset iBMC task"))
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

function Reset-iBMCServer {
<#
.SYNOPSIS
Reset iBMC Server.

.DESCRIPTION
Reset iBMC Server.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER ResetType
Indicates the Server reset type.
Available Value Set: On, ForceOff, GracefulShutdown, ForceRestart, Nmi, ForcePowerCycle.
- On: power on the Server.
- ForceOff: forcibly powers on the server.
- GracefulShutdown: gracefully shut down the OS.
- ForceRestart: forcibly restart the Server.
- Nmi: triggers a non-maskable interrupt (NMI).
- ForcePowerCycle: forcibly power off and then power on the Server.

.OUTPUTS
None
Returns None if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Reset-iBMCServer -Session $session -ResetType ForceRestart


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

    [ResetType[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
    $ResetType
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $ResetType 'ResetType'
    $ResetTypeList = Get-MatchedSizeArray $Session $ResetType

    $Logger.info("Invoke Reset iBMC Server function")

    $ScriptBlock = {
      param($RedfishSession, $Payload)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Reset iBMC Server now"))
      $Path = "/Systems/$($RedfishSession.Id)/Actions/ComputerSystem.Reset"
      Invoke-RedfishRequest $RedfishSession $Path 'POST' $Payload | Out-Null
      return $null
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Payload = @{
          "ResetType" = $ResetTypeList[$idx];
        } | Resolve-EnumValues
        $Parameters = @($RedfishSession, $Payload)
        $Logger.info($(Trace-Session $RedfishSession "Submit Reset iBMC Server task"))
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