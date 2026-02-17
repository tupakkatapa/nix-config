{
  title = "Home";
  views = [
    {
      title = "Home";
      cards = [
        # Weather
        {
          type = "weather-forecast";
          entity = "weather.forecast_home";
          show_forecast = true;
        }
        # Scene buttons
        {
          type = "horizontal-stack";
          cards = [
            {
              type = "button";
              name = "Morning";
              tap_action = { action = "call-service"; service = "script.good_morning"; };
              icon = "mdi:weather-sunny";
            }
            {
              type = "button";
              name = "Evening";
              tap_action = { action = "call-service"; service = "script.good_evening"; };
              icon = "mdi:weather-sunset";
            }
            {
              type = "button";
              name = "Night";
              tap_action = { action = "call-service"; service = "script.good_night"; };
              icon = "mdi:weather-night";
            }
            {
              type = "button";
              name = "Sleep";
              tap_action = { action = "call-service"; service = "script.good_sleep"; };
              icon = "mdi:sleep";
            }
          ];
        }
        # Individual light controls
        {
          type = "horizontal-stack";
          cards = [
            { type = "light"; entity = "light.innr_rb_282_c"; name = "Bedroom"; }
            { type = "light"; entity = "light.innr_rb_282_c_2"; name = "Living Room"; }
          ];
        }
        {
          type = "horizontal-stack";
          cards = [
            { type = "light"; entity = "light.innr_rb_282_c_3"; name = "Kitchen"; }
            { type = "light"; entity = "light.innr_rb_282_c_4"; name = "Hallway"; }
          ];
        }
        # Wake up schedule
        {
          type = "entities";
          title = "Wake Up";
          show_header_toggle = false;
          entities = [
            "input_boolean.morning_alarm"
            "input_datetime.morning_alarm_time"
            "input_boolean.morning_alarm_repeat"
            "input_boolean.morning_alarm_wol"
          ];
        }
        # Wind down schedule
        {
          type = "entities";
          title = "Wind Down";
          show_header_toggle = false;
          entities = [
            "input_boolean.wind_down"
            "input_datetime.wind_down_time"
            "input_boolean.wind_down_repeat"
          ];
        }
        # Wake on LAN
        {
          type = "entities";
          title = "Wake on LAN";
          entities = [ "switch.maliwan" "switch.torgue" "switch.kaakkuri" ];
        }
      ];
    }
    {
      title = "Lights";
      icon = "mdi:lightbulb-group";
      cards = [
        # All lights slider
        {
          type = "light";
          entity = "light.all_lights";
          name = "All Lights";
        }
        # Brightness controls row 1
        {
          type = "horizontal-stack";
          cards = [
            {
              type = "button";
              name = "Off";
              tap_action = { action = "call-service"; service = "script.all_off"; };
              icon = "mdi:lightbulb-off";
            }
            {
              type = "button";
              name = "10%";
              tap_action = { action = "call-service"; service = "script.brightness_10"; };
              icon = "mdi:lightbulb-on-10";
            }
            {
              type = "button";
              name = "25%";
              tap_action = { action = "call-service"; service = "script.brightness_25"; };
              icon = "mdi:lightbulb-on-20";
            }
          ];
        }
        # Brightness controls row 2
        {
          type = "horizontal-stack";
          cards = [
            {
              type = "button";
              name = "50%";
              tap_action = { action = "call-service"; service = "script.brightness_50"; };
              icon = "mdi:lightbulb-on-50";
            }
            {
              type = "button";
              name = "75%";
              tap_action = { action = "call-service"; service = "script.brightness_75"; };
              icon = "mdi:lightbulb-on-80";
            }
            {
              type = "button";
              name = "100%";
              tap_action = { action = "call-service"; service = "script.all_on"; };
              icon = "mdi:lightbulb-on";
            }
          ];
        }
        # Temperature controls row 1
        {
          type = "horizontal-stack";
          cards = [
            {
              type = "button";
              name = "Cool";
              tap_action = { action = "call-service"; service = "script.temp_cool"; };
              icon = "mdi:snowflake-thermometer";
            }
            {
              type = "button";
              name = "Daylight";
              tap_action = { action = "call-service"; service = "script.temp_daylight"; };
              icon = "mdi:white-balance-sunny";
            }
            {
              type = "button";
              name = "Neutral";
              tap_action = { action = "call-service"; service = "script.temp_neutral"; };
              icon = "mdi:sun-thermometer-outline";
            }
          ];
        }
        # Temperature controls row 2
        {
          type = "horizontal-stack";
          cards = [
            {
              type = "button";
              name = "Warm";
              tap_action = { action = "call-service"; service = "script.temp_warm"; };
              icon = "mdi:sun-thermometer";
            }
            {
              type = "button";
              name = "Cozy";
              tap_action = { action = "call-service"; service = "script.temp_cozy"; };
              icon = "mdi:lamp";
            }
            {
              type = "button";
              name = "Candle";
              tap_action = { action = "call-service"; service = "script.temp_candle"; };
              icon = "mdi:candle";
            }
          ];
        }
        # Vanity presets
        {
          type = "horizontal-stack";
          cards = [
            {
              type = "button";
              name = "Purple";
              tap_action = { action = "call-service"; service = "script.vanity_purple"; };
              icon = "mdi:palette";
            }
            {
              type = "button";
              name = "Ocean";
              tap_action = { action = "call-service"; service = "script.vanity_ocean"; };
              icon = "mdi:waves";
            }
            {
              type = "button";
              name = "Sunset";
              tap_action = { action = "call-service"; service = "script.vanity_sunset"; };
              icon = "mdi:weather-sunset";
            }
          ];
        }
      ];
    }
  ];
}
