{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  openrgb-rules = builtins.fetchurl {
    url = "https://gitlab.com/CalcProgrammer1/OpenRGB/-/blob/84de7ebc3ea7186d9d4da4397b6ff7bf8ed180d0/60-openrgb.rules";
    sha256 = "sha256:0cv30p5qycq8yrnyf77f06r86cdfxpq72l00kwvf4qdxbrraxvm7";
  };
in
with lib; {
  boot.loader.systemd-boot.enable = true;
  time.timeZone = "Europe/Helsinki";
  system.stateVersion = "23.11";

  imports = [
    ./hardware-configuration.nix
    ../../home-manager/kari
  ];

  # AMD GPU
  boot.kernelParams = [
    "amdgpu.ppfeaturemask=0xffffffff"
  ];

  # Use stable kernel
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest);

  # Connectivity
  networking = {
    networkmanager.enable = true;
    hostName = "torque";
    firewall.enable = false;
  };
  hardware.bluetooth.enable = true;

  # Host spesific packages
  environment.systemPackages = with pkgs; [
    libblockdev # as team dependency
    pulseaudio # has pactl
  ];

  # RGB
  systemd.services.openrgb = {
    description = "OpenRGB Daemon";
      wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = "${pkgs.openrgb}/bin/openrgb --server";
      Restart = "on-failure";
    };
  };
    services.udev.packages = [pkgs.openrgb];
    services.udev.extraRules = builtins.readFile openrgb-rules;
  # You must load the i2c-dev module along with the correct i2c driver for your motherboard.  
  # This is usually i2c-piix4 for AMD systems and i2c-i801 for Intel systems.
    boot.kernelModules = ["v4l2loopback" "i2c-dev" "i2c-piix4"];

  # Gaming
  nixpkgs.config.allowUnfree = true;
  programs.steam.enable = true;
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
    };
  };

  hardware.opengl = {
    ## radv: an open-source Vulkan driver from freedesktop
    driSupport = true;
    driSupport32Bit = true;

    ## amdvlk: an open-source Vulkan driver from AMD
    extraPackages = [pkgs.amdvlk];
    extraPackages32 = [pkgs.driversi686Linux.amdvlk];
  };
  hardware.steam-hardware.enable = true;
  hardware.xpadneo.enable = true;

  # Sound
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Window manager
  home-manager.sharedModules = [
    inputs.hyprland.homeManagerModules.default
  ];
  programs = {
    hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };
    waybar = {
      enable = true;
      package = pkgs.waybar.overrideAttrs (oa: {
        mesonFlags = (oa.mesonFlags or []) ++ ["-Dexperimental=true"];
      });
    };
    fish.loginShellInit = ''
      if test (tty) = "/dev/tty1"
        exec Hyprland &> /dev/null
      end
    '';
  };
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    LIBSEAT_BACKEND = "logind";
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";

    BROWSER = "librewolf";
    TERMINAL = "alacritty";
    EDITOR = "nvim";
  };

  # Firmware blobs
  hardware.enableRedistributableFirmware = true;
}
