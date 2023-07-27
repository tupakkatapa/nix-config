#!/bin/sh
# https://github.com/yeyushengfan258/Win11-icon-theme/tree/main/src/status/24

killall dunst
notify-send -i "~/.config/hypr/audio-volume-high-panel.svg" " Volume " " $(pamixer --get-volume)% "