{
  pkgs,
  config,
  inputs,
  lib,
  ...
}:
with lib; {
  boot.loader.systemd-boot.enable = true;
  time.timeZone = "Europe/Helsinki";
  system.stateVersion = "23.11";

  imports = [
    ./hardware-configuration.nix
    ../../home-manager/kari
  ];

  # Autologin if password not set
  services.getty.autologinUser = "kari";

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

  # SSH
  services.openssh = {
    enable = true;
    allowSFTP = false;
    extraConfig = ''
      AllowTcpForwarding yes
      X11Forwarding no
      AllowAgentForwarding no
      AllowStreamLocalForwarding no
      AuthenticationMethods publickey
    '';
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

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
  environment.systemPackages = with pkgs; [
    libblockdev # a Steam dependency
    gamescope
  ];
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
  environment.systemPackages = with pkgs; [
    pulseaudio # has pactl
  ];

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
