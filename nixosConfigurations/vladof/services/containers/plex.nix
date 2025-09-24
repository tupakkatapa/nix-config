{ dataDir
, servicesConfig
, globalContainerConfig
, ...
}:
{
  containers.plex = {
    autoStart = true;
    privateNetwork = true;
    inherit (servicesConfig.plex) hostAddress localAddress;

    # Bind mount the persistent data directory
    bindMounts = {
      "/var/lib/plex" = {
        hostPath = "${dataDir}/home/plex/appdata/plex";
        isReadOnly = false;
      };
      "/media/movies" = {
        hostPath = "${dataDir}/sftp/media/movies";
        isReadOnly = true;
      };
      "/media/music" = {
        hostPath = "${dataDir}/sftp/media/music";
        isReadOnly = true;
      };
      "/media/series" = {
        hostPath = "${dataDir}/sftp/media/series";
        isReadOnly = true;
      };
      "/media/gallery" = {
        hostPath = "${dataDir}/sftp/media/img";
        isReadOnly = true;
      };
      "/media/misc" = {
        hostPath = "${dataDir}/sftp/media/misc/plex";
        isReadOnly = true;
      };
    };

    config = _: (globalContainerConfig "plex") // {
      services.plex = {
        enable = true;
        dataDir = "/var/lib/plex";
        user = "plex";
        group = "plex";
      };

      # Ensure plex data directory exists with correct permissions
      systemd.tmpfiles.rules = [
        "Z /var/lib/plex 0755 plex plex - -"
      ];

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ servicesConfig.plex.port ];
      };
    };
  };
}
