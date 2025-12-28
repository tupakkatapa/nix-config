#!/usr/bin/env bash
# https://askubuntu.com/a/871207/307523
# https://github.com/yeyushengfan258/Win11-icon-theme/tree/main/src/status/24

pamixer "$@"

# Get the current state
volume=$(pamixer --get-volume)
muted=$(pamixer --get-mute)

# Choose the icon and message
if [ "$muted" == "true" ]; then
  icon="@ICON_MUTED@"
  message="Muted"
else
  if [ "$volume" -ge 66 ]; then
    icon="@ICON_HIGH@"
  elif [ "$volume" -ge 33 ]; then
    icon="@ICON_MEDIUM@"
  else
    icon="@ICON_LOW@"
  fi
  message="${volume}%"
fi

# Send the notification
notify-send -i "$icon" \
  "Volume" \
  "$message" \
  -h string:x-canonical-private-synchronous:anything
