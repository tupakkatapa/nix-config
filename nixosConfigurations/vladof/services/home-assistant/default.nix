{ dataDir
, haConfig
, config
}:
let
  inherit (haConfig) port;
  hassSshKey = config.age.secrets.hass-ssh-key.path;

  cfg = import ./config.nix;
  dashboard = import ./dashboard.nix cfg;
  scripts = import ./scripts.nix cfg;
  automations = import ./automations.nix cfg;

  # Global settings → input_boolean
  globalInputBooleans = builtins.mapAttrs
    (_: v: {
      inherit (v) name icon;
      inherit (v) initial;
    })
    cfg.globalSettings;

  # Button transition → input_number
  globalInputNumbers = {
    button_transition = {
      inherit (cfg.buttonTransition) name icon min max step initial unit_of_measurement;
    };
  };

  # Per-slot input helpers
  slotInputDatetimes = builtins.listToAttrs (
    map
      (s: {
        name = "sched_${s.key}_time";
        value = {
          name = "Time";
          has_date = false;
          has_time = true;
          icon = "mdi:clock-outline";
          initial = s.defaultTime;
        };
      })
      cfg.scheduleSlots
  );

  slotInputNumbers = builtins.listToAttrs (
    builtins.concatMap
      (s:
        if s.key == "off" then [ ]
        else [
          {
            name = "sched_${s.key}_brightness";
            value = {
              name = "Brightness";
              icon = "mdi:brightness-percent";
              min = 0;
              max = 100;
              step = 5;
              initial = s.defaultBrightness;
              unit_of_measurement = "%";
            };
          }
          {
            name = "sched_${s.key}_transition";
            value = {
              name = "Transition";
              icon = "mdi:timer-sand";
              min = -60;
              max = 60;
              step = 5;
              initial = s.defaultTransition;
              unit_of_measurement = "min";
            };
          }
        ])
      cfg.scheduleSlots
  );

  slotInputSelects = builtins.listToAttrs (
    builtins.concatMap
      (s:
        if s.defaultPreset != null then [{
          name = "sched_${s.key}_preset";
          value = {
            name = "Preset";
            icon = "mdi:palette";
            options = cfg.presetOptions;
            initial = s.defaultPreset;
          };
        }]
        else [ ])
      cfg.scheduleSlots
  );

  slotEnabledBooleans = builtins.listToAttrs (
    map
      (s: {
        name = "sched_${s.key}_enabled";
        value = { name = "Enabled"; icon = "mdi:power"; initial = true; };
      })
      cfg.scheduleSlots
  );

  slotExtraBooleans = builtins.listToAttrs (
    builtins.concatMap
      (s: map (b: { name = b.key; value = { inherit (b) name icon; }; }) s.extraBooleans)
      cfg.scheduleSlots
  );

  # Template sensor: active slot name
  slotList = builtins.concatStringsSep ", " (
    map (s: "('${s.alias}', states('input_datetime.sched_${s.key}_time'))") cfg.scheduleSlots
  );
  activeSlotTemplate = ''
    {%- set ns = namespace(active='Off') -%}
    {%- set now_t = now().strftime('%H:%M:%S') -%}
    {%- set slots = [${slotList}] | sort(attribute='1') -%}
    {%- for name, time in slots | reverse -%}
      {%- if now_t >= time and ns.active == 'Off' -%}
        {%- set ns.active = name -%}
      {%- endif -%}
    {%- endfor -%}
    {%- if states('input_boolean.schedule_override') == 'on' -%}
      Override
    {%- else -%}
      {{ ns.active }}
    {%- endif -%}'';
in
{
  services.home-assistant = {
    enable = true;
    openFirewall = true;
    configWritable = false;
    configDir = "${dataDir}/home/home-assistant/appdata/hass";

    extraComponents = [
      "default_config"
      "met"
      "wake_on_lan"
      "openrgb"
      "zha"
    ];

    lovelaceConfig = dashboard;

    config = {
      homeassistant = {
        name = "Home";
        unit_system = "metric";
        time_zone = "Europe/Helsinki";
        latitude = 65.0;
        longitude = 25.5;
        external_url = "https://home.coditon.com";
        internal_url = "https://home.coditon.com";
      };

      http = {
        server_port = port;
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "10.42.0.0/24"
          "10.42.1.0/24"
          "172.16.16.0/24"
          "169.254.0.0/16"
        ];
      };

      wake_on_lan = { };

      shell_command = builtins.listToAttrs (
        builtins.concatMap
          (name:
            let m = cfg.machines.${name}; in
            if m.canShutdown then [{
              inherit name;
              value = "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i ${hassSshKey} service@${m.ip}";
            }]
            else [ ])
          cfg.machineOrder
      );

      template = [{
        sensor = [{
          name = "Active Schedule";
          state = activeSlotTemplate;
          icon = "mdi:calendar-clock";
        }];
      }];

      input_boolean = globalInputBooleans // slotEnabledBooleans // slotExtraBooleans // {
        wake_pc = { inherit (cfg.wakePC.enabled) name icon; };
        applying_preset = { name = "Applying Preset"; initial = false; };
      };
      input_datetime = slotInputDatetimes // {
        wake_pc_time = {
          inherit (cfg.wakePC.time) name icon initial;
          has_date = false;
          has_time = true;
        };
      };
      input_number = globalInputNumbers // slotInputNumbers;
      input_select = slotInputSelects // {
        schedule_preset = {
          name = "Preset";
          icon = "mdi:palette-swatch";
          options = (map (p: p.alias) cfg.schedulePresets) ++ [ "Custom" ];
          initial =
            let
              match = builtins.head (builtins.filter (p: p.key == cfg.defaultSchedulePreset) cfg.schedulePresets);
            in
            match.alias;
        };
      };

      light = [
        {
          platform = "group";
          name = "All Lights";
          entities = cfg.allLights;
        }
        {
          platform = "group";
          name = "All Except Bedside";
          entities = cfg.allExceptBedside;
        }
      ];

      switch = map
        (name:
          let m = cfg.machines.${name}; in
          {
            platform = "wake_on_lan";
            inherit name;
            inherit (m) mac;
            broadcast_address = "10.42.0.255";
          } // (if m.canShutdown then {
            turn_off.service = "shell_command.${name}";
          } else { }))
        cfg.machineOrder;

      automation = automations;
      script = scripts;
    };
  };

  # Ensure data directory exists with correct ownership
  systemd.tmpfiles.rules = [
    "d ${dataDir}/home/home-assistant/appdata/hass 755 hass hass -"
    "Z ${dataDir}/home/home-assistant/appdata/hass - hass hass -"
  ];
}
