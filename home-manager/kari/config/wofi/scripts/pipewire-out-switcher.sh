#!/usr/bin/env bash
# https://gitlab.com/dwt1/dmscripts/-/blob/master/scripts/dm-pipewire-out-switcher

set -euo pipefail

# Config
CONFIG="$HOME/.config/wofi/config"
STYLE="$HOME/.config/wofi/style.css"
COLORS="$HOME/.config/wofi/colors"
DMENU="wofi --dmenu -p Search... --conf ${CONFIG} --style ${STYLE} --color ${COLORS}"

# Script
get_default_sink() {
  pactl --format=json info | jq -r .default_sink_name
}
get_all_sinks() {
  pactl --format=json list short sinks |\
    current=$(get_default_sink) jq -r '.[] | if .name == env.current then .state="* " else .state="" end | .state + .name'
}

main() {
  choice=$(printf '%s\n' "$(get_all_sinks)" | \
      sort | \
      ${DMENU} 'Sink: ' "$@") || exit 1

      if [ "$choice" ]; then
        if [[ "${choice}" == "* $(get_default_sink)" ]]; then
          exit 0
        fi
        pactl set-default-sink "${choice}"
        notify-send "Sink is now: ${choice}"
      else
          echo "Program terminated." && exit 0
      fi
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"