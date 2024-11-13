#!/usr/bin/env bash
# https://askubuntu.com/a/871207/307523
# https://github.com/yeyushengfan258/Win11-icon-theme/tree/main/src/status/24

brightnessctl "$@"

current_value=$(brightnessctl -m | awk -F, '{print substr($4, 0, length($4)-1)}')

notify-send -i @ICON_PATH@ \
  " Brightness " \
  " $current_value% " \
   -h string:x-canonical-private-synchronous:anything
