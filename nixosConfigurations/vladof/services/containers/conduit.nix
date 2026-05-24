{ lib
, dataDir
, domain
, containerConfig
, globalContainerConfig
, ...
}:
let
  uid = builtins.toString containerConfig.conduit.uid;
in
{
  containers.conduit = {
    autoStart = true;
    privateNetwork = true;
    inherit (containerConfig.conduit) hostAddress localAddress;

    bindMounts = {
      "/var/lib/matrix-conduit" = {
        hostPath = "${dataDir}/home/conduit/appdata/conduit";
        isReadOnly = false;
      };
    };

    config = _: (globalContainerConfig "conduit") // {
      services.matrix-conduit = {
        enable = true;
        settings.global = {
          server_name = domain;
          address = "0.0.0.0";
          inherit (containerConfig.conduit) port;
          allow_registration = false;
          allow_federation = true;
          trusted_servers = [ "matrix.org" ];
          max_request_size = 20000000;
          database_backend = "rocksdb";
          # Voice/video: requires coturn + shared TURN secret. Add:
          #   turn_uris = [ "turn:turn.${domain}:3478?transport=udp"
          #                 "turn:turn.${domain}:3478?transport=tcp" ];
          # plus services.coturn on host with same static-auth-secret-file.
        };
      };

      # nixpkgs module names the unit `conduit.service`, not `matrix-conduit`.
      # DynamicUser=true (module default) collides with our bind-mounted state
      # dir owned by the container's fixed `conduit` uid — force off.
      systemd.services.conduit.serviceConfig.DynamicUser = lib.mkForce false;

      networking.firewall.allowedTCPPorts = [ containerConfig.conduit.port ];
    };
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir}/home/conduit/appdata/conduit 755 ${uid} ${uid} -"
    "Z ${dataDir}/home/conduit/appdata/conduit - ${uid} ${uid} -"
  ];
}
