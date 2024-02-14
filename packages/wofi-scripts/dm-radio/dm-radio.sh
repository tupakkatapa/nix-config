#!/usr/bin/env bash
# Derived from https://gitlab.com/dwt1/dmscripts/-/blob/master/scripts/dm-radio

DMENU="wofi --dmenu -w 1"
DMRADIOVOLUME="30"

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_stations_json>"
    exit 1
fi

RADIO_STATIONS_FILE="$1"

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
        mpv --vf=format=yuv420p,scale=1280:720 --autofit=20% --volume="${DMRADIOVOLUME:-100}" "$URL"
        ;;
    esac
}

main "$@"


