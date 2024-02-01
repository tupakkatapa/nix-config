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
    };
  };

  # Secrets
  sops.secrets = {
    "vaultwarden-env".sopsFile = ../../secrets.yaml;
    "lanraragi-admin-password" = {
      sopsFile = ../../secrets.yaml;
      mode = "444";
    };
  };

  # Main config
  containers.private = {
    inherit hostAddress localAddress;
    autoStart = true;
    privateNetwork = true;

    # Binds
    bindMounts =
      {
        "/run/secrets/vaultwarden-env" = {
          hostPath = "/run/secrets/vaultwarden-env";
          isReadOnly = true;
        };
        "/run/secrets/lanraragi-admin-password" = {
          hostPath = "/run/secrets/lanraragi-admin-password";
          isReadOnly = true;
        };
      }
      // helpers.bindMounts
      [
        # Appdata
        "${appData}/jackett"
        "${appData}/radarr"
        "${appData}/transmission"
        "${appData}/vaultwarden"
        "${appData}/lanraragi"
        # Media
        "/mnt/wd-red/sftp/dnld"
        "/mnt/wd-red/sftp/media/movies"
        "/mnt/wd-red/sftp/media/books/lanraragi"
        "/mnt/wd-red/sftp/media/img"
      ];
    forwardPorts = helpers.bindPorts {
      tcp = [
        7878
        9091
        9117
        8222
        3000
      ];
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
        openRPCPort = true;
        home = "${appData}/transmission";
        settings = {
          umask = 0;
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

      # Lanraragi (3000)
      services.lanraragi = {
        enable = true;
        passwordFile = "/run/secrets/lanraragi-admin-password";
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
      # https://github.com/dani-garcia/vaultwarden/blob/main/.env.template
      services.vaultwarden = {
        enable = true;
        dbBackend = "sqlite";
        backupDir = "${appData}/vaultwarden/backup";
        environmentFile = "/run/secrets/vaultwarden-env";
        config = {
          domain = "https://vault.${domain}";
          rocketPort = 8222;
          rocketAddress = "0.0.0.0";
          signupsAllowed = false;
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
