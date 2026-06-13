{ domain, dataDir, config, ... }:
{
  # Monitoring
  services.monitoring = {
    enable = true;
    server = {
      enable = true;
      grafana.domain = "grafana.${domain}";
      extraExporters.kaakkuri = "10.42.0.25:9100";
    };
  };

  # Dashboards + DB on disk
  services.grafana.dataDir = "${dataDir}/home/grafana/appdata/grafana";

  # Secrets
  age.secrets.grafana-secret-key.rekeyFile = ../secrets/grafana-secret-key.age;
  services.grafana.settings.security.secret_key = "$__file{${config.age.secrets.grafana-secret-key.path}}";

  # Pin grafana gid (uid 196 already static upstream)
  users.users.grafana.uid = 196;
  users.groups.grafana.gid = 196;
}
