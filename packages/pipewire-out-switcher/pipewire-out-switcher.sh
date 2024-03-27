#!/usr/bin/env bash

declare -A device_aliases

display_usage() {
  cat <<USAGE
Usage: pipewire-out-switcher [OPTIONS..] [JSON_FILE_PATH]

Description:
  Switches audio output devices and optionally takes a JSON file to map device aliases.

Options:
  -h, --help
    Display this help message.

  JSON_FILE_PATH
    Path to JSON file containing device aliases. If not provided, uses device names from pactl.

    Example:

    {
      "speakers": "alsa_output.pci-0000_0c_00.4.analog-stereo",
      "headset": "alsa_output.usb-Corsair_CORSAIR_VIRTUOSO_XT_Wireless_Gaming_Receiver_16af0ba8000200da-00.analog-stereo"
    }

USAGE
}

# Parse command line arguments
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
    -h | --help)
      display_usage
      exit 0
      ;;
    *)
      DEVICE_ALIASES_JSON="$1"
      shift
      ;;
    esac
  done
}


main() {
  parse_arguments "$@"

  # Convert JSON file to associative array or use original names from pactl
  if [ -n "${DEVICE_ALIASES_JSON}" ] && [ -f "${DEVICE_ALIASES_JSON}" ]; then
      while IFS="=" read -r key value; do
          device_aliases["$key"]="$value"
      done < <(jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" "${DEVICE_ALIASES_JSON}")
  else
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
}

main "$@"

