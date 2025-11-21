{ config
, dataDir
, servicesConfig
, globalContainerConfig
, ...
}:
let
  uid = builtins.toString servicesConfig.kavita.uid;
in
{
  containers.kavita = {
    autoStart = true;
    privateNetwork = true;
    inherit (servicesConfig.kavita) hostAddress localAddress;

    # Bind mount the persistent data directory
    bindMounts = {
      "/var/lib/kavita" = {
        hostPath = "${dataDir}/home/kavita/appdata/kavita";
        isReadOnly = false;
      };
      "/etc/kavita-token" = {
        hostPath = config.age.secrets.kavita-token.path;
        isReadOnly = true;
      };
      "/books" = {
        hostPath = "${dataDir}/sftp/media/books";
        isReadOnly = true;
      };
    };

    config = _: (globalContainerConfig "kavita") // {
      services.kavita = {
        enable = true;
        dataDir = "/var/lib/kavita";
        tokenKeyFile = "/etc/kavita-token";
        settings.Port = servicesConfig.kavita.port;
        user = "kavita";
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ servicesConfig.kavita.port ];
      };
    };
  };

  # Ensure host directories for the bind mount exist
  systemd.tmpfiles.rules = [
    "d ${dataDir}/home/kavita/appdata/kavita 755 ${uid} ${uid} -"
  ];
}
