{ pkgs
, ...
}: {
  imports = [
    ../.config/pipewire.nix
    ../.config/tuigreet-hypr.nix
    ./hardware-configuration.nix
  ];

  # Bootloader for x86_64-linux / aarch64-linux
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # https://github.com/NixOS/nixpkgs/issues/143365
  security.pam.services.swaylock = { };

  # https://github.com/nix-community/home-manager/issues/3113
  programs.dconf.enable = true;

  # Basic font packages
  fonts.packages = with pkgs; [
    fira-code
    fira-code-symbols
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
  ];

  # Enable GVfs service for file managers to work properly
  services.gvfs.enable = true;

  # Enable ADB for android development
  programs.adb.enable = true;

  # Enable sshfs package for mounting SSH drives
  # https://nixos.org/manual/nixos/stable/#sec-sshfs-non-interactive
  system.fsPackages = [ pkgs.sshfs ];

  # Connectivity
  networking = {
    networkmanager.enable = true;
    hostName = "maliwan";
    firewall.enable = false;
  };
  hardware.bluetooth.enable = true;

  # Firmware blobs
  hardware.enableRedistributableFirmware = true;

  # Enable OpenGL drivers
  hardware.graphics.enable = true;
}
