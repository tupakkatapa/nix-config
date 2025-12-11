_:
{
  networking.useNetworkd = true;
  systemd.network.enable = true;

  systemd.network = {
    networks."10-wan" = {
      matchConfig.Name = "enp1s0";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = false;
      };
      linkConfig.RequiredForOnline = "routable";
      dhcpV4Config = {
        UseDNS = false;
        UseNTP = false;
      };
    };
    # LAN managed by Nixie (br-upstream bridge)
  };

  boot.kernel.sysctl = {
    # Packet forwarding
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = 1;

    # IPv6 disabled (no firewall rules yet)
    "net.ipv6.conf.all.disable_ipv6" = 1;
    "net.ipv6.conf.default.disable_ipv6" = 1;
    "net.ipv6.conf.enp1s0.disable_ipv6" = 1;

    # Anti-spoofing
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;

    # ICMP redirect protection
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;

    # Source routing disabled
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;

    # SYN flood protection
    "net.ipv4.tcp_syncookies" = 1;

    # Martian packet logging
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;

    # ICMP protection
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
  };
}
