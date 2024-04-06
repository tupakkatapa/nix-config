{ pkgs
, ...
}:
let
  user = "kari";
in
{
  /*
     Persistent file memo

    nix-serve:
    /var/cache-priv-key.pem
    /var/cache-pub-key.pem

    yubikey:
    ~/.config/Yubico/u2f_keys

    ssh:
    ~/.ssh/id_ed25519
    /etc/ssh/ssh_host_ed25519_key
  */

  # # Enable NIC driver for stage-1
  # boot.kernelPatches = [
  #   {
  #     name = "kernel nic config (torgue)";
  #     patch = null;
  #     extraConfig = ''
  #       IGB y
  #       ETHERNET y
  #       NET_VENDOR_INTEL y
  #     '';
  #   }
  # ];

  # services.kepler.enable = true;
  # services.havana.enable = true;

  # Extra SSH/SFTP settings
  # services.openssh.hostKeys = [
  #   {
  #     path = "/mnt/860/secrets/ssh/ssh_host_ed25519_key";
  #     type = "ed25519";
  #   }
  # ];

  # Mount drives
  # fileSystems."/mnt/860" = {
  #   device = "/dev/disk/by-uuid/a11f36c2-e601-4e6c-b8c2-136c4b07203e";
  #   fsType = "btrfs";
  #   # options = ["subvolid=420"];
  #   neededForBoot = true;
  # };
  # fileSystems."/mnt/boot" = {
  #   device = "/dev/disk/by-uuid/AD1A-1390";
  #   fsType = "auto";
  # };
  # fileSystems."/mnt/870" = {
  #   device = "/dev/disk/by-uuid/74D4CED9D4CE9CAC";
  #   fsType = "ntfs-3g";
  #   options = ["rw"];
  # };

  # Create directories, these are persistent
  # systemd.tmpfiles.rules = [
  #   "d /mnt/sftp                   755 root root -"
  #   "d /mnt/boot                   755 root root -"
  #   "d /mnt/860                    755 root root -"
  #   "d /mnt/860/games              755 root root -"
  #   "d /mnt/860/secrets            755 root root -"
  #   "d /mnt/860/nix-config         755 root root -"
  #   "d /mnt/860/${appData}         777 root root -"
  #   "d /mnt/860/${appData}/firefox 755 ${user} ${user} -"
  #   "d /mnt/870                    755 root root -"
  # ];

  # Bind firefox directory to preserve cookies and such
  # fileSystems."/home/${user}/.mozilla" = {
  #   device = "${appData}/firefox";
  #   options = ["bind" "mode=755"];
  # };

  services.ollama = {
    enable = true;
    acceleration = "rocm";
    listenAddress = "0.0.0.0:11434";
  };

  # Mirror Android phone automatically
  services.autoScrcpy = {
    enable = true;
    user = {
      name = "kari";
      id = 1000;
    };
    waylandDisplay = "wayland-1";
  };

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

  # Support for cross compilation
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

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

  # Podman
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # VirtualBox
  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;
  };
}
