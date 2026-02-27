{ domain, ... }:
{
  services.monitoring = {
    enable = true;
    grafana = {
      enable = true;
      domain = "grafana.${domain}";
      extraExporters.kaakkuri = "10.42.0.25:9100";
    };
  };
}
