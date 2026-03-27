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

    # GPU access for NVENC hardware transcoding
    allowedDevices = [
      { modifier = "rw"; node = "/dev/nvidia0"; }
      { modifier = "rw"; node = "/dev/nvidiactl"; }
      { modifier = "rw"; node = "/dev/nvidia-uvm"; }
    ];

    # Bind mount the persistent data directory and GPU devices
    bindMounts = {
      "/dev/nvidia0".hostPath = "/dev/nvidia0";
      "/dev/nvidiactl".hostPath = "/dev/nvidiactl";
      "/dev/nvidia-uvm".hostPath = "/dev/nvidia-uvm";
      "/run/opengl-driver" = {
        hostPath = "/run/opengl-driver";
        isReadOnly = true;
      };
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

      # NVIDIA for hardware transcoding
      hardware.graphics.enable = true;

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
