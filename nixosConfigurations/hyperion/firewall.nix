_:
{
  networking.firewall.enable = true;

  # nftables with flow offloading
  networking.nftables = {
    enable = true;
    checkRuleset = false;
    tables."nixos-fw" = {
      family = "inet";
      content = ''
        flowtable f {
          hook ingress priority 0;
          devices = { enp1s0, br-upstream };
          flags offload;
        }
      '';
    };
  };

  # NAT and port forwarding
  networking.nat = {
    enable = true;
    externalInterface = "enp1s0";
    internalInterfaces = [ "br-upstream" ];
    internalIPs = [ "192.168.1.0/24" ];

    forwardPorts = [
      # Vladof services
      { destination = "192.168.1.8:80"; sourcePort = 80; proto = "tcp"; }
      { destination = "192.168.1.8:443"; sourcePort = 443; proto = "tcp"; }
      { destination = "192.168.1.8:32400"; sourcePort = 32400; proto = "tcp"; }
      { destination = "192.168.1.8:54783"; sourcePort = 54783; proto = "tcp"; }

      # Kaakkuri services
      { destination = "192.168.1.25:9001"; sourcePort = 9001; proto = "tcp"; }
      { destination = "192.168.1.25:30303"; sourcePort = 30303; proto = "tcp"; }
      { destination = "192.168.1.25:30303"; sourcePort = 30303; proto = "udp"; }
      { destination = "192.168.1.25:51821"; sourcePort = 51821; proto = "udp"; }
    ];
  };

  # Firewall: explicit allow rules per interface
  # SECURITY: Do NOT use trustedInterfaces
  networking.firewall = {
    trustedInterfaces = [ ];

    interfaces = {
      "br-upstream" = {
        allowedTCPPorts = [ 22 53 80 9100 ];
        allowedUDPPorts = [ 53 67 69 123 ];
      };

      "wg0" = {
        allowedTCPPorts = [ 22 53 ];
        allowedUDPPorts = [ 53 123 ];
      };

      "enp1s0" = {
        allowedTCPPorts = [ ];
        allowedUDPPorts = [ 51820 ];
      };
    };

    extraInputRules = ''
      # Anti-spoofing: drop RFC1918 from WAN
      iifname "enp1s0" ip saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } drop

      # Rate limiting
      iifname { "br-upstream", "wg0" } tcp dport 22 limit rate over 10/minute drop
      iifname { "br-upstream", "wg0" } udp dport 53 limit rate over 50/second drop

      # Logging (sampled to avoid flooding)
      limit rate 1/minute log prefix "INPUT DROP: "
    '';

    extraForwardRules = ''
      # Allow LAN → WAN
      iifname "br-upstream" oifname "enp1s0" accept

      # Allow WireGuard → WAN and LAN
      iifname "wg0" oifname { "enp1s0", "br-upstream" } accept

      # Rate limit new connections (anti-DoS)
      ct state new limit rate over 100/second drop

      # Flow offloading (only established connections for security)
      meta l4proto { tcp, udp } ct state established flow add @f

      # Logging (sampled)
      limit rate 1/minute log prefix "FORWARD DROP: "
    '';
  };
}
