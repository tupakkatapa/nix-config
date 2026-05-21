{ config
, lib
, ...
}: {
  boot.kernelParams = [
    "intel_pstate=active"
  ];

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
