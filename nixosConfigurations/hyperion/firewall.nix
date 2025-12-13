_: {
  networking.firewall.enable = true;

  # nftables with flow offloading
  networking.nftables = {
    enable = true;
    checkRuleset = false; # interfaces don't exist at build time
    tables."nixos-fw" = {
      family = "inet";
      content = ''
        flowtable f {
          hook ingress priority 0;
          devices = { enp1s0, br-lan, br-wifi };
        }
      '';
    };
  };

  # NAT and port forwarding
  networking.nat = {
    enable = true;
    externalInterface = "enp1s0";
    internalInterfaces = [ "br-lan" "br-wifi" ];
    internalIPs = [ "10.42.0.0/24" "10.42.1.0/24" ];

    forwardPorts = [
      # Vladof services
      { destination = "10.42.0.8:80"; sourcePort = 80; proto = "tcp"; }
      { destination = "10.42.0.8:443"; sourcePort = 443; proto = "tcp"; }
      { destination = "10.42.0.8:32400"; sourcePort = 32400; proto = "tcp"; }
      { destination = "10.42.0.8:54783"; sourcePort = 54783; proto = "tcp"; }

      # Kaakkuri services
      { destination = "10.42.0.25:9001"; sourcePort = 9001; proto = "tcp"; }
      { destination = "10.42.0.25:30303"; sourcePort = 30303; proto = "tcp"; }
      { destination = "10.42.0.25:30303"; sourcePort = 30303; proto = "udp"; }
      { destination = "10.42.0.25:51821"; sourcePort = 51821; proto = "udp"; }
    ];
  };

  # Firewall: explicit allow rules per interface
  # SECURITY: Do NOT use trustedInterfaces
  networking.firewall = {
    trustedInterfaces = [ ];

    interfaces = {
      "br-lan" = {
        allowedTCPPorts = [ 22 53 52080 9100 ]; # SSH, DNS, Nixie HTTP, Prometheus
        allowedUDPPorts = [ 53 67 69 123 ]; # DNS, DHCP, TFTP, NTP
      };

      "wg0" = {
        allowedTCPPorts = [ 22 53 ]; # SSH, DNS
        allowedUDPPorts = [ 53 123 ]; # DNS, NTP
      };

      "br-wifi" = {
        allowedTCPPorts = [ 53 52080 ]; # DNS, Nixie HTTP
        allowedUDPPorts = [ 53 67 69 123 ]; # DNS, DHCP, TFTP, NTP
      };

      "enp1s0" = {
        allowedTCPPorts = [ ];
        allowedUDPPorts = [ 51820 ]; # WireGuard
      };
    };

    extraInputRules = ''
      # Anti-spoofing: drop RFC1918 from WAN (except our own ranges for hairpin NAT)
      iifname "enp1s0" ip saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } drop

      # Rate limiting
      iifname { "br-lan", "wg0" } tcp dport 22 limit rate over 10/minute drop
      iifname { "br-lan", "wg0", "br-wifi" } udp dport 53 limit rate over 50/second drop
      iifname { "br-lan", "wg0", "br-wifi" } udp dport 123 limit rate over 10/second drop

      # Logging (sampled to avoid flooding)
      limit rate 1/minute log prefix "INPUT DROP: "
    '';

    extraForwardRules = ''
      # Allow LAN → WAN
      iifname "br-lan" oifname "enp1s0" accept

      # Allow WireGuard → WAN and LAN
      iifname "wg0" oifname { "enp1s0", "br-lan" } accept

      # Allow WiFi → WAN only (no LAN access - guest network)
      iifname "br-wifi" oifname "enp1s0" accept

      # Rate limit new connections (anti-DoS)
      ct state new limit rate over 100/second drop

      # Flow offloading (only established connections for security)
      meta l4proto { tcp, udp } ct state established flow add @f

      # Logging (sampled)
      limit rate 1/minute log prefix "FORWARD DROP: "
    '';
  };
}
