{ pkgs
, lib
, config
, inputs
, ...
}:
let
  domain = "coditon.com";
  user = "kari";
  dataDir = "/mnt/wd-red";

  # Inherit global stuff for imports
  extendedArgs = { inherit pkgs lib config domain dataDir inputs; };
in
{
  age.rekey = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEJktZ00i+OxH4Azi1tLkwoYrJ0qo2RIZ5huzzK+g2w root@vladof";
    agePlugins = [ pkgs.age-plugin-fido2-hmac ];
    localStorageDir = ./secrets/rekeyed;
    storageMode = "local";
  };

  imports = [
    (import ./services extendedArgs)
    (import ./persistence.nix extendedArgs)
    ../.config/hw/cpu-intel.nix
    ../.config/hw/gpu-nvidia.nix
    ../.config/motd.nix
    ../.config/hw/pipewire.nix
    ../.config/hw/yubikey.nix
    ./sunshine.nix
  ];

  # Disk-aware garbage collection
  sys2x.gc.useDiskAware = true;

  # Autologin
  services.getty.autologinUser = user;

  # Cage-kiosk (firefox)
  services.cage = {
    enable = true;
    inherit user;
    program = lib.concatStringsSep " \\\n\t" [
      "${config.home-manager.users."${user}".programs.firefox.package}/bin/firefox"
      "https://www.youtube.com"
      "http://10.23.0.14:32400" # plex
    ];
    environment = {
      XKB_DEFAULT_LAYOUT = "fi";
      HOME = "/home/${user}";
      XCURSOR_THEME = "Capitaine Cursors (Gruvbox)";
      XCURSOR_SIZE = "32";
    };
  };
  systemd.services.cage-tty1 = {
    serviceConfig = {
      Restart = "always";
      RestartSec = 3;
      StartLimitBurst = 0; # unlimited restarts
    };
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };


  # SFTP user/group retained for container file ownership on ${dataDir}/sftp/*
  users.users.sftp = {
    isSystemUser = true;
    useDefaultShell = false;
    group = "sftp";
    home = "${dataDir}/sftp";
  };
  users.groups.sftp = { };

  # Connectivity
  networking = {
    hostName = "vladof";
    domain = "${domain}";
    useDHCP = false;
  };
  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    links."10-wol" = {
      matchConfig.MACAddress = "30:9c:23:3c:b9:01";
      linkConfig = {
        NamePolicy = "kernel database onboard slot path";
        WakeOnLan = "magic";
      };
    };
    networks = {
      "10-wan" = {
        linkConfig.RequiredForOnline = "routable";
        matchConfig.Name = [ "enp0s31f6" ];
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
        };
        dhcpV6Config.DUIDType = "link-layer";
      };
    };
  };

}
