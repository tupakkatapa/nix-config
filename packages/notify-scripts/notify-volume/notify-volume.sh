#!/usr/bin/env bash
# https://askubuntu.com/a/871207/307523
# https://github.com/yeyushengfan258/Win11-icon-theme/tree/main/src/status/24

pamixer $@

notify-send -i audio-volume-high-panel.svg \
  " Volume " \
  " $(pamixer --get-volume)% " \
   -h string:x-canonical-private-synchronous:anything
