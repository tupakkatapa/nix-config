{ domain, dataDir, ... }:
{
  services.monitoring = {
    enable = true;
    grafana = {
      enable = true;
      domain = "grafana.${domain}";
      extraExporters.kaakkuri = "10.42.0.25:9100";
    };
  };

  # Dashboards + DB on disk
  services.grafana.dataDir = "${dataDir}/home/grafana/appdata/grafana";

  # Pin grafana gid (uid 196 already static upstream)
  users.users.grafana.uid = 196;
  users.groups.grafana.gid = 196;
}
