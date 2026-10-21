#!/usr/bin/env bash
# Float, size and center a window once its title matches. For windows that
# open under a generic title and rename after load, which window rules miss.
# Usage: float-on-title REGEX WIDTH HEIGHT

set -euo pipefail

[ "$#" -eq 3 ] || {
  echo "usage: float-on-title REGEX WIDTH HEIGHT" >&2
  exit 2
}
regex=$1
width=$2
height=$3
sock="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
declare -A seen

socat -u "UNIX-CONNECT:$sock" - | while IFS= read -r line; do
  [[ $line == "windowtitlev2>>"* ]] || continue
  rest=${line#windowtitlev2>>}
  addr=${rest%%,*}
  title=${rest#*,}
  [[ -z ${seen[$addr]:-} && $title =~ $regex ]] || continue
  seen[$addr]=1
  # centerwindow needs focus, which may not have moved yet; place it by hand
  read -r mx my mw mh < <(hyprctl monitors -j | jq -r '.[] | select(.focused) | "\(.x) \(.y) \(.width / .scale | floor) \(.height / .scale | floor)"') || continue
  x=$((mx + (mw - width) / 2))
  y=$((my + (mh - height) / 2))
  hyprctl --batch "dispatch setfloating address:0x$addr; dispatch resizewindowpixel exact $width $height,address:0x$addr; dispatch movewindowpixel exact $x $y,address:0x$addr" >/dev/null
done
