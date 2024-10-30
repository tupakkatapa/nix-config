#!/usr/bin/env bash

# Run pipewire-out-switcher and capture the output alias
current_alias=$(pipewire-out-switcher devices.json)

# Notify
notify-send -i audio-volume-high-panel.svg \
  "Device" \
  "$current_alias" \
  -h string:x-canonical-private-synchronous:anything
