{ lib
, dataDir
, servicesConfig
, globalContainerConfig
, ...
}:
let
  uid = builtins.toString servicesConfig.transmission.uid;
in
{
  containers.transmission = {
    autoStart = true;
    privateNetwork = true;
    inherit (servicesConfig.transmission) hostAddress localAddress;

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
          rpc-port = servicesConfig.transmission.port;
          rpc-host-whitelist-enabled = false;
          rpc-whitelist-enabled = false;
          # Force verification of existing torrents
          start-added-torrents = true;
          script-torrent-done-enabled = false;
        };
      };

      # Ensure transmission data directory has correct permissions
      systemd.tmpfiles.rules = [
        "Z /var/lib/transmission 0750 transmission transmission - -"
      ];

      # Workaround for
      # https://github.com/NixOS/nixpkgs/issues/258793
      systemd.services.transmission.serviceConfig = {
        RootDirectoryStartOnly = lib.mkForce null;
        RootDirectory = lib.mkForce null;
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ servicesConfig.transmission.port ];
      };
    };
  };

  # Ensure host directories for the bind mount exist
  systemd.tmpfiles.rules = [
    "d ${dataDir}/home/transmission/appdata/transmission 755 ${uid} ${uid} -"
  ];
}
