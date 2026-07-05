{ config, ... }: {
  # Load the NVIDIA proprietary driver
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics.enable = true;

  # legacy_580: 595+ dropped Pascal (GTX 10xx). Strip unused libs (NVENC/NVDEC + EGL only).
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_580.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      rm -f "$out"/lib/libnvoptix.so* "$out"/lib/nvoptix.bin \
            "$out"/lib/libnvidia-rtcore.so* "$out"/lib/libnvidia-opencl.so*
    '';
  });

  hardware.nvidia = {
    # Proprietary modules required for Pascal (GTX 10xx)
    open = false;

    # Pascal has no GPU System Processor
    gsp.enable = false;

    # Required for Wayland compositors
    modesetting.enable = true;

    # Keep GPU initialized in headless mode
    nvidiaPersistenced = true;

    # Preserve VRAM across driver events
    powerManagement.enable = true;
    powerManagement.finegrained = false; # Turing+ PRIME only

    # VA-API via NVDEC for hardware transcoding
    videoAcceleration = true;

    # No GUI settings tool on headless/server
    nvidiaSettings = false;
  };

  # VRAM state to disk-backed storage (not tmpfs)
  boot.kernelParams = [ "nvidia.NVreg_TemporaryFilePath=/var/tmp" ];
}
