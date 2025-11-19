{ dataDir
, servicesConfig
, globalContainerConfig
, ...
}:
{
  containers.radicale = {
    autoStart = true;
    privateNetwork = true;
    inherit (servicesConfig.radicale) hostAddress localAddress;

    # Bind mount the persistent data directory
    bindMounts = {
      "/var/lib/radicale" = {
        hostPath = "${dataDir}/home/radicale/appdata/radicale";
        isReadOnly = false;
      };
    };

    config = _: (globalContainerConfig "radicale") // {
      services.radicale = {
        enable = true;
        settings = {
          server.hosts = [ "0.0.0.0:${builtins.toString servicesConfig.radicale.port}" ];
          storage.filesystem_folder = "/var/lib/radicale/collections";
          auth.type = "none";
        };
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ servicesConfig.radicale.port ];
      };
    };
  };
}

