{ lib
, dataDir
, containerConfig
, globalContainerConfig
, ...
}:
let
  uid = builtins.toString containerConfig.ntfy.uid;
in
{
  containers.ntfy = {
    autoStart = true;
    privateNetwork = true;
    inherit (containerConfig.ntfy) hostAddress localAddress;

    # Bind mount the persistent data directory
    bindMounts = {
      "/var/lib/ntfy-sh" = {
        hostPath = "${dataDir}/home/ntfy/appdata/ntfy-sh";
        isReadOnly = false;
      };
    };

    config = _: (globalContainerConfig "ntfy") // {
      services.ntfy-sh = {
        enable = true;
        settings = {
          base-url = "https://${containerConfig.ntfy.addr}";
          listen-http = "0.0.0.0:${builtins.toString containerConfig.ntfy.port}";
          behind-proxy = true;
        };
      };

      # Disable DynamicUser to work with bind-mounted state directory
      systemd.services.ntfy-sh.serviceConfig.DynamicUser = lib.mkForce false;

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ containerConfig.ntfy.port ];
      };
    };
  };

  # Ensure host directories for the bind mount exist with correct ownership
  systemd.tmpfiles.rules = [
    "d ${dataDir}/home/ntfy/appdata/ntfy-sh 755 ${uid} ${uid} -"
    "Z ${dataDir}/home/ntfy/appdata/ntfy-sh - ${uid} ${uid} -"
  ];
}
