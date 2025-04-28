{ pkgs
, lib
, config
, domain
, dataDir
, ...
}:
let
  # Private services access whitelist
  authorizedIPs = [
    "192.168.1.7"
    "192.168.1.8"
    "172.16.16.2"
    "172.16.16.3"
  ];

  # Quick service config
  servicesConfig = {
    transmission = {
      addr = "torrent.${domain}";
      port = 9091;
      private = true;
    };
    vaultwarden = {
      addr = "vault.${domain}";
      port = 8222;
      private = true;
    };
    plex = {
      addr = "plex.${domain}";
      port = 32400;
      private = false;
    };
    coditon-md = {
      addr = "blog.${domain}";
      port = 54783;
      private = false;
    };
    service-index = {
      addr = "index.${domain}";
      port = 53654;
      private = true;
    };
    kavita = {
      addr = "lib.${domain}";
      port = 37600;
      private = true;
    };
    # minecraft = {
    #   addr = "craft.${domain}";
    #   port = 25565;
    #   private = false;
    # };
    immich = {
      addr = "img.${domain}";
      port = 2283;
      private = true;
    };
  };

  # Define the derivation for blog contents
  blogContents = pkgs.runCommand "blog-contents" { } ''
    mkdir -p $out
    cp -r ${./blog-contents}/* $out
  '';

  # Filter for public and private services
  publicServices = lib.filterAttrs (_: service: !service.private) servicesConfig;
  privateServices = lib.filterAttrs (_: service: service.private) servicesConfig;

  # Generate self-signed cert for private services
  selfSignedCert = pkgs.runCommand "self-signed-cert"
    {
      buildInputs = [ pkgs.openssl ];
    } ''
    mkdir -p $out
    openssl req -x509 -newkey rsa:4096 -keyout $out/key.pem -out $out/cert.pem -days 3650 -nodes \
      -subj "/CN=*.${domain}" \
      -addext "subjectAltName = DNS:*.${domain}"
  '';

  # Generate index page
  indexPage = import ./index.nix { inherit pkgs lib domain servicesConfig; };
in
{
  # Reverse proxy
  services.caddy = {
    enable = true;
    virtualHosts =
      # Public services with ACME certs
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
        (lib.filterAttrs (name: _: name != "service-index") publicServices)
      # Private services with self-signed certs
      // lib.mapAttrs'
        (name: service: {
          name = service.addr;
          value = {
            extraConfig = ''
              tls ${selfSignedCert}/cert.pem ${selfSignedCert}/key.pem

              @authorized {
                remote_ip ${lib.concatStringsSep " " authorizedIPs}
              }
              handle @authorized {
                reverse_proxy http://127.0.0.1:${toString service.port}
              }
              handle {
                respond "Unauthorized" 403
              }
            '';
          };
        })
        (lib.filterAttrs (name: _: name != "service-index") privateServices)
      // {
        "${servicesConfig.service-index.addr}" = {
          extraConfig = ''
            tls ${selfSignedCert}/cert.pem ${selfSignedCert}/key.pem

            @authorized {
              remote_ip ${lib.concatStringsSep " " authorizedIPs}
            }
            handle @authorized {
              root * ${indexPage}
              file_server
            }
            handle {
              respond "Unauthorized" 403
            }
          '';
        };
      };
  };
  users.users.caddy.extraGroups = [ "acme" ];

  # TLS/SSL certificates
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "jesse@ponkila.com";
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      credentialFiles = {
        CF_DNS_API_TOKEN_FILE = config.age.secrets.acme-cf-dns-token.path;
      };
      dnsPropagationCheck = true;
      reloadServices = [ "caddy.service" ];
    };
    certs =
      lib.mapAttrs'
        (name: service: {
          name = service.addr;
          value = { };
        })
        publicServices;
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts =
      lib.mapAttrsToList (_name: service: service.port) publicServices
      ++ [
        80
        443
        8080 # magic port
      ];
  };

  # Secrets
  age.secrets = {
    "vaultwarden-env".rekeyFile = ../secrets/vaultwarden-env.age;
    "acme-cf-dns-token" = {
      rekeyFile = ../secrets/acme-cf-dns-token.age;
      group = "acme";
      mode = "440";
    };
    "kavita-token".rekeyFile = ../secrets/kavita-token.age;
  };

  # Torrent
  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    downloadDirPermissions = "0777";
    openRPCPort = false;
    home = "/var/lib/transmission";
    settings = {
      umask = 0;
      download-dir = "${dataDir}/sftp/dnld";
      incomplete-dir = "${dataDir}/sftp/dnld/.incomplete";
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
    # Hotfix, nixRemount runs too late
    after = [ "nix-remount.service" ];
    requires = [ "nix-remount.service" ];
  };

  # Vaultwarden
  # https://github.com/dani-garcia/vaultwarden/blob/main/.env.template
  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";
    environmentFile = config.age.secrets.vaultwarden-env.path;
    config = {
      domain = "https://${servicesConfig.vaultwarden.addr}";
      rocketPort = servicesConfig.vaultwarden.port;
      rocketAddress = "127.0.0.1";
      signupsAllowed = false;
    };
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
    dataDir = "/var/lib/plex";
  };

  # Kavita
  services.kavita = {
    enable = true;
    dataDir = "/var/lib/kavita";
    tokenKeyFile = config.age.secrets.kavita-token.path;
    settings.Port = servicesConfig.kavita.port;
  };

  # Vanilla Minecraft server
  # services.minecraft-server = {
  #   enable = true;
  #   eula = true;
  #   openFirewall = true;
  #   dataDir = "/var/lib/minecraft";
  #   declarative = true;
  #   whitelist = {
  #     # https://mcuuid.net/
  #     Tupakkatapa = "94d38539-5c6d-41ab-8660-4b00363ad9ea";
  #   };
  #   # https://minecraft.fandom.com/wiki/Server.properties
  #   serverProperties = {
  #     difficulty = 2;
  #     gamemode = 0;
  #     max-players = 5;
  #     pvp = false;
  #     server-port = servicesConfig.minecraft.port;
  #     simulation-distance = 32;
  #     view-distance = 32;
  #     white-list = true;
  #   };
  # };

  # Immich
  services.immich = {
    enable = true;
    host = "0.0.0.0";
    inherit (servicesConfig.immich) port;
    openFirewall = true;
  };
}
