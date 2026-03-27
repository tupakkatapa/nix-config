{ config
, lib
, ...
}: {
  boot.kernelParams = [
    "amd_pstate=active"
  ];

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
