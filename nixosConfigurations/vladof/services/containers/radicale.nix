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

    config = { ... }: {
      imports = [ (globalContainerConfig "radicale") ];

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
        # The first section that matches decides, and the sections sort by name: the
        # assistant writes in the owner's two collections and reads the rest, the
        # others own their own. `w` also deletes a whole collection, which the
        # hourly snapshots of the data cover
        rights = {
          assistant-1-items = { user = "assistant"; collection = "admin/(contacts|calendar)"; permissions = "rw"; };
          assistant-2-rest = { user = "assistant"; collection = ".*"; permissions = "Rr"; };
          collections = { user = ".+"; collection = "{user}/[^/]+"; permissions = "rw"; };
          principal = { user = ".+"; collection = "{user}"; permissions = "RW"; };
          root = { user = ".+"; collection = ""; permissions = "R"; };
        };
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ containerConfig.radicale.port ];
      };
    };
  };

  # Ensure host directories for the bind mount exist with correct ownership
  systemd.tmpfiles.rules = [
    "d ${dataDir}/home/radicale/appdata/radicale 755 ${uid} ${uid} -"
    "Z ${dataDir}/home/radicale/appdata/radicale - ${uid} ${uid} -"
  ];
}
