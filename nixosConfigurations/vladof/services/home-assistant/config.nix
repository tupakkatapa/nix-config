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
    { key = "purple"; alias = "Purple"; hs = [ 270 100 ]; icon = "mdi:palette"; }
    { key = "firelight"; alias = "Firelight"; hs = [ 18 65 ]; icon = "mdi:fireplace"; }
    { key = "overcast"; alias = "Overcast"; hs = [ 210 10 ]; icon = "mdi:weather-cloudy"; }
  ];

  # Combined preset enum for schedule input_select
  allPresets = temperatures ++ colors;
  presetOptions = map (p: p.alias) allPresets;

  # Schedule slots with circadian defaults
  scheduleSlots = [
    {
      key = "morning";
      alias = "Morning";
      icon = "mdi:weather-sunset-up";
      lights = with lights; [ bedside livingRoom dining hallway ];

      defaultTime = "07:00";
      defaultBrightness = 100;
      defaultPreset = "Daylight";
      defaultTransition = -30;
    }
    {
      key = "midday";
      alias = "Midday";
      icon = "mdi:white-balance-sunny";
      lights = with lights; [ livingRoom dining hallway ];

      defaultTime = "09:00";
      defaultBrightness = 100;
      defaultPreset = "Cool";
      defaultTransition = -30;
    }
    {
      key = "evening";
      alias = "Evening";
      icon = "mdi:weather-sunset-down";
      lights = with lights; [ livingRoom dining hallway ];

      defaultTime = "18:00";
      defaultBrightness = 60;
      defaultPreset = "Neutral";
      defaultTransition = -60;
    }
    {
      key = "dusk";
      alias = "Dusk";
      icon = "mdi:weather-night-partly-cloudy";
      lights = with lights; [ livingRoom dining hallway ];

      defaultTime = "20:00";
      defaultBrightness = 30;
      defaultPreset = "Warm";
      defaultTransition = -30;
    }
    {
      key = "night";
      alias = "Night";
      icon = "mdi:weather-night";
      lights = with lights; [ bedside livingRoom dining hallway ];

      defaultTime = "21:30";
      defaultBrightness = 10;
      defaultPreset = "Candle";
      defaultTransition = -30;
    }
    {
      key = "bedtime";
      alias = "Bedtime";
      icon = "mdi:bed";
      lights = with lights; [ bedside ];

      defaultTime = "22:30";
      defaultBrightness = 5;
      defaultPreset = "Candle";
      defaultTransition = -30;
    }
    {
      key = "off";
      alias = "Off";
      icon = "mdi:lightbulb-off";
      lights = [ ];

      defaultTime = "23:00";
      defaultBrightness = 0;
      defaultPreset = null;
      defaultTransition = 0;
    }
  ];

  # Time offset (shifts all schedule times, replaces preset switching)
  timeOffset = {
    name = "Time Offset";
    icon = "mdi:clock-fast";
    min = -1;
    max = 4;
    step = 0.5;
    initial = 0;
    unit_of_measurement = "h";
  };

  # Wake PC
  wakePC = {
    enabled = { name = "Enabled"; icon = "mdi:power"; };
    time = { name = "Time"; icon = "mdi:clock-outline"; initial = "08:30"; };
  };

  # Helpers
  slotKeys = map (s: s.key) scheduleSlots;
  activeSlots = builtins.filter (s: s.key != "off") scheduleSlots;
}
