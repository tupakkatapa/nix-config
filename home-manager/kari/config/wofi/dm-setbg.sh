#!/usr/bin/env bash
# https://gitlab.com/dwt1/dmscripts/-/blob/master/scripts/dm-setbg

set -euo pipefail

# Config
CONFIG="$HOME/.config/wofi/menu_config"
STYLE="$HOME/.config/wofi/menu_style.css"
COLORS="$HOME/.config/wofi/menu_colors"
DMENU="wofi --dmenu --conf ${CONFIG} --style ${STYLE} --color ${COLORS}"

setbg_dir=~/Pictures/Wallpapers/
setbg_random_dir=~/Pictures/Wallpapers/random

# Set this to 1 if you want to use imv and wayland, 0 if you want to use sxiv
# Note that sxiv is X11 only, you need to mark the image you want to use.
use_imv=0

# Script
setrgb() {
  sudo -u $(logname) ~/scripts/sh/wallpaper-scripts/set_openrgb.sh
}

setbg() {
  ~/.config/hypr/scripts/set_wallpaper.sh "$1"
}

main() {
  choice="$(printf "Set\nRandom\nExit" | ${DMENU} -p "What would you like to do?")"
  case "$choice" in
    "Set")
    if [ "$use_imv" = 0 ]; then
      wallpaper="$(sxiv -t -o -r "${setbg_dir}")"
      echo "$wallpaper" > "$HOME"/.cache/wall
      setbg "$wallpaper"
      #setrgb "$wallpaper"
    else
      imv "${setbg_dir}" | while read -r LINE; do
        pidof "swaybg" && killall "swaybg"
        pidof "xwallpaper" && killall "xwallpaper"
        setbg "$LINE" & # Sets the wallpaper and frees it from the process
        notify-send "Wallpaper has been updated" "$LINE is the current wallpaper, edit your window manager config if you would like this to persist on reboot"
        #setrgb "$wallpaper"
      done
    fi
    ;;
    "Random")
    valid_paper="No"
    until [ "$valid_paper" = "Yes" ]; do
      pidof "swaybg" && killall "swaybg"
      pidof "xwallpaper" && killall "xwallpaper"
      wallpaper="$(find "${setbg_random_dir}" -type f -name "01*" | shuf -n 1)"
      setbg "$wallpaper" &
      echo "$wallpaper" > "$HOME/.cache/wall"
      valid_paper="$(printf "Yes\nNo" | ${DMENU} -p "Do you like the new wallpaper?")"
    done

    #setrgb "$wallpaper"

    ;;
    "Exit") echo "Program terminated" && exit 1;;
    *) err "Invalid choice";;
  esac


}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"