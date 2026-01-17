{ dataDir
, containerConfig
, globalContainerConfig
, config
, ...
}:
let
  uid = builtins.toString containerConfig.radicale.uid;
in
{
  containers.radicale = {
    autoStart = true;
    privateNetwork = true;
    inherit (containerConfig.radicale) hostAddress localAddress;

    # Bind mount the persistent data directory
    bindMounts = {
      "/var/lib/radicale" = {
        hostPath = "${dataDir}/home/radicale/appdata/radicale";
        isReadOnly = false;
      };
      "/etc/radicale-admin-pass" = {
        hostPath = config.age.secrets.radicale-admin-pass.path;
        isReadOnly = true;
      };
    };

    config = _: (globalContainerConfig "radicale") // {
      services.radicale = {
        enable = true;
        settings = {
          server.hosts = [ "0.0.0.0:${builtins.toString containerConfig.radicale.port}" ];
          storage.filesystem_folder = "/var/lib/radicale/collections";
          auth = {
            type = "htpasswd";
            htpasswd_filename = "/etc/radicale-admin-pass";
            htpasswd_encryption = "plain";
          };
        };
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ containerConfig.radicale.port ];
      };
    };
  };

  # Ensure host directories for the bind mount exist
  systemd.tmpfiles.rules = [
    "d ${dataDir}/home/radicale/appdata/radicale 755 ${uid} ${uid} -"
  ];
}
