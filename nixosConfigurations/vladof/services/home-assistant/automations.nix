[
  # Sunrise: 30 min before alarm, gradually brighten lights
  {
    alias = "Sunrise";
    trigger = [{
      platform = "time_pattern";
      minutes = "/1";
    }];
    condition = [
      {
        condition = "state";
        entity_id = "input_boolean.morning_alarm";
        state = "on";
      }
      {
        condition = "template";
        value_template = "{{ now().strftime('%H:%M') == ((state_attr('input_datetime.morning_alarm_time', 'timestamp') | int - 1800) | timestamp_custom('%H:%M', false)) }}";
      }
    ];
    action = [
      {
        service = "light.turn_on";
        target.entity_id = "light.all_lights";
        data = {
          brightness_pct = 1;
          color_temp_kelvin = 2200;
        };
      }
      {
        service = "light.turn_on";
        target.entity_id = "light.all_lights";
        data = {
          brightness_pct = 100;
          color_temp_kelvin = 4000;
          transition = 1800;
        };
      }
    ];
  }
  # Wake Up: at alarm time, WOL + disable
  {
    alias = "Wake Up";
    trigger = [{
      platform = "time";
      at = "input_datetime.morning_alarm_time";
    }];
    condition = [{
      condition = "state";
      entity_id = "input_boolean.morning_alarm";
      state = "on";
    }];
    action = [
      {
        "if" = [{
          condition = "state";
          entity_id = "input_boolean.morning_alarm_wol";
          state = "on";
        }];
        "then" = [{
          service = "switch.turn_on";
          target.entity_id = "switch.torgue";
        }];
      }
      {
        "if" = [{
          condition = "state";
          entity_id = "input_boolean.morning_alarm_repeat";
          state = "off";
        }];
        "then" = [{
          service = "input_boolean.turn_off";
          target.entity_id = "input_boolean.morning_alarm";
        }];
      }
    ];
  }
]
