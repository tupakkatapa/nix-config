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
    "mullvad-private" = {
      rekeyFile = ./secrets/mullvad-private.age;
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

      # Mullvad VPN tunnel — client subnet traffic routed via policy rules
      "53-mullvad" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "mullvad";
          MTUBytes = "1300";
        };
        wireguardConfig = {
          PrivateKeyFile = config.age.secrets.mullvad-private.path;
        };
        wireguardPeers = [{
          PublicKey = "/iivwlyqWqxQ0BVWmJRhcXIFdJeo0WbHQ/hZwuXaN3g=";
          Endpoint = "193.32.127.66:51820";
          AllowedIPs = [ "0.0.0.0/0" ];
        }];
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
      "mullvad" = {
        matchConfig.Name = "mullvad";
        address = [ "10.72.145.215/32" ];
        routes = [{
          Destination = "0.0.0.0/0";
          Table = 51820;
        }];
        routingPolicyRules = [
          # Use main table for everything except the default route
          {
            Table = "main";
            SuppressPrefixLength = 0;
            Priority = 80;
          }
          # Port-forwarded responses go direct
          {
            FirewallMark = 1;
            Table = "main";
            Priority = 85;
          }
          # Kaakkuri bypasses Mullvad
          {
            From = "10.42.0.25";
            Table = "main";
            Priority = 85;
          }
          # Client subnets → Mullvad
          {
            From = "10.42.0.0/24";
            Table = 51820;
            Priority = 90;
          }
          {
            From = "10.42.1.0/24";
            Table = 51820;
            Priority = 90;
          }
          {
            From = "172.16.16.0/24";
            Table = 51820;
            Priority = 90;
          }
          {
            From = "172.16.17.0/24";
            Table = 51820;
            Priority = 90;
          }
          {
            From = "172.16.18.0/24";
            Table = 51820;
            Priority = 90;
          }
        ];
      };
    };
  };
}
