<# NOTE: iBMC boot module Cmdlets #>

function Get-iBMCBootupSequence {
<#
.SYNOPSIS
Query bios boot up device sequence.

.DESCRIPTION
Query bios boot up device sequence. Boot up device contains: Hdd, Cd, Pxe, Others.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
Array[String[]]
Returns string array identifies boot up device in order if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $Sequence = Get-iBMCBootupSequence $session
PS C:\> $Sequence

Host           BootupSequence
----           --------------
10.1.1.2       {Pxe, HDD, Cd, Others}

PS C:\> $Sequence | fl

Host           : 10.1.1.2
BootupSequence : {Pxe, HDD, Cd, Others}

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Set-iBMCBootupSequence
Get-iBMCBootSourceOverride
Set-iBMCBootSourceOverride
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

    $Logger.info("Invoke Get Bootup Sequence function")

    $ScriptBlock = {
      param($RedfishSession)
      $Path = "/redfish/v1/Systems/$($RedfishSession.Id)"
      $Response = $(Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse)
      # V3
      if ($null -ne $Response.Oem.Huawei.BootupSequence) {
        $Logger.info($(Trace-Session $RedfishSession "Find System.Oem.Huawei.BootupSequence, return directly"))
        $Clone = New-Object PSObject
        $Clone | Add-Member -MemberType NoteProperty "BootupSequence" $Response.Oem.Huawei.BootupSequence
        return $(Update-SessionAddress $RedfishSession $Clone)
      }
      else {
        # V5
        $Logger.info($(Trace-Session $RedfishSession "V5 BMC, will try get sequence from BIOS API"))
        $BiosPath = "$Path/Bios"
        $BiosResponse = $(Invoke-RedfishRequest $RedfishSession $BiosPath | ConvertFrom-WebResponse)
        $Attrs = $BiosResponse.Attributes
        $seq = New-Object System.Collections.ArrayList
        0..3 | ForEach-Object {
          $BootType = $Attrs."BootTypeOrder$_"
          [Void] $seq.Add($BMC.V52V3Mapping[$BootType])
        }

        $Clone = New-Object PSObject
        $Clone | Add-Member -MemberType NoteProperty "BootupSequence" $seq.ToArray()
        return $(Update-SessionAddress $RedfishSession $Clone)
      }
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get Bootup Sequence task"))
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


function Set-iBMCBootupSequence {
<#
.SYNOPSIS
Set bios boot up device sequence.

.DESCRIPTION
Set bios boot up device sequence.
Boot up device contains: Hdd, Cd, Pxe, Others.
New boot up sequence settings take effect upon the next restart of the system.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER BootSequence
A array set of boot device in order, should contains all available boot devices.
example: ,@('Hdd', 'Cd', 'Pxe', 'Others')

.OUTPUTS
None
Returns None if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $BootUpSequence = ,@('Pxe', 'Hdd', 'Cd', 'Others')
PS C:\> Set-iBMCBootupSequence $session $BootUpSequence

Set boot up device sequence for single iBMC server

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2,10.1.1.3 -Credential $credential -TrustCert
PS C:\> $BootUpSequence = @(@('Pxe', 'Hdd', 'Cd', 'Others'), @('Cd', 'Pxe', 'Hdd', 'Others'))
PS C:\> Set-iBMCBootupSequence $session $BootUpSequence

Set boot up device sequence for multiple iBMC server


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCBootupSequence
Get-iBMCBootSourceOverride
Set-iBMCBootSourceOverride
Connect-iBMC
Disconnect-iBMC

#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session,

    [BootSequence[][]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
    $BootSequence
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $BootSequence 'BootSequence'
    $BootSequenceList = Get-MatchedSizeArray $Session $BootSequence 'Session' 'BootSequence'
    # validate boot sequence input
    $BootSequenceList | ForEach-Object {
      if ($null -ne $_ -or $_.Count -eq 4) {
        $ValidSet = Get-EnumNames "BootSequence"
        $diff = Compare-Object $_ $ValidSet -PassThru
        if ($null -eq $diff) {
          return
        }
      }
      throw [String]::format($(Get-i18n "ERROR_ILLEGAL_BOOT_SEQ"), $_ -join ",")
    }

    $Logger.info("Invoke Set Bootup Sequence function")

    $ScriptBlock = {
      param($RedfishSession, $BootSequence)
      $Path = "/redfish/v1/Systems/$($RedfishSession.Id)"
      $Response = Invoke-RedfishRequest $RedfishSession $Path
      $System = $Response | ConvertFrom-WebResponse

      if ($null -ne $System.Oem.Huawei.BootupSequence) {
        # V3
        $Logger.info($(Trace-Session $RedfishSession "[V3] Will set boot sequence using System resource"))
        $Payload = @{
          "Oem" = @{
            "Huawei" = @{
              "BootupSequence" = $BootSequence;
            } | Resolve-EnumValues;
          };
        }

        $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Payload | ConvertTo-Json -Depth 5)"))
        $Headers = @{'If-Match' = $Response.Headers.get('ETag'); }
        Invoke-RedfishRequest $RedfishSession $Path 'PATCH' $Payload $Headers | Out-Null
        return $null
      }
      else {
        # V5
        $Logger.info($(Trace-Session $RedfishSession "[V5] Will set boot sequence using BIOS settings resource"))
        $SetBiosPath = "$Path/Bios/Settings"
        $V5BootSequence = @{}
        for ($idx = 0; $idx -lt $BootSequence.Count; $idx++) {
          $BootType = $BMC.V32V5Mapping[$BootSequence[$idx].toString()]
          $V5BootSequence."BootTypeOrder$idx" = $BootType
        }
        $Logger.info($(Trace-Session $RedfishSession "[V5] Boot device sequence: $V5BootSequence"))
        $Payload = @{"Attributes" = $V5BootSequence; }
        $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Payload | ConvertTo-Json -Depth 5)"))
        Invoke-RedfishRequest $RedfishSession $SetBiosPath 'PATCH' $Payload | Out-Null
        return $null
      }
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Parameters = @($RedfishSession, $BootSequenceList[$idx])
        $Logger.info($(Trace-Session $RedfishSession "Submit Get Bootup Sequence task"))
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


function Get-iBMCBootSourceOverride {
<#
.SYNOPSIS
Query bios boot source override target.

.DESCRIPTION
Query bios boot source override target. Boot up device contains: 'None', 'Pxe', 'Floppy', 'Cd', 'Hdd', 'BiosSetup'.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
String[]
Returns bios boot source override target if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $BootSourceOverride = Get-iBMCBootSourceOverride $session
PS C:\> $BootSourceOverride

Host     BootSourceOverrideTarget BootSourceOverrideEnabled
----     ------------------------ -------------------------
10.1.1.2 None                     Disabled

PS C:\> $BootSourceOverride | fl

Host                      : 10.1.1.2
BootSourceOverrideTarget  : None
BootSourceOverrideEnabled : Disabled

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCBootupSequence
Set-iBMCBootupSequence
Set-iBMCBootSourceOverride
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

    $Logger.info("Invoke Get Boot Source Override function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Get boot source override target now"))
      $Path = "/redfish/v1/Systems/$($RedfishSession.Id)"
      $Response = $(Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse)
      $Properties = @(
        "BootSourceOverrideTarget", "BootSourceOverrideEnabled"
      )
      $BootSourceOverride = Copy-ObjectProperties $Response.Boot $Properties
      return $(Update-SessionAddress $RedfishSession $BootSourceOverride)
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get Boot Source Override task"))
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


function Set-iBMCBootSourceOverride {
<#
.SYNOPSIS
Modify bios boot source override target.

.DESCRIPTION
Modify bios boot source override target.
Available boot source override target: 'None', 'Pxe', 'Floppy', 'Cd', 'Hdd', 'BiosSetup'.
This boot source override target takes effect upon the next restart of the system.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER BootSourceOverrideTarget
BootSourceOverrideTarget specifies the bios boot source override target

.OUTPUTS
Null
Returns Null if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> Set-iBMCBootSourceOverride $session 'Pxe' 'Once'

Set boot source override target for single iBMC server

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2,10.1.1.5 -Credential $credential -TrustCert
PS C:\> Set-iBMCBootSourceOverride -Session $session -BootSourceOverrideTarget Pxe `
          -BootSourceOverrideEnabled Once

Set boot source override target for multiple iBMC server


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

Get-iBMCBootupSequence
Set-iBMCBootupSequence
Get-iBMCBootSourceOverride
Connect-iBMC
Disconnect-iBMC

#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session,

    [BootSourceOverrideTarget[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
    $BootSourceOverrideTarget,

    [BootSourceOverrideEnabled[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 2)]
    $BootSourceOverrideEnabled
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $BootSourceOverrideTarget 'BootSourceOverrideTarget'
    $BootSourceOverrideTargetList = Get-MatchedSizeArray $Session $BootSourceOverrideTarget 'Session' 'BootSourceOverrideTarget'
    $BootSourceOverrideEnabledList = Get-MatchedSizeArray $Session $BootSourceOverrideEnabled 'Session' 'BootSourceOverrideEnabled'

    $Logger.info("Invoke Set Bootup Sequence function")

    $ScriptBlock = {
      param($RedfishSession, $BootSourceOverrideTarget, $BootSourceOverrideEnabled)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Set boot source override target: $BootSourceOverrideTarget, $BootSourceOverrideEnabled"))
      $Path = "/redfish/v1/Systems/$($RedfishSession.Id)"
      $Payload = @{
        "Boot" = @{
          "BootSourceOverrideTarget" = $BootSourceOverrideTarget.toString();
          "BootSourceOverrideEnabled" = $BootSourceOverrideEnabled.toString();
        };
      }

      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Payload | ConvertTo-Json)"))
      Invoke-RedfishRequest $RedfishSession $Path 'PATCH' $Payload | Out-Null
      return $null
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Parameters = @($RedfishSession, $BootSourceOverrideTargetList[$idx], $BootSourceOverrideEnabledList[$idx])
        $Logger.info($(Trace-Session $RedfishSession "Submit Set Boot source override target task"))
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
