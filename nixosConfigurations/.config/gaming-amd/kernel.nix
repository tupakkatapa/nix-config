{ config
, pkgs
, lib
, ...
}: {
  # Use Zen kernel
  boot.kernelPackages = pkgs.linuxPackages_zen;

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
