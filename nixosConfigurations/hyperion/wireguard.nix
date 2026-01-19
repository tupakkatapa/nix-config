{ config, ... }:
{
  age.secrets = {
    "wg-server-private" = {
      rekeyFile = ./secrets/wg-server-private.age;
      owner = "systemd-network";
      mode = "400";
    };
    "wg1-server-private" = {
      rekeyFile = ./secrets/wg1-server-private.age;
      owner = "systemd-network";
      mode = "400";
    };
    "wg2-server-private" = {
      rekeyFile = ./secrets/wg2-server-private.age;
      owner = "systemd-network";
      mode = "400";
    };
  };

  # WireGuard server configuration
  networking.useNetworkd = true;
  systemd.network = {
    enable = true;
    netdevs = {
      "50-wg0" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
          MTUBytes = "1300";
        };
        wireguardConfig = {
          PrivateKeyFile = config.age.secrets.wg-server-private.path;
          ListenPort = 51820;
        };
        wireguardPeers = [
          # OnePlus 9
          {
            PublicKey = "PH/wZiXlLiCiWqB2AAxB7TRhPVbUh0Dyy6bB8zEthBM=";
            AllowedIPs = [ "172.16.16.2/32" ];
            PersistentKeepalive = 25;
          }
          # Kari
          {
            PublicKey = "vdCiN71d/Qn2I1GF5wJnXNWcqBSVyWvjtpLSUykbLkA=";
            AllowedIPs = [ "172.16.16.3/32" ];
          }
          # Boox
          {
            PublicKey = "IZHDryL8A0tM70q/8yU4Cjmd6oZm294C2XQ0RQVWMWY=";
            AllowedIPs = [ "172.16.16.4/32" ];
            PersistentKeepalive = 25;
          }
        ];
      };

      # Site-to-site VPN interface 1
      "51-wg1" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg1";
          MTUBytes = "1300";
        };
        wireguardConfig = {
          PrivateKeyFile = config.age.secrets.wg1-server-private.path;
          ListenPort = 51822;
        };
        wireguardPeers = [
          {
            PublicKey = "elemyZtQ50TbqqaMp27M2iIW7KoTHxcmn2d0CCK22xM=";
            AllowedIPs = [ "172.16.17.2/32" ];
            PersistentKeepalive = 25;
          }
        ];
      };

      # Site-to-site VPN interface 2
      "52-wg2" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg2";
          MTUBytes = "1300";
        };
        wireguardConfig = {
          PrivateKeyFile = config.age.secrets.wg2-server-private.path;
          ListenPort = 51823;
        };
        wireguardPeers = [ ];
      };
    };
    networks = {
      "wg0" = {
        matchConfig.Name = "wg0";
        address = [ "172.16.16.1/24" ];
        networkConfig = {
          IPMasquerade = "ipv4";
          IPv4Forwarding = true;
        };
      };
      "wg1" = {
        matchConfig.Name = "wg1";
        address = [ "172.16.17.1/24" ];
        networkConfig = {
          IPMasquerade = "ipv4";
          IPv4Forwarding = true;
        };
      };
      "wg2" = {
        matchConfig.Name = "wg2";
        address = [ "172.16.18.1/24" ];
        networkConfig = {
          IPMasquerade = "ipv4";
          IPv4Forwarding = true;
        };
      };
    };
  };
}
