{
  pkgs,
  lib,
  config,
  domain,
  appData,
  helpers,
  ...
}: let
  hostAddress = "192.168.100.1";
  localAddress = "192.168.100.2";
in {
  # Create directories, these are persistent
  systemd.tmpfiles.rules = [
    "d ${appData}/transmission   700  70  70 -"
    "d ${appData}/radarr         700 275 275 -"
    "d ${appData}/jackett        700 276 276 -"
    "d ${appData}/vaultwarden    700 993 993 -"
  ];

  # Reverse proxy
  services.caddy = {
    enable = true;
    virtualHosts = {
      "torrent.${domain}" = {
        useACMEHost = config.networking.fqdn;
        extraConfig = ''
          reverse_proxy http://${localAddress}:9091
        '';
      };
      "radarr.${domain}" = {
        useACMEHost = config.networking.fqdn;
        extraConfig = ''
          reverse_proxy http://${localAddress}:7878
        '';
      };
      "jackett.${domain}" = {
        useACMEHost = config.networking.fqdn;
        extraConfig = ''
          reverse_proxy http://${localAddress}:9117
        '';
      };
      "vault.${domain}" = {
        useACMEHost = config.networking.fqdn;
        extraConfig = ''
          reverse_proxy http://${localAddress}:8222
        '';
      };
    };
  };

  # Main config
  containers.private = {
    inherit hostAddress localAddress;
    autoStart = true;
    privateNetwork = true;

    # Binds
    bindMounts =
      helpers.bindMounts
      [
        # Appdata
        "${appData}/jackett"
        "${appData}/radarr"
        "${appData}/transmission"
        "${appData}/vaultwarden"
        # Media
        "/mnt/wd-red/sftp/dnld"
        "/mnt/wd-red/sftp/media/movies"
        # Other
        "/mnt/wd-red/secrets"
      ];
    forwardPorts = helpers.bindPorts {
      tcp = [7878 9091 9117 8222];
      udp = [51820];
    };

    config = {
      config,
      lib,
      pkgs,
      ...
    }: {
      # Radarr (7878)
      services.radarr = {
        enable = true;
        dataDir = "${appData}/radarr";
        openFirewall = true;
      };
      users.users.radarr.extraGroups = ["transmission"];

      # Jackett (9117)
      services.jackett = {
        enable = true;
        dataDir = "${appData}/jackett";
        openFirewall = true;
      };
      users.users.jackett.extraGroups = ["transmission"];

      # Torrent (9091)
      services.transmission = {
        enable = true;
        openFirewall = true;
        downloadDirPermissions = "0777";
        umask = 0;
        openRPCPort = true;
        home = "${appData}/transmission";
        settings = {
          download-dir = "/mnt/wd-red/sftp/dnld";
          incomplete-dir = "/mnt/wd-red/sftp/dnld/.incomplete";
          download-queue-enabled = false;
          rpc-authentication-required = false;
          rpc-bind-address = localAddress;
          rpc-port = 9091;
          rpc-host-whitelist-enabled = false;
          rpc-whitelist-enabled = false;
        };
      };
      # Workaround for https://github.com/NixOS/nixpkgs/issues/258793
      systemd.services.transmission = {
        serviceConfig = {
          RootDirectoryStartOnly = lib.mkForce false;
          RootDirectory = lib.mkForce "";
        };
      };

      # Vaultwarden
      # Vaultwarden (8222)
      services.vaultwarden = {
        enable = true;
        dbBackend = "sqlite";
        backupDir = "${appData}/vaultwarden/backup";
        config = {
          domain = "https://vault.${domain}";
          rocketAddress = localAddress;
          rocketPort = 8222;
        };
      };
      # Bind service directories to persistent disk
      fileSystems."/var/lib/bitwarden_rs" = {
        device = "${appData}/vaultwarden";
        options = ["bind"];
      };

      # Other
      networking = {
        firewall.enable = false;
        # Use systemd-resolved inside the container
        # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
        useHostResolvConf = lib.mkForce false;
      };
      services.resolved.enable = true;
      nixpkgs.config.allowUnfree = true;
      system.stateVersion = "23.11";
    };
  };
}
