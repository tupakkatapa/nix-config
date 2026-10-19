{ pkgs
, lib
, config
, domain
, dataDir
, containerConfig
, inputs
, ...
}:
let
  # Global container settings with user creation
  globalContainerConfig = serviceName: {
    system.stateVersion = "24.11";
    nixpkgs.config.allowUnfree = true;
    i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" "fi_FI.UTF-8/UTF-8" ];
    documentation.enable = false;

    networking = {
      domain = "${domain}";
      useDHCP = false;
      # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
      useHostResolvConf = lib.mkForce false;
      resolvconf.enable = false; # we write /etc/resolv.conf directly below
    };

    # Disable systemd-resolved since it's not working in containers
    services.resolved.enable = lib.mkForce false;

    # Direct resolv.conf configuration (documented workaround)
    # Uses hyperion (router) DNS which provides filtering and privacy
    environment.etc."resolv.conf".text = ''
      nameserver 10.42.0.1
    '';

    # Disable root login
    users.users.root.hashedPassword = "!";

    # Create service user with matching UID
    users.users."${serviceName}" = {
      isSystemUser = true;
      home = "/var/lib/${serviceName}";
      uid = lib.mkForce containerConfig."${serviceName}".uid;
      group = serviceName;
    };
    users.groups."${serviceName}" = {
      gid = lib.mkForce containerConfig."${serviceName}".uid;
    };
  };

in
{
  # Create host users for containers
  users = {
    users = lib.mapAttrs
      (name: service: {
        isSystemUser = true;
        home = "${dataDir}/home/${name}";
        uid = lib.mkForce service.uid;
        group = name;
      })
      containerConfig;
    groups = lib.mapAttrs (_name: service: { gid = lib.mkForce service.uid; }) containerConfig;
  };

  # Containers
  imports = [
    (import ./kavita.nix { inherit config lib domain dataDir containerConfig globalContainerConfig; })
    (import ./vaultwarden.nix { inherit config lib domain dataDir containerConfig globalContainerConfig; })
    (import ./transmission.nix { inherit config lib domain dataDir containerConfig globalContainerConfig; })
    (import ./searx.nix { inherit config lib domain dataDir containerConfig globalContainerConfig; })
    (import ./ollama.nix { inherit config lib domain dataDir containerConfig globalContainerConfig; })
    (import ./plex.nix { inherit config lib domain dataDir containerConfig globalContainerConfig; })
    (import ./radicale.nix { inherit config lib domain dataDir containerConfig globalContainerConfig; })
    (import ./ntfy.nix { inherit lib domain dataDir containerConfig globalContainerConfig; })
    (import ./conduit.nix { inherit lib domain dataDir containerConfig globalContainerConfig; })
    (import ./kaloriina.nix { inherit dataDir containerConfig inputs globalContainerConfig; })
    (import ./molesk { inherit config lib pkgs domain dataDir containerConfig inputs globalContainerConfig; })
  ];
  boot.enableContainers = true;

  # Container secrets
  age.secrets = {
    "vaultwarden-env".rekeyFile = ../../secrets/vaultwarden-env.age;
    "kavita-token".rekeyFile = ../../secrets/kavita-token.age;
    "searx-env".rekeyFile = ../../secrets/searx-env.age;
    "transmission-creds" = {
      rekeyFile = ../../secrets/transmission-creds.age;
      owner = toString containerConfig.transmission.uid;
      mode = "400";
    };
    "radicale-admin-pass" = {
      rekeyFile = ../../secrets/radicale-admin-pass.age;
      owner = toString containerConfig.radicale.uid;
      mode = "0400";
    };
  };

  # Host networking for all containers
  networking = {
    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "enp0s31f6";
    };
    firewall = {
      # Own chains so rules can be flushed on reload instead of accumulating
      extraCommands =
        ''
          iptables -t nat -N vladof-ctr-dnat 2>/dev/null || iptables -t nat -F vladof-ctr-dnat
          iptables -N vladof-ctr-fwd 2>/dev/null || iptables -F vladof-ctr-fwd
          iptables -t nat -A PREROUTING -j vladof-ctr-dnat
          iptables -A FORWARD -j vladof-ctr-fwd

          # Block containers from initiating new connections (except DNS)
          iptables -A vladof-ctr-fwd -i ve-+ -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
          iptables -A vladof-ctr-fwd -i ve-+ -d 10.42.0.1 -p udp --dport 53 -j ACCEPT
          iptables -A vladof-ctr-fwd -i ve-+ -d 10.42.0.1 -p tcp --dport 53 -j ACCEPT
          iptables -A vladof-ctr-fwd -i ve-+ -o ve-+ -j DROP
          iptables -A vladof-ctr-fwd -i ve-+ -d 10.23.0.0/24 -j DROP
          iptables -A vladof-ctr-fwd -i ve-+ -d 10.42.0.0/24 -j DROP
          iptables -A vladof-ctr-fwd -i ve-+ -d 10.42.1.0/24 -j DROP
          iptables -A vladof-ctr-fwd -i ve-+ -d 172.16.16.0/24 -j DROP
          iptables -A vladof-ctr-fwd -i ve-+ -d 172.16.17.0/24 -j DROP
          iptables -A vladof-ctr-fwd -i ve-+ -d 172.16.18.0/24 -j DROP

          # Host services take INPUT, so they miss the FORWARD rules above
          iptables -I nixos-fw 1 -i ve-+ -m conntrack --ctstate NEW -j nixos-fw-refuse
        ''
        # Raw ports for public services and plex, the rest go through Caddy
        + lib.concatStringsSep "\n"
          (
            lib.mapAttrsToList
              (name: service: ''
                # ${name}
                iptables -t nat -A vladof-ctr-dnat ! -i ve-+ -p tcp -d 10.42.0.8 --dport ${toString service.port} -j DNAT --to-destination ${service.localAddress}:${toString service.port}
                iptables -A vladof-ctr-fwd ! -i ve-+ -p tcp -d ${service.localAddress} --dport ${toString service.port} -j ACCEPT
              '')
              (lib.filterAttrs (name: service: !service.private || name == "plex") containerConfig)
          );

      extraStopCommands = ''
        iptables -t nat -D PREROUTING -j vladof-ctr-dnat 2>/dev/null || true
        iptables -D FORWARD -j vladof-ctr-fwd 2>/dev/null || true
        iptables -t nat -F vladof-ctr-dnat 2>/dev/null || true
        iptables -F vladof-ctr-fwd 2>/dev/null || true
        iptables -t nat -X vladof-ctr-dnat 2>/dev/null || true
        iptables -X vladof-ctr-fwd 2>/dev/null || true
      '';
    };
  };
}
