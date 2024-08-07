{ pkgs
, lib
, config
, domain
, appData
, ...
}:
let
  servicesConfig = {
    transmission = {
      addr = "torrent.${domain}";
      port = 9091;
    };
    vaultwarden = {
      addr = "vault.${domain}";
      port = 8222;
    };
    lanraragi = {
      addr = "lanraragi.${domain}";
      port = 3000;
    };
    plex = {
      addr = "plex.${domain}";
      port = 32400;
    };
    coditon-md = {
      addr = "blog.${domain}";
      port = 54783;
    };
    service-index = {
      addr = "index.${domain}";
      port = 53654;
    };
  };

  # Define the derivation for blog contents
  blogContents = pkgs.runCommand "blog-contents" { } ''
    mkdir -p $out
    cp -r ${./blog-contents}/* $out
  '';

  # Generate things and stuff for services
  servicesTmpfileRules = lib.mapAttrsToList (name: _: "d ${appData}/${name} 700 ${name} ${name} -") servicesConfig;
  servicesPorts = lib.mapAttrsToList (_name: service: service.port) servicesConfig;
  servicesVirtualHosts =
    lib.mapAttrs'
      (name: service: {
        name = service.addr;
        value = {
          useACMEHost = service.addr;
          extraConfig = ''
            reverse_proxy http://127.0.0.1:${toString service.port}
          '';
        };
      })
      servicesConfig;

  # Generate index page
  indexPage = import ./index.nix { inherit pkgs lib domain servicesConfig; };
in
{
  # Reverse proxy
  services.caddy = {
    enable = true;
    virtualHosts =
      servicesVirtualHosts
      // {
        "${servicesConfig.service-index.addr}" = {
          extraConfig = ''
            root * ${indexPage}
            file_server
          '';
        };
      };
  };

  # TLS/SSL certificates
  security.acme = {
    acceptTerms = true;
    defaults.email = "jesse@ponkila.com";
    defaults.webroot = "${appData}/acme";
    certs =
      lib.mapAttrs'
        (name: service: {
          name = service.addr;
          value = { };
        })
        servicesConfig;
  };
  # Bind service directories to persistent disk
  fileSystems."/var/lib/acme" = {
    device = "${appData}/acme";
    options = [ "bind" ];
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts =
      servicesPorts
      ++ [
        80
        443
        5001 # IPFS
        4001
        8080
      ];
  };

  # Create directories, these are persistent
  systemd.tmpfiles.rules =
    servicesTmpfileRules
    ++ [
      "d ${appData}/acme  700 acme acme -"
    ];

  # Secrets
  sops.secrets = {
    "vaultwarden-env".sopsFile = ../../secrets.yaml;
    "lanraragi-admin-password" = {
      sopsFile = ../../secrets.yaml;
      mode = "444";
    };
  };

  # IPFS seed for Jhvst
  # https://github.com/ipfs/kubo/blob/master/docs/config.md
  services.kubo = {
    enable = true;
    localDiscovery = true;
    dataDir = "${appData}/ipfs";
    settings = {
      Addresses.API = "/ip4/127.0.0.1/tcp/5001";
      API.HTTPHeaders = {
        Access-Control-Allow-Origin = [ "http://127.0.0.1:5001" "https://webui.ipfs.io" ];
        Access-Control-Allow-Methods = [ "PUT" "POST" ];
      };
      Ipns = {
        RepublishPeriod = "1h";
        RecordLifetime = "48h";
        ResolveCacheSize = 128;
        MaxCacheTTL = "1m";
      };
      Peering = {
        Peers = [
          {
            ID = "12D3KooWLiaVwjwrgGbxbQ8Zk7qMNMUHhhU5KQyTh93pf1kYnXxU";
          }
          {
            ID = "12D3KooWPpN7WoKZyBsYBVfwUDBtFaU22PJ5PgSaQRBx6gvn4Fg7";
          }
        ];
      };
    };
  };
  # Set IPFS path and pin objects to local storage
  systemd.services.ipfs = {
    postStart = "ipfs pin add /ipns/nixos.fi";
    environment = {
      IPFS_PATH = "${config.services.kubo.dataDir}";
    };
  };

  # Torrent
  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    downloadDirPermissions = "0777";
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
  users.groups.lanraragi = { };
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
    options = [ "bind" ];
  };
  fileSystems."/var/lib/private/lanraragi/content" = {
    device = "/mnt/wd-red/sftp/media/books/lanraragi";
    options = [ "bind" ];
  };

  # Vaultwarden
  # https://github.com/dani-garcia/vaultwarden/blob/main/.env.template
  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";
    # backupDir = "${appData}/vaultwarden/backup";
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
    options = [ "bind" ];
  };

  # Blog
  services.coditon-md = {
    enable = true;
    inherit (servicesConfig.coditon-md) port;
    dataDir = "${blogContents}";
    name = "Jesse Karjalainen";
    image = "${blogContents}/profile.jpg";
    links = [
      {
        fab = "fa-github";
        url = "https://github.com/tupakkatapa";
      }
      {
        fab = "fa-x-twitter";
        url = "https://x.com/tupakkatapa";
      }
      {
        fab = "fa-linkedin-in";
        url = "https://www.linkedin.com/in/jesse-karjalainen-a7bb612b8/";
      }
    ];
  };

  # Plex (32400)
  services.plex = {
    enable = true;
    dataDir = "${appData}/plex";
  };
}
