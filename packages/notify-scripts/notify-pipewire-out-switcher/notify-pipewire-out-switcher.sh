#!/usr/bin/env bash

pipewire-out-switcher devices.json

# Get current alias
current_device=$(pactl info | awk '/Default Sink: /{print $3}')
current_alias=$(jq -r --arg device "$current_device" 'to_entries | .[] | select(.value == $device) | .key' devices.json)

# Notify
notify-send -i audio-volume-high-panel.svg \
  "Device" \
  "$current_alias" \
  -h string:x-canonical-private-synchronous:anything
