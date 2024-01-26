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
      "lanraragi.${domain}" = {
        useACMEHost = config.networking.fqdn;
        extraConfig = ''
          reverse_proxy http://${localAddress}:3000
        '';
      };
      "prism.${domain}" = {
        useACMEHost = config.networking.fqdn;
        extraConfig = ''
          reverse_proxy http://${localAddress}:2342
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
        "${appData}/photoprism"
        "${appData}/lanraragi"
        # Media
        "/mnt/wd-red/sftp/dnld"
        "/mnt/wd-red/sftp/media/movies"
        "/mnt/wd-red/sftp/media/books/lanraragi"
        "/mnt/wd-red/sftp/media/img"
        # Other
        "/mnt/wd-red/secrets"
      ];
    forwardPorts = helpers.bindPorts {
      tcp = [7878 9091 9117 8222 3000 2342];
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
      # Ensure user/group, might be configured upstream
      users.users.radarr = {
        createHome = true;
        extraGroups = ["transmission"];
        group = "radarr";
        home = "${appData}/radarr";
        isSystemUser = true;
      };
      users.groups.radarr = {};

      # Jackett (9117)
      services.jackett = {
        enable = true;
        dataDir = "${appData}/jackett";
        openFirewall = true;
      };
      # Ensure user/group, might be configured upstream
      users.users.jackett = {
        createHome = true;
        extraGroups = ["transmission"];
        group = "jackett";
        home = "${appData}/jackett";
        isSystemUser = true;
      };
      users.groups.jackett = {};

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
      # Ensure user, might be configured upstream
      users.users.transmission = {
        createHome = true;
        group = "transmission";
        home = "${appData}/transmission";
        isSystemUser = true;
      };
      users.groups.transmission = {};
      # Workaround for https://github.com/NixOS/nixpkgs/issues/258793
      systemd.services.transmission = {
        serviceConfig = {
          RootDirectoryStartOnly = lib.mkForce false;
          RootDirectory = lib.mkForce "";
        };
      };

      # Photoprism (2342)
      services.photoprism = {
        enable = true;
        address = localAddress;
        originalsPath = "/mnt/wd-red/sftp/media/img";
        passwordFile = pkgs.writeText "pass" "admin";
        settings = {
          PHOTOPRISM_SPONSOR = "true";
          PHOTOPRISM_AUTH_MODE = "public";
          PHOTOPRISM_READONLY = "true";
        };
      };
      # Ensure user/group, might be configured upstream
      users.users.photoprism = {
        createHome = true;
        group = "photoprism";
        home = "${appData}/photoprism";
        isSystemUser = true;
      };
      users.groups.photoprism = {};
      # Bind service directories to persistent disk
      fileSystems."/var/lib/private/photoprism" = {
        device = "${appData}/photoprism";
        options = ["bind"];
      };

      # Lanraragi (3000)
      services.lanraragi = {
        enable = true;
        passwordFile = pkgs.writeText "pass" "admin";
      };
      # Ensure user/group, might be configured upstream
      users.users.lanraragi = {
        createHome = true;
        group = "lanraragi";
        home = "${appData}/lanraragi";
        isSystemUser = true;
      };
      users.groups.lanraragi = {};
      # Append to systemd service
      systemd.services.lanraragi = {
        serviceConfig = {
          User = "lanraragi";
          Group = "lanraragi";
        };
      };
      # Bind service directories to persistent disk
      fileSystems."/var/lib/private/lanraragi" = {
        device = "${appData}/lanraragi";
        options = ["bind"];
      };
      fileSystems."/var/lib/private/lanraragi/content" = {
        device = "/mnt/wd-red/sftp/media/books/lanraragi";
        options = ["bind"];
      };

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
