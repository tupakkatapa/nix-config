#!/usr/bin/env bash
# Derived from https://gitlab.com/dwt1/dmscripts/-/blob/master/scripts/dm-radio

DMENU="wofi --dmenu -w 1"
DMRADIOVOLUME="30"
VIDEO=false

# Display usage information
display_usage() {
  cat <<USAGE
Usage: dm-radio [OPTIONS] <path_to_stations_json>

Description:
  Opens an interactive menu to select and play radio stations from a specified JSON file.

Options:
  -v, --video
    Enable video output for stations that support it.

USAGE
}

# Parse and validate command line arguments
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -v|--video)
      VIDEO=true
      shift
      ;;
    -h|--help)
      display_usage
      exit 0
      ;;
    *)
      if [[ -n $1 ]] && [[ ! $1 =~ ^- ]]; then
        RADIO_STATIONS_FILE="$1"
        shift
      else
        echo "Unknown option: $1"
        display_usage
        exit 1
      fi
      ;;
    esac
  done

  if [[ -z $RADIO_STATIONS_FILE ]]; then
    echo "Error: You must specify the path to the stations JSON file."
    display_usage
    exit 1
  fi
}

parse_arguments "$@"

menu() {
    printf '%s\n' "quit"
    jq -r '.[].name' < "${RADIO_STATIONS_FILE}" | sort
}

main() {
    # Choosing a radio station from JSON file.
    choice=$(menu | ${DMENU} 'Choose radio station:') || exit 1

    case $choice in
    quit)
        notify-send "Stopping dm-radio" "You have quit dm-radio. 🎶"
        pkill -f http
        exit
        ;;
    *)
        pkill -f http || echo "mpv not running."
        notify-send "Starting dm-radio" "Playing station: $choice. 🎶"
        URL=$(jq -r --arg choice "$choice" '.[] | select(.name==$choice) | .url' < "${RADIO_STATIONS_FILE}")
        if [ "$VIDEO" = true ]; then
          mpv --vf=format=yuv420p,scale=1280:720 --autofit=20% --volume="${DMRADIOVOLUME:-100}" "$URL"
        else
          mpv --no-video --volume="${DMRADIOVOLUME:-100}" "$URL"
        fi
        ;;
    esac
}

main
