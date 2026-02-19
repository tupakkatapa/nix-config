{ config, lib, outputs, pkgs, ... }:
let
  cfg = config.services.monitoring;

  # Auto-discover monitored hosts from flake outputs
  allHosts = builtins.attrNames outputs.nixosConfigurations;
  monitoredHosts = lib.filter
    (name: lib.attrByPath [ "services" "monitoring" "enable" ] false
      outputs.nixosConfigurations.${name}.config)
    allHosts;

  # Build scrape targets using DNS: ${hostname}.${domain}
  inherit (config.networking) domain;
  scrapeConfigs = map
    (name:
      let
        isSelf = name == config.networking.hostName;
      in
      {
        job_name = name;
        static_configs = [{
          targets = [ "${if isSelf then "127.0.0.1" else "${name}.${domain}"}:9100" ];
          labels.host = name;
        }];
      }
    )
    monitoredHosts;

  # Extract real mountpoints from monitored hosts' fileSystems
  realFsTypes = [ "btrfs" "ext4" "xfs" "vfat" "ntfs" "f2fs" "zfs" "bcachefs" ];
  mountpoints = lib.unique (lib.concatMap
    (name:
      let
        fs = outputs.nixosConfigurations.${name}.config.fileSystems;
      in
      lib.filter
        (mp:
          builtins.elem (fs.${mp}.fsType or "") realFsTypes
        )
        (builtins.attrNames fs)
    )
    monitoredHosts
  );

  # Dashboard as Nix
  dashboard = import ./dashboard.nix { inherit mountpoints; };
  dashboardDir = pkgs.writeTextDir "nodes.json" (builtins.toJSON dashboard);
in
{
  options.services.monitoring = {
    enable = lib.mkEnableOption "monitoring (node exporter, Prometheus + Grafana when grafana enabled)";

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open firewall for node exporter";
    };

    retentionTime = lib.mkOption {
      type = lib.types.str;
      default = "30d";
      description = "Prometheus data retention time";
    };

    grafana = {
      enable = lib.mkEnableOption "Grafana dashboards (also enables Prometheus server)";

      domain = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Domain for Grafana reverse proxy";
      };

      extraDatasources = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [ ];
        description = "Additional Grafana datasources to provision alongside the local Prometheus";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [

    # Node exporter
    {
      services.prometheus.exporters.node = {
        enable = true;
        port = 9100;
        inherit (cfg) openFirewall;
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
      };
    }

    # Prometheus + Grafana
    (lib.mkIf cfg.grafana.enable {
      services.prometheus = {
        enable = true;
        port = 9090;
        listenAddress = "127.0.0.1";
        inherit (cfg) retentionTime;
        stateDir = "prometheus";
        inherit scrapeConfigs;
      };

      services.grafana = {
        enable = true;
        settings = {
          server = {
            http_addr = "127.0.0.1";
            http_port = 3000;
            inherit (cfg.grafana) domain;
            root_url = "https://${cfg.grafana.domain}";
          };
          analytics.reporting_enabled = false;
          "auth.anonymous" = {
            enabled = true;
            org_role = "Viewer";
          };
          security = {
            cookie_secure = true;
            cookie_samesite = "strict";
          };
          users.allow_sign_up = false;
          dashboards.default_home_dashboard_path = "${dashboardDir}/nodes.json";
        };
        provision = {
          datasources.settings.datasources = [{
            name = "Prometheus";
            type = "prometheus";
            url = "http://127.0.0.1:9090";
            isDefault = true;
          }] ++ cfg.grafana.extraDatasources;
          dashboards.settings.providers = [{
            name = "Node Exporter";
            options.path = dashboardDir;
            disableDeletion = true;
          }];
        };
      };
    })
  ]);
}
