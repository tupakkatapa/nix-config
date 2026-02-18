cfg:
let
  take = n: list: builtins.genList (i: builtins.elemAt list i) n;
  drop = n: list: builtins.genList (i: builtins.elemAt list (i + n)) (builtins.length list - n);
  halfBrightness = builtins.length cfg.brightnessLevels / 2;
  halfTemps = builtins.length cfg.temperatures / 2;

  mkBrightnessButton = { pct, icon, ... }: {
    type = "button";
    name = "${toString pct}%";
    tap_action = { action = "call-service"; service = "script.brightness_${toString pct}"; };
    inherit icon;
  };

  mkTempButton = { key, alias, icon, ... }: {
    type = "button";
    name = alias;
    tap_action = { action = "call-service"; service = "script.temp_${key}"; };
    inherit icon;
  };

  mkColorButton = { key, alias, icon, ... }: {
    type = "button";
    name = alias;
    tap_action = { action = "call-service"; service = "script.color_${key}"; };
    inherit icon;
  };

  mkVanityButton = { key, alias, icon, ... }: {
    type = "button";
    name = alias;
    tap_action = { action = "call-service"; service = "script.vanity_${key}"; };
    inherit icon;
  };

  mkSceneButton = slot: {
    type = "button";
    name = slot.alias;
    tap_action = { action = "call-service"; service = "script.scene_${slot.key}"; };
    inherit (slot) icon;
  };

  mkMachineEntities = name: [
    { entity = "switch.${name}"; secondary_info = "last-changed"; }
  ];

  # Schedule settings card entries per slot
  mkSlotCard = slot: {
    type = "entities";
    title = slot.alias;
    show_header_toggle = false;
    entities =
      [ "input_boolean.sched_${slot.key}_enabled" ]
      ++ [ "input_datetime.sched_${slot.key}_time" ]
      ++ (if slot.defaultPreset != null then [
        "input_number.sched_${slot.key}_brightness"
        "input_select.sched_${slot.key}_preset"
      ] else [ ])
      ++ (if slot.key != "off" then
        [ "input_number.sched_${slot.key}_transition" ]
      else [ ])
      ++ map (b: "input_boolean.${b.key}") slot.extraBooleans;
  };
in
{
  title = "Home";
  views = [
    # View 1: Home
    {
      title = "Home";
      cards = [
        # Active schedule sensor
        {
          type = "entities";
          entities = [{
            entity = "sensor.active_schedule";
            name = "Schedule";
          }];
        }
        # Weather
        {
          type = "weather-forecast";
          entity = "weather.forecast_home";
          forecast_type = "daily";
        }
        # Scene buttons row 1
        {
          type = "horizontal-stack";
          cards = map mkSceneButton (take 4 cfg.scheduleSlots);
        }
        # Scene buttons row 2
        {
          type = "horizontal-stack";
          cards = map mkSceneButton (drop 4 cfg.scheduleSlots)
            ++ [{
            type = "button";
            name = "Resume";
            tap_action = { action = "call-service"; service = "script.resume_schedule"; };
            icon = "mdi:play";
          }];
        }
        # Individual light controls
        {
          type = "horizontal-stack";
          cards = [
            { type = "light"; entity = cfg.lights.bedside; name = "Bedside"; }
            { type = "light"; entity = cfg.lights.livingRoom; name = "Living Room"; }
          ];
        }
        {
          type = "horizontal-stack";
          cards = [
            { type = "light"; entity = cfg.lights.dining; name = "Dining"; }
            { type = "light"; entity = cfg.lights.hallway; name = "Hallway"; }
          ];
        }
        # OpenRGB devices on torgue
        {
          type = "entities";
          title = "RGB";
          entities = [
            "light.asus_rog_strix_b450_f_gaming"
            "light.corsair_lighting_node_pro"
          ];
        }
        # Machines
        {
          type = "entities";
          title = "Machines";
          entities = builtins.concatMap mkMachineEntities cfg.machineOrder;
        }
      ];
    }
    # View 2: Quick Presets
    {
      title = "Presets";
      icon = "mdi:lightbulb-group";
      cards = [
        # All lights slider
        {
          type = "light";
          entity = cfg.group.all;
          name = "All Lights";
        }
        # Brightness row 1: Off + first half
        {
          type = "horizontal-stack";
          cards = [
            {
              type = "button";
              name = "0%";
              tap_action = { action = "call-service"; service = "script.all_off"; };
              icon = "mdi:lightbulb-off";
            }
          ] ++ map mkBrightnessButton (take halfBrightness cfg.brightnessLevels);
        }
        # Brightness row 2: second half + 100%
        {
          type = "horizontal-stack";
          cards = map mkBrightnessButton (drop halfBrightness cfg.brightnessLevels) ++ [
            {
              type = "button";
              name = "100%";
              tap_action = { action = "call-service"; service = "script.all_on"; };
              icon = "mdi:lightbulb-on";
            }
          ];
        }
        # Temperature row 1: cool
        {
          type = "horizontal-stack";
          cards = map mkTempButton (take halfTemps cfg.temperatures);
        }
        # Temperature row 2: warm
        {
          type = "horizontal-stack";
          cards = map mkTempButton (drop halfTemps cfg.temperatures);
        }
        # Color row
        {
          type = "horizontal-stack";
          cards = map mkColorButton cfg.colors;
        }
        # Vanity row
        {
          type = "horizontal-stack";
          cards = map mkVanityButton cfg.vanityPresets;
        }
      ];
    }
    # View 3: Schedule Settings
    {
      title = "Schedule";
      icon = "mdi:calendar-clock";
      cards = [
        # Global toggles
        {
          type = "entities";
          title = "Settings";
          show_header_toggle = false;
          entities = [
            "input_boolean.schedule_enabled"
            "input_boolean.continuous_transitions"
            "input_select.schedule_preset"
            "input_number.button_transition"
          ];
        }
        # Wake PC
        {
          type = "entities";
          title = "Wake PC";
          show_header_toggle = false;
          entities = [
            "input_boolean.wake_pc"
            "input_datetime.wake_pc_time"
          ];
        }
      ] ++ map mkSlotCard cfg.scheduleSlots;
    }
  ];
}
