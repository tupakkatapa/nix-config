{ dataDir, ... }:
{
  # Support for cross compilation
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

  services.nixie = {
    enable = true;
    dataDir = "${dataDir}/home/root/appdata/nixie";

    file-server = {
      https = {
        enable = false;
        address = "ipxe.coditon.com";
      };

      menus = [
        {
          name = "kaakkuri-ephemeral-alpha";
          flakeUrl = "github:ponkila/homestaking-infra?ref=jhvst/patroni";
          hosts = [ "kaakkuri-ephemeral-alpha" ];
          timeout = 1;
        }
        {
          name = "torgue";
          flakeUrl = "github:tupakkatapa/nix-config";
          hosts = [ "torgue" "bandit" ];
          default = "torgue";
          rollbacks.enable = true;
          timeout = 1;
        }
        {
          name = "vladof";
          flakeUrl = "github:tupakkatapa/nix-config";
          hosts = [ "vladof" "bandit" ];
          rollbacks.enable = true;
          timeout = 1;
        }
        {
          name = "bandit";
          flakeUrl = "github:tupakkatapa/nix-config";
          hosts = [ "bandit" ];
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
          address = "192.168.1.2";
          interfaces = [ "enp2s0" ];
          defaultMenu = "bandit";
          clients = [
            {
              menu = "torgue";
              mac = "d4:5d:64:d1:12:52";
              address = "192.168.1.7";
            }
            {
              menu = "vladof";
              mac = "30:9c:23:3c:b9:01";
              address = "192.168.1.8";
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

