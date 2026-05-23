#!/usr/bin/env bash
# Centered warning when memory usage crosses a threshold.
# Usage: mem-warn [THRESHOLD_PERCENT]  (default 90)

set -euo pipefail

THRESHOLD="${1:-90}"
APP_NAME="warning"
SYNC_ID="mem-warn"
STATEFILE="/run/user/$(id -u)/mem-warn.state"

read -r _ total _ < <(grep '^MemTotal:' /proc/meminfo)
read -r _ avail _ < <(grep '^MemAvailable:' /proc/meminfo)
used_pct=$(((total - avail) * 100 / total))

prev=0
[ -f "$STATEFILE" ] && prev=$(cat "$STATEFILE")
echo "$used_pct" >"$STATEFILE"

# Only fire on rising edge across the threshold
if [ "$used_pct" -ge "$THRESHOLD" ] && [ "$prev" -lt "$THRESHOLD" ]; then
  notify-send --app-name="$APP_NAME" -u critical -t 5000 \
    -h "string:x-canonical-private-synchronous:$SYNC_ID" \
    "Memory ${used_pct}%"
fi
