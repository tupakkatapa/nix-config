#!/usr/bin/env bash
# https://gitlab.com/dwt1/dmscripts/-/blob/master/scripts/dm-radio
# deps: mpv

set -euo pipefail

# Config
DMENU="wofi --dmenu -w 1"

DMRADIOVOLUME="100"
declare -A radio_stations
radio_stations[lofi hip hop radio 📚 - beats to relax/study to]="https://www.youtube.com/watch?v=jfKfPfyJRdk"
radio_stations[synthwave radio 🌌 - beats to chill/game to]="https://www.youtube.com/watch?v=MVPTGNGiI-4"
radio_stations[lofi hip hop radio 💤 - beats to sleep/chill to]="https://www.youtube.com/watch?v=rUxyKA_-grg"
radio_stations[non stop Music - monstercat TV 🎶]="https://www.twitch.tv/monstercat"
radio_stations[PaulinPelivideot 🎮]="https://www.twitch.tv/paulinpelivideot"

# Script
menu() {
    printf '%s\n' "quit"
    printf '%s\n' "${!radio_stations[@]}" | sort
}

# Functions for sending notification messages
start_radio() {
    notify-send "Starting dm-radio" "Playing station: $1. 🎶"
}

end_radio() {
    notify-send "Stopping dm-radio" "You have quit dm-radio. 🎶"
}

main() {
    # Choosing a radio station from array sourced in 'config'.
    choice=$(menu | ${DMENU} 'Choose radio station:' "$@") || exit 1

    case $choice in
    Quit)
        end_radio
        pkill -f http
        exit
        ;;
    *)
        pkill -f http || echo "mpv not running."
        start_radio "$choice"
        mpv --vf=format=yuv420p,scale=1280:720 --autofit=20% --volume="${DMRADIOVOLUME:-100}" "${radio_stations["${choice}"]}"
        return
        ;;
    esac

}

main "$@"