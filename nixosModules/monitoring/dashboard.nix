{ mountpoints, watchedUnits }:
let
  # PromQL regex matching all real mountpoints from monitored hosts
  mountpointRegex = builtins.concatStringsSep "|" mountpoints;

  # PromQL regex matching watched systemd units
  hasWatchedUnits = watchedUnits != [ ];
  watchedUnitsRegex = builtins.concatStringsSep "|" watchedUnits;

  # Panel helpers
  timeseries = title: gridPos: fieldConfig: targets: {
    inherit title gridPos targets;
    type = "timeseries";
    fieldConfig = {
      defaults = { custom = { fillOpacity = 10; }; } // fieldConfig;
      overrides = [ ];
    };
    options = {
      legend.displayMode = "list";
      tooltip.mode = "multi";
    };
  };

  percent = { unit = "percentunit"; min = 0; max = 1; };

  query = expr: legendFormat: { inherit expr legendFormat; };
in
{
  annotations.list = [ ];
  editable = false;
  fiscalYearStartMonth = 0;
  graphTooltip = 1;
  links = [ ];
  schemaVersion = 39;
  tags = [ "node-exporter" ];
  templating.list = [ ];
  time = { from = "now-6h"; to = "now"; };
  title = "Nodes";
  uid = "nodes-overview";

  panels = [
    # Row 1: CPU + Memory
    (timeseries "CPU Usage" { h = 8; w = 12; x = 0; y = 0; } percent [
      (query ''1 - avg by (host) (rate(node_cpu_seconds_total{mode="idle"}[5m]))'' "{{host}}")
    ])

    (timeseries "Memory Usage" { h = 8; w = 12; x = 12; y = 0; } percent [
      (query ''1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)'' "{{host}}")
    ])

    # Row 2: Network + Disk I/O
    (timeseries "Network Traffic" { h = 8; w = 12; x = 0; y = 8; } { unit = "Bps"; } [
      (query ''sum by (host) (rate(node_network_receive_bytes_total{device!~"lo|veth.*|br-.*|wg.*"}[5m]))'' "{{host}} rx")
      (query ''-sum by (host) (rate(node_network_transmit_bytes_total{device!~"lo|veth.*|br-.*|wg.*"}[5m]))'' "{{host}} tx")
    ])

    (timeseries "Disk I/O" { h = 8; w = 12; x = 12; y = 8; } { unit = "Bps"; } [
      (query ''sum by (host) (rate(node_disk_read_bytes_total[5m]))'' "{{host}} read")
      (query ''-sum by (host) (rate(node_disk_written_bytes_total[5m]))'' "{{host}} write")
    ])

    # Row 3: Disk Usage + Load Average
    {
      title = "Disk Usage";
      type = "bargauge";
      gridPos = { h = 8; w = 12; x = 0; y = 16; };
      fieldConfig = {
        defaults = {
          inherit (percent) unit min max;
          thresholds.steps = [
            { color = "green"; value = null; }
            { color = "yellow"; value = 0.7; }
            { color = "red"; value = 0.9; }
          ];
        };
        overrides = [ ];
      };
      options = {
        orientation = "horizontal";
        displayMode = "gradient";
        reduceOptions.calcs = [ "lastNotNull" ];
      };
      targets = [
        (query ''1 - (node_filesystem_avail_bytes{mountpoint=~"${mountpointRegex}"} / node_filesystem_size_bytes{mountpoint=~"${mountpointRegex}"})'' "{{host}} {{mountpoint}}")
      ];
    }

    (timeseries "Load Average (1m)" { h = 8; w = 12; x = 12; y = 16; } { } [
      (query "node_load1" "{{host}}")
    ])

    # Row 4: Uptime + Failed Units
    {
      title = "Uptime";
      type = "stat";
      gridPos = { h = 4; w = 12; x = 0; y = 24; };
      fieldConfig = {
        defaults.unit = "s";
        overrides = [ ];
      };
      options = {
        reduceOptions.calcs = [ "lastNotNull" ];
        colorMode = "none";
        textMode = "auto";
      };
      targets = [ (query "time() - node_boot_time_seconds" "{{host}}") ];
    }

    {
      title = "Systemd Failed Units";
      type = "stat";
      gridPos = { h = 4; w = 12; x = 12; y = 24; };
      fieldConfig = {
        defaults.thresholds.steps = [
          { color = "green"; value = null; }
          { color = "red"; value = 1; }
        ];
        overrides = [ ];
      };
      options = {
        reduceOptions.calcs = [ "lastNotNull" ];
        colorMode = "value";
        textMode = "auto";
      };
      targets = [ (query ''node_systemd_units{state="failed"}'' "{{host}}") ];
    }
  ] ++ (if hasWatchedUnits then [
    # Row 5: Watched service status
    {
      title = "Service Status";
      type = "table";
      gridPos = { h = 10; w = 12; x = 0; y = 28; };
      fieldConfig = {
        defaults = { };
        overrides = [
          {
            matcher = { id = "byName"; options = "Value"; };
            properties = [
              {
                id = "mappings";
                value = [
                  { type = "value"; options."0" = { text = "OK"; color = "green"; index = 0; }; }
                  { type = "value"; options."1" = { text = "Failed"; color = "red"; index = 1; }; }
                ];
              }
              { id = "custom.cellOptions"; value = { type = "color-background"; }; }
              { id = "custom.width"; value = 70; }
            ];
          }
        ];
      };
      options = {
        showHeader = true;
        footer.enablePagination = true;
      };
      targets = [{
        expr = ''max by (host, name) (node_systemd_unit_state{name=~"(${watchedUnitsRegex})",name=~".+\\.service",state="failed"})'';
        legendFormat = "";
        instant = true;
        format = "table";
      }];
      transformations = [
        {
          id = "organize";
          options = {
            excludeByName = { Time = true; };
            renameByName = { host = "Host"; name = "Service"; Value = "Status"; };
            indexByName = { host = 0; name = 1; Value = 2; };
          };
        }
      ];
    }
  ] else [ ]);
}
