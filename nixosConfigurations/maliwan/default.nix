{
  pkgs,
  lib,
  config,
  ...
}: {
  # Bootloader for x86_64-linux / aarch64-linux
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # Use the latest kernel
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest);

  # Timezone, system version and locale
  time.timeZone = "Europe/Helsinki";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_MESSAGES = "en_US.UTF-8";
    LC_TIME = "fi_FI.UTF-8";
  };
  console.keyMap = "fi";

  # Import hardware configuration
  imports = [./hardware-configuration.nix];

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
  system.fsPackages = [pkgs.sshfs];

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
      AllowAgentForwarding no
      AllowStreamLocalForwarding no
      AllowTcpForwarding yes
      AuthenticationMethods publickey
      X11Forwarding no
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

  # Enable OpenGL drivers
  hardware.opengl.enable = true;
}
