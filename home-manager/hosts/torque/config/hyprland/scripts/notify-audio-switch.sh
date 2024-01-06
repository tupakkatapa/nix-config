#!/usr/bin/env bash
# deps: pactl

declare -A device_aliases
device_aliases["speakers"]="alsa_output.pci-0000_0c_00.4.analog-stereo"
#device_aliases["speakers+headset"]="alsa_output.pci-0000_0c_00.4.analog-stereo,alsa_output.usb-Corsair_CORSAIR_VIRTUOSO_XT_Wireless_Gaming_Receiver_16af0ba8000200da-00.analog-stereo"
device_aliases["headset"]="alsa_output.usb-Corsair_CORSAIR_VIRTUOSO_XT_Wireless_Gaming_Receiver_16af0ba8000200da-00.analog-stereo"
#device_aliases["monitor"]="alsa_output.pci-0000_0a_00.1.hdmi-stereo"
#device_aliases["speakers+monitor"]="alsa_output.pci-0000_0c_00.4.analog-stereo,alsa_output.pci-0000_0a_00.1.hdmi-stereo"

# Get available devices
# pactl list sinks | awk '/Name: /{print $2}'

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

# Check if next combined
IFS=',' read -ra next_sink_array <<< "$next_device"
[[ "${#next_sink_array[@]}" -gt 1 ]] && next_combined=true

# Switch
if [ "$next_combined" == true ]; then
  # Create combined sink if does not exist
  if ! pactl list sinks | awk '/Name: /{print $2}' | grep -q "$next_alias"; then
    pactl load-module module-combine-sink \
      sink_name="$next_alias" \
      sink_properties=device.description="$next_alias" \
      slaves="$next_device" \
      channels="${#next_sink_array[@]}"
  fi

  # Set
  pactl set-default-sink "$next_alias"
else
  # Unload module if currently combined
  IFS=',' read -ra current_sink_array <<< "$current_device"
  [[ "${#current_sink_array[@]}" -gt 1 ]] && pactl unload-module module-combine-sink

  # Set
  pactl set-default-sink "$next_device"
fi

# Notify
notify-send -i ~/.config/hypr/audio-volume-high-panel.svg \
  "Device" \
  "$next_alias" \
  -h string:x-canonical-private-synchronous:anything
