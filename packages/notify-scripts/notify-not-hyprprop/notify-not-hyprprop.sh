#!/usr/bin/env bash

# Fetch the active window details
active_window=$(hyprctl -j activewindow)

# Check if the active window data is valid
if [ -z "$active_window" ] || [ "$active_window" == "null" ]; then
    echo "Error: Could not determine the active window."
    exit 1
fi

# Extract and display the information
notify-send -a "my-app" "Active Window Details" \
"Title: $(echo "$active_window" | jq -r '.title')
Classname: $(echo "$active_window" | jq -r '.class')
Size: $(echo "$active_window" | jq -r '.size | "\(.[0])x\(.[1])"')
Position: $(echo "$active_window" | jq -r '.at | "x=\(.[0]) y=\(.[1])"')
Pid: $(echo "$active_window" | jq -r '.pid')"

