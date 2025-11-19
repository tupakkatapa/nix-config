{ config
, servicesConfig
, globalContainerConfig
, ...
}:
{
  containers.searx = {
    autoStart = true;
    privateNetwork = true;
    inherit (servicesConfig.searx) hostAddress localAddress;

    # Bind mount the environment file
    bindMounts = {
      "/etc/searx-env" = {
        hostPath = config.age.secrets.searx-env.path;
        isReadOnly = true;
      };
    };

    config = { pkgs, ... }: (globalContainerConfig "searx") // {
      services.searx = {
        enable = true;
        package = pkgs.searxng;
        settings = {
          server = {
            inherit (servicesConfig.searx) port;
            bind_address = "0.0.0.0";
            secret_key = "@SEARX_SECRET_KEY@";
          };
          search.formats = [
            "html"
            "json"
          ];
        };
        environmentFile = "/etc/searx-env";
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ servicesConfig.searx.port ];
      };
    };
  };
}
