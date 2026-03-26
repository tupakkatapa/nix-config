{ dataDir, ... }:
{
  # Support for cross compilation
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

  services.nixie = {
    enable = true;
    prune = true;
    dataDir = "${dataDir}/home/root/appdata/nixie";
    logDir = "${dataDir}/home/root/appdata/nixie/logs";

    fileServer = {
      https = {
        enable = false;
        address = "ipxe.coditon.com";
      };
    };

    menus = [
      {
        name = "kaakkuri-ephemeral-alpha";
        flakeUrl = "github:ponkila/homestaking-infra?ref=jhvst/feat/monitoring";
        hosts = [ "kaakkuri-ephemeral-alpha" ];
        timeout = 1;
      }
      {
        name = "torgue";
        flakeUrl = "github:tupakkatapa/nix-config";
        hosts = [ "torgue" "bandit" ];
        default = "torgue";
        rollbacks = {
          enable = true;
          keep = 2;
        };
        timeout = 1;
      }
      {
        name = "vladof";
        flakeUrl = "github:tupakkatapa/nix-config";
        hosts = [ "vladof" "bandit" ];
        default = "vladof";
        rollbacks = {
          enable = true;
          keep = 2;
        };
        timeout = 1;
      }
      {
        name = "maliwan";
        flakeUrl = "github:tupakkatapa/nix-config";
        hosts = [ "maliwan" "bandit" ];
        default = "maliwan";
        rollbacks = {
          enable = true;
          keep = 2;
        };
        timeout = 1;
      }
      {
        name = "bandit";
        flakeUrl = "github:tupakkatapa/nix-config";
        hosts = [ "bandit" ];
        timeout = 3;
      }
    ];

    wan = {
      enable = true;
      interface = "enp1s0";
      ipv6 = {
        enable = true;
        prefixDelegation = false;
      };
    };

    dhcp = {
      enable = true;
      subnets = [
        {
          name = "lan";
          serve = true;
          interfaces = [ "enp2s0" ];
          ipv4 = {
            address = "10.42.0.1";
            poolStart = "10.42.0.30";
            poolEnd = "10.42.0.254";
          };
          ipv6 = {
            address = "fd42:42:42:1::1";
            managed = true;
            poolStart = "fd42:42:42:1::1000";
            poolEnd = "fd42:42:42:1::ffff";
          };
          defaultMenu = "bandit";
          clients = [
            {
              menu = "torgue";
              mac = "d4:5d:64:d1:12:52";
              ipv4.address = "10.42.0.7";
              ipv6.address = "fd42:42:42:1::7";
            }
            {
              menu = "vladof";
              mac = "30:9c:23:3c:b9:01";
              ipv4.address = "10.42.0.8";
              ipv6.address = "fd42:42:42:1::8";
            }
            {
              menu = "maliwan";
              mac = "18:3d:2d:d2:de:41";
              ipv4.address = "10.42.0.9";
              ipv6.address = "fd42:42:42:1::9";
            }
            {
              menu = "kaakkuri-ephemeral-alpha";
              mac = "70:85:c2:b5:be:db";
              ipv4.address = "10.42.0.25";
              ipv6.address = "fd42:42:42:1::25";
            }
            {
              serve = false;
              mac = "70:af:24:ad:4e:f1";
              ipv4.address = "10.42.0.6";
              ipv6.address = "fd42:42:42:1::6";
            }
          ];
        }
        {
          name = "wifi";
          serve = true;
          interfaces = [ "wlp0s20f3" ];
          ipv4 = {
            address = "10.42.1.1";
            poolStart = "10.42.1.10";
            poolEnd = "10.42.1.254";
          };
          ipv6 = {
            address = "fd42:42:42:2::1";
            managed = true;
            poolStart = "fd42:42:42:2::1000";
            poolEnd = "fd42:42:42:2::ffff";
          };
          defaultMenu = "bandit";
        }
      ];
    };
  };
}
