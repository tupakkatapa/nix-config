rec {
  lights = {
    bedside = "light.innr_rb_282_c";
    livingRoom = "light.innr_rb_282_c_2";
    dining = "light.innr_rb_282_c_3";
    hallway = "light.innr_rb_282_c_4";
  };

  allLights = builtins.attrValues lights;
  allExceptBedside = with lights; [ livingRoom dining hallway ];

  rgb = {
    corsair = "light.corsair_lighting_node_pro";
    motherboard = "light.asus_rog_strix_b450_f_gaming";
  };
  allRgb = builtins.attrValues rgb;

  group = {
    all = "light.all_lights";
    allExceptBedside = "light.all_except_bedside";
  };

  machines = {
    torgue = { ip = "10.42.0.7"; mac = "d4:5d:64:d1:12:52"; canShutdown = true; };
    maliwan = { ip = "10.42.0.9"; mac = "18:3d:2d:d2:de:41"; canShutdown = false; };
    kaakkuri = { ip = "10.42.0.25"; mac = "70:85:c2:b5:be:db"; canShutdown = false; };
  };
  machineOrder = [ "torgue" "maliwan" "kaakkuri" ];

  # Global settings
  globalSettings = {
    schedule_enabled = { name = "Schedule"; icon = "mdi:calendar-clock"; initial = true; };
    continuous_transitions = { name = "Continuous"; icon = "mdi:transition"; initial = true; };
    schedule_override = { name = "Override"; icon = "mdi:hand-back-right"; initial = false; };
  };

  buttonTransition = {
    name = "Button Transition";
    icon = "mdi:timer-sand";
    min = 0;
    max = 5;
    step = 0.5;
    initial = 1;
    unit_of_measurement = "s";
  };

  # Brightness presets (Page 2 buttons only)
  brightnessLevels = [
    { pct = 5; icon = "mdi:lightbulb-outline"; }
    { pct = 10; icon = "mdi:lightbulb-on-10"; }
    { pct = 20; icon = "mdi:lightbulb-on-20"; }
    { pct = 35; icon = "mdi:lightbulb-on-30"; }
    { pct = 50; icon = "mdi:lightbulb-on-50"; }
    { pct = 75; icon = "mdi:lightbulb-on-80"; }
  ];

  # Temperature presets (Page 2 buttons + schedule preset enum)
  temperatures = [
    { key = "daylight"; alias = "Daylight"; kelvin = 6500; icon = "mdi:white-balance-sunny"; }
    { key = "cool"; alias = "Cool"; kelvin = 5000; icon = "mdi:snowflake-thermometer"; }
    { key = "neutral"; alias = "Neutral"; kelvin = 4000; icon = "mdi:sun-thermometer-outline"; }
    { key = "warm"; alias = "Warm"; kelvin = 3000; icon = "mdi:sun-thermometer"; }
    { key = "cozy"; alias = "Cozy"; kelvin = 2700; icon = "mdi:lamp"; }
    { key = "candle"; alias = "Candle"; kelvin = 2200; icon = "mdi:candle"; }
  ];

  # Color presets (Page 2 buttons + schedule preset enum, use hs_color)
  colors = [
    { key = "moonlight"; alias = "Moonlight"; hs = [ 220 25 ]; icon = "mdi:moon-waning-crescent"; }
    { key = "twilight"; alias = "Twilight"; hs = [ 255 25 ]; icon = "mdi:weather-sunset-up"; }
    { key = "sunrise"; alias = "Sunrise"; hs = [ 32 22 ]; icon = "mdi:weather-sunset"; }
    { key = "sunset"; alias = "Sunset"; hs = [ 25 40 ]; icon = "mdi:weather-sunset-down"; }
    { key = "aurora"; alias = "Aurora"; hs = [ 145 35 ]; icon = "mdi:aurora"; }
  ];

  # Combined preset enum for schedule input_select
  allPresets = temperatures ++ colors;
  presetOptions = map (p: p.alias) allPresets;
  # Vanity presets (Page 2 two-tone buttons)
  vanityPresets = [
    { key = "purple"; alias = "Purple"; icon = "mdi:palette"; groupA = [ 133 2 85 ]; groupB = [ 51 0 102 ]; }
    { key = "ocean"; alias = "Ocean"; icon = "mdi:waves"; groupA = [ 0 102 255 ]; groupB = [ 0 204 204 ]; }
    { key = "nature"; alias = "Nature"; icon = "mdi:tree"; groupA = [ 0 153 51 ]; groupB = [ 51 204 0 ]; }
    { key = "lava"; alias = "Lava"; icon = "mdi:fire"; groupA = [ 255 30 0 ]; groupB = [ 255 100 0 ]; }
    { key = "circus"; alias = "Circus"; icon = "mdi:ferris-wheel"; groupA = [ 255 0 128 ]; groupB = [ 0 255 128 ]; }
  ];
  vanityGroupA = with lights; [ bedside hallway ];
  vanityGroupB = with lights; [ livingRoom dining ];

  # Schedule presets (apply all slot settings at once)
  defaultSchedulePreset = "circadian";
  schedulePresets = [
    {
      key = "realistic";
      alias = "Realistic";
      icon = "mdi:sun-clock";
      slots = {
        morning = { time = "06:30"; brightness = 40; preset = "Sunrise"; transition = -30; };
        midday = { time = "08:30"; brightness = 100; preset = "Daylight"; transition = -30; };
        evening = { time = "17:00"; brightness = 80; preset = "Neutral"; transition = -60; };
        dusk = { time = "19:30"; brightness = 50; preset = "Warm"; transition = -30; };
        night = { time = "21:00"; brightness = 25; preset = "Moonlight"; transition = -30; };
        bedtime = { time = "22:00"; brightness = 10; preset = "Candle"; transition = -30; };
        off = { time = "23:00"; transition = 0; };
      };
    }
    {
      key = "circadian";
      alias = "Circadian";
      icon = "mdi:heart-pulse";
      slots = {
        morning = { time = "07:00"; brightness = 100; preset = "Daylight"; transition = -30; };
        midday = { time = "09:00"; brightness = 100; preset = "Cool"; transition = -30; };
        evening = { time = "18:00"; brightness = 60; preset = "Neutral"; transition = -60; };
        dusk = { time = "20:00"; brightness = 30; preset = "Warm"; transition = -30; };
        night = { time = "21:30"; brightness = 10; preset = "Candle"; transition = -30; };
        bedtime = { time = "22:30"; brightness = 5; preset = "Candle"; transition = -30; };
        off = { time = "23:00"; transition = 0; };
      };
    }
    {
      key = "cozy";
      alias = "Cozy";
      icon = "mdi:sofa";
      slots = {
        morning = { time = "09:00"; brightness = 45; preset = "Warm"; transition = -30; };
        midday = { time = "11:00"; brightness = 55; preset = "Warm"; transition = -30; };
        evening = { time = "16:00"; brightness = 40; preset = "Cozy"; transition = -60; };
        dusk = { time = "18:30"; brightness = 30; preset = "Cozy"; transition = -30; };
        night = { time = "20:30"; brightness = 20; preset = "Candle"; transition = -30; };
        bedtime = { time = "21:30"; brightness = 10; preset = "Candle"; transition = -30; };
        off = { time = "23:00"; transition = 0; };
      };
    }
  ];

  # Schedule slots (defaults derived from defaultSchedulePreset)
  scheduleSlots =
    let
      preset = builtins.head (builtins.filter (p: p.key == defaultSchedulePreset) schedulePresets);
      withDefaults = slot:
        let s = preset.slots.${slot.key};
        in slot // {
          defaultTime = s.time;
          defaultTransition = s.transition;
          defaultPreset = s.preset or null;
          defaultBrightness = s.brightness or 0;
        };
    in
    map withDefaults [
      {
        key = "morning";
        alias = "Morning";
        icon = "mdi:weather-sunset-up";
        lights = with lights; [ bedside livingRoom dining hallway ];
        extraBooleans = [ ];
      }
      {
        key = "midday";
        alias = "Midday";
        icon = "mdi:white-balance-sunny";
        lights = with lights; [ livingRoom dining hallway ];
        extraBooleans = [ ];
      }
      {
        key = "evening";
        alias = "Evening";
        icon = "mdi:weather-sunset-down";
        lights = with lights; [ livingRoom dining hallway ];
        extraBooleans = [ ];
      }
      {
        key = "dusk";
        alias = "Dusk";
        icon = "mdi:weather-night-partly-cloudy";
        lights = with lights; [ livingRoom dining hallway ];
        extraBooleans = [ ];
      }
      {
        key = "night";
        alias = "Night";
        icon = "mdi:weather-night";
        lights = with lights; [ bedside livingRoom dining hallway ];
        extraBooleans = [ ];
      }
      {
        key = "bedtime";
        alias = "Bedtime";
        icon = "mdi:bed";
        lights = with lights; [ bedside ];
        extraBooleans = [ ];
      }
      {
        key = "off";
        alias = "Off";
        icon = "mdi:lightbulb-off";
        lights = [ ];
        extraBooleans = [ ];
      }
    ];

  # Wake PC
  wakePC = {
    enabled = { name = "Enabled"; icon = "mdi:power"; };
    time = { name = "Time"; icon = "mdi:clock-outline"; initial = "08:30"; };
  };

  # Helpers
  slotKeys = map (s: s.key) scheduleSlots;
  activeSlots = builtins.filter (s: s.key != "off") scheduleSlots;
}
