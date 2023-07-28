#!/bin/sh
# https://askubuntu.com/a/871207/307523
# https://github.com/yeyushengfan258/Win11-icon-theme/tree/main/src/status/24
# deps: pamixer

notify-send -i "~/.config/hypr/audio-volume-high-panel.svg" \
  " Volume " \
  " $(pamixer --get-volume)% " \
   -h string:x-canonical-private-synchronous:anything