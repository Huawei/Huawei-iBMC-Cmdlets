# Copyright (C) 2020 Huawei Technologies Co., Ltd. All rights reserved.	
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the MIT License		

# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# MIT License for more detail

# Implement your module commands in this script.

# . $PSScriptRoot/common/Common.ps1
# . $PSScriptRoot/common/Redfish.ps1

# Import all functional scripts
$CommonFunctions = @(Get-ChildItem -Path $PSScriptRoot\common\ -Recurse -Filter *.ps1)
$CommonFunctions | ForEach-Object {
  $File = $_.FullName
  try {
    . $File
  } catch {
      Write-Error -Message "Failed to import file: $File"
  }
}

# Import all User scripts
$UserFunctions = @(Get-ChildItem -Path $PSScriptRoot\scripts\ -Recurse -Filter *.ps1)
$UserFunctions | ForEach-Object {
  $File = $_.FullName
  try {
    . $File
  } catch {
      Write-Error -Message "Failed to import file: $File"
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
Returns module details include Name, Version, Path, Description

.EXAMPLE
Get-iBMCModuleVersion

Name        : Huawei-iBMC-Cmdlets
Version     : 1.0.1
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
    # $versionObject | Add-member 'GUID' $module.GUID
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
