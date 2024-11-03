#!/usr/bin/env bash

# Run pipewire-out-switcher and capture the output alias
current_alias=$(pipewire-out switch @CONFIG_PATH@)

# Notify
notify-send -i @ICON_PATH@ \
  "Device" \
  "$current_alias" \
  -h string:x-canonical-private-synchronous:anything
