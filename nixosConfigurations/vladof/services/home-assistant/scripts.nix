{
  # Basic controls
  all_on = {
    alias = "On";
    sequence = [{
      service = "light.turn_on";
      target.entity_id = "light.all_lights";
      data.brightness_pct = 100;
    }];
  };
  all_off = {
    alias = "Off";
    sequence = [{
      service = "light.turn_off";
      target.entity_id = "light.all_lights";
    }];
  };

  # Brightness levels
  brightness_10 = {
    alias = "10%";
    sequence = [{
      service = "light.turn_on";
      target.entity_id = "{{ expand('light.all_lights') | selectattr('state', 'eq', 'on') | map(attribute='entity_id') | list }}";
      data.brightness_pct = 10;
    }];
  };
  brightness_25 = {
    alias = "25%";
    sequence = [{
      service = "light.turn_on";
      target.entity_id = "{{ expand('light.all_lights') | selectattr('state', 'eq', 'on') | map(attribute='entity_id') | list }}";
      data.brightness_pct = 25;
    }];
  };
  brightness_50 = {
    alias = "50%";
    sequence = [{
      service = "light.turn_on";
      target.entity_id = "{{ expand('light.all_lights') | selectattr('state', 'eq', 'on') | map(attribute='entity_id') | list }}";
      data.brightness_pct = 50;
    }];
  };
  brightness_75 = {
    alias = "75%";
    sequence = [{
      service = "light.turn_on";
      target.entity_id = "{{ expand('light.all_lights') | selectattr('state', 'eq', 'on') | map(attribute='entity_id') | list }}";
      data.brightness_pct = 75;
    }];
  };

  # Color temperatures
  temp_candle = {
    alias = "Candle";
    sequence = [{
      service = "light.turn_on";
      target.entity_id = "{{ expand('light.all_lights') | selectattr('state', 'eq', 'on') | map(attribute='entity_id') | list }}";
      data.color_temp_kelvin = 2200;
    }];
  };
  temp_cozy = {
    alias = "Cozy";
    sequence = [{
      service = "light.turn_on";
      target.entity_id = "{{ expand('light.all_lights') | selectattr('state', 'eq', 'on') | map(attribute='entity_id') | list }}";
      data.color_temp_kelvin = 2700;
    }];
  };
  temp_warm = {
    alias = "Warm";
    sequence = [{
      service = "light.turn_on";
      target.entity_id = "{{ expand('light.all_lights') | selectattr('state', 'eq', 'on') | map(attribute='entity_id') | list }}";
      data.color_temp_kelvin = 3000;
    }];
  };
  temp_neutral = {
    alias = "Neutral";
    sequence = [{
      service = "light.turn_on";
      target.entity_id = "{{ expand('light.all_lights') | selectattr('state', 'eq', 'on') | map(attribute='entity_id') | list }}";
      data.color_temp_kelvin = 4000;
    }];
  };
  temp_cool = {
    alias = "Cool";
    sequence = [{
      service = "light.turn_on";
      target.entity_id = "{{ expand('light.all_lights') | selectattr('state', 'eq', 'on') | map(attribute='entity_id') | list }}";
      data.color_temp_kelvin = 6500;
    }];
  };
  temp_daylight = {
    alias = "Daylight";
    sequence = [{
      service = "light.turn_on";
      target.entity_id = "{{ expand('light.all_lights') | selectattr('state', 'eq', 'on') | map(attribute='entity_id') | list }}";
      data.color_temp_kelvin = 5000;
    }];
  };

  # Scene scripts
  good_morning = {
    alias = "Good Morning";
    description = "All lights on at full brightness, Torgue on";
    sequence = [
      {
        service = "light.turn_on";
        target.entity_id = "light.all_lights";
        data = {
          brightness_pct = 100;
          color_temp_kelvin = 4000;
        };
      }
      {
        service = "switch.turn_on";
        target.entity_id = "switch.torgue";
      }
    ];
  };
  good_evening = {
    alias = "Good Evening";
    description = "Dim all lights to 20% warm";
    sequence = [{
      service = "light.turn_on";
      target.entity_id = "light.all_lights";
      data = {
        brightness_pct = 20;
        color_temp_kelvin = 2700;
      };
    }];
  };
  good_night = {
    alias = "Good Night";
    description = "Bedroom 10% warm, all other lights off";
    sequence = [
      {
        service = "light.turn_on";
        target.entity_id = "light.innr_rb_282_c";
        data = {
          brightness_pct = 10;
          color_temp_kelvin = 2700;
        };
      }
      {
        service = "light.turn_off";
        target.entity_id = "light.all_except_bedroom";
      }
    ];
  };
}
