{
  pkgs,
  lib,
  config,
  domain,
  appData,
  ...
}: let
  servicesConfig = {
    transmission = {
      addr = "torrent.${domain}";
      port = 9091;
    };
    radarr = {
      addr = "radarr.${domain}";
      port = 7878;
    };
    jackett = {
      addr = "jackett.${domain}";
      port = 9117;
    };
    vaultwarden = {
      addr = "vault.${domain}";
      port = 8222;
    };
    lanraragi = {
      addr = "lanraragi.${domain}";
      port = 3000;
    };
  };
in {
  # Reverse proxy
  services.caddy = {
    enable = true;
    virtualHosts =
      lib.mapAttrs' (name: service: {
        name = service.addr;
        value = {
          useACMEHost = service.addr;
          extraConfig = ''
            reverse_proxy http://127.0.0.1:${toString service.port}
          '';
        };
      })
      servicesConfig;
  };

  # TLS/SSL certificates
  security.acme = {
    certs =
      lib.mapAttrs' (name: service: {
        name = service.addr;
        value = {};
      })
      servicesConfig;
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = lib.mapAttrsToList (name: service: service.port) servicesConfig;
  };

  # Create directories, these are persistent
  systemd.tmpfiles.rules =
    lib.mapAttrsToList (
      name: _: "d ${appData}/${name} 700 ${name} ${name} -"
    )
    servicesConfig;

  # Secrets
  sops.secrets = {
    "vaultwarden-env".sopsFile = ../../secrets.yaml;
    "lanraragi-admin-password" = {
      sopsFile = ../../secrets.yaml;
      mode = "444";
    };
  };

  # Radarr
  services.radarr = {
    enable = true;
    dataDir = "${appData}/radarr";
    openFirewall = true;
  };
  users.users.radarr.extraGroups = ["transmission"];

  # Jackett
  services.jackett = {
    enable = true;
    dataDir = "${appData}/jackett";
    openFirewall = true;
  };
  users.users.jackett.extraGroups = ["transmission"];

  # Torrent
  services.transmission = {
    enable = true;
    openFirewall = true;
    downloadDirPermissions = "0770";
    openRPCPort = true;
    home = "${appData}/transmission";
    settings = {
      umask = 0;
      download-dir = "/mnt/wd-red/sftp/dnld";
      incomplete-dir = "/mnt/wd-red/sftp/dnld/.incomplete";
      download-queue-enabled = false;
      rpc-authentication-required = false;
      rpc-bind-address = "127.0.0.1";
      rpc-port = servicesConfig.transmission.port;
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

  # Lanraragi (3000)
  services.lanraragi = {
    enable = true;
    passwordFile = config.sops.secrets.lanraragi-admin-password.path;
  };
  # Create user/group
  users.users.lanraragi = {
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

  # Vaultwarden
  # https://github.com/dani-garcia/vaultwarden/blob/main/.env.template
  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";
    backupDir = "${appData}/vaultwarden/backup";
    environmentFile = config.sops.secrets.vaultwarden-env.path;
    config = {
      domain = "https://${servicesConfig.vaultwarden.addr}";
      rocketPort = servicesConfig.vaultwarden.port;
      rocketAddress = "0.0.0.0";
      signupsAllowed = false;
    };
  };
  # Bind service directories to persistent disk
  fileSystems."/var/lib/bitwarden_rs" = {
    device = "${appData}/vaultwarden";
    options = ["bind"];
  };
}
