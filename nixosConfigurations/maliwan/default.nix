{
  pkgs,
  lib,
  config,
  ...
}: {
  # Timezone, system version and locale
  time.timeZone = "Europe/Helsinki";
  system.stateVersion = "23.11";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_MESSAGES = "en_US.UTF-8";
    LC_TIME = "fi_FI.UTF-8";
  };

  # Import hardware configuration
  imports = [
    ./hardware-configuration.nix
  ];

  # Greetd
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = builtins.concatStringsSep " " [
          "${pkgs.greetd.tuigreet}/bin/tuigreet"
          "--asterisks"
          "--remember"
          "--time"
          "--cmd Hyprland"
        ];
        user = "greeter";
      };
    };
  };
  # https://www.reddit.com/r/NixOS/comments/u0cdpi/tuigreet_with_xmonad_how/
  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    # Without this errors will spam on screen
    StandardError = "journal";
    # Without these bootlogs will spam on screen
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };

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

  # Enable ADB for android development
  programs.adb.enable = true;

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
    jack.enable = true;
  };
  # Make pipewire realtime-capable
  security.rtkit.enable = true;

  # Firmware blobs
  hardware.enableRedistributableFirmware = true;
}
