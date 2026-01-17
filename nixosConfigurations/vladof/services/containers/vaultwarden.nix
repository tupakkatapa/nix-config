{ config
, dataDir
, containerConfig
, globalContainerConfig
, ...
}:
let
  uid = builtins.toString containerConfig.vaultwarden.uid;
in
{
  containers.vaultwarden = {
    autoStart = true;
    privateNetwork = true;
    inherit (containerConfig.vaultwarden) hostAddress localAddress;

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
          domain = "https://${containerConfig.vaultwarden.addr}";
          rocketPort = containerConfig.vaultwarden.port;
          rocketAddress = "0.0.0.0";
          signupsAllowed = false;
          showPasswordHint = false;
          experimentalClientFeatureFlags = "fido2-vault-credentials,ssh-key-vault-item,ssh-agent";
        };
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ containerConfig.vaultwarden.port ];
      };
    };
  };

  # Ensure host directories for the bind mount exist with correct ownership
  systemd.tmpfiles.rules = [
    "d ${dataDir}/home/vaultwarden/appdata/vaultwarden 755 ${uid} ${uid} -"
    "Z ${dataDir}/home/vaultwarden/appdata/vaultwarden - ${uid} ${uid} -"
  ];
}
