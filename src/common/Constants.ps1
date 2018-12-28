$global:BMC = @{

  'V52V3Mapping' = @{
    'HardDiskDrive'='HDD';
    'DVDROMDrive'='Cd';
    'PXE'='Pxe';
    'Others'='Others';
  };

  'V32V5Mapping' = @{
    'HDD'='HardDiskDrive';
    'Cd'='DVDROMDrive';
    'Pxe'='PXE';
    'Others'='Others';
  };

  Severity = @{
    OK='OK';
  };

  LinkStatus = @{
    NoLink='NoLink';
    LinkUp='LinkUp';
  };

  TaskState = @{
    Completed='Completed';
    Exception='Exception';
  };

  FRUOperationSystem = 0;

  OutBandFirmwares = @(
    "ActiveBMC", "BackupBMC", "Bios", "MainBoardCPLD", "chassisDiskBP1CPLD"
  );

  InBandFirmwares = @(
    "PCIeCards"
  );

  OutBandImageFileSupportSchema = @(
    "https",
    "scp",
    "sftp",
    "cifs",
    "tftp",
    "nfs",
    "file"
  );

  InBandImageFileSupportSchema = @(
    "https",
    "sftp",
    "nfs",
    "cifs",
    "scp",
    "file"
  );

  SPImageFileSupportSchema = @(
    "nfs",
    "cifs"
  );

  SignalFileSupportSchema = @(
    "https",
    "sftp",
    "nfs",
    "cifs",
    "scp",
    "file"
  );

  BIOSConfigFileSupportSchema = @(
    "https",
    "sftp",
    "nfs",
    "cifs",
    "scp",
    "file"
  );

  NTPKeyFileSupportSchema = @(
    "https",
    "sftp",
    "nfs",
    "cifs",
    "scp",
    "file"
  );

}
