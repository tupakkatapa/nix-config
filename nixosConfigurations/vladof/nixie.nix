{ dataDir
, appData
, ...
}: {
  # Support for cross compilation
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

  # Create directories, these are persistent
  systemd.tmpfiles.rules = [
    "d ${appData}/nixie          755 root root -"
    "d ${appData}/nixie/netboot  755 root root -"
    "d ${appData}/nixie/logs     755 root root -"
  ];

  # Mount '/nix/.rw-store' and '/tmp' to disk
  services.nixRemount = {
    enable = true;
    where = "${dataDir}/store";
    type = "none";
    options = [ "bind" ];
  };

  services.nixie = {
    enable = true;
    dataDir = "${appData}/nixie/netboot";
    logDir = "${appData}/nixie/logs";

    file-server = {
      httpPort = 10951;
      menus = [
        {
          name = "kaakkuri-ephemeral-alpha";
          flakeUrl = "github:ponkila/homestaking-infra\?ref=kaakkuri-ephemeral-alpha";
          hosts = [ "kaakkuri-ephemeral-alpha" ];
          timeout = 1;
        }
        {
          name = "torgue";
          flakeUrl = "github:tupakkatapa/nix-config";
          hosts = [ "torgue" "tediore" "bandit" ];
          default = "torgue";
          timeout = 3;
        }
      ];
    };

    dhcp = {
      enable = true;
      subnets = [
        {
          name = "upstream";
          serve = true;
          address = "192.168.1.8";
          interfaces = [ "enp0s31f6" ];
          clients = [
            {
              menu = "torgue";
              mac = "d4:5d:64:d1:12:52";
              address = "192.168.1.7";
            }
            {
              menu = "kaakkuri-ephemeral-alpha";
              mac = "70:85:c2:b5:be:db";
              address = "192.168.1.25";
            }
          ];
          poolStart = "192.168.1.30";
          poolEnd = "192.168.1.59";
        }
      ];
    };
  };

  # TODO: Binary cache
  # services.nix-serve = {
  #   enable = true;
  #   secretKeyFile = "/var/cache-priv-key.pem";
  #   port = 5000;
  #   openFirewall = true;
  # };
}

