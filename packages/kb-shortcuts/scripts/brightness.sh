#!/usr/bin/env bash
# Adjust laptop brightness and notify (laptop only, desktop uses waybar + monitor-adjust)

if [ -d /sys/class/backlight ] && [ -n "$(ls -A /sys/class/backlight 2>/dev/null)" ]; then
  brightnessctl "$@"
  current_value=$(brightnessctl -m | awk -F, '{print substr($4, 0, length($4)-1)}')
  notify-send -i @ICON_PATH@ "Brightness" "$current_value%" \
    -h string:x-canonical-private-synchronous:brightness
fi
