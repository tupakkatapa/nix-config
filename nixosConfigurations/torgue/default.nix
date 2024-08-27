{ pkgs
, config
, ...
}: {
  imports = [
    ../.config/openrgb.nix
    ../.config/gaming-amd.nix
    ../.config/pipewire.nix
    ../.config/tuigreet-hypr.nix
    ../.config/retroarch.nix
    ../.config/virtualisation.nix
    ./hardware-configuration.nix
  ];

  # For screensharing via OBS
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    config.common.default = "hyprland";
  };

  # Mirror android phone automatically
  services.autoScrcpy = {
    enable = true;
    user = {
      name = "kari";
      id = 1000;
    };
    waylandDisplay = "wayland-1";
  };

  # EFI Bootloader
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    grub = {
      enable = true;
      configurationLimit = 50;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
      # Text mode
      gfxmodeEfi = "text";
      gfxmodeBios = "text";
      splashImage = null;
    };
    timeout = 1;
  };
  time.hardwareClockInLocalTime = true;

  # Support for cross compilation
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

  # Set the font for GRUB
  boot.loader.grub.font = "${pkgs.terminus_font}/share/fonts/terminus/ter-x24n.pcf.gz";
  boot.loader.grub.fontSize = 24;

  # https://github.com/NixOS/nixpkgs/issues/143365
  security.pam.services.swaylock = { };

  # https://github.com/nix-community/home-manager/issues/3113
  programs.dconf.enable = true;

  # Basic font packages
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    fira-code
    fira-code-symbols
  ];

  # Enable GVfs service for file managers to work properly
  services.gvfs.enable = true;

  # Enable ADB for android development
  programs.adb.enable = true;

  # Add support for NTFS file system for mounting Windows drives
  # https://nixos.wiki/wiki/NTFS
  boot.supportedFilesystems = [ "ntfs" ];

  # Connectivity
  networking = {
    networkmanager.enable = true;
    hostName = "torgue";
    firewall.enable = false;
  };
  hardware.bluetooth.enable = true;

  # Binary cache
  services.nix-serve = {
    enable = true;
    secretKeyFile = config.age.secrets."cache-priv-key".path;
    port = 5000;
    openFirewall = true;
  };

  # Optimize kernel for low-latency audio
  powerManagement.cpuFreqGovernor = "performance";
  musnix.enable = true;

  # Logitech unifying receiver
  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true;

  # Logitech steering wheel
  hardware.new-lg4ff.enable = true;

  # Host-spesific system packages
  environment.systemPackages = with pkgs; [
    # Hardware
    oversteer
    solaar
  ];
}
