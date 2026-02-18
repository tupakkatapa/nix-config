cfg:
let
  btnTransition = "{{ states('input_number.button_transition') | float }}";

  # Resolve preset to light.turn_on data (Jinja2 template)

  # Build the choose block for applying a preset
  mkPresetAction = slotKey: lights: transitionExpr: {
    choose = [{
      conditions = [{
        condition = "template";
        value_template =
          let
            colorAliases = builtins.concatStringsSep ", " (map (c: "'${c.alias}'") cfg.colors);
          in
          "{{ states('input_select.sched_${slotKey}_preset') in [${colorAliases}] }}";
      }];
      sequence =
        let
          hsMap = builtins.concatStringsSep ", " (
            map (c: "'${c.alias}': [${toString (builtins.elemAt c.hs 0)}, ${toString (builtins.elemAt c.hs 1)}]") cfg.colors
          );
        in
        [{
          service = "light.turn_on";
          target.entity_id = lights;
          data = {
            transition = transitionExpr;
            hs_color = "{{ {${hsMap}}[states('input_select.sched_${slotKey}_preset')] }}";
          };
        }];
    }];
    default =
      let
        kelvinMap = builtins.concatStringsSep ", " (
          map (t: "'${t.alias}': ${toString t.kelvin}") cfg.temperatures
        );
      in
      [{
        service = "light.turn_on";
        target.entity_id = lights;
        data = {
          transition = transitionExpr;
          color_temp_kelvin = "{{ {${kelvinMap}}[states('input_select.sched_${slotKey}_preset')] }}";
        };
      }];
  };

  # Lights not in current slot (order-independent)
  exitingLights = slot:
    builtins.filter (l: !(builtins.elem l slot.lights)) cfg.allLights;

  # Generate automation for a single slot
  mkSlotAutomation = slot:
    let
      transitionEntity = "states('input_number.sched_${slot.key}_transition') | int";
      absTransition = "{{ (${transitionEntity}) | abs * 60 }}";
      brightnessEntity = "states('input_number.sched_${slot.key}_brightness') | int";
      exiting = exitingLights slot;
    in
    if slot.key == "off" then
    # Off slot: simple turn off at exact time
      [{
        alias = "Schedule: Off";
        mode = "restart";
        trigger = [{
          platform = "time";
          at = "input_datetime.sched_off_time";
        }];
        condition = [
          { condition = "state"; entity_id = "input_boolean.schedule_enabled"; state = "on"; }
          { condition = "state"; entity_id = "input_boolean.sched_off_enabled"; state = "on"; }
          { condition = "state"; entity_id = "input_boolean.schedule_override"; state = "off"; }
        ];
        action = [{
          service = "light.turn_off";
          target.entity_id = cfg.group.all;
          data = { transition = btnTransition; };
        }];
      }]
    else [{
      alias = "Schedule: ${slot.alias}";
      mode = "restart";

      # Trigger: at slot time offset by transition (if negative, earlier; if positive, at slot time)
      trigger = [{
        platform = "template";
        value_template = ''
          {% set t = ${transitionEntity} %}
          {% set slot_ts = state_attr('input_datetime.sched_${slot.key}_time', 'timestamp') | int %}
          {% set offset = (t | abs * 60) if t < 0 else 0 %}
          {% set trigger_ts = slot_ts - offset %}
          {{ now().strftime('%H:%M') == (trigger_ts | timestamp_custom('%H:%M', false)) }}'';
      }];

      condition = [
        { condition = "state"; entity_id = "input_boolean.schedule_enabled"; state = "on"; }
        { condition = "state"; entity_id = "input_boolean.sched_${slot.key}_enabled"; state = "on"; }
        { condition = "state"; entity_id = "input_boolean.schedule_override"; state = "off"; }
      ];

      action =
        # Phase 1: Turn on slot lights with preset + brightness over transition
        [{
          service = "light.turn_on";
          target.entity_id = slot.lights;
          data = {
            transition = absTransition;
            brightness_pct = "{{ ${brightnessEntity} }}";
          };
        }
          (mkPresetAction slot.key slot.lights absTransition)]

        # Fade out exiting lights
        ++ (if exiting != [ ] then [{
          service = "light.turn_on";
          target.entity_id = exiting;
          data = {
            transition = absTransition;
            brightness_pct = 0;
          };
        }] else [ ])

        # Phase 2: After transition completes
        ++ [{
          delay = {
            seconds = "{{ (${transitionEntity}) | abs * 60 }}";
          };
        }]

        # Turn off exited lights cleanly
        ++ (if exiting != [ ] then [{
          service = "light.turn_off";
          target.entity_id = exiting;
          data = { transition = btnTransition; };
        }] else [ ])

        # Morning: reset override
        ++ (if slot.key == "morning" then [{
          service = "input_boolean.turn_off";
          target.entity_id = "input_boolean.schedule_override";
        }] else [ ]);
    }];

  # Continuous transition automation (alternative mode)
  continuousAutomations =
    let
      slotPairs = builtins.genList
        (i: {
          current = builtins.elemAt cfg.scheduleSlots i;
          next = builtins.elemAt cfg.scheduleSlots (
            if i + 1 < builtins.length cfg.scheduleSlots
            then i + 1
            else 0
          );
        })
        (builtins.length cfg.scheduleSlots);

      mkContinuous = { current, next }:
        if current.key == "off" || next.key == "off" then [ ]
        else if current.lights == [ ] then [ ]
        else [{
          alias = "Continuous: ${current.alias} → ${next.alias}";
          mode = "restart";
          trigger = [{
            platform = "time";
            at = "input_datetime.sched_${current.key}_time";
          }];
          condition = [
            { condition = "state"; entity_id = "input_boolean.schedule_enabled"; state = "on"; }
            { condition = "state"; entity_id = "input_boolean.sched_${current.key}_enabled"; state = "on"; }
            { condition = "state"; entity_id = "input_boolean.schedule_override"; state = "off"; }
            { condition = "state"; entity_id = "input_boolean.continuous_transitions"; state = "on"; }
          ];
          action =
            let
              transitionExpr = ''
                {% set cur_ts = state_attr('input_datetime.sched_${current.key}_time', 'timestamp') | int %}
                {% set nxt_ts = state_attr('input_datetime.sched_${next.key}_time', 'timestamp') | int %}
                {{ nxt_ts - cur_ts }}'';
            in
            [{
              service = "light.turn_on";
              target.entity_id = current.lights;
              data = {
                transition = transitionExpr;
                brightness_pct = "{{ states('input_number.sched_${next.key}_brightness') | int }}";
              };
            }
              (mkPresetAction next.key current.lights transitionExpr)];
        }];
    in
    builtins.concatMap mkContinuous slotPairs;

  # All slot entity IDs (for Custom detection trigger)
  slotEntities = builtins.concatMap
    (s:
      [ "input_datetime.sched_${s.key}_time" ]
      ++ (if s.defaultPreset != null then [
        "input_number.sched_${s.key}_brightness"
        "input_select.sched_${s.key}_preset"
      ] else [ ])
      ++ (if s.key != "off" then
        [ "input_number.sched_${s.key}_transition" ]
      else [ ]))
    cfg.scheduleSlots;

  # Preset alias → key lookup for Jinja
  presetLookup = builtins.concatStringsSep ", " (
    map (p: "'${p.alias}': '${p.key}'") cfg.schedulePresets
  );
in
builtins.concatMap mkSlotAutomation cfg.scheduleSlots
++ continuousAutomations
++ [
  # Apply preset when dropdown changes to a named preset
  {
    alias = "Apply Schedule Preset";
    mode = "restart";
    trigger = [{
      platform = "state";
      entity_id = "input_select.schedule_preset";
    }];
    condition = [
      { condition = "state"; entity_id = "input_boolean.applying_preset"; state = "off"; }
      {
        condition = "template";
        value_template = "{{ trigger.to_state.state != 'Custom' }}";
      }
    ];
    action = [{
      service = "script.turn_on";
      target.entity_id = "{{ 'script.schedule_preset_' ~ {${presetLookup}}[trigger.to_state.state] }}";
    }];
  }

  # Detect manual slot changes → set to Custom
  {
    alias = "Detect Custom Schedule";
    mode = "restart";
    trigger = map
      (e: {
        platform = "state";
        entity_id = e;
      })
      slotEntities;
    condition = [
      { condition = "state"; entity_id = "input_boolean.applying_preset"; state = "off"; }
      {
        condition = "template";
        value_template = "{{ states('input_select.schedule_preset') != 'Custom' }}";
      }
    ];
    action = [{
      service = "input_select.select_option";
      target.entity_id = "input_select.schedule_preset";
      data.option = "Custom";
    }];
  }

  # Wake PC: standalone WOL automation
  {
    alias = "Wake PC";
    mode = "single";
    trigger = [{
      platform = "time";
      at = "input_datetime.wake_pc_time";
    }];
    condition = [{
      condition = "state";
      entity_id = "input_boolean.wake_pc";
      state = "on";
    }];
    action = [{
      service = "switch.turn_on";
      target.entity_id = "switch.torgue";
    }];
  }
]
