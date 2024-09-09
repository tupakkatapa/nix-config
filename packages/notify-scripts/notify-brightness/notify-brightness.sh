#!/usr/bin/env bash
# https://askubuntu.com/a/871207/307523
# https://github.com/yeyushengfan258/Win11-icon-theme/tree/main/src/status/24

monitor-adjust "$@"

current_value=$(ddcutil getvcp 10 | awk -F 'current value =|, max value =' '{print $2}')

notify-send -i display-brightness-symbolic.svg \
  " Brightness " \
  " $current_value% " \
   -h string:x-canonical-private-synchronous:anything
