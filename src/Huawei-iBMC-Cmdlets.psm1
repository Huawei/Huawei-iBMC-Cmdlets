# Implement your module commands in this script.

# . $PSScriptRoot/common/Common.ps1
# . $PSScriptRoot/common/Redfish.ps1

# Import all functional scripts
$CommonFunctions = @(Get-ChildItem -Path $PSScriptRoot\common\ -Recurse -Filter *.ps1)
$CommonFunctions | ForEach-Object {
  try {
    . $_.FullName
  } catch {
      Write-Error -Message "Failed to import file $($_.fullname)"
  }
}

# Import all User scripts
$UserFunctions = @(Get-ChildItem -Path $PSScriptRoot\scripts\ -Recurse -Filter *.ps1)
$UserFunctions | ForEach-Object {
  try {
    . $_.FullName
  } catch {
      Write-Error -Message "Failed to import file $($_.fullname)"
  }
}


function Get-iBMCModuleVersion {
<#
.SYNOPSIS
Gets the module details for the Huawei-iBMC-Cmdlets module.

.DESCRIPTION
Gets the module details for the Huawei-iBMC-Cmdlets module.

.INPUTS

.OUTPUTS
PSObject
Returns module details include GUID, Name, Version, Path, Description

.EXAMPLE
Get-iBMCModuleVersion

GUID        : 89a819e4-4ce1-438a-bd57-ac9828aa5ef5
Name        : Huawei-iBMC-Cmdlets
Version     : 0.0.1
Path        : C:\Program Files\WindowsPowerShell\Modules\Huawei-iBMC-Cmdlets\Huawei-iBMC-Cmdlets.psm1
Description : Huawei iBMC cmdlets provide cmdlets to quick access iBMC Redfish devices.
              These cmdlets contains operation used most such as: bois setting, syslog, snmp, network, power and etc.


This example shows the cmdlets module details.

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

#>
    [CmdletBinding(PositionalBinding=$false)]
    $module = Get-module | Where-Object {$_.Name -eq 'Huawei-iBMC-Cmdlets'}
    $versionObject = New-Object PSObject
    $versionObject | Add-member 'GUID' $module.GUID
    $versionObject | Add-member 'Name' $module.Name
    $versionObject | Add-member 'Version' $module.Version
    $versionObject | Add-member 'Path' $module.Path
    $versionObject | Add-member 'Description' $module.Description
    return $versionObject
}

# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.
# Export-ModuleMember -Function *-*
Export-ModuleMember -Function *-iBMC*
