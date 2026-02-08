{ domain, ... }:
{
  services.monitoring = {
    enable = true;
    grafana = {
      enable = true;
      domain = "grafana.${domain}";
    };
  };
}
