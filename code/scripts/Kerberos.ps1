# Copyright (C) 2020-2021 Huawei Technologies Co., Ltd. All rights reserved.
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the MIT License		

# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# MIT License for more detail

<# NOTE: iBMC Systems module Cmdlets #>

function Get-iBMCKerberos {
<#
.SYNOPSIS
Get Kerberos resource details of the server.

.DESCRIPTION
Get Kerberos resource details of the server.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.OUTPUTS
Object[]
Return Object Arrays. Elements contain iBMC Kerberos information if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $System = Get-iBMCKerberos $session
PS C:\> $System

Host            : 192.168.1.1
Id              : KerberosService
Name            : Kerberos Service
KerberosEnabled : True

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

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

    $Logger.info("Invoke Get iBMC Kerberos function")

    $ScriptBlock = {
      param($RedfishSession)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get iBMC Kerberos now"))
      $Path = "/AccountService/KerberosService"
      $Response = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
      $Properties = @(
        "^Id$", "^Name$", "^KerberosEnabled$"
      )

      $System = Copy-ObjectProperties $Response $Properties
      return Update-SessionAddress $RedfishSession $System
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get iBMC Kerberos task"))
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

function Set-iBMCKerberos {
<#
.SYNOPSIS
Set Kerberos resource details of the server.

.DESCRIPTION
Set Kerberos resource details of the server.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER KerberosEnabled
parameter to set KerberosEnabled configuration
Available Value Set: $true(1), $false(0)
-$true(1): Enable KerberosEnabled
-$false(0) Disable KerberosEnabled

.OUTPUTS
Object[]
Return Object Arrays. Elements contain iBMC Kerberos information if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $System = Set-iBMCKerberos -Session $session -KerberosEnabled $true
PS C:\> $System

Host            : 192.168.1.1
Id              : KerberosService
Name            : Kerberos Service
KerberosEnabled : True

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

#>

  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session,

    [Boolean[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $KerberosEnabled
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $KerberosEnabled 'KerberosEnabled'
    $ConfigList = Get-MatchedSizeArray $Session $KerberosEnabled 'Session' 'KerberosEnabled'

    $Logger.info("Invoke Set iBMC Kerberos enable function")

    $ScriptBlock = {
      param($RedfishSession, $Config)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Set iBMC Kerberos Enabled now"))
      $Path = "/AccountService/KerberosService"
      $Payload = @{"KerberosEnabled" = $Config}
      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Payload | ConvertTo-Json)"))
      $Response = Invoke-RedfishRequest $RedfishSession $Path 'Patch' $Payload | ConvertFrom-WebResponse
      $Properties = @(
        "^Id$", "^Name$", "^KerberosEnabled$"
      )

      $System = Copy-ObjectProperties $Response $Properties
      return Update-SessionAddress $RedfishSession $System
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $Config = $ConfigList[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Set iBMC Kerberos Enabled task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock @($RedfishSession, $Config)))
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

function Get-iBMCKerberosController {
<#
.SYNOPSIS
Get Kerberos Controllers or certain controller details of the server.

.DESCRIPTION
Get Kerberos Controllers or certain controller details of the server.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER Id
controller member id, integer, not mandatory

.OUTPUTS
Object[]
Return Object Arrays. Elements contain iBMC Kerberos Controllers or certain controller information if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $System = Get-iBMCKerberosController -Session $session
PS C:\> $System

Host         Id              Name                KerberosEnabled
----         --              ----                ---------------
192.168.1.1 KerberosService Kerberos Service               True
             1               Kerberos Controller

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $System = Get-iBMCKerberosController -Session $session -Id 1
PS C:\> $System

Host                  : 192.168.1.1
Name                  : Kerberos Controller
Id                    : 1
KerberosServerAddress : hi
KerberosPort          : 88
Realm                 : realm
KerberosGroups        : {@{MemberId=0; GroupName=test; GroupDomain=hello; GroupSID=; GroupRole=No Access; GroupLo
                        ginRule=System.Object[]; GroupLoginInterface=System.Object[]}, @{MemberId=1; GroupName=test2; G
                        roupDomain=chedck world; GroupSID=test2; GroupRole=Common User; GroupLoginRule=System.Object[];
                         GroupLoginInterface=System.Object[]}, @{MemberId=2; GroupName=test; GroupDomain=CN=12345
                        ; GroupSID=5678; GroupRole=Administrator; GroupLoginRule=System.Object[]; GroupLoginInterface=S
                        ystem.Object[]}, @{MemberId=3; GroupName=; GroupDomain=; GroupSID=; GroupRole=No Access; GroupL
                        oginRule=System.Object[]; GroupLoginInterface=System.Object[]}...}

.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

#>

  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session,

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateSet('1')]
    $Id
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'

    $IdList = Get-OptionalMatchedSizeArray $Session $Id
    $Logger.info("Invoke Get iBMC Kerberos Controllers function")

    $ScriptBlock = {
      param($RedfishSession,$MemberId)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Get iBMC Kerberos Controllers now"))
      if ($MemberId) {
        $Path = "/AccountService/KerberosService/KerberosControllers/$($MemberId)"
        $Response = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
        $Properties = @(
          "^Name$", "^Members", "^Id$", "^KerberosServerAddress$", "^KerberosPort$", "^Realm$", "^KerberosGroups$"
        )

        $System = Copy-ObjectProperties $Response $Properties
        return Update-SessionAddress $RedfishSession $System
      } 
      else {
        $Results = New-Object System.Collections.ArrayList

        $KerberosEnablePath = "/AccountService/KerberosService/"
        $KerberosEnableResponse = Invoke-RedfishRequest $RedfishSession $KerberosEnablePath | ConvertFrom-WebResponse
        $KerberosEnableInfo = New-Object PSObject
        $KerberosEnableInfo | Add-Member -MemberType NoteProperty "Id" $KerberosEnableResponse.Id
        $KerberosEnableInfo | Add-Member -MemberType NoteProperty "Name" $KerberosEnableResponse.Name
        $KerberosEnableInfo | Add-Member -MemberType NoteProperty "KerberosEnabled" $KerberosEnableResponse.KerberosEnabled
        $KerberosEnableInfo = $(Update-SessionAddress $RedfishSession $KerberosEnableInfo)
        [Void] $Results.Add($KerberosEnableInfo)

        $Path = "/AccountService/KerberosService/KerberosControllers/"
        $Response = Invoke-RedfishRequest $RedfishSession $Path | ConvertFrom-WebResponse
        $KerberosControllers = $Response.Members
        $KerberosControllers | ForEach-Object {
          $KerberosResponse = Invoke-RedfishRequest $RedfishSession $_.'@odata.id' | ConvertFrom-WebResponse
          $KerberosInfo = New-Object PSObject
          $KerberosInfo | Add-Member -MemberType NoteProperty "Id" $KerberosResponse.Id
          $KerberosInfo | Add-Member -MemberType NoteProperty "Name" $KerberosResponse.Name
          $KerberosInfo | Add-Member -MemberType NoteProperty "KerberosServerAddress" $KerberosResponse.KerberosServerAddress
          $KerberosInfo | Add-Member -MemberType NoteProperty "KerberosPort" $KerberosResponse.KerberosPort
          $KerberosInfo | Add-Member -MemberType NoteProperty "Realm" $KerberosResponse.Realm
          [Void] $Results.Add($KerberosInfo)
        }
        return , $Results.ToArray()
      }
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $MemberId = $IdList[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit Get iBMC Kerberos Controllers task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock @($RedfishSession, $MemberId)))
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


function Set-iBMCKerberosController {
<#
.SYNOPSIS
Set Kerberos Controllers or certain controller details of the server.

.DESCRIPTION
Set Kerberos Controllers or certain controller details of the server.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER Id
controller member id, integer, not mandatory parameter

.PARAMETER GroupID
specify which group to modify, not mandatory parameter, range from 0 to 4 inclusive

.PARAMETER Port
Domain controller port No. A number ranging from 1 to 65535. mandatory parameter

.PARAMETER SeverAddress
Controller Server Address, String

.PARAMETER Realm
controller domain, Character string, for example, TEST.HUAWEI.COM.

.PARAMETER GroupName
Kerberos user group name, Character string

.PARAMETER GroupDomain
Kerberos user group domain, Character string, for example: CN=qwert,OU=admin,DC=huawei,DC=com

.PARAMETER GroupSID
SID of the Kerberos user group, Character string NOTE If the value of group_SID is null, the group configuration information will be deleted.

.PARAMETER GroupRole
Role of the Kerberos user group, Character string

.PARAMETER RuleId
Login rules of the Kerberos user group, Array consisting of character strings. Multiple values can be entered, for example: ["Rule1","Rule2","Rule3"], 

.PARAMETER InterId
Login interface of the Kerberos user group, Array consisting of character strings. Currently, this parameter can be set only to ["Web"]., 

.OUTPUTS
Object[]
Return Object Arrays. Elements contain iBMC Kerberos Controllers or certain controller infomation if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $System = Set-iBMCKerberosController -Session $session -Id 1 -Port 8888
PS C:\> $System

Host                  : 192.168.1.1
Id                    : 1
Name                  : Kerberos Controller
KerberosServerAddress :
KerberosPort          : 8888
Realm                 :
KerberosGroups        : {@{MemberId=0; GroupName=; GroupDomain=; GroupSID=; GroupRole=No Access; GroupLoginRule=System.Object[]; GroupLoginInterface=Sy
                        stem.Object[]}, @{MemberId=1; GroupName=; GroupDomain=; GroupSID=; GroupRole=No Access; GroupLoginRule=System.Object[]; GroupLo
                        ginInterface=System.Object[]}, @{MemberId=2; GroupName=; GroupDomain=; GroupSID=; GroupRole=Operator; GroupLoginRule=System.Obj
                        ect[]; GroupLoginInterface=System.Object[]}, @{MemberId=3; GroupName=; GroupDomain=; GroupSID=; GroupRole=Operator; GroupLoginR
                        ule=System.Object[]; GroupLoginInterface=System.Object[]}...}


.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $System = Set-iBMCKerberosController -Session $session -Id 1 -GroupID 1,3 -GroupName "123"
PS C:\> $System

Host                  : 192.168.1.1
Id                    : 1
Name                  : Kerberos Controller
KerberosServerAddress : hi
KerberosPort          : 88
Realm                 : realm
KerberosGroups        : {@{MemberId=0; GroupName=; GroupDomain=hello; GroupSID=; GroupRole=No Access; GroupLo
                        ginRule=System.Object[]; GroupLoginInterface=System.Object[]}, @{MemberId=1; GroupName=123;
                         GroupDomain=chedck world; GroupSID=test2; GroupRole=Common User; GroupLoginRule=System.Object[
                        ]; GroupLoginInterface=System.Object[]}, @{MemberId=2; GroupName=; GroupDomain=CN=123
                        45; GroupSID=5678; GroupRole=Administrator; GroupLoginRule=System.Object[]; GroupLoginInterface
                        =System.Object[]}, @{MemberId=3; GroupName=123; GroupDomain=; GroupSID=; GroupRole=No Acces
                        s; GroupLoginRule=System.Object[]; GroupLoginInterface=System.Object[]}...}


.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

#>

  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session,

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
    [ValidateSet('1')]
    $Id = @('1'),

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $SeverAddress,

    [int32[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateRange(1, 65535)]
    $Port,

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $Realm,

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $GroupName,

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $GroupDomain,

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $GroupSID = @(' '),

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $GroupRole,

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $RuleId,

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $InterId,

    [int32[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateRange(0, 4)]
    $GroupID
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $Id 'Id'
    $IdList = Get-OptionalMatchedSizeArray $Session $Id
    $PortList = Get-OptionalMatchedSizeArray $Session $Port
    $SeverAddressList = Get-OptionalMatchedSizeArray $Session $SeverAddress
    $RealmList = Get-OptionalMatchedSizeArray $Session $Realm
    $GroupNameList = Get-OptionalMatchedSizeArray $Session $GroupName
    $GroupDomainList = Get-OptionalMatchedSizeArray $Session $GroupDomain
    $GroupSIDList = Get-OptionalMatchedSizeArray $Session $GroupSID
    $GroupRoleList = Get-OptionalMatchedSizeArray $Session $GroupRole
    $RuleIdList = Get-OptionalMatchedSizeArray $Session $RuleId
    $InterIdList = Get-OptionalMatchedSizeArray $Session $InterId

    $Logger.info("Invoke Set iBMC Kerberos Controllers function")

    $ScriptBlock = {
      param($RedfishSession, $MemberId, $Payload)
      $(Get-Logger).info($(Trace-Session $RedfishSession "Invoke Set iBMC Kerberos Controllers now"))
      $Path = "/AccountService/KerberosService/KerberosControllers/$($MemberId)"
      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Payload | ConvertTo-Json)"))

      $Response = Invoke-RedfishRequest $RedfishSession $Path 'Patch' $Payload | ConvertFrom-WebResponse
      $Properties = @(
        "^Id$", "^Name$", "^KerberosServerAddress$", "^KerberosPort$", "^Realm$", "^KerberosGroups$"
      )

      $System = Copy-ObjectProperties $Response $Properties
      return Update-SessionAddress $RedfishSession $System
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $MemberId = $IdList[$idx]
        $Payload = @{
          "KerberosGroups" = New-Object System.Collections.ArrayList
        }
        # Kerberos groups range from 0 to 4
        for ($i = 0; $i -lt 5; $i++) {
          [Void]$Payload."KerberosGroups".Add(@{})
        }
        for ($GroupIdIdx = 0; $GroupIdIdx -lt $GroupID.Count; $GroupIdIdx++) {
          $tempId = $GroupID[$GroupIdIdx]
          if ($null -ne $tempId) {
            $KerberosGroups = $Payload."KerberosGroups"[$tempId]
            if ($null -ne $GroupNameList[$idx]) {
              $KerberosGroups.Add("GroupName", $GroupNameList[$idx])
            }
            if ($null -ne $GroupDomainList[$idx]) {
              $KerberosGroups.Add("GroupDomain", $GroupDomainList[$idx])
            }
            if ([string]::IsNullOrEmpty($GroupSIDList[$idx])) {
              $Logger.info("set groupid to null")
              $KerberosGroups.Add("GroupSID", $null)
            } else {
              $KerberosGroups.Add("GroupSID", $GroupSIDList[$idx])
            }
            if ($null -ne $GroupRoleList[$idx]) {
              $KerberosGroups.Add("GroupRole", $GroupRoleList[$idx])
            }
            if ($null -ne $RuleIdList[$idx]) {
              $rawStr = $RuleIdList[$idx]
              $arrayStr = $rawStr.split(",")
              $KerberosGroups.Add("GroupLoginRule", $arrayStr)
            }
            if ($null -ne $InterIdList[$idx]) {
              $KerberosGroups.Add("GroupLoginInterface", @($InterIdList[$idx]))
            }
          } 
        }
        if ($null -ne $SeverAddressList[$idx]) {
          $Payload.Add("KerberosServerAddress", $SeverAddressList[$idx])
        }
        if ($null -ne $RealmList[$idx]) {
          $Payload.Add("Realm", $RealmList[$idx])
        }
        if ($null -ne $PortList[$idx]) {
          $Payload.Add("KerberosPort", $PortList[$idx])
        }
        $Logger.info($(Trace-Session $RedfishSession "Submit Set iBMC Kerberos Controllers task"))
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock @($RedfishSession, $MemberId, $Payload)))
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

function Import-iBMCKerberosControllerKeyTable {
<#
.SYNOPSIS
Import iBMC BIOS and BMC configuration

.DESCRIPTION
Import iBMC iBMCKerberos controller key table.

.PARAMETER Session
iBMC redfish session object which is created by Connect-iBMC cmdlet.
A session object identifies an iBMC server to which this cmdlet will be executed.

.PARAMETER Id
controller member id, integer, not mandatory parameter

.PARAMETER KeyTable
Local path of the key table.

File path support:
1. import from local storage, example: C:\config.xml

.OUTPUTS
PSObject[]
Returns the import configuration task array if cmdlet executes successfully.
In case of an error or warning, exception will be returned.

.EXAMPLE

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 192.168.1.1 -Credential $credential -TrustCert
PS C:\> $result = Import-iBMCKerberosControllerKeyTable -Session $session -Id 1 -KeyTable "C:\Users\test\Desktop\iBMC1021.keytab"
PS C:\> $result

Host              : 192.168.1.1
MessageId         : iBMC.1.0.KRBKeytabUploadSuccess
RelatedProperties : {}
Message           : The Kerberos key table is uploaded successfully.
MessageArgs       : {}
Severity          : OK
Resolution        : None

This example shows how to import bios settings from local file
  
.LINK
https://github.com/Huawei/Huawei-iBMC-Cmdlets

#>
  [CmdletBinding()]
  param (
    [RedfishSession[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
    $Session,

    [string[]]
    [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateSet('1')]
    $Id = @('1'),

    [string[]]
    [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    $KeyTable
  )

  begin {
  }

  process {
    Assert-ArrayNotNull $Session 'Session'
    Assert-ArrayNotNull $KeyTable 'KeyTable'
    Assert-ArrayNotNull $Id 'Id'
    $IdList = Get-OptionalMatchedSizeArray $Session $Id
    $KeyTableList = Get-MatchedSizeArray $Session $KeyTable 'Session' 'KeyTable'

    $Logger.info("Import iBMC Kerberos Controller Key table function, batch size: $($Session.Count)")

    $ScriptBlock = {
      param($RedfishSession, $MemberId, $KeyTablePath)

      $Payload = @{'Content' = ''}
      if ($KeyTablePath.StartsWith("/tmp")) {
        $payload.Content = $KeyTablePath
      } else {
        $ContentURI = Invoke-FileUploadIfNeccessary $RedfishSession $KeyTablePath $BMC.BIOSConfigFileSupportSchema
        $Payload.Content = $ContentURI
      }

      $Clone = $Payload.clone()
      $Clone.Content = Protect-NetworkUriUserInfo $Payload.Content
      $Logger.info($(Trace-Session $RedfishSession "Sending payload: $($Clone | ConvertTo-Json)"))
      $Path = "/AccountService/KerberosService/KerberosControllers/$($MemberId)/Actions/HwKerberosController.ImportKeyTable"
      $Response = Invoke-RedfishRequest $RedfishSession $Path 'Post' $Payload | ConvertFrom-WebResponse
      $Properties = @(
        "^MessageId$", "^RelatedProperties$", "^Message$", "^MessageArgs$", "^Severity$", "^Resolution$"
      )
      $System = Copy-ObjectProperties $Response.error.'@Message.ExtendedInfo'[0] $Properties

      return Update-SessionAddress $RedfishSession $System
    }

    try {
      $tasks = New-Object System.Collections.ArrayList
      $pool = New-RunspacePool $Session.Count
      for ($idx = 0; $idx -lt $Session.Count; $idx++) {
        $RedfishSession = $Session[$idx]
        $KeyTablePath = $KeyTableList[$idx];
        $MemberId = $IdList[$idx]
        $Logger.info($(Trace-Session $RedfishSession "Submit import iBMC Kerberos Controller Key table task"))
        $Parameters = @($RedfishSession, $MemberId, $KeyTablePath)
        [Void] $tasks.Add($(Start-ScriptBlockThread $pool $ScriptBlock $Parameters))
      }

      $Results = Get-AsyncTaskResults $tasks
      $Logger.Info("Import iBMC Kerberos Controller Key table task: " + $RedfishTasks)
      return ,$Results
    }
    finally {
      Close-Pool $pool
    }
  }

  end {
  }
}