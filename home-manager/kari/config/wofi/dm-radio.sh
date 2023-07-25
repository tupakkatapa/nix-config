#!/usr/bin/env bash
# https://gitlab.com/dwt1/dmscripts/-/blob/master/scripts/dm-radio

set -euo pipefail

# Config
CONFIG="$HOME/.config/wofi/menu_config"
STYLE="$HOME/.config/wofi/menu_style.css"
COLORS="$HOME/.config/wofi/menu_colors"
DMENU="wofi --dmenu --conf ${CONFIG} --style ${STYLE} --color ${COLORS}"

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
    # As this is loaded from other file it is technically not defined.
    # shellcheck disable=SC2154
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
    choice=$(menu | ${MENU} 'Choose radio station:' "$@") || exit 1

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

noOpt=1
# If script is run with '-d', it will use 'dmenu'
# If script is run with '-f', it will use 'fzf'
# If script is run with '-d', it will use 'rofi'
while getopts "dfrh" arg 2>/dev/null; do
    case "${arg}" in
    d) # shellcheck disable=SC2153
        MENU=${DMENU}
        [[ "${BASH_SOURCE[0]}" == "${0}" ]] && main
        ;;
    f) # shellcheck disable=SC2153
        MENU=${FMENU}
        [[ "${BASH_SOURCE[0]}" == "${0}" ]] && main
        ;;
    r) # shellcheck disable=SC2153
        MENU=${RMENU}
        [[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "@"
        ;;
    h) help ;;
    *) printf '%s\n' "Error: invalid option" "Type $(basename "$0") -h for help" ;;
    esac
    noOpt=0
done

# If script is run with NO argument, it will use 'dmenu'
[ $noOpt = 1 ] && MENU=${DMENU} && [[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"