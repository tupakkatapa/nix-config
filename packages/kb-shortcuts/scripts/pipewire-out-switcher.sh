#!/usr/bin/env bash
# Cycle audio output and notify

declare -A device_aliases
while IFS="=" read -r key value; do
  device_aliases["$key"]="$value"
done < <(jq -r 'to_entries|map("\(.key)=\(.value)")|.[]' "@CONFIG_PATH@")

# Get current device and its alias
current_device=$(pactl info | awk '/Default Sink:/{print $3}')
current_alias="$current_device"
for alias in "${!device_aliases[@]}"; do
  [[ ${device_aliases[$alias]} == "$current_device" ]] && current_alias=$alias && break
done

# Find next device
aliases=("${!device_aliases[@]}")
for i in "${!aliases[@]}"; do
  [[ ${aliases[i]} == "$current_alias" ]] && current_index=$i && break
done
next_index=$(((current_index + 1) % ${#aliases[@]}))
next_alias="${aliases[next_index]}"

# Switch and notify
pactl set-default-sink "${device_aliases[$next_alias]}"
notify-send -i @ICON_PATH@ "Audio Output" "$next_alias" \
  -h string:x-canonical-private-synchronous:pipewire-switcher
