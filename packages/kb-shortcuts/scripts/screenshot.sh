#!/usr/bin/env bash
# https://askubuntu.com/a/871207/307523

if [[ -z $1 ]]; then
  notify-send "Error: No path provided."
  exit 1
fi

if [[ ! -d $1 ]]; then
  notify-send "Error: The provided path is not a directory."
  exit 1
fi

if [[ ! -w $1 ]]; then
  notify-send "Error: The provided path is not writable."
  exit 1
fi

mkdir -p "$1"

# Capturing the screenshot
screenshot_path="$1/$(date +"Screenshot_%Y-%m-%d_%H-%M-%S.png")"

if [[ $2 == "fullscreen" ]]; then
  notify-send "Took a fullscreen screenshot"
  grim "$screenshot_path"
else
  notify-send "Select a region"
  grim -g "$(slurp)" "$screenshot_path"
fi

notify-send "Screenshot saved in $1" \
  -h string:x-canonical-private-synchronous:anything
