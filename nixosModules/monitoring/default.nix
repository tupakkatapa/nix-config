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
  scrapeConfigs = (map
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
    monitoredHosts)
  ++ (lib.mapAttrsToList
    (name: target: {
      job_name = name;
      static_configs = [{
        targets = [ target ];
        labels.host = name;
      }];
    })
    cfg.server.extraExporters);

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

  # Audit log path may be redirected per host
  auditPath = config.security.auditd.settings.log_file or "/var/log/audit/audit.log";
in
{
  options.services.monitoring = {
    enable = lib.mkEnableOption "node exporter + Vector log shipper (clients)";

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open firewall for node exporter (9100/tcp).";
    };

    endpoint = lib.mkOption {
      type = lib.types.str;
      default = "10.42.0.8:3100";
      description = "host:port of the central Loki push API (vladof on WG by default).";
    };

    server = {
      enable = lib.mkEnableOption "central monitoring server: Prometheus + Grafana + Loki";

      retentionTime = lib.mkOption {
        type = lib.types.str;
        default = "30d";
        description = "Prometheus metrics retention.";
      };

      grafana.domain = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "FQDN for Grafana reverse proxy.";
      };

      extraExporters = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Additional node exporters to scrape: { host = \"address:port\"; }";
        example = { kaakkuri = "10.42.0.25:9100"; };
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [

    # Node exporter — every monitored host
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

    # Vector agent — every monitored host (ships journald + audit to central Loki)
    {
      services.vector = {
        enable = true;
        journaldAccess = true;
        settings = {
          sources = {
            journald = {
              type = "journald";
              current_boot_only = false;
            };
          } // lib.optionalAttrs config.security.auditd.enable {
            audit = {
              type = "file";
              include = [ auditPath ];
              read_from = "beginning";
            };
          };

          transforms.enrich = {
            type = "remap";
            inputs = [ "journald" ] ++ lib.optional config.security.auditd.enable "audit";
            source = ''
              .host = "${config.networking.hostName}"
              if !exists(.source_type) { .source_type = "journald" }
              if !exists(.unit) { .unit = ._SYSTEMD_UNIT || "unknown" }
            '';
          };

          sinks.loki = {
            type = "loki";
            inputs = [ "enrich" ];
            endpoint = "http://${cfg.endpoint}";
            encoding.codec = "json";
            labels = {
              host = "{{ host }}";
              source_type = "{{ source_type }}";
              unit = "{{ unit }}";
            };
            remove_label_fields = true;
            request.retry_attempts = 9999;
            buffer = {
              type = "disk";
              max_size = 1073741824;
            };
          };
        };
      };

      # Vector runs DynamicUser=true; module sets SupplementaryGroups to a single string.
      # Override with list when audit access is needed so both groups apply.
      security.auditd.settings.log_group = lib.mkIf config.security.auditd.enable "audit";
      users.groups.audit = lib.mkIf config.security.auditd.enable { };
      systemd.services.vector.serviceConfig.SupplementaryGroups =
        lib.mkIf config.security.auditd.enable [ "systemd-journal" "audit" ];
    }

    # Server bundle: Prometheus + Grafana + Loki
    (lib.mkIf cfg.server.enable {
      services.prometheus = {
        enable = true;
        port = 9090;
        listenAddress = "127.0.0.1";
        inherit (cfg.server) retentionTime;
        stateDir = "prometheus";
        inherit scrapeConfigs;
      };

      services.loki = {
        enable = true;
        # Server binary only; drops logcli/lokitool/loki-canary (~225 MB)
        package = pkgs.runCommand "loki-server" { } ''
          mkdir -p $out/bin
          cp ${pkgs.grafana-loki}/bin/loki $out/bin/loki
        '';
        dataDir = "/var/lib/loki";
        configuration = {
          auth_enabled = false;
          server = {
            http_listen_address = "0.0.0.0";
            http_listen_port = 3100;
            log_format = "json";
            log_level = "warn";
          };
          common = {
            ring = {
              instance_addr = "127.0.0.1";
              kvstore.store = "inmemory";
            };
            replication_factor = 1;
            path_prefix = "/var/lib/loki";
          };
          schema_config.configs = [{
            from = "2026-01-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }];
          storage_config.filesystem.directory = "/var/lib/loki/chunks";
          limits_config = {
            retention_period = "90d";
            allow_structured_metadata = true;
          };
          compactor = {
            working_directory = "/var/lib/loki/compactor";
            retention_enabled = true;
            delete_request_store = "filesystem";
          };
        };
      };

      # Internal-only ingress on WireGuard subnet
      networking.firewall.extraInputRules = ''
        ip saddr 10.42.0.0/24 tcp dport 3100 accept
      '';

      services.grafana = {
        enable = true;
        settings = {
          server = {
            http_addr = "127.0.0.1";
            http_port = 3000;
            inherit (cfg.server.grafana) domain;
            root_url = "https://${cfg.server.grafana.domain}";
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
          datasources.settings.datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              url = "http://127.0.0.1:9090";
              isDefault = true;
            }
            {
              name = "Loki";
              type = "loki";
              url = "http://127.0.0.1:3100";
              access = "proxy";
            }
          ];
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
