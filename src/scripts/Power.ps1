<# NOTE: iBMC Power module Cmdlets #>

function Get-iBMCPowerInfo {
<#
.SYNOPSIS
Get all iBMC Power Controls consumed infomation.

.DESCRIPTION
Get all iBMC Power Controls consumed infomation.
Including Id, Name, Consumed Watts, Min Consumed Watts, Max Consumed Watts, Avg Consumed Watts.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
PSObject[][]
Returns Array of PSObject indicates all iBMC Power Controls Reading infomation if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Get-iBMCPowerInfo -Session $session

Id                   : 0
Name                 : System Power Control 1
PowerConsumedWatts   : 222 Watts
MaxConsumedWatts     : 432 Watts
MinConsumedWatts     : 18 Watts
AverageConsumedWatts : 183 Watts


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

    $Logger.info("Invoke Get All iBMC Power Controls Readings function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get All iBMC Power Controls Readings  now"))
      $Path = "/Chassis/$($RedfishSession.Id)/Power"
      $Response = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
      $PowerControls = $Response.PowerControl

      $Results = New-Object System.Collections.ArrayList
      $PowerControls | ForEach-Object {
        $Metrics = $_.PowerMetrics
        $PowerInfo = New-Object PSObject
        $PowerInfo | Add-Member -MemberType NoteProperty "Id" $_.MemberId
        $PowerInfo | Add-Member -MemberType NoteProperty "Name" $_.Name
        $PowerInfo | Add-Member -MemberType NoteProperty "PowerConsumedWatts" "$($_.PowerConsumedWatts) Watts"
        $PowerInfo | Add-Member -MemberType NoteProperty "MaxConsumedWatts" "$($Metrics.MaxConsumedWatts) Watts"
        $PowerInfo | Add-Member -MemberType NoteProperty "MinConsumedWatts" "$($Metrics.MinConsumedWatts) Watts"
        $PowerInfo | Add-Member -MemberType NoteProperty "AverageConsumedWatts" "$($Metrics.AverageConsumedWatts) Watts"
        [Void] $Results.Add($PowerInfo)
      }
      return ,$Results.ToArray()
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get All iBMC Power Controls Readings  task"))
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
