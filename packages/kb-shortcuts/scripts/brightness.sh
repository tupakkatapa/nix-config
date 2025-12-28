#!/usr/bin/env bash
# Adjust brightness and notify (auto-detects laptop vs desktop)

if [ -d /sys/class/backlight ] && [ -n "$(ls -A /sys/class/backlight 2>/dev/null)" ]; then
  brightnessctl "$@"
  current_value=$(brightnessctl -m | awk -F, '{print substr($4, 0, length($4)-1)}')
else
  monitor-adjust -b "$@"
  current_value=$(monitor-adjust --show | awk '/Brightness:/{print $2}')
fi

notify-send -i @ICON_PATH@ "Brightness" "$current_value%" \
  -h string:x-canonical-private-synchronous:brightness
