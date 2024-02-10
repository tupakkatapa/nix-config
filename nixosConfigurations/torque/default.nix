{
  pkgs,
  lib,
  config,
  ...
}: {
  # EFI Bootloader with dualboot
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

  # Set the font for GRUB
  boot.loader.grub.font = "${pkgs.terminus_font}/share/fonts/terminus/ter-x24n.pcf.gz";
  boot.loader.grub.fontSize = 24;

  # Imports
  imports = [
    ../.config/openrgb.nix
    ../.config/gaming-amd.nix
    ../.config/pipewire.nix
    ../.config/tuigreet-hypr.nix
    ../.config/yubikey.nix
    ./hardware-configuration.nix
  ];

  # https://github.com/NixOS/nixpkgs/issues/143365
  security.pam.services = {swaylock = {};};

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
  boot.supportedFilesystems = ["ntfs"];

  # Enable sshfs package for mounting SSH drives
  # https://nixos.org/manual/nixos/stable/#sec-sshfs-non-interactive
  system.fsPackages = [pkgs.sshfs];

  # Connectivity
  networking = {
    networkmanager.enable = true;
    hostName = "torque";
    firewall.enable = false;
  };
  hardware.bluetooth.enable = true;

  # Binary cache
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/var/cache-priv-key.pem";
    port = 5000;
    openFirewall = true;
  };

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

    # Wine
    winetricks
    wineWowPackages.waylandFull

    # Podman-compose
    podman-compose
  ];

  # VirtualBox
  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;
  };
}
