{ config
, lib
, dataDir
, domain
, containerConfig
, globalContainerConfig
, ...
}:
let
  uid = builtins.toString containerConfig.conduit.uid;
  appdata = "${dataDir}/home/conduit/appdata";

  # Bridges share the container so Conduit reaches them on localhost
  bridgeUids = {
    whatsapp = 10111;
    signal = 10112;
    telegram = 10113;
  };
  homeserver = {
    address = "http://localhost:${toString containerConfig.conduit.port}";
    inherit domain;
  };
  permissions.${domain} = "user";
in
{
  containers.conduit = {
    autoStart = true;
    privateNetwork = true;
    inherit (containerConfig.conduit) hostAddress localAddress;

    bindMounts = {
      "/var/lib/matrix-conduit" = {
        hostPath = "${appdata}/conduit";
        isReadOnly = false;
      };
      "/etc/conduit-env" = {
        hostPath = config.age.secrets.conduit-env.path;
        isReadOnly = true;
      };
      "/etc/mautrix-env" = {
        hostPath = config.age.secrets.mautrix-env.path;
        isReadOnly = true;
      };
    }
    // lib.mapAttrs'
      (name: _: lib.nameValuePair "/var/lib/mautrix-${name}" {
        hostPath = "${appdata}/mautrix-${name}";
        isReadOnly = false;
      })
      bridgeUids;

    config = { pkgs, ... }: {
      imports = [ (globalContainerConfig "conduit") ];

      services.matrix-conduit = {
        enable = true;
        settings.global = {
          server_name = domain;
          address = "0.0.0.0";
          inherit (containerConfig.conduit) port;
          allow_registration = true;
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

      # goolm and no E2BE keep libolm (marked insecure) out of the closure
      services.mautrix-whatsapp = {
        enable = true;
        package = pkgs.mautrix-whatsapp.override { withGoolm = true; };
        environmentFile = "/etc/mautrix-env";
        settings.bridge = { inherit permissions; };
      };

      services.mautrix-signal = {
        enable = true;
        package = pkgs.mautrix-signal.override { withGoolm = true; };
        environmentFile = "/etc/mautrix-env";
        settings.bridge = { inherit permissions; };
      };

      services.mautrix-telegram = {
        enable = true;
        package = pkgs.mautrix-telegram.override { withE2BE = false; };
        environmentFile = "/etc/mautrix-env";
        serviceDependencies = [ "conduit.service" ];
        settings = {
          inherit homeserver;
          appservice = {
            port = 29317;
            address = "http://localhost:29317";
          };
          # Its "user" level can't log in, "full" adds puppeting
          bridge.permissions.${domain} = "full";
        };
      };

      users = {
        users = lib.mapAttrs' (name: id: lib.nameValuePair "mautrix-${name}" { uid = id; }) bridgeUids;
        groups = lib.mapAttrs' (name: id: lib.nameValuePair "mautrix-${name}" { gid = id; }) bridgeUids;
      };

      # nixpkgs module names the unit `conduit.service`, not `matrix-conduit`.
      # DynamicUser=true (module default) collides with our bind-mounted state
      # dir owned by the container's fixed `conduit` uid — force off.
      systemd.services.conduit.serviceConfig = {
        DynamicUser = lib.mkForce false;
        EnvironmentFile = "/etc/conduit-env";
      };

      networking.firewall.allowedTCPPorts = [ containerConfig.conduit.port ];
    };
  };

  systemd.tmpfiles.rules = [
    "d ${appdata}/conduit 755 ${uid} ${uid} -"
    "Z ${appdata}/conduit - ${uid} ${uid} -"
  ]
  ++ lib.concatLists (lib.mapAttrsToList
    (name: id: [
      "d ${appdata}/mautrix-${name} 750 ${toString id} ${toString id} -"
      "Z ${appdata}/mautrix-${name} - ${toString id} ${toString id} -"
    ])
    bridgeUids);
}
