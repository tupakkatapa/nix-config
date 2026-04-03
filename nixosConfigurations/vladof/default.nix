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

  # SFTP Server
  services.sftpServer = {
    enable = true;
    dataDir = "${dataDir}/sftp";
    authorizedKeys = [
      # kari@phone (preferably removed, keep until YubiKey NFC for SFTP is possible)
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPFKfmSYqFE+hXp/P1X8oqcpnUG9cx9ILzk4dqQzlEOC kari@phone"

      # kari@boox
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOliW+jvO3gMcZdwGvaSNlqcA3BWDWL+PM3omgXyWSHZ kari@boox"

      # kari@trezor
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIPSvwAIfx+2EYVbr9eC2imb5NJgpn36v6XAeofQjg5BEAAAABHNzaDo= kari@trezor"

      # kari@yubikey
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOdsfK46X5IhxxEy81am6A8YnHo2rcF2qZ75cHOKG7ToAAAACHNzaDprYXJp ssh:kari"
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOcS3prYIi5uC9LxscaKSYzyuF2Sh7f3I5V9s1sCWSc1AAAACXNzaDprYXJpMg== ssh:kari2"
    ];
    extraGroups = [ "transmission" ];
  };

}
