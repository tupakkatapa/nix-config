{ ...
}: {
  imports = [
    # ../.config/gaming-amd.nix
    ../.config/pipewire.nix
    ../.config/tuigreet-hypr.nix
    # ../.config/retroarch.nix
    # ../.config/virtualisation.nix
    ../.config/yubikey.nix
    ./ephemeral.nix
    # ./hardware-configuration.nix
  ];

  # Nixos-hardware
  hardware.amdgpu = {
    amdvlk.enable = true;
    initrd.enable = true;
    # opencl.enable = true;
  };

  # # For screensharing via OBS
  # xdg.portal = {
  #   enable = true;
  #   wlr.enable = true;
  #   config.common.default = "hyprland";
  # };
  #
  # # Mirror android phone automatically
  # services.autoScrcpy = {
  #   enable = true;
  #   user = {
  #     name = "kari";
  #     id = 1000;
  #   };
  #   waylandDisplay = "wayland-1";
  # };

  # Simple bootloader
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;

  # Support for cross compilation
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

  # https://github.com/NixOS/nixpkgs/issues/143365
  # security.pam.services.swaylock = { };

  # https://github.com/nix-community/home-manager/issues/3113
  # programs.dconf.enable = true;

  # Basic font packages
  # fonts.packages = with pkgs; [
  #   noto-fonts
  #   noto-fonts-cjk
  #   noto-fonts-emoji
  #   fira-code
  #   fira-code-symbols
  # ];

  # Enable ADB for android development
  programs.adb.enable = true;

  # Add support for NTFS file system for mounting Windows drives
  # https://nixos.wiki/wiki/NTFS
  boot.supportedFilesystems = [ "ntfs" ];

  # Connectivity
  networking = {
    hostName = "torgue";
    firewall.enable = false;
    useDHCP = false;
  };
  systemd.network = {
    enable = true;
    networks = {
      "10-wan" = {
        linkConfig.RequiredForOnline = "routable";
        matchConfig.Name = "enp3s0";
        networkConfig = {
          DHCP = "no";
          IPv6AcceptRA = true;
        };
        address = [ "192.168.1.7/24" ]; # static IP
      };
    };
  };

  hardware.bluetooth.enable = true;

  # Optimize kernel for low-latency audio
  powerManagement.cpuFreqGovernor = "performance";
  musnix.enable = true;

  # OpenRGB
  services.hardware.openrgb.enable = true;

  # Logitech unifying receiver
  hardware.logitech.wireless.enable = true;
  # hardware.logitech.wireless.enableGraphical = true;

  # Logitech steering wheel
  # hardware.new-lg4ff.enable = true;

  # Host-spesific system packages
  # environment.systemPackages = with pkgs; [
  #   oversteer
  #   solaar
  # ];
}
