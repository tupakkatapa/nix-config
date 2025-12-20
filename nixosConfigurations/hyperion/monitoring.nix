{ pkgs, config, ... }:
{
  # eBPF observability tools
  environment.systemPackages = with pkgs; [
    bpftrace
    bpftop
    config.boot.kernelPackages.bcc
    tetragon
  ];

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

  # Tetragon - eBPF security observability
  systemd.services.tetragon = {
    description = "Tetragon eBPF Security Observability";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.tetragon}/bin/tetragon --bpf-lib ${pkgs.tetragon}/lib/tetragon/bpf/";
      Restart = "on-failure";
      RestartSec = "5s";
      StateDirectory = "tetragon";
      RuntimeDirectory = "tetragon";

      # Tetragon needs root for eBPF
      User = "root";

      # Hardening (what we can apply while keeping eBPF access)
      NoNewPrivileges = false; # Required for eBPF
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ "/var/lib/tetragon" "/var/run/tetragon" ];
    };
  };
}
