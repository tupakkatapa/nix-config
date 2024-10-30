#!/usr/bin/env bash

# Initialize variables
declare -A device_aliases
verbose=false

# Verbose output function
say() {
    if [[ "$verbose" == true ]]; then
        echo "$@"
    fi
}

# Display usage information
display_usage() {
  cat <<USAGE
Usage: pipewire-out-switcher [OPTIONS..] [JSON_FILE_PATH]

Description:
  Switches audio output devices by cycling through available devices detected by pactl.

Options:
  -h, --help
    Display this help message

  -v, --verbose
    Enable verbose output

  JSON_FILE_PATH
    Optional JSON file with device aliases to limit cycling to listed devices only.

Example JSON file format:
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
    -h|--help)
      display_usage
      exit 0
      ;;
    -v|--verbose)
      verbose=true
      shift
      ;;
    *)
      DEVICE_ALIASES_JSON="$1"
      shift
      ;;
    esac
  done
}

# Validate JSON format and structure
validate_json_format() {
  say "status: validating JSON format and structure"
  if ! jq -e 'type == "object" and all(.[]; type == "string")' "${DEVICE_ALIASES_JSON}" > /dev/null 2>&1; then
    echo "error: Invalid JSON format or structure in file '${DEVICE_ALIASES_JSON}'"
    echo "Please ensure the JSON file contains a flat key-value pair structure with string values."
    exit 1
  fi
}

# Validate each device in JSON file and exit if any device is invalid
validate_devices() {
  say "status: validating listed devices against available output devices"
  # Collect valid devices from pactl
  declare -A valid_devices
  while IFS= read -r device; do
    valid_devices["$device"]=true
  done < <(pactl list sinks | awk '/Name: /{print $2}')

  # Check JSON devices against valid devices
  for alias in "${!device_aliases[@]}"; do
    if [[ -z "${valid_devices[${device_aliases[$alias]}]}" ]]; then
      echo "error: device '${device_aliases[$alias]}' for alias '$alias' is not a valid output device"
      exit 1
    else
      say "info: '${device_aliases[$alias]}' for alias '$alias' is a valid output device"
    fi
  done
}

main() {
  parse_arguments "$@"

  # Convert JSON file to associative array or use original names from pactl
  if [ -n "${DEVICE_ALIASES_JSON}" ] && [ -f "${DEVICE_ALIASES_JSON}" ]; then
      say "status: loading device aliases from JSON file '${DEVICE_ALIASES_JSON}'"
      validate_json_format
      while IFS="=" read -r key value; do
          device_aliases["$key"]="$value"
      done < <(jq -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" "${DEVICE_ALIASES_JSON}")
      validate_devices
  else
      say "status: loading available devices directly from pactl"
      while IFS= read -r line; do
          device_aliases["$line"]="$line"
      done < <(pactl list sinks | awk '/Name: /{print $2}')
  fi

  # Get current device
  current_device=$(pactl info | awk '/Default Sink: /{print $3}')
  say "info: current default device is '$current_device'"

  # Get alias of the current device, if alias list exists
  current_alias="$current_device"
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

  # Determine the next device alias
  next_index=$(( (current_index + 1) % ${#aliases[@]} ))
  next_alias="${aliases[next_index]}"
  next_device="${device_aliases[$next_alias]}"

  # Verbose output for device switching
  say "status: switching to the next device"
  say "info: previous alias: $current_alias"
  say "info: next alias: $next_alias"
  say "info: next device: $next_device"

  # Switch to the next device
  pactl set-default-sink "$next_device"

  # Output only the alias name if an alias list was provided
  if [ -n "${DEVICE_ALIASES_JSON}" ] && [ -f "${DEVICE_ALIASES_JSON}" ]; then
    echo "$next_alias"
  else
    echo "$next_device"
  fi
}

main "$@"
