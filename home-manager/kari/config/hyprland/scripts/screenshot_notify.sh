#!/bin/sh
notify-send " Select a region "
grim -g "$(slurp)" "~/Pictures/Screenshots/$(date +"Screenshot_%Y-%m-%d_%H-%M-%S.png")"
exec notify-send "Screenshot saved in ~/Pictures/Screenshots"
