# Copyright (C) 2020 Huawei Technologies Co., Ltd. All rights reserved.	
# This program is free software; you can redistribute it and/or modify 
# it under the terms of the MIT License		

# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# MIT License for more detail

<# NOTE: A PowerShell type definition implementation. #>

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

try { [SnmpV3PrivProtocol] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum SnmpV3PrivProtocol {
      DES,
      AES
    }
'@
}

try { [SnmpV3AuthProtocol] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum SnmpV3AuthProtocol {
      MD5,
      SHA1
    }
'@
}

try { [TrapVersion] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum TrapVersion {
      V1,
      V2C,
      V3
    }
'@
}

try { [TrapMode] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum TrapMode {
      OID,
      EventCode,
      PreciseAlarm
    }
'@
}

try { [ServerIdentity] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum ServerIdentity {
      HostName,
      BoardSN,
      ProductAssetTag
    }
'@
}

try { [AlarmSeverity] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum AlarmSeverity {
      Critical,
      Major,
      Minor,
      Normal
    }
'@
}

try { [TransmissionProtocol] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum TransmissionProtocol {
      UDP,
      TCP,
      TLS
    }
'@
}

try { [BootSourceOverrideTarget] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum BootSourceOverrideTarget {
      None,
      Pxe,
      Floppy,
      Cd,
      Hdd,
      BiosSetup
    }
'@
}

try { [BootSourceOverrideEnabled] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum BootSourceOverrideEnabled {
      Disabled,
      Once,
      Continuous
    }
'@
}

try { [ServiceName] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum ServiceName {
      HTTP,
      HTTPS,
      SNMP,
      VirtualMedia,
      IPMI,
      SSH,
      KVMIP,
      VNC,
      Video,
      NAT
    }
'@
}

try { [UserRole] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum UserRole {
      Administrator,
      Operator,
      Commonuser,
      Noaccess,
      CustomRole1,
      CustomRole2,
      CustomRole3,
      CustomRole4
    }
'@
}

try { [LogType] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum LogType {
      OperationLog,
      SecurityLog,
      EventLog
    }
'@
}

try { [BootSequence] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum BootSequence {
      Pxe,
      Hdd,
      Cd,
      Others
    }
'@
}


try { [FirmwareType] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum FirmwareType {
      OutBand,
      InBand,
      SP
    }
'@
}

try { [UpgradeMode] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum UpgradeMode {
      Auto,
      Full,
      Recover,
      APP,
      Driver
    }
'@
}

try { [DriveLEDState] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum DriveLEDState {
      Off,
      Blinking
    }
'@
}

try { [DriveState] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum DriveState {
      Online,
      Offline,
      UnconfiguredGood,
      UnconfigureBad,
      JBOD
    }
'@
}

try { [HotSpareType] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum HotSpareType {
      None,
      Global,
      Dedicated
    }
'@
}

try { [VolumeInitAction] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum VolumeInitAction {
      QuickInit,
      FullInit,
      CancelInit
    }
'@
}

try { [VolumeInitMode] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum VolumeInitMode {
      UnInit,
      QuickInit,
      FullInit
    }
'@
}

try { [StripSize] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum StripSize {
      Size64KB = 65536,
      Size128KB = 131072,
      Size256KB = 262144,
      Size512KB = 524288,
      Size1MB = 1048576
    }
'@
}

try { [RAIDLevel] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum RAIDLevel {
      RAID0,
      RAID1,
      RAID5,
      RAID6,
      RAID10,
      RAID50,
      RAID60
    }
'@
}

try { [SPRAIDLevel] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum SPRAIDLevel {
      RAID0,
      RAID1,
      RAID10,
      RAID1E
    }
'@
}

try { [DefaultReadPolicy] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum DefaultReadPolicy {
      NoReadAhead,
      ReadAhead
    }
'@
}

try { [DefaultWritePolicy] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum DefaultWritePolicy {
      WriteThrough,
      WriteBackWithBBU,
      WriteBack
    }
'@
}

try { [DefaultCachePolicy] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum DefaultCachePolicy {
      CachedIO,
      DirectIO
    }
'@
}

try { [AccessPolicy] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum AccessPolicy {
      ReadWrite,
      ReadOnly,
      Blocked
    }
'@
}

try { [DriveCachePolicy] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum DriveCachePolicy {
      Unchanged,
      Enabled,
      Disabled
    }
'@
}

try { [RAIDCardModel] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum RAIDCardModel {
      LSI3008
    }
'@
}

try { [FRU] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum FRU {
      OS = 0,
      Base = 1,
      Fabric = 2,
      FC = 3
    }
'@
}

try { [ControlType] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum ControlType {
      On,
      GracefulShutdown,
      ForceRestart,
      Nmi,
      ForcePowerCycle
    }
'@
}

try { [LicenseSource] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum LicenseSource {
      iBMC,
      FusionDirector,
      eSight
    }
'@
}

try { [IPVersion] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum IPVersion {
      IPv4,
      IPv6,
      IPv4AndIPv6
    }
'@
}

try { [IPv4AddressOrigin] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum IPv4AddressOrigin {
      Static,
      DHCP
    }
'@
}

try { [IPv6AddressOrigin] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum IPv6AddressOrigin {
      Static,
      DHCPv6
    }
'@
}

try { [CertificateVerificationLevel] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum CertificateVerificationLevel {
      Demand,
      Allow
    }
'@
}

try { [GroupLoginRole] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum GroupLoginRole {
      Rule1,
      Rule2,
      Rule3
    }
'@
}

try { [GroupLoginInterface] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum GroupLoginInterface {
      Web,
      SSH,
      Redfish
    }
'@
}

try { [LDAPGroupRole] | Out-Null } catch {
  Add-Type -TypeDefinition @'
    public enum LDAPGroupRole {
      Administrator,
      Operator,
      Commonuser,
      CustomRole1,
      CustomRole2,
      CustomRole3,
      CustomRole4
    }
'@
}
