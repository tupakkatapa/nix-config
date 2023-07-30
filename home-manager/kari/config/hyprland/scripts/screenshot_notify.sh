#!/bin/sh
# https://askubuntu.com/a/871207/307523
# deps: grim, slurp

notify-send " Select a region "

grim -g "$(slurp)" ~/Pictures/Screenshots/"$(date +"Screenshot_%Y-%m-%d_%H-%M-%S.png")"

notify-send "Screenshot saved in ~/Pictures/Screenshots" \
  -h string:x-canonical-private-synchronous:anything
