{ lib
, dataDir
, containerConfig
, globalContainerConfig
, ...
}:
let
  uid = builtins.toString containerConfig.transmission.uid;
in
{
  containers.transmission = {
    autoStart = true;
    privateNetwork = true;
    inherit (containerConfig.transmission) hostAddress localAddress;

    # Bind mount the persistent data directory
    bindMounts = {
      "/var/lib/transmission" = {
        hostPath = "${dataDir}/home/transmission/appdata/transmission";
        isReadOnly = false;
      };
      "/downloads" = {
        hostPath = "${dataDir}/sftp/dnld";
        isReadOnly = false;
      };
      "/media/movies" = {
        hostPath = "${dataDir}/sftp/media/movies";
        isReadOnly = true;
      };
      "/media/series" = {
        hostPath = "${dataDir}/sftp/media/series";
        isReadOnly = true;
      };
    };

    config = { pkgs, ... }: (globalContainerConfig "transmission") // {
      services.transmission = {
        enable = true;
        package = pkgs.transmission_4;
        openRPCPort = false;
        home = "/var/lib/transmission";
        user = "transmission";
        group = "transmission";
        settings = {
          download-dir = "/downloads";
          incomplete-dir = "/downloads/.incomplete";
          download-queue-enabled = false;
          rpc-authentication-required = false;
          rpc-bind-address = "0.0.0.0";
          rpc-port = containerConfig.transmission.port;
          rpc-host-whitelist-enabled = false;
          rpc-whitelist-enabled = false;
          # Force verification of existing torrents
          start-added-torrents = true;
          script-torrent-done-enabled = false;
        };
      };

      # Ensure transmission data directory has correct permissions
      systemd.tmpfiles.rules = [
        "Z /downloads            0775 transmission transmission - -"
        "Z /var/lib/transmission 0755 transmission transmission - -"
      ];

      # Workaround for
      # https://github.com/NixOS/nixpkgs/issues/258793
      systemd.services.transmission.serviceConfig = {
        RootDirectoryStartOnly = lib.mkForce null;
        RootDirectory = lib.mkForce null;
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ containerConfig.transmission.port ];
      };
    };
  };

  # Ensure host directories for the bind mount exist
  systemd.tmpfiles.rules = [
    "d ${dataDir}/sftp/dnld                              755 ${uid} ${uid} -"
    "d ${dataDir}/home/transmission/appdata/transmission 755 ${uid} ${uid} -"
  ];
}
