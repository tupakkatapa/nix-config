{
  pkgs,
  lib,
  config,
  ...
}: let
  domain = "coditon.com";
  serviceDataDir = "/var/lib";
in {
  # Bootloader for x86_64-linux / aarch64-linux
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use the latest kernel
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest);

  # Localization and basic stuff
  time.timeZone = "Europe/Helsinki";
  system.stateVersion = "23.11";
  console.keyMap = "fi";

  # Networking
  networking = {
    hostName = "vladof";
    useNetworkd = true;
    interfaces."enp2s0".ipv4.addresses = [
      {
        address = "192.168.1.100"; # static IP
        prefixLength = 24;
      }
    ];
  };
  systemd.network.enable = true;

  # Create directories, these are persistent
  systemd.tmpfiles.rules = [
    "d /mnt/sftp 755 sftp sftp -"
    "d ${serviceDataDir} 755 sftp sftp -"
  ];

  # Mounts
  fileSystems."/mnt/sftp" = {
    device = "/dev/disk/by-uuid/779bb7b3-9ce8-49df-9ade-4f50b379bed9";
    fsType = "ext4";
    options = ["noatime"];
  };

  # Strict SSH settings
  services.openssh = {
    enable = true;
    allowSFTP = true;
    extraConfig = ''
      AllowAgentForwarding no
      AllowStreamLocalForwarding no
      AllowTcpForwarding yes
      AuthenticationMethods publickey
      X11Forwarding no
      Match User sftp
        PermitTunnel no
        ChrootDirectory /mnt/sftp
        ForceCommand internal-sftp
        AllowTcpForwarding no
      Match all
    '';
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  # Message of the day
  programs.rust-motd = {
    enable = true;
    enableMotdInSSHD = true;
    settings = {
      banner = {
        color = "yellow";
        command = ''
          echo "  _____ __    _____ ____  _____ _____   "
          echo " |  |  |  |  |  _  |    \|     |   __|  "
          echo " |  |  |  |__|     |  |  |  |  |   __|  "
          echo "  \___/|_____|__|__|____/|_____|__|     "
          echo "                                        "
          systemctl --failed --quiet
        '';
      };
      uptime.prefix = "Uptime:";
      last_login = builtins.listToAttrs (map
        (user: {
          name = user;
          value = 2;
        })
        (builtins.attrNames config.home-manager.users));
    };
  };

  # Nginx
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    virtualHosts = {
      "transmission.${domain}".locations."/".proxyPass = "http://localhost:9091";
      "radarr.${domain}".locations."/".proxyPass = "http://localhost:7878";
      "sonarr${domain}".locations."/".proxyPass = "http://localhost:8989";
      "plex.${domain}".locations."/".proxyPass = "http://localhost:32400/web";
      "jackett.${domain}".locations."/".proxyPass = "http://localhost:9117";
      "vaultwarden.${domain}".locations."/".proxyPass = "http://localhost:8177";
    };
  };

  # Sftp user/group
  users.users."sftp" = {
    isSystemUser = true;
    group = "sftp";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEdpdbTOz0h9tVvkn13k1e8X7MnctH3zHRFmYWTbz9T kari@torque"
    ];
    shell = null;
    createHome = false;
    home = "/mnt/sftp";
  };
  users.groups."sftp" = {};

  # Plex
  services.plex = {
    enable = true;
    dataDir = "${serviceDataDir}/plex";
    openFirewall = true;
  };
  users.users.plex.extraGroups = ["sftp"];

  # Sonarr
  services.sonarr = {
    enable = true;
    dataDir = "${serviceDataDir}/sonarr";
    openFirewall = true;
  };
  users.users.sonarr.extraGroups = ["sftp"];

  # Radarr
  services.radarr = {
    enable = true;
    dataDir = "${serviceDataDir}/radarr";
    openFirewall = true;
  };

  # Jackett
  services.jackett = {
    enable = true;
    dataDir = "${serviceDataDir}/jackett";
    openFirewall = true;
  };
  users.users.jackett.extraGroups = ["sftp"];

  # Transmission
  services.transmission = {
    enable = true;
    settings = {
      download-dir = "${serviceDataDir}/transmission";
      encryption = 2;
      incomplete-dir-enabled = false;
      rpc-bind-address = "0.0.0.0";
      rpc-whitelist-enabled = false;
    };
    downloadDirPermissions = "775";
    openPeerPorts = true;
    openRPCPort = true;
    openFirewall = true;
  };
  users.users.transmission.extraGroups = ["sftp"];

  # Vaultwarden
  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";
    backupDir = "${serviceDataDir}/vaultwarden/backup";
    config = {
      DOMAIN = "https://vault.${domain}";
      SIGNUPS_ALLOWED = false;
      ROCKETPORT = 8177;
    };
    environmentFile = "${serviceDataDir}/vaultwarden/envfile";
  };
}
