{ config
, lib
, ...
}: {
  # Enable clock and voltage adjustment for AMD GPU
  boot.kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];

  hardware = {
    # Xbox controller
    bluetooth.enable = true;
    xpadneo.enable = true;
    xone.enable = true;

    # Vulkan
    amdgpu.amdvlk.enable = false;

    # Firmware configurations
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
