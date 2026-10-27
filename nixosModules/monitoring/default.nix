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

      grafana.enable = lib.mkEnableOption "Grafana" // { default = true; };

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
        # The bundled OpenSSL's version string names the compiler, which would
        # otherwise pull gcc into the closure
        package = lib.mkDefault (pkgs.runCommand pkgs.vector.name
          {
            nativeBuildInputs = [ pkgs.removeReferencesTo ];
            disallowedReferences = [ pkgs.stdenv.cc ];
            inherit (pkgs.vector) meta;
          } ''
          cp -r ${pkgs.vector} $out
          chmod -R u+w $out
          remove-references-to -t ${pkgs.stdenv.cc} $out/bin/vector
        '');
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

      # base.nix forces DynamicUser=false, without a static user this is root
      users.users.vector = {
        isSystemUser = true;
        group = "vector";
      };
      users.groups.vector = { };

      security.auditd.settings.log_group = lib.mkIf config.security.auditd.enable "audit";
      users.groups.audit = lib.mkIf config.security.auditd.enable { };
      systemd.services.vector.serviceConfig = {
        User = "vector";
        Group = "vector";
        # Upstream sets a single string, mkForce so both apply
        SupplementaryGroups = lib.mkForce
          ([ "systemd-journal" ] ++ lib.optional config.security.auditd.enable "audit");
        CapabilityBoundingSet = [ "" ];
        AmbientCapabilities = lib.mkForce [ "" ];
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        RestrictSUIDSGID = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" "~@privileged" ];
      };
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

      # Internal-only ingress on LAN, extraInputRules is nftables-only
      networking.firewall = lib.mkMerge [
        (lib.mkIf config.networking.nftables.enable {
          extraInputRules = ''
            ip saddr 10.42.0.0/24 tcp dport 3100 accept
          '';
        })
        (lib.mkIf (!config.networking.nftables.enable) {
          extraCommands = ''
            iptables -I nixos-fw -p tcp --dport 3100 -s 10.42.0.0/24 -j nixos-fw-accept
          '';
          extraStopCommands = ''
            iptables -D nixos-fw -p tcp --dport 3100 -s 10.42.0.0/24 -j nixos-fw-accept 2>/dev/null || true
          '';
        })
      ];

      # Reassert ownership on persisted @loki each boot (unpinned uid drifts)
      systemd.tmpfiles.rules = [ "Z /var/lib/loki - loki loki - -" ];

      services.grafana = lib.mkIf cfg.server.grafana.enable {
        enable = true;
        settings = {
          server = {
            http_addr = "127.0.0.1";
            http_port = 3000;
            inherit (cfg.server.grafana) domain;
            root_url = "https://${cfg.server.grafana.domain}";
          };
          analytics.reporting_enabled = false;
          # Grafana proxies the Loki datasource, so this would expose all logs
          "auth.anonymous".enabled = false;
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
