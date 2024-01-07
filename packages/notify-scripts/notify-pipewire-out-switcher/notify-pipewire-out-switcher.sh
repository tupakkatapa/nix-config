#!/usr/bin/env bash

declare -A device_aliases

# Check if JSON file path is provided
if [ "$#" -eq 1 ]; then
    DEVICE_ALIASES_JSON="$1"

    # Convert JSON file to associative array
    while IFS="=" read -r key value; do
        device_aliases["$key"]="$value"
    done < <(jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" "${DEVICE_ALIASES_JSON}")
else
    # Use original names from pactl
    while IFS= read -r line; do
        device_aliases["$line"]="$line"
    done < <(pactl list sinks | awk '/Name: /{print $2}')
fi

# Get current device
current_device=$(pactl info | awk '/Default Sink: /{print $3}')

# Get alias of the current device
current_alias=""
for alias in "${!device_aliases[@]}"; do
  if [ "${device_aliases[$alias]}" == "$current_device" ]; then
    current_alias=$alias
    break
  fi
done

# Aliases array
aliases=("${!device_aliases[@]}")

# Get index of the current device
current_index=0
for i in "${!aliases[@]}"; do
  if [ "${aliases[i]}" == "$current_alias" ]; then
    current_index=$i
    break
  fi
done

# Figure out the next device alias
next_index=$(( (current_index + 1) % ${#aliases[@]} ))
next_alias="${aliases[next_index]}"
next_device="${device_aliases[$next_alias]}"

# For debugging
echo "previous index: $current_index"
echo "previous alias: $current_alias"
echo "previous device: $current_device"
echo "current index: $next_index"
echo "current alias: $next_alias"
echo "current device: $next_device"

# Switch to next device
pactl set-default-sink "$next_device"

# Notify
notify-send -i audio-volume-high-panel.svg \
  "Device" \
  "$next_alias" \
  -h string:x-canonical-private-synchronous:anything
