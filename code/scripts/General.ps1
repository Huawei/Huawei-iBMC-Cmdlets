# Copyright (C) 2020-2021 Huawei Technologies Co., Ltd. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the terms of the MIT License

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# MIT License for more detail

<# NOTE: iBMC General Call module Cmdlets #>

function Invoke-iBMCGeneralCall {
<#
.SYNOPSIS
Universal Call for redfish api.

.DESCRIPTION
Universal Call for redfish api.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER Url
iBMC redfish Api from the redfish api document, String data type

.PARAMETER Method
Http Method, value to be 'get', 'post', 'patch', 'delete', String type

.PARAMETER ContentType
ContentType http header, value set: Form or Json

.PARAMETER Payload
if post, patch method is provided, one of the Payload and File is mandatory.  Otherwise, general call may be failed

.PARAMETER File
if http method post, patch method is provided, one of the Payload and File is mandatory.  Otherwise, general call may be failed
if ContentType Form is provided, File is mandatory

.OUTPUTS
Object[]
Return Object Arrays. Elements contain iBMC Kerberos infomation if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $System = Invoke-iBMCGeneralCall -Session $session -Url "/AccountService/KerberosService" -Method 'Get' -ContentType Json
PS C:\> $System

Host                : 192.168.1.1
@odata.context      : /redfish/v1/$metadata#AccountService/KerberosService
@odata.id           : /redfish/v1/AccountService/KerberosService
@odata.type         : #HwKerberosService.v1_0_0.HwKerberosService
Id                  : KerberosService
Name                : Kerberos Service
KerberosEnabled     : True
KerberosControllers : @{@odata.id=/redfish/v1/AccountService/KerberosService/KerberosControllers}


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

#>
    
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session,

    [string[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $Url,

    [string[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateSet('Get', 'Delete', 'Post', 'Patch')]
    $Method,

    [HttpContentType[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $ContentType,

    [hashtable[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $Payload,

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $File
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $Url 'Url'
    Assert-ArrayNotNull $Method 'Method'
    Assert-ArrayNotNull $ContentType 'ContentType'

    $UrlList = Get-MatchedSizeArray $Session $Url 'Session' 'Url'
    $MethodList = Get-MatchedSizeArray $Session $Method 'Session' 'Method'
    $ContentTypeList = Get-MatchedSizeArray $Session $ContentType 'Session' 'ContentType'
    $PayloadList = Get-OptionalMatchedSizeArray $Session $Payload
    $FilesList = Get-OptionalMatchedSizeArray $Session $File
    $Logger.info("Invoke iBMC General Request function")
    $ScriptBlock = {
      param($RedfishSession, $UrlApi, $HttpMethod, $Header, $RequestBody, $FilePath)
      if ('Form' -eq $Header) {
        if ([string]::IsNullOrEmpty($FilePath) -or 'get' -eq $HttpMethod.ToLower()) {
          throw $(GET-i18n "ERROR_INVALID_PARAMETERS")
        }
        $UploadFileName = Split-Path $FilePath -Leaf
        Invoke-RedfishFirmwareUpload $RedfishSession $UploadFileName $FilePath | Out-Null
        $Logger.Info($(Trace-Session $RedfishSession "File uploaded as $UploadFileName success"))
        $Result = New-Object PSObject
        $Result | Add-Member -MemberType NoteProperty "Path" "/tmp/web/$UploadFileName"
        return $Result
      }
      elseif ('Json' -eq $Header) {
        if (-Not [string]::IsNullOrEmpty($FilePath)) {
          $RequestBody = Get-Content $FilePath | ConvertFrom-Json
        }
        $Response = Invoke-RedfishRequest $RedfishSession $UrlApi $HttpMethod $RequestBody | ConvertFrom-WebResponse
      }
      return Update-SessionAddress $RedfishSession $Response
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Path = $UrlList[$idx]
        $HttpMethod = $MethodList[$idx]
        $Header = $ContentTypeList[$idx]
        $Payload = $PayloadList[$idx]
        $FilePath = $FilesList[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Invoke iBMC General Request task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock @($RedfishSession, $Path, $HttpMethod, $Header, $Payload, $FilePath)))
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