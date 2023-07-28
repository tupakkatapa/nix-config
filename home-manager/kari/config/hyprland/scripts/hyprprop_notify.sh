#!/bin/sh
# https://askubuntu.com/a/871207/307523
# deps: jq

notify-send " Select a window " \
  -h string:x-canonical-private-synchronous:anything

hyprprop_output=$(hyprprop)

classname=$(jq -r '.class' <<< "$hyprprop_output")
title=$(jq -r '.title' <<< "$hyprprop_output")
pid=$(jq -r '.pid' <<< "$hyprprop_output")

# Extract 'at' and format it as "x=<value> y=<value>"
at=$(jq -r '.at | "x=\(.[0]) y=\(.[1])"' <<< "$hyprprop_output")

# Extract 'size' and format it as "<value>x<value>"
size=$(jq -r '.size | "\(.[0])x\(.[1])"' <<< "$hyprprop_output")

notify-send -t 8000 -a "my-app" "Hyprprop" \
"<br>Title: $title
Classname: $classname
Size: $size
Position: $at
Pid: $pid"