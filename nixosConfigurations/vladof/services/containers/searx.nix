{ config
, containerConfig
, globalContainerConfig
, ...
}:
{
  containers.searx = {
    autoStart = true;
    privateNetwork = true;
    inherit (containerConfig.searx) hostAddress localAddress;

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
            inherit (containerConfig.searx) port;
            bind_address = "0.0.0.0";
            secret_key = "@SEARX_SECRET_KEY@";
          };
          search = {
            safe_search = 2;
            default_lang = "en-US";
            formats = [
              "html"
              "json"
            ];
          };
        };
        environmentFile = "/etc/searx-env";
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ containerConfig.searx.port ];
      };
    };
  };
}
