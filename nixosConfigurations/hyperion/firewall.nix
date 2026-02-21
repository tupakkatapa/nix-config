_:
{
  networking.firewall.enable = true;

  # nftables with NAT
  networking.nftables = {
    enable = true;
    checkRuleset = false; # interfaces don't exist at build time

    tables."mangle" = {
      family = "ip";
      content = ''
        chain prerouting {
          type filter hook prerouting priority mangle; policy accept;
          ct mark 0x1 meta mark set ct mark
        }
      '';
    };

    tables."nat" = {
      family = "ip";
      content = ''
        chain prerouting {
          type nat hook prerouting priority dstnat; policy accept;

          # Mark inbound WAN connections so responses bypass Mullvad
          iifname "enp1s0" ct state new ct mark set 0x1

          # Port forwarding to Vladof
          iifname "enp1s0" tcp dport 80 dnat to 10.42.0.8:80
          iifname "enp1s0" tcp dport 443 dnat to 10.42.0.8:443
          iifname "enp1s0" tcp dport 32400 dnat to 10.42.0.8:32400   # Plex
          iifname "enp1s0" tcp dport 54783 dnat to 10.42.0.8:54783   # Blog

          # Port forwarding to Kaakkuri
          iifname "enp1s0" tcp dport 9001 dnat to 10.42.0.25:9001
          iifname "enp1s0" tcp dport 30303 dnat to 10.42.0.25:30303
          iifname "enp1s0" udp dport 30303 dnat to 10.42.0.25:30303
          iifname "enp1s0" udp dport 51821 dnat to 10.42.0.25:51821
        }

        chain postrouting {
          type nat hook postrouting priority 100; policy accept;

          # Masquerade DNAT'd traffic so LAN hosts reply via hyperion, not via Mullvad
          oifname "br-lan" ct status dnat masquerade

          # Masquerade traffic going to WAN or Mullvad
          oifname { "enp1s0", "mullvad" } masquerade
        }
      '';
    };
  };

  # Firewall: explicit allow rules per interface
  # SECURITY: Do NOT use trustedInterfaces
  networking.firewall = {
    trustedInterfaces = [ ];
    checkReversePath = false; # Breaks with SuppressPrefixLength = 0; anti-spoofing in extraInputRules
    filterForward = true; # Enable forward chain for extraForwardRules

    interfaces = {
      "br-lan" = {
        allowedTCPPorts = [ 22 53 80 443 52080 ]; # SSH, DNS, HTTP, HTTPS, Nixie HTTP
        allowedUDPPorts = [ 53 67 69 123 ]; # DNS, DHCP, TFTP, NTP
      };

      "wg0" = {
        allowedTCPPorts = [ 22 53 ]; # SSH, DNS
        allowedUDPPorts = [ 53 123 ]; # DNS, NTP
      };

      "br-wifi" = {
        allowedTCPPorts = [ 53 ]; # DNS
        allowedUDPPorts = [ 53 67 123 51820 ]; # DNS, DHCP, NTP, WireGuard
      };

      "enp1s0" = {
        allowedTCPPorts = [ ];
        allowedUDPPorts = [ 51820 51822 ]; # WireGuard (wg0, wg1)
      };

      "wg1" = {
        allowedTCPPorts = [ 22 53 ]; # SSH, DNS
        allowedUDPPorts = [ 53 123 ]; # DNS, NTP
      };

      "wg2" = {
        allowedTCPPorts = [ 22 53 ]; # SSH, DNS
        allowedUDPPorts = [ 53 123 ]; # DNS, NTP
      };
    };

    extraInputRules = ''
      # Anti-spoofing: drop RFC1918 from WAN (except our own ranges for hairpin NAT)
      iifname "enp1s0" ip saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } drop

      # Allow ICMPv6 for IPv6 to work (neighbor discovery, router advertisements, etc.)
      ip6 nexthdr icmpv6 icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, echo-request, echo-reply, nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } accept

      # Allow DHCPv6 client on WAN
      iifname "enp1s0" udp sport 547 udp dport 546 accept

      # Allow vladof to scrape node exporter (Prometheus)
      iifname "br-lan" ip saddr 10.42.0.8 tcp dport 9100 accept

      # Rate limiting
      iifname { "br-lan", "wg0", "wg1", "wg2" } tcp dport 22 limit rate over 10/minute drop
      iifname { "br-lan", "wg0", "wg1", "wg2", "br-wifi" } udp dport 53 limit rate over 50/second drop
      iifname { "br-lan", "wg0", "wg1", "wg2", "br-wifi" } udp dport 123 limit rate over 10/second drop

      # Logging (sampled to avoid flooding)
      limit rate 1/minute log prefix "INPUT DROP: "
    '';

    extraForwardRules = ''
      # Allow established/related (stateful)
      ct state established,related accept

      # Rate limit forwarded services to vladof (WAN → LAN)
      iifname "enp1s0" tcp dport { 80, 443 } ct state new limit rate over 30/second drop
      iifname "enp1s0" tcp dport 32400 ct state new limit rate over 30/second drop
      iifname "enp1s0" tcp dport 54783 ct state new limit rate over 10/second drop

      # Allow Vladof to reach Cloudflare NS for ACME DNS propagation check
      # ricardo.ns.cloudflare.com + haley.ns.cloudflare.com
      iifname "br-lan" ip saddr 10.42.0.8 ip daddr { 172.64.35.211, 108.162.195.211, 162.159.44.211, 172.64.34.15, 108.162.194.15, 162.159.38.15 } tcp dport 53 accept
      iifname "br-lan" ip saddr 10.42.0.8 ip daddr { 172.64.35.211, 108.162.195.211, 162.159.44.211, 172.64.34.15, 108.162.194.15, 162.159.38.15 } udp dport 53 accept

      # Block external DNS (force clients through local resolver)
      iifname { "br-lan", "br-wifi", "wg0", "wg1", "wg2" } oifname { "enp1s0", "mullvad" } tcp dport 53 reject with tcp reset
      iifname { "br-lan", "br-wifi", "wg0", "wg1", "wg2" } oifname { "enp1s0", "mullvad" } udp dport 53 reject

      # Egress blocks (defense in depth)
      oifname { "enp1s0", "mullvad" } tcp dport { 21, 23, 25, 135, 137, 138, 139, 445 } drop  # FTP, Telnet, SMTP, RPC, SMB
      oifname { "enp1s0", "mullvad" } udp dport { 137, 138, 139, 445 } drop                   # NetBIOS/SMB

      # Allow LAN → WAN and Mullvad
      iifname "br-lan" oifname { "enp1s0", "mullvad" } accept

      # Allow WireGuard → WAN, Mullvad, and LAN
      iifname "wg0" oifname { "enp1s0", "mullvad", "br-lan" } accept

      # wg1: only garage on vladof (10.42.0.8), no other LAN access
      iifname "wg1" oifname "br-lan" ip daddr 10.42.0.8 tcp dport { 3900, 3901, 3902, 3903 } accept
      iifname "wg1" oifname "br-lan" drop
      iifname "wg1" oifname { "enp1s0", "mullvad" } accept

      # wg2: WAN only, no LAN access
      iifname "wg2" oifname "br-lan" drop
      iifname "wg2" oifname { "enp1s0", "mullvad" } accept

      # Allow WiFi → WAN only (no LAN access - guest network)
      iifname "br-wifi" oifname { "enp1s0", "mullvad" } accept

      # Allow ICMPv6 forwarding (required for path MTU discovery, etc.)
      ip6 nexthdr icmpv6 accept

      # Rate limit new connections (anti-DoS)
      ct state new limit rate over 100/second drop

      # Allow port-forwarded services from WAN to LAN
      iifname "enp1s0" oifname "br-lan" ip daddr 10.42.0.8 tcp dport { 80, 443, 32400, 54783 } accept
      iifname "enp1s0" oifname "br-lan" ip daddr 10.42.0.25 tcp dport { 9001, 30303 } accept
      iifname "enp1s0" oifname "br-lan" ip daddr 10.42.0.25 udp dport { 30303, 51821 } accept

      # Block unsolicited WAN → LAN
      iifname "enp1s0" oifname { "br-lan", "br-wifi" } drop

      # Logging (sampled)
      limit rate 1/minute log prefix "FORWARD DROP: "
    '';
  };
}
