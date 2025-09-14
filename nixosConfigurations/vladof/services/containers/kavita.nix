{ config
, lib
, domain
, dataDir
, servicesConfig
, containerNetwork
, ...
}:
{
  containers.kavita = {
    autoStart = true;
    privateNetwork = true;
    inherit (containerNetwork) hostAddress;
    localAddress = containerNetwork.kavita.address;

    # Bind mount the persistent data directory
    bindMounts = {
      "/var/lib/kavita" = {
        hostPath = "${dataDir}/appdata/kavita";
        isReadOnly = false;
      };
      "/etc/kavita-token" = {
        hostPath = config.age.secrets.kavita-token.path;
        isReadOnly = true;
      };
    };

    config = _: {
      system.stateVersion = "24.11";

      services.kavita = {
        enable = true;
        dataDir = "/var/lib/kavita";
        tokenKeyFile = "/etc/kavita-token";
        settings.Port = servicesConfig.kavita.port;
      };

      networking = {
        firewall = {
          enable = true;
          allowedTCPPorts = [ servicesConfig.kavita.port ];
        };
        domain = "${domain}";

        # Use systemd-resolved inside the container
        # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
        useHostResolvConf = lib.mkForce false;
      };

      services.resolved.enable = true;

      # Disable root login
      users.users.root.hashedPassword = "!";
    };
  };
}
