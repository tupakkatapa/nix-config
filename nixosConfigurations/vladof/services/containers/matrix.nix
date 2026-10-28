{ config
, lib
, dataDir
, domain
, containerConfig
, globalContainerConfig
, ...
}:
let
  uid = builtins.toString containerConfig.matrix.uid;
  appdata = "${dataDir}/home/matrix/appdata";

  # Bridges share the container so Tuwunel reaches them on localhost
  bridgeUids = {
    whatsapp = 10111;
    signal = 10112;
    telegram = 10113;
  };
  homeserver = {
    address = "http://localhost:${toString containerConfig.matrix.port}";
    inherit domain;
  };
  permissions.${domain} = "user";
in
{
  containers.matrix = {
    autoStart = true;
    privateNetwork = true;
    inherit (containerConfig.matrix) hostAddress localAddress;

    bindMounts = {
      "/var/lib/tuwunel" = {
        hostPath = "${appdata}/tuwunel";
        isReadOnly = false;
      };
      "/etc/matrix-env" = {
        hostPath = config.age.secrets.matrix-env.path;
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
      imports = [ (globalContainerConfig "matrix") ];

      services.matrix-tuwunel = {
        enable = true;
        user = "matrix";
        group = "matrix";
        settings.global = {
          server_name = domain;
          address = [ "0.0.0.0" ];
          port = [ containerConfig.matrix.port ];
          allow_registration = true;
          appservice_dir = "/run/tuwunel/appservices";
          # Tokens come from TUWUNEL_APPSERVICE__DOUBLEPUPPET__{AS,HS}_TOKEN
          appservice.doublepuppet = {
            sender_localpart = "doublepuppet";
            users = [{ regex = "@.*:${lib.escapeRegex domain}"; }];
          };
        };
      };

      systemd.services.tuwunel = {
        after = lib.mapAttrsToList (name: _: "mautrix-${name}.service") bridgeUids;
        serviceConfig = {
          # DynamicUser can't own the bind-mounted state dir
          DynamicUser = lib.mkForce false;
          EnvironmentFile = "/etc/matrix-env";
          # Runs as root to read the bridges' registrations; `cp -P` keeps a
          # symlink a symlink, so a bridge can't make root read another file
          ExecStartPre = "+${pkgs.writeShellScript "tuwunel-appservices" ''
            umask 077
            dir=/run/tuwunel/appservices
            mkdir -p "$dir"
            ${lib.concatMapStrings (name: ''
              f=/var/lib/mautrix-${name}/${name}-registration.yaml
              if [ -e "$f" ]; then
                cp -P --remove-destination "$f" "$dir/${name}.yaml"
              fi
            '') (lib.attrNames bridgeUids)}
            chown -hR matrix:matrix "$dir"
          ''}";
        };
      };

      # goolm and no E2BE keep libolm (marked insecure) out of the closure
      services.mautrix-whatsapp = {
        enable = true;
        package = pkgs.mautrix-whatsapp.override { withGoolm = true; };
        environmentFile = "/etc/matrix-env";
        settings = {
          inherit homeserver;
          bridge = { inherit permissions; };
        };
      };

      services.mautrix-signal = {
        enable = true;
        package = pkgs.mautrix-signal.override { withGoolm = true; };
        environmentFile = "/etc/matrix-env";
        settings = {
          inherit homeserver;
          bridge = { inherit permissions; };
        };
      };

      services.mautrix-telegram = {
        enable = true;
        package = pkgs.mautrix-telegram.override { withE2BE = false; };
        environmentFile = "/etc/matrix-env";
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

      networking.firewall.allowedTCPPorts = [ containerConfig.matrix.port ];
    };
  };

  systemd.tmpfiles.rules = [
    "d ${appdata}/tuwunel 700 ${uid} ${uid} -"
    "Z ${appdata}/tuwunel - ${uid} ${uid} -"
  ]
  ++ lib.concatLists (lib.mapAttrsToList
    (name: id: [
      "d ${appdata}/mautrix-${name} 750 ${toString id} ${toString id} -"
      "Z ${appdata}/mautrix-${name} - ${toString id} ${toString id} -"
    ])
    bridgeUids);
}
