#!/usr/bin/env bash
# Centered warning when battery drops past a level while discharging.
# Usage: bat-warn [LEVEL_PERCENT...]  (default 20 10 5)
# Fires once per level crossed; unplugging below a level counts as crossing it.

set -euo pipefail

[ "$#" -gt 0 ] || set -- 20 10 5
APP_NAME="warning"
SYNC_ID="bat-warn"
STATEFILE="/run/user/$(id -u)/bat-warn.state"

bat=$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' -print -quit)
[ -n "$bat" ] || exit 0

capacity=$(cat "$bat/capacity")
status=$(cat "$bat/status")

# Not discharging: reset, so next unplug re-arms every level
if [ "$status" != "Discharging" ]; then
  echo 100 >"$STATEFILE"
  exit 0
fi

prev=100
[ -f "$STATEFILE" ] && prev=$(cat "$STATEFILE")
echo "$capacity" >"$STATEFILE"

for level in "$@"; do
  if [ "$capacity" -le "$level" ] && [ "$prev" -gt "$level" ]; then
    notify-send --app-name="$APP_NAME" -u critical -t 5000 \
      -h "string:x-canonical-private-synchronous:$SYNC_ID" \
      "Battery ${capacity}%"
    break
  fi
done
