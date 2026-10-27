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

# Build list of available sinks (node.name -> wpctl id), skipping sinks whose
# card has no active, plugged-in port for them (e.g. unused HDMI/DP outputs)
declare -A available_ids
while IFS=$'\t' read -r id name; do
  available_ids["$name"]="$id"
done < <(pw-dump 2>/dev/null | jq -r '
  (map(select(.type == "PipeWire:Interface:Device"))
    | map({key: (.id | tostring), value: [.info.params.Route[]? | select(.direction == "Output")]})
    | from_entries) as $routes
  | .[] | select(.type == "PipeWire:Interface:Node" and .info.props["media.class"] == "Audio/Sink")
  | .info.props as $p
  | ($routes[$p["device.id"] | tostring] // []) as $r
  | select(($r | length) == 0 or any($r[]; .device == $p["card.profile.device"] and .available != "no"))
  | [(.id | tostring), $p["node.name"]] | @tsv')

# Get current default sink node name
current_device=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk -F'"' '/node.name/{print $2}')

# Find current index in configured devices
current_index=-1
for i in "${!aliases[@]}"; do
  # shellcheck disable=SC2053 # config values are glob patterns
  [[ $current_device == ${device_map[${aliases[i]}]} ]] && current_index=$i && break
done

# Cycle through devices starting from next, skip unavailable
count=${#aliases[@]}
for ((offset = 1; offset <= count; offset++)); do
  idx=$(((current_index + offset) % count))
  alias="${aliases[idx]}"
  id=""
  for name in "${!available_ids[@]}"; do
    # shellcheck disable=SC2053 # config values are glob patterns
    [[ $name == ${device_map[$alias]} ]] && id="${available_ids[$name]}" && break
  done
  if [[ -n $id ]]; then
    wpctl set-default "$id"
    notify-send -i @ICON_PATH@ "Audio Output" "$alias" \
      -h string:x-canonical-private-synchronous:pipewire-switcher
    exit 0
  fi
done

notify-send -i @ICON_PATH@ "Audio Output" "no devices available" \
  -h string:x-canonical-private-synchronous:pipewire-switcher
