{ pkgs
, lib
, config
, domain
, dataDir
, servicesConfig
, inputs
, ...
}:
let
  # Global container settings with user creation
  globalContainerConfig = serviceName: {
    system.stateVersion = "24.11";
    nixpkgs.config.allowUnfree = true;
    networking = {
      domain = "${domain}";
      useDHCP = false;
      # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
      useHostResolvConf = lib.mkForce false;
    };

    # Disable systemd-resolved since it's not working in containers
    services.resolved.enable = lib.mkForce false;

    # Direct resolv.conf configuration (documented workaround)
    environment.etc."resolv.conf".text = ''
      nameserver 1.1.1.1
      nameserver 8.8.8.8
    '';

    # Disable root login
    users.users.root.hashedPassword = "!";

    # Create service user with matching UID
    users.users."${serviceName}" = {
      isSystemUser = true;
      home = "/var/lib/${serviceName}";
      uid = lib.mkForce servicesConfig."${serviceName}".uid;
      group = serviceName;
    };
    users.groups."${serviceName}" = {
      gid = lib.mkForce servicesConfig."${serviceName}".uid;
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
        extraGroups = [ "sftp" ];
      })
      servicesConfig;
    groups = lib.mapAttrs (_name: service: { gid = lib.mkForce service.uid; }) servicesConfig;
  };

  # Containers
  imports = [
    (import ./kavita.nix { inherit config lib domain dataDir servicesConfig globalContainerConfig; })
    (import ./vaultwarden.nix { inherit config lib domain dataDir servicesConfig globalContainerConfig; })
    (import ./transmission.nix { inherit config lib domain dataDir servicesConfig globalContainerConfig; })
    (import ./searx.nix { inherit config lib domain dataDir servicesConfig globalContainerConfig; })
    (import ./ollama.nix { inherit config lib domain dataDir servicesConfig globalContainerConfig; })
    (import ./plex.nix { inherit config lib domain dataDir servicesConfig globalContainerConfig; })
    (import ./radicale.nix { inherit config lib domain dataDir servicesConfig globalContainerConfig; })
    (import ./coditon-md { inherit config lib pkgs domain dataDir servicesConfig inputs globalContainerConfig; })
  ];
  boot.enableContainers = true;

  # Container secrets
  age.secrets = {
    "vaultwarden-env".rekeyFile = ../../secrets/vaultwarden-env.age;
    "kavita-token".rekeyFile = ../../secrets/kavita-token.age;
    "searx-env".rekeyFile = ../../secrets/searx-env.age;
    "radicale-admin-pass".rekeyFile = ../../secrets/radicale-admin-pass.age;
  };

  # Host networking for all containers
  networking = {
    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "enp0s31f6";
    };
    firewall = {
      extraCommands =
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList
            (name: service: ''
              # ${name}
              iptables -t nat -A PREROUTING -p tcp -d 10.42.0.8 --dport ${toString service.port} -j DNAT --to-destination ${service.localAddress}:${toString service.port}
              iptables -t nat -A PREROUTING -p tcp -d 172.16.16.1 --dport ${toString service.port} -j DNAT --to-destination ${service.localAddress}:${toString service.port}
              iptables -A FORWARD -p tcp -d ${service.localAddress} --dport ${toString service.port} -j ACCEPT
            '')
            servicesConfig
        );
    };
  };
}
