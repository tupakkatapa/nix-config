{ pkgs
, lib
, config
, ...
}: {
  # Enable clock and voltage adjustment for AMD GPU
  boot.kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];

  # System packages
  environment.systemPackages = with pkgs; [
    xow_dongle-firmware
  ];

  # Steam and gaming settings
  nixpkgs.config.allowUnfree = true;
  programs.steam = {
    enable = true;
    package = pkgs.steam.override {
      extraPkgs = pkgs:
        with pkgs; [
          xorg.libXcursor
          xorg.libXi
          xorg.libXinerama
          xorg.libXScrnSaver
          libblockdev
          libpng
          libpulseaudio
          libvorbis
          stdenv.cc.cc.lib
          libkrb5
          keyutils
        ];
    };
  };
  hardware.xpadneo.enable = true;
  hardware.xone.enable = true;
  hardware.bluetooth.enable = true;
  security.rtkit.enable = true;

  programs.gamemode = {
    enable = true;
    settings = {
      general = { renice = 10; };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
    };
  };

  # Nixos-hardware
  hardware.amdgpu.amdvlk = true;
  hardware.amdgpu.loadInInitrd = true;
  hardware.amdgpu.opencl = true;

  # Firmware blobs
  hardware.enableRedistributableFirmware = true;
}
