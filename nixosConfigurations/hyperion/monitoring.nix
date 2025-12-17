_:
{
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
      "conntrack"
    ];
    listenAddress = "10.42.0.1";
  };

  # vnStat - monitors bandwidth usage
  services.vnstat.enable = true;

  # Static UID/GID for persistent storage
  users.users.vnstatd.uid = 993;
  users.groups.vnstatd.gid = 991;
}
