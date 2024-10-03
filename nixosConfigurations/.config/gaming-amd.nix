{ pkgs
, config
, lib
, ...
}: {
  imports = [
    ./virtualization/wine.nix
  ];

  # Enable clock and voltage adjustment for AMD GPU
  boot.kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];

  # System packages
  environment.systemPackages = with pkgs; [
    xow_dongle-firmware
    discord

    # Lutris
    # (lutris.override {
    #   extraPkgs = _pkgs: [
    #     # List package dependencies here
    #     winetricks
    #     wineWowPackages.waylandFull
    #   ];
    # })
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
  hardware.graphics.enable32Bit = true;

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
  hardware.amdgpu = {
    amdvlk.enable = true;
    initrd.enable = true;
    # opencl.enable = true;
  };

  # Firmware blobs
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
