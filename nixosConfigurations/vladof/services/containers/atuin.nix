{ dataDir
, containerConfig
, globalContainerConfig
, ...
}:
{
  containers.atuin = {
    autoStart = true;
    privateNetwork = true;
    inherit (containerConfig.atuin) hostAddress localAddress;

    # Bind mount the persistent data directory
    bindMounts = {
      "/var/lib/postgresql" = {
        hostPath = "${dataDir}/home/atuin/appdata/postgresql";
        isReadOnly = false;
      };
    };

    config = { ... }: {
      imports = [ (globalContainerConfig "atuin") ];

      services.atuin = {
        enable = true;
        host = "0.0.0.0";
        inherit (containerConfig.atuin) port;
        database.createLocally = true;
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ containerConfig.atuin.port ];
      };
    };
  };

  # Postgres runs as its static uid 71 inside the container
  systemd.tmpfiles.rules = [
    "d ${dataDir}/home/atuin/appdata/postgresql 750 71 71 -"
  ];
}
