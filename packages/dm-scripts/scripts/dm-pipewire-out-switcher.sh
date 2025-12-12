#!/usr/bin/env bash
# Derived from https://gitlab.com/dwt1/dmscripts/-/blob/master/scripts/dm-pipewire-out-switcher

DMENU="wofi --dmenu -w 1"

get_default_sink() {
  pactl --format=json info | jq -r .default_sink_name
}
get_all_sinks() {
  pactl --format=json list short sinks |
    current=$(get_default_sink) jq -r '.[] | if .name == env.current then .state="* " else .state="" end | .state + .name'
}

main() {
  choice=$(printf '%s\n' "$(get_all_sinks)" |
    sort |
    ${DMENU} 'Sink: ' "$@") || exit 1

  if [ "$choice" ]; then
    if [[ ${choice} == "* $(get_default_sink)" ]]; then
      exit 0
    fi
    pactl set-default-sink "${choice}"
    notify-send "Sink is now: ${choice}"
  else
    echo "Program terminated." && exit 0
  fi
}

[[ ${BASH_SOURCE[0]} == "${0}" ]] && main "$@"
