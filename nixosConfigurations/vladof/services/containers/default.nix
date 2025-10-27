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
  # Generate self-signed cert for service index at host level
  selfSignedCert = pkgs.runCommand "self-signed-cert"
    {
      buildInputs = [ pkgs.openssl ];
    } ''
    mkdir -p $out
    openssl req -x509 -newkey rsa:4096 -keyout $out/key.pem -out $out/cert.pem -days 3650 -nodes \
      -subj "/CN=*.${domain}" \
      -addext "subjectAltName = DNS:*.${domain}"
  '';

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
    (import ./plex.nix { inherit config lib domain dataDir servicesConfig globalContainerConfig; })
    (import ./nextcloud.nix { inherit config lib domain dataDir servicesConfig globalContainerConfig; })
    (import ./coditon-md { inherit config lib pkgs domain dataDir servicesConfig inputs globalContainerConfig; })
    (import ./index { inherit config lib pkgs domain dataDir servicesConfig globalContainerConfig; inherit selfSignedCert; })
  ];
  boot.enableContainers = true;

  # Container secrets
  age.secrets = {
    "vaultwarden-env".rekeyFile = ../../secrets/vaultwarden-env.age;
    "kavita-token".rekeyFile = ../../secrets/kavita-token.age;
    "searx-env".rekeyFile = ../../secrets/searx-env.age;
    "nextcloud-admin-pass".rekeyFile = ../../secrets/nextcloud-admin-pass.age;
  };

  # Host networking for all containers
  networking = {
    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "br-upstream"; # Created by Nixie's Kea
    };
    firewall = {
      extraCommands =
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList
            (name: service: ''
              # ${name}
              iptables -t nat -A PREROUTING -p tcp -d 192.168.1.8 --dport ${toString service.port} -j DNAT --to-destination ${service.localAddress}:${toString service.port}
              iptables -A FORWARD -p tcp -d ${service.localAddress} --dport ${toString service.port} -j ACCEPT
            '')
            servicesConfig
        );
    };
  };
}
