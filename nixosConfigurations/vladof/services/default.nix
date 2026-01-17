{ pkgs
, lib
, config
, domain
, dataDir
, inputs
, ...
}:
let
  # Container configuration
  containerSubnet = "10.23.0";
  containerConfig = lib.mapAttrs
    (_name: service: service // {
      localAddress = "${containerSubnet}.${toString service.lastOctet}";
      hostAddress = "${containerSubnet}.1";
    })
    {
      ollama = {
        addr = "chat.${domain}";
        port = 11444;
        private = true;
        lastOctet = 18;
        uid = 10009;
      };
      radicale = {
        addr = "dav.${domain}";
        port = 5232;
        private = true;
        lastOctet = 17;
        uid = 10008;
      };
      transmission = {
        addr = "torrent.${domain}";
        port = 9091;
        private = true;
        lastOctet = 12;
        uid = 10003;
      };
      vaultwarden = {
        addr = "vault.${domain}";
        port = 8222;
        private = true;
        lastOctet = 11;
        uid = 10002;
      };
      plex = {
        addr = "plex.${domain}";
        port = 32400;
        private = false;
        lastOctet = 14;
        uid = 10005;
      };
      coditon-md = {
        addr = "blog.${domain}";
        port = 54783;
        private = false;
        lastOctet = 15;
        uid = 10006;
      };
      kavita = {
        addr = "lib.${domain}";
        port = 37600;
        private = true;
        lastOctet = 10;
        uid = 10001;
      };
      searx = {
        addr = "search.${domain}";
        port = 7777;
        private = true;
        lastOctet = 13;
        uid = 10004;
      };
    };

  # Service configuration
  serviceConfig = {
    home-assistant = {
      addr = "home.${domain}";
      port = 8123;
      private = true;
      uid = 10010;
    };
  };

  # Filter for public and private services
  publicServices = lib.filterAttrs (_: service: !service.private) containerConfig;
  privateServices = lib.filterAttrs (_: service: service.private) containerConfig;

  # Filter host services by public/private
  privateHostServices = lib.filterAttrs (_: service: service.private) serviceConfig;

  # CA + server cert hierarchy for private services
  caCertPem = ./certs/ca-cert.pem;
  serverCertPem = ./certs/server-cert.pem;
  serverCertKey = config.age.secrets.server-key.path;

  # Generate DER format of CA cert for Android
  caCertDer = pkgs.runCommand "ca-cert-der"
    {
      buildInputs = [ pkgs.openssl ];
    } ''
    openssl x509 -in ${caCertPem} -outform DER -out $out
  '';

  # Generate index page
  indexPage = import ./index.nix { inherit pkgs lib domain containerConfig serviceConfig; };
in
{
  imports = [
    (import ./containers { inherit pkgs lib config domain dataDir containerConfig containerSubnet inputs; })
    (import ./home-assistant { inherit lib dataDir; haConfig = serviceConfig.home-assistant; })
  ];

  # Reverse proxy
  services.caddy = {
    enable = true;
    virtualHosts =
      # Public services with ACME certs
      lib.mapAttrs'
        (_name: service: {
          name = service.addr;
          value = {
            useACMEHost = service.addr;
            extraConfig = ''
              reverse_proxy http://${service.localAddress}:${toString service.port}
            '';
          };
        })
        publicServices
      # Private services with self-signed certs
      // lib.mapAttrs'
        (_name: service: {
          name = service.addr;
          value = {
            extraConfig = ''
              tls ${serverCertPem} ${serverCertKey}
              reverse_proxy http://${service.localAddress}:${toString service.port}
            '';
          };
        })
        privateServices
      # Private host services with self-signed certs
      // lib.mapAttrs'
        (_name: service: {
          name = service.addr;
          value = {
            extraConfig = ''
              tls ${serverCertPem} ${serverCertKey}
              reverse_proxy http://127.0.0.1:${toString service.port}
            '';
          };
        })
        privateHostServices
      // {
        "index.${domain}" = {
          extraConfig = ''
            tls ${serverCertPem} ${serverCertKey}
            root * ${indexPage}
            file_server
          '';
        };
        # Serve the self-signed cert for easy download on any device
        "cert.${domain}" = {
          extraConfig = ''
            tls ${serverCertPem} ${serverCertKey}
            rewrite * /${domain}.cer
            root * ${pkgs.linkFarm "cert-download" [{ name = "${domain}.cer"; path = caCertDer; }]}
            header Content-Disposition "attachment; filename=${domain}.cer"
            file_server
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
      dnsResolver = "10.42.0.1:53";
      credentialFiles = {
        CF_DNS_API_TOKEN_FILE = config.age.secrets.acme-cf-dns-token.path;
      };
      dnsPropagationCheck = true;
      reloadServices = [ "caddy.service" ];
    };
    certs =
      # ACME certs from Let's Encrypt
      lib.mapAttrs'
        (_name: service: {
          name = service.addr;
          value = { };
        })
        publicServices;
  };

  # Ensure proper ACME certificate permissions
  systemd.tmpfiles.rules = [
    "Z /var/lib/acme 0755 acme acme - -"
  ];

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts =
      lib.mapAttrsToList (_name: service: service.port) publicServices
      ++ [
        80
        443
        8080 # magic port
        53654 # index
      ];
  };

  # Secrets
  age.secrets = {
    "acme-cf-dns-token" = {
      rekeyFile = ../secrets/acme-cf-dns-token.age;
      group = "acme";
      mode = "440";
    };
    "server-key" = {
      rekeyFile = ../secrets/server-key.age;
      owner = "caddy";
      mode = "400";
    };
  };
}
