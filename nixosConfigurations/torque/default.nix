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
      configurationLimit = 10;
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

  # Set the console keymap and font
  console.keyMap = "fi";
  console.font = "${pkgs.terminus_font}/share/consolefonts/ter-c24n.psf.gz";

  # Use the latest kernel
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest);

  # Timezone, system version and locale
  time.timeZone = "Europe/Helsinki";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_MESSAGES = "en_US.UTF-8";
    LC_TIME = "fi_FI.UTF-8";
  };

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

  # Enable clock and voltage adjustment for AMD GPU
  boot.kernelParams = ["amdgpu.ppfeaturemask=0xffffffff"];

  # RGB
  systemd.services.openrgb = {
    description = "OpenRGB Daemon";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = "${pkgs.openrgb}/bin/openrgb --server";
      Restart = "on-failure";
    };
  };
  services.udev.packages = [pkgs.openrgb-with-all-plugins];
  # You must load the i2c-dev module along with the correct i2c driver for your motherboard.
  # This is usually i2c-piix4 for AMD systems and i2c-i801 for Intel systems.
  boot.kernelModules = ["i2c-dev" "i2c-piix4"];

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
  services.resolved.enable = true;

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

  # Host-spesific system packages
  environment.systemPackages = with pkgs; [
    # Hardware
    oversteer
    openrgb-with-all-plugins
    solaar
    xow_dongle-firmware

    # Wine
    wineWowPackages.staging
    winetricks

    # Podman-compose
    podman-compose
  ];

  # VirtualBox
  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;
  };

  # Podman
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    # dnsname allows containers to use ${name}.dns.podman to reach each other
    # on the same host instead of using hard-coded IPs.
    # NOTE: --net must be the same on the containers, and not eq "host"
    # TODO: extend this with flannel ontop of wireguard for cross-node comms
    defaultNetwork.settings = {dns_enabled = true;};
  };

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
  hardware.steam-hardware.enable = true;

  programs.gamemode = {
    enable = true;
    settings = {
      general = {renice = 10;};
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
  hardware.xpadneo.enable = true;
}
