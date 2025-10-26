{ config
, dataDir
, servicesConfig
, globalContainerConfig
, ...
}:
{
  containers.nextcloud = {
    autoStart = true;
    privateNetwork = true;
    inherit (servicesConfig.nextcloud) hostAddress localAddress;

    # Bind mount the persistent data directory
    bindMounts = {
      "/var/lib/nextcloud" = {
        hostPath = "${dataDir}/home/nextcloud/appdata/nextcloud";
        isReadOnly = false;
      };
      "/etc/nextcloud-admin-pass" = {
        hostPath = config.age.secrets.nextcloud-admin-pass.path;
        isReadOnly = true;
      };
    };

    config = { pkgs, ... }: (globalContainerConfig "nextcloud") // {
      services.nextcloud = {
        enable = true;
        package = pkgs.nextcloud31;
        hostName = servicesConfig.nextcloud.addr;

        extraApps = {
          inherit (pkgs.nextcloud31.packages.apps) notes contacts calendar tasks;
        };
        extraAppsEnable = true;

        config = {
          adminuser = "admin";
          adminpassFile = "/etc/nextcloud-admin-pass";
          dbtype = "sqlite";
        };

        settings = {
          # Reverse proxy configuration
          trusted_proxies = [ servicesConfig.nextcloud.hostAddress ];
          trusted_domains = [ servicesConfig.nextcloud.addr ];
          overwriteprotocol = "https";
          overwrite.cli.url = "https://${servicesConfig.nextcloud.addr}";

          # Android client fix
          "csrf.optout" = [ "/Nextcloud-android/" ];
        };

        phpOptions = {
          "opcache.interned_strings_buffer" = "32";
        };
      };

      # Configure nginx to listen on the specified port
      services.nginx.virtualHosts.${servicesConfig.nextcloud.addr} = {
        listen = [{
          addr = "0.0.0.0";
          inherit (servicesConfig.nextcloud) port;
        }];
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ servicesConfig.nextcloud.port ];
      };
    };
  };
}
