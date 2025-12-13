{ config
, lib
, ...
}: {
  # Kernel parameters to optimize performance
  boot.kernelParams = [
    "mitigations=off"
    "l1tf=off"
    "mds=off"
    "no_stf_barrier"
    "noibpb"
    "noibrs"
    "nopti"
    "nospec_store_bypass_disable"
    "nospectre_v1"
    "nospectre_v2"
    "tsx=on"
    "tsx_async_abort=off"

    # Enable clock and voltage adjustment for AMD GPU
    "amdgpu.ppfeaturemask=0xffffffff"
  ];

  # Load I2C modules for hw communication
  boot.kernelModules = [ "i2c-dev" "i2c-piix4" ];

  hardware = {
    # Xbox controller
    bluetooth.enable = true;
    xpadneo.enable = true;

    # Xbox Wireless Adapter dongle
    xone.enable = true;

    # Firmware configurations
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
