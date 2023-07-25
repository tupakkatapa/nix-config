#!/bin/bash
hyprprop_output=$(hyprprop)
classname=$(echo "$hyprprop_output" | jq -r '.class')
title=$(echo "$hyprprop_output" | jq -r '.title')
pid=$(echo "$hyprprop_output" | jq -r '.pid')

at=$(echo "$hyprprop_output" | jq -r '.at')
at=$(echo $at | sed 's/\[\s*\([0-9]\+\)\s*,\s*\([0-9]\+\)\s*\]/x=\1 y=\2/')

size=$(echo "$hyprprop_output" | jq -r '.size')
size=$(echo $size | sed 's/\[\s*\([0-9]\+\)\s*,\s*\([0-9]\+\)\s*\]/\1x\2/')

notify-send -a "my-app" "Hyprprop" "Classname: $classname<br>Size: $size<br>Position: $at<br>Pid: $pid"
