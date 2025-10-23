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
          # Example: https://github.com/dani-garcia/vaultwarden/blob/main/.env.template
          # Defaults: https://github.com/dani-garcia/vaultwarden/blob/main/src/config.rs
          domain = "https://${servicesConfig.vaultwarden.addr}";
          rocketPort = servicesConfig.vaultwarden.port;
          rocketAddress = "0.0.0.0";
          signupsAllowed = false;
          showPasswordHint = false;
          experimentalClientFeatureFlags = "fido2-vault-credentials,ssh-key-vault-item,ssh-agent";
        };
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ servicesConfig.vaultwarden.port ];
      };
    };
  };
}
