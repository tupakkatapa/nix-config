{ config, ... }:
{
  age.secrets = {
    "wg-server-private" = {
      rekeyFile = ./secrets/wg-server-private.age;
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
        ];
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
    };
  };
}
