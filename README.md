# Huawei iBMC Cmdlets

Huawei iBMC Cmdlets provide cmdlets to quick access iBMC Redfish devices.
These cmdlets contains operation used most such as: bois setting, syslog, snmp, network, power, firmware update and etc.


## Requirements

- PowerShell 5.0+

- [.Net Framework 4.5](http://www.microsoft.com/en-us/download/details.aspx?id=30653)


## Install

- Online installation 
  ```powershell
  Install-Module -Name Huawei-iBMC-Cmdlets -RequiredVersion 1.0.0
  ```
- Local installation

  1、Decompress the Huawei-iBMC-Cmdlets V1.0.zip software package to obtain the Huawei-iBMC-Cmdlets folder.

  2、Copy the Huawei-iBMC-Cmdlets folder to the PowerShell installation directory.

  3、Run the following command to install Huawei-iBMC-Cmdlets:

  ```powershell
  Import-Module Huawei-iBMC-Cmdlets -Force
  ```

## Usage

This is a sample for get user accounts:

```powershell

PS C:\> $credential = Get-Credential
PS C:\> $session = Connect-iBMC -Address 10.1.1.2 -Credential $credential -TrustCert
PS C:\> $Users = Get-iBMCUser -Session $session
PS C:\> $Users

Id       : 2
Name     : User Account
UserName : Administrator
RoleId   : Administrator
Locked   : False
Enabled  : True
Oem      : @{Huawei=}

Id       : 3
Name     : User Account
UserName : root
RoleId   : Administrator
Locked   : True
Enabled  : True
Oem      : @{Huawei=}

```

To get all available cmdlets provided by Huawei-iBMC-Cmdlets

```
PS C:\> Get-Command -Module Huawei-iBMC-Cmdlets
```


To get help for a specified cmdlet:

```
PS C:\> get-help Connect-iBMC -Full
```
