_: {
  networking.firewall.enable = true;

  # nftables with flow offloading and NAT
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
    tables."nat" = {
      family = "ip";
      content = ''
        chain prerouting {
          type nat hook prerouting priority dstnat; policy accept;

          # Port forwarding to Vladof
          iifname "enp1s0" tcp dport 80 dnat to 10.42.0.8:80
          iifname "enp1s0" tcp dport 443 dnat to 10.42.0.8:443
          iifname "enp1s0" tcp dport 32400 dnat to 10.42.0.8:32400
          iifname "enp1s0" tcp dport 54783 dnat to 10.42.0.8:54783

          # Port forwarding to Kaakkuri
          iifname "enp1s0" tcp dport 9001 dnat to 10.42.0.25:9001
          iifname "enp1s0" tcp dport 30303 dnat to 10.42.0.25:30303
          iifname "enp1s0" udp dport 30303 dnat to 10.42.0.25:30303
          iifname "enp1s0" udp dport 51821 dnat to 10.42.0.25:51821
        }

        chain postrouting {
          type nat hook postrouting priority 100; policy accept;

          # Masquerade all traffic going to WAN
          oifname "enp1s0" masquerade
        }
      '';
    };
  };

  # Wait for bridges before starting nftables (flowtable needs them)
  systemd.services.nftables = {
    after = [ "sys-subsystem-net-devices-br\\x2dlan.device" "sys-subsystem-net-devices-br\\x2dwifi.device" ];
    wants = [ "sys-subsystem-net-devices-br\\x2dlan.device" "sys-subsystem-net-devices-br\\x2dwifi.device" ];
    serviceConfig.TimeoutStartSec = "30s";
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

      # Allow ICMPv6 for IPv6 to work (neighbor discovery, router advertisements, etc.)
      ip6 nexthdr icmpv6 icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, echo-request, echo-reply, nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } accept

      # Allow DHCPv6 client on WAN
      iifname "enp1s0" udp sport 547 udp dport 546 accept

      # Rate limiting
      iifname { "br-lan", "wg0" } tcp dport 22 limit rate over 10/minute drop
      iifname { "br-lan", "wg0", "br-wifi" } udp dport 53 limit rate over 50/second drop
      iifname { "br-lan", "wg0", "br-wifi" } udp dport 123 limit rate over 10/second drop

      # Logging (sampled to avoid flooding)
      limit rate 1/minute log prefix "INPUT DROP: "
    '';

    extraForwardRules = ''
      # Allow established/related (stateful)
      ct state established,related accept

      # Allow LAN → WAN (IPv4 + IPv6)
      iifname "br-lan" oifname "enp1s0" accept

      # Allow WireGuard → WAN and LAN
      iifname "wg0" oifname { "enp1s0", "br-lan" } accept

      # Allow WiFi → WAN only (no LAN access - guest network)
      iifname "br-wifi" oifname "enp1s0" accept

      # Allow ICMPv6 forwarding (required for path MTU discovery, etc.)
      ip6 nexthdr icmpv6 accept

      # Rate limit new connections (anti-DoS)
      ct state new limit rate over 100/second drop

      # Flow offloading (only established connections for security)
      meta l4proto { tcp, udp } ct state established flow add @f

      # Block unsolicited WAN → LAN (defense in depth for IPv6)
      iifname "enp1s0" oifname { "br-lan", "br-wifi" } drop

      # Logging (sampled)
      limit rate 1/minute log prefix "FORWARD DROP: "
    '';
  };
}
