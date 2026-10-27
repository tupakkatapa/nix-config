{ dataDir
, containerConfig
, globalContainerConfig
, ...
}:
let
  uid = builtins.toString containerConfig.plex.uid;
in
{
  containers.plex = {
    autoStart = true;
    privateNetwork = true;
    inherit (containerConfig.plex) hostAddress localAddress;

    # GPU access for hardware transcoding
    allowedDevices = [
      { modifier = "rw"; node = "/dev/dri/renderD128"; }
    ];

    # Bind mount the persistent data directory and the render node
    bindMounts = {
      "/dev/dri/renderD128".hostPath = "/dev/dri/renderD128";
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

    config = { config, pkgs, ... }: {
      imports = [ (globalContainerConfig "plex") ];

      services.plex = {
        enable = true;
        # buildFHSEnv bundles every glibc locale; only the container's are needed
        package = pkgs.plex.override {
          buildFHSEnv = pkgs.buildFHSEnv.override {
            callPackage = fn: args: pkgs.callPackage fn (args // {
              pkgs = pkgs // {
                glibcLocales = pkgs.glibcLocales.override {
                  allLocales = false;
                  locales = config.i18n.supportedLocales;
                };
              };
            });
          };
        };
        dataDir = "/var/lib/plex";
        user = "plex";
        group = "plex";
      };

      # Mesa's VA-API driver for the Radeon
      hardware.graphics.enable = true;

      # Render node is root:render 0660 on the host; gid is static across NixOS
      users.users.plex.extraGroups = [ "render" "video" ];

      # Ensure plex data directory exists with correct permissions
      systemd.tmpfiles.rules = [
        "Z /var/lib/plex 0755 plex plex - -"
      ];

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ containerConfig.plex.port ];
      };
    };
  };

  # Ensure host directories for the bind mount exist with correct ownership
  systemd.tmpfiles.rules = [
    "d ${dataDir}/home/plex/appdata/plex 755 ${uid} ${uid} -"
    "Z ${dataDir}/home/plex/appdata/plex - ${uid} ${uid} -"
  ];
}
