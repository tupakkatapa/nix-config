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
  sops = {
    secrets = {
      "nextcloud-admin-password" = {
        sopsFile = ../../secrets.yaml;
        mode = "444";
      };
    };
    age.sshKeyPaths = [
      "/mnt/wd-red/secrets/ssh/ssh_host_ed25519_key"
    ];
  };

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
        # Media
        "/mnt/wd-red/sftp/media/movies"
        "/mnt/wd-red/sftp/media/music"
        "/mnt/wd-red/sftp/media/series"
        "/mnt/wd-red/sftp/media/img"
      ];
    forwardPorts = helpers.bindPorts {
      tcp = [32400 3005 8324 32469 8888];
      udp = [1900 5353 32410 32412 32413 32414];
    };
    config = {
      config,
      lib,
      pkgs,
      ...
    }: {
      imports = [inputs.coditon-blog.nixosModules.default];

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
      # Ensure user/group, might be configured upstream
      users.users.plex = {
        createHome = true;
        group = "plex";
        home = "${appData}/plex";
        isSystemUser = true;
      };
      users.groups.plex = {};

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
