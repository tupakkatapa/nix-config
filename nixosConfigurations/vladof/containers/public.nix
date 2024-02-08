{
  inputs,
  pkgs,
  lib,
  config,
  domain,
  appData,
  helpers,
  ...
}: let
  hostAddress = "192.168.200.1";
  localAddress = "192.168.200.2";
in {
  # Reverse proxy
  services.caddy = {
    enable = true;
    virtualHosts = {
      "plex.${domain}" = {
        useACMEHost = config.networking.fqdn;
        extraConfig = ''
          reverse_proxy http://${localAddress}:32400
        '';
      };
      "blog.${domain}" = {
        useACMEHost = config.networking.fqdn;
        extraConfig = ''
          reverse_proxy http://${localAddress}:1337
        '';
      };
      "next.${domain}" = {
        useACMEHost = config.networking.fqdn;
        extraConfig = ''
          reverse_proxy http://${localAddress}:8888
        '';
      };
    };
  };

  # Secrets
  sops.secrets = {
    "nextcloud-admin-password" = {
      sopsFile = ../../secrets.yaml;
      mode = "444";
    };
  };

  # Create directories
  systemd.tmpfiles.rules = [
    "d /mnt/wd-red/sftp/nextcloud 700 root root -"
    "d ${appData}/nextcloud       755 root root -"
    "d ${appData}/plex            700 root root -"
  ];

  # Main config
  containers.public = {
    inherit hostAddress localAddress;
    autoStart = true;
    privateNetwork = true;

    # Binds
    bindMounts =
      {
        "/run/secrets/nextcloud-admin-password" = {
          hostPath = "/run/secrets/nextcloud-admin-password";
          isReadOnly = true;
        };
      }
      // helpers.bindMounts [
        # Appdata
        "${appData}/plex"
        "${appData}/nextcloud"
        "/mnt/wd-red/sftp/nextcloud"
        # Media
        "/mnt/wd-red/sftp/media/movies"
        "/mnt/wd-red/sftp/media/music"
        "/mnt/wd-red/sftp/media/series"
      ];
    forwardPorts = helpers.bindPorts {
      tcp = [32400 3005 8324 32469 8888 1337];
      udp = [1900 5353 32410 32412 32413 32414];
    };
    config = {
      config,
      lib,
      pkgs,
      ...
    }: {
      imports = [inputs.coditon-blog.nixosModules.default];

      # Set permissions
      systemd.tmpfiles.rules = [
        "d /mnt/wd-red/sftp/nextcloud 777 nextcloud nextcloud -"
        "d ${appData}/nextcloud       777 nextcloud nextcloud -"
        "d ${appData}/plex            700 plex plex -"
      ];

      # Nextcloud (8888)
      services.nextcloud = {
        enable = true;
        package = pkgs.nextcloud28;
        hostName = "next.${domain}";
        datadir = "${appData}/nextcloud";
        https = true;
        config = {
          adminuser = "admin";
          adminpassFile = "/run/secrets/nextcloud-admin-password";
        };
      };
      services.nginx.virtualHosts."next.${domain}".listen = [
        {
          addr = "0.0.0.0";
          port = 8888;
        }
      ];

      # Blog (1337)
      services.coditon-blog = {
        enable = true;
        openFirewall = true;
        port = 1337;
      };

      # Plex (32400)
      services.plex = {
        enable = true;
        dataDir = "${appData}/plex";
        openFirewall = true;
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
