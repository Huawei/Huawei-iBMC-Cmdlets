# Huawei iBMC Cmdlets

    Huawei iBMC cmdlets provide cmdlets to quick access iBMC Redfish devices.  
    These cmdlets contains the most commonly used features such as: information query, RAID configuration, OS deploy, firmware upgrade.

# Supported Device

    Huawei Blade Server:        CH121 V3, CH242 V3  
    Huawei Rack Server:         1288H V5, 2288H V5, 2288 V5, 2488H V5，RH1288 V3, RH2288 V3, RH2288H V3   
    Huawei High-density Server: XH622 V3

## Requirements

- PowerShell 5.0+

- [.Net Framework 4.5](http://www.microsoft.com/en-us/download/details.aspx?id=30653)

- [WMF 5.0](https://www.microsoft.com/en-us/download/details.aspx?id=50395)

## Install

- Online installation  

  ```powershell
  Install-Module -Name Huawei-iBMC-Cmdlets -RequiredVersion 1.1.0
  ```
- Local installation  

  1、Decompress the Huawei-iBMC-Cmdlets v1.1.0.zip software packages to obtaion the Huawei-iBMC-Cmdlets folder  
  2、Copy the Huawei-iBMC-Cmdlets folder to the PowerShell installation directory  
  3、Run the following command to install Huawei-iBMC-Cmdlets:  
  
  ```powershell
  Import-Module -Name Huawei-iBMC-Cmdlets -Force
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

## Open Source Software Statement
    URL: https://github.com/Huawei/Huawei-iBMC-Cmdlets/Open Source Software Statement.xlsx 
