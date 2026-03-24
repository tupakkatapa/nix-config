#!/usr/bin/env bash
# Cycle audio output and notify

# Read configured devices in order from JSON
config="${XDG_CONFIG_HOME:-$HOME/.config}/pipewire-out-switcher/devices.json"
if [[ ! -f $config ]]; then
  notify-send -i @ICON_PATH@ "Audio Output" "no config found" \
    -h string:x-canonical-private-synchronous:pipewire-switcher
  exit 1
fi
mapfile -t aliases < <(jq -r 'keys[]' "$config")
declare -A device_map
while IFS="=" read -r key value; do
  device_map["$key"]="$value"
done < <(jq -r 'to_entries|map("\(.key)=\(.value)")|.[]' "$config")

# Build list of available sinks (node.name -> wpctl id)
declare -A available_ids
while IFS=$'\t' read -r id name; do
  available_ids["$name"]="$id"
done < <(pw-dump 2>/dev/null | jq -r '
  [.[] | select(.type == "PipeWire:Interface:Node" and .info.props["media.class"] == "Audio/Sink")]
  | .[] | [(.id | tostring), .info.props["node.name"]] | @tsv')

# Get current default sink node name
current_device=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk -F'"' '/node.name/{print $2}')

# Find current index in configured devices
current_index=-1
for i in "${!aliases[@]}"; do
  [[ ${device_map[${aliases[i]}]} == "$current_device" ]] && current_index=$i && break
done

# Cycle through devices starting from next, skip unavailable
count=${#aliases[@]}
for ((offset = 1; offset <= count; offset++)); do
  idx=$(((current_index + offset) % count))
  alias="${aliases[idx]}"
  node="${device_map[$alias]}"
  id="${available_ids[$node]}"
  if [[ -n $id ]]; then
    wpctl set-default "$id"
    notify-send -i @ICON_PATH@ "Audio Output" "$alias" \
      -h string:x-canonical-private-synchronous:pipewire-switcher
    exit 0
  fi
done

notify-send -i @ICON_PATH@ "Audio Output" "no devices available" \
  -h string:x-canonical-private-synchronous:pipewire-switcher
