{ lib
, pkgs
, domain
, servicesConfig
, globalContainerConfig
, selfSignedCert
, ...
}:
let
  # Generate index page
  indexPage = import ./index.nix { inherit pkgs lib domain servicesConfig; };
in
{
  containers.service-index = {
    autoStart = true;
    privateNetwork = true;
    inherit (servicesConfig.service-index) hostAddress localAddress;

    # Bind mount the index page and certificates
    bindMounts = {
      "/var/www/index" = {
        hostPath = "${indexPage}";
        isReadOnly = true;
      };
      "/etc/ssl/certs" = {
        hostPath = "${selfSignedCert}";
        isReadOnly = true;
      };
    };

    config = _: (globalContainerConfig "service-index") // {
      services.caddy = {
        enable = true;
        virtualHosts.":${toString servicesConfig.service-index.port}" = {
          extraConfig = ''
            bind 0.0.0.0
            tls /etc/ssl/certs/cert.pem /etc/ssl/certs/key.pem
            root * /var/www/index
            file_server
          '';
        };
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ servicesConfig.service-index.port ];
      };
    };
  };
}
