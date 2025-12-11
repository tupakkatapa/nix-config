_:
{
  # Fail2ban - monitors SSH logs for attacks
  services.fail2ban = {
    enable = true;

    # Whitelist LAN subnets
    ignoreIP = [
      "127.0.0.1/8"
      "192.168.1.0/24" # LAN
      "172.16.16.0/24" # WireGuard
    ];

    maxretry = 5;

    bantime = "24h";
    bantime-increment = {
      enable = true;
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "10w";
      overalljails = true;
    };
  };

  # Prometheus node exporter - monitors system metrics
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = [
      "systemd"
      "cpu"
      "diskstats"
      "filesystem"
      "loadavg"
      "meminfo"
      "netdev"
      "netstat"
      "stat"
      "time"
      "uname"
      "ethtool"
      "tcpstat"
    ];
    listenAddress = "192.168.1.2"; # TESTING: Change to .1 for production
  };

  # vnStat - monitors bandwidth usage
  services.vnstat.enable = true;
}
