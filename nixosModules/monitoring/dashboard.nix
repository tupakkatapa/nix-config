{ mountpoints, ... }:
let
  # PromQL regex matching all real mountpoints from monitored hosts
  mountpointRegex = builtins.concatStringsSep "|" mountpoints;

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
    # Row 1: Health at a glance
    {
      title = "Uptime";
      type = "stat";
      gridPos = { h = 4; w = 12; x = 0; y = 0; };
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
      gridPos = { h = 4; w = 12; x = 12; y = 0; };
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

    # Row 2: CPU + Memory
    (timeseries "CPU Usage" { h = 8; w = 12; x = 0; y = 4; } percent [
      (query ''1 - avg by (host) (rate(node_cpu_seconds_total{mode="idle"}[5m]))'' "{{host}}")
    ])

    (timeseries "Memory Usage" { h = 8; w = 12; x = 12; y = 4; } percent [
      (query ''1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)'' "{{host}}")
    ])

    # Row 3: Network + Disk I/O
    (timeseries "Network Traffic" { h = 8; w = 12; x = 0; y = 12; } { unit = "Bps"; } [
      (query ''sum by (host) (rate(node_network_receive_bytes_total{device!~"lo|veth.*|br-.*|wg.*"}[5m]))'' "{{host}} rx")
      (query ''-sum by (host) (rate(node_network_transmit_bytes_total{device!~"lo|veth.*|br-.*|wg.*"}[5m]))'' "{{host}} tx")
    ])

    (timeseries "Disk I/O" { h = 8; w = 12; x = 12; y = 12; } { unit = "Bps"; } [
      (query ''sum by (host) (rate(node_disk_read_bytes_total[5m]))'' "{{host}} read")
      (query ''-sum by (host) (rate(node_disk_written_bytes_total[5m]))'' "{{host}} write")
    ])

    # Row 4: Disk Usage + Load Average
    {
      title = "Disk Usage";
      type = "bargauge";
      gridPos = { h = 8; w = 12; x = 0; y = 20; };
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

    (timeseries "Load Average (1m)" { h = 8; w = 12; x = 12; y = 20; } { } [
      (query "node_load1" "{{host}}")
    ])

    # Row 5: Temperatures
    (timeseries "Temperatures" { h = 8; w = 24; x = 0; y = 28; } { unit = "celsius"; } [
      (query "node_hwmon_temp_celsius" "{{host}} {{chip}} {{sensor}}")
    ])

    # Row 6: Failed unit details
    {
      title = "Failed Units";
      type = "table";
      gridPos = { h = 6; w = 24; x = 0; y = 36; };
      fieldConfig = {
        defaults = { };
        overrides = [ ];
      };
      options = {
        showHeader = true;
        footer.enablePagination = false;
      };
      targets = [{
        expr = ''node_systemd_unit_state{state="failed"} == 1'';
        legendFormat = "";
        instant = true;
        format = "table";
      }];
      transformations = [
        {
          id = "organize";
          options = {
            excludeByName = { Time = true; Value = true; state = true; "__name__" = true; instance = true; job = true; };
            renameByName = { host = "Host"; name = "Unit"; };
            indexByName = { host = 0; name = 1; };
          };
        }
      ];
    }
  ];
}
