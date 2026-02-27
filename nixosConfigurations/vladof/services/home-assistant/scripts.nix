cfg:
let
  btnTransition = "{{ states('input_number.button_transition') | float }}";
  onLights = "{{ expand('${cfg.group.all}') | selectattr('state', 'eq', 'on') | map(attribute='entity_id') | list or expand('${cfg.group.all}') | map(attribute='entity_id') | list }}";
  setOverride = {
    service = "input_boolean.turn_on";
    target.entity_id = "input_boolean.schedule_override";
  };

  # Brightness button scripts (Page 2, only affect on lights)
  mkBrightness = { pct, ... }: {
    name = "brightness_${toString pct}";
    value = {
      alias = "${toString pct}%";
      sequence = [
        {
          service = "light.turn_on";
          target.entity_id = onLights;
          data = {
            transition = btnTransition;
            brightness_pct = pct;
          };
        }
        setOverride
      ];
    };
  };

  # Temperature button scripts (Page 2, only affect on lights)
  mkTemperature = { key, alias, kelvin, ... }: {
    name = "temp_${key}";
    value = {
      inherit alias;
      sequence = [
        {
          service = "light.turn_on";
          target.entity_id = onLights;
          data = {
            transition = btnTransition;
            color_temp_kelvin = kelvin;
          };
        }
        setOverride
      ];
    };
  };

  # Color button scripts (Page 2, only affect on lights, use hs_color)
  mkColor = { key, alias, hs, ... }: {
    name = "color_${key}";
    value = {
      inherit alias;
      sequence = [
        {
          service = "light.turn_on";
          target.entity_id = onLights;
          data = {
            transition = btnTransition;
            hs_color = hs;
          };
        }
        setOverride
      ];
    };
  };

  # Scene scripts per slot (read from helpers, optionally set override)
  mkScene = slot: {
    name = "scene_${slot.key}";
    value = {
      inherit (slot) alias;
      fields.skip_override = {
        description = "Skip setting schedule override";
        default = false;
        selector.boolean = { };
      };
      sequence =
        # Turn on slot lights with preset from helper
        (if slot.lights != [ ] then
          let
            presetEntity = "states('input_select.sched_${slot.key}_preset')";
            brightnessEntity = "states('input_number.sched_${slot.key}_brightness') | int";
          in
          [{
            service = "light.turn_on";
            target.entity_id = slot.lights;
            data = {
              transition = btnTransition;
              brightness_pct = "{{ ${brightnessEntity} }}";
            };
          }
            # Apply preset (color or temperature)
            {
              choose = [{
                conditions = [{
                  condition = "template";
                  value_template = builtins.concatStringsSep "" [
                    "{{ ${presetEntity} in ["
                    (builtins.concatStringsSep ", " (map (c: "'${c.alias}'") cfg.colors))
                    "] }}"
                  ];
                }];
                sequence =
                  let
                    hsLookup = builtins.concatStringsSep ", " (
                      map (c: "'${c.alias}': [${toString (builtins.elemAt c.hs 0)}, ${toString (builtins.elemAt c.hs 1)}]") cfg.colors
                    );
                  in
                  [{
                    service = "light.turn_on";
                    target.entity_id = slot.lights;
                    data = {
                      transition = btnTransition;
                      hs_color = "{{ {${hsLookup}}[${presetEntity}] }}";
                    };
                  }];
              }];
              default =
                let
                  kelvinLookup = builtins.concatStringsSep ", " (
                    map (t: "'${t.alias}': ${toString t.kelvin}") cfg.temperatures
                  );
                in
                [{
                  service = "light.turn_on";
                  target.entity_id = slot.lights;
                  data = {
                    transition = btnTransition;
                    color_temp_kelvin = "{{ {${kelvinLookup}}[${presetEntity}] }}";
                  };
                }];
            }]
          # Turn off lights not in this slot
          ++ (
            let
              exitLights = builtins.filter (l: !(builtins.elem l slot.lights)) cfg.allLights;
            in
            if exitLights != [ ] then [{
              service = "light.turn_off";
              target.entity_id = exitLights;
              data = { transition = btnTransition; };
            }]
            else [ ]
          )
        else
        # Off slot: turn off all
          [{
            service = "light.turn_off";
            target.entity_id = cfg.group.all;
            data = { transition = btnTransition; };
          }])
        # Set override unless explicitly skipped
        ++ [{
          "if" = [{
            condition = "template";
            value_template = "{{ not skip_override }}";
          }];
          "then" = [ setOverride ];
        }];
    };
  };

  # Resume schedule script
  resumeSchedule =
    let
      slotTimeChecks = builtins.concatStringsSep ", " (
        map (s: "('${s.key}', (state_attr('input_datetime.sched_${s.key}_time', 'timestamp') | int + time_offset) % 86400)") cfg.scheduleSlots
      );
      resolveSlot = ''
        {%- set time_offset = states('input_number.schedule_time_offset') | float * 3600 | int -%}
        {%- set ns = namespace(active='off') -%}
        {%- set now_s = now().hour * 3600 + now().minute * 60 + now().second -%}
        {%- set slots = [${slotTimeChecks}] | sort(attribute='1') -%}
        {%- for key, ts in slots | reverse -%}
          {%- if now_s >= ts and ns.active == 'off' -%}
            {%- set ns.active = key -%}
          {%- endif -%}
        {%- endfor -%}
        script.scene_{{ ns.active }}'';
    in
    {
      alias = "Resume Schedule";
      sequence = [
        {
          service = "input_boolean.turn_off";
          target.entity_id = "input_boolean.schedule_override";
        }
        {
          service = "script.turn_on";
          target.entity_id = resolveSlot;
          data.variables.skip_override = true;
        }
      ];
    };
in
{
  # Basic controls
  all_on = {
    alias = "On";
    sequence = [
      {
        service = "light.turn_on";
        target.entity_id = cfg.group.all;
        data = {
          transition = btnTransition;
          brightness_pct = 100;
        };
      }
      setOverride
    ];
  };
  all_off = {
    alias = "Off";
    sequence = [
      {
        service = "light.turn_off";
        target.entity_id = cfg.group.all;
        data = { transition = btnTransition; };
      }
      setOverride
    ];
  };

  resume_schedule = resumeSchedule;
}
// builtins.listToAttrs (map mkBrightness cfg.brightnessLevels)
// builtins.listToAttrs (map mkTemperature cfg.temperatures)
// builtins.listToAttrs (map mkColor cfg.colors)
  // builtins.listToAttrs (map mkScene cfg.scheduleSlots)
