{
  inputs,
  pkgs,
  lib,
  config,
  domain,
  appData,
  ...
}: let
  servicesConfig = {
    plex = {
      addr = "plex.${domain}";
      port = 32400;
    };
    coditon-blog = {
      addr = "blog.${domain}";
      port = 54783;
    };
  };
in {
  # Reverse proxies
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

  # Blog
  services.coditon-blog = {
    enable = true;
    openFirewall = true;
    port = servicesConfig.coditon-blog.port;
  };

  # Plex (32400)
  services.plex = {
    enable = true;
    dataDir = "${appData}/plex";
    openFirewall = true;
  };
}
