<# NOTE: iBMC Power Control module Cmdlets #>

try { [PowerControlType] | Out-Null } catch {
Add-Type -TypeDefinition @'
    public enum PowerControlType {
      On,
      GracefulShutdown,
      ForceRestart,
      Nmi,
      ForcePowerCycle
    }
'@
}

function Set-iBMCServerPower {
<#
.SYNOPSIS
Control iBMC Server Power.

.DESCRIPTION
Control iBMC Server Power.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER PowerControlType
Indicates the Server Power type.
Available Value Set:  On, GracefulShutdown, ForceRestart, Nmi, ForcePowerCycle.
- On: power on the Server.
- GracefulShutdown: gracefully shut down the Server.
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
PS C:\> Set-iBMCServerPower -Session $session -PowerControlType GracefulShutdown


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

    [PowerControlType[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
    $PowerControlType
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $PowerControlType 'PowerControlType'
    $PowerControlTypeList = Get-MatchedSizeArray $Session $PowerControlType

    $Logger.info("Invoke Control iBMC Server Power function")

    $ScriptBlock = {
      param($RedfishSession, $Payload)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Control iBMC Server Power now"))
      $Path = "/Systems/$($RedfishSession.Id)/Actions/Oem/Huawei/ComputerSystem.FruControl"
      Invoke-RedfishRequest $RedfishSession $Path 'POST' $Payload | Out-Null
      return $null
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Payload = @{
          FruControlType=$PowerControlTypeList[$idx];
          FruID=$BMC.FRUOperationSystem;
        } | Resolve-EnumValues

        $Parameters = @($RedfishSession, $Payload)
        $Logger.info($(Trace-Session $RedfishSession "Submit Control iBMC Server Power task"))
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
