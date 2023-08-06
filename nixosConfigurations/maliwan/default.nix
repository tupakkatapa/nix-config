{
  pkgs,
  lib,
  config,
  ...
}: {
  # Timezone and system version
  time.timeZone = "Europe/Helsinki";
  system.stateVersion = "23.11";

  # Import hardware configuration
  imports = [
    ./hardware-configuration.nix
  ];

  # https://github.com/NixOS/nixpkgs/issues/143365
  security.pam.services = {swaylock = {};};

  # https://github.com/nix-community/home-manager/issues/3113
  programs.dconf.enable = true;

  # Font packages
  fonts.packages = with pkgs; [
    fira-code
    fira-code-symbols
    font-awesome
    jetbrains-mono
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
  ];

  # Thunar
  programs.thunar.enable = true;
  programs.thunar.plugins = with pkgs.xfce; [
    thunar-media-tags-plugin
    thunar-archive-plugin
    thunar-volman
  ];
  # Archive manager
  programs.file-roller.enable = true;
  # Mount, trash, and other functionalities
  services.gvfs.enable = true;
  # Thumbnail support for images
  services.tumbler.enable = true;

  # Use the latest kernel
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest);

  # Enable sshfs package for mounting SSH drives
  # https://nixos.org/manual/nixos/stable/#sec-sshfs-non-interactive
  system.fsPackages = [pkgs.sshfs];

  # Create directories, these are persistent
  systemd.tmpfiles = builtins.listToAttrs (map (user: {
    name = "rules";
    value = [
      "d /home/${user}/.ssh 755 ${user} ${user} -"
      "d /home/${user}/Pictures/Screenshots 755 ${user} ${user} -"
      "d /home/${user}/Workspace 755 ${user} ${user} -"
    ];
  }) (builtins.attrNames config.home-manager.users));

  # Connectivity
  networking = {
    networkmanager.enable = true;
    hostName = "maliwan";
    firewall.enable = false;
  };
  hardware.bluetooth.enable = true;

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

  # Audio settings
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Firmware blobs
  hardware.enableRedistributableFirmware = true;
}
