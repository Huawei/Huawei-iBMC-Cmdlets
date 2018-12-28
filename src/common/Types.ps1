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
