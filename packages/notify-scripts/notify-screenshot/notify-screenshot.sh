#!/usr/bin/env bash
# https://askubuntu.com/a/871207/307523

notify-send "Select a region"

if [[ -z "$1" ]]; then
    notify-send "Error: No path provided."
    exit 1
fi

if [[ ! -d "$1" ]]; then
    notify-send "Error: The provided path is not a directory."
    exit 1
fi

if [[ ! -w "$1" ]]; then
    notify-send "Error: The provided path is not writable."
    exit 1
fi

mkdir -p "$1"

# Capturing the screenshot
screenshot_path="$1/$(date +"Screenshot_%Y-%m-%d_%H-%M-%S.png")"
grim -g "$(slurp)" "$screenshot_path"

notify-send "Screenshot saved in $1" \
  -h string:x-canonical-private-synchronous:anything
