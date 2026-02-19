{ domain, ... }:
{
  services.monitoring = {
    enable = true;
    grafana = {
      enable = true;
      domain = "grafana.${domain}";
      extraDatasources = [{
        name = "kaakkuri";
        type = "prometheus";
        url = "http://10.42.0.25:9090";
      }];
    };
  };
}
