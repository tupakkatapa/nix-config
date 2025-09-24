{ config
, dataDir
, servicesConfig
, globalContainerConfig
, ...
}:
{
  containers.vaultwarden = {
    autoStart = true;
    privateNetwork = true;
    inherit (servicesConfig.vaultwarden) hostAddress localAddress;

    # Bind mount the persistent data directory
    bindMounts = {
      "/var/lib/vaultwarden" = {
        hostPath = "${dataDir}/home/vaultwarden/appdata/vaultwarden";
        isReadOnly = false;
      };
      "/etc/vaultwarden-env" = {
        hostPath = config.age.secrets.vaultwarden-env.path;
        isReadOnly = true;
      };
    };

    config = _: (globalContainerConfig "vaultwarden") // {
      services.vaultwarden = {
        enable = true;
        dbBackend = "sqlite";
        environmentFile = "/etc/vaultwarden-env";
        config = {
          domain = "https://${servicesConfig.vaultwarden.addr}";
          rocketPort = servicesConfig.vaultwarden.port;
          rocketAddress = "0.0.0.0";
          signupsAllowed = false;
        };
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ servicesConfig.vaultwarden.port ];
      };
    };
  };
}
