#!/usr/bin/env bash
# Centered countdown notification; cursor movement cancels, else loginctl lock-session.
# Usage: lock-countdown [SECONDS] [nolock] | lock-countdown cancel

set -euo pipefail

PIDFILE="/run/user/$(id -u)/lock-countdown.pid"
APP_NAME="lock-countdown"
SYNC_ID="lock-countdown"

cancel_running() {
  if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    kill "$(cat "$PIDFILE")" 2>/dev/null || true
    rm -f "$PIDFILE"
    # Dismiss the synchronous notification via a 1ms blank replacement
    notify-send --app-name="$APP_NAME" -t 1 \
      -h "string:x-canonical-private-synchronous:${SYNC_ID}" " "
  fi
}

if [ "${1:-}" = "cancel" ]; then
  cancel_running
  exit 0
fi

SECONDS_TOTAL="${1:-10}"
LOCK_AT_END=1
[ "${2:-}" = "nolock" ] && LOCK_AT_END=0

# Don't stack countdowns
cancel_running

# Skip if already locked
if pgrep -x hyprlock >/dev/null; then
  exit 0
fi

echo $$ >"$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT
trap 'exit 0' TERM INT

# Initial cursor position; mouse movement cancels
START_POS=$(hyprctl cursorpos 2>/dev/null || echo "")

for i in $(seq "$SECONDS_TOTAL" -1 1); do
  # -t 1100 must match default-timeout in the mako rule `app-name=lock-countdown`
  notify-send --app-name="$APP_NAME" -t 1100 \
    -h "string:x-canonical-private-synchronous:${SYNC_ID}" \
    -h "int:value:$((i * 100 / SECONDS_TOTAL))" \
    "Idle. Locking in ${i}.."
  # Poll cursor 10x/sec for responsive cancel
  for _ in $(seq 1 10); do
    sleep 0.1
    if [ -n "$START_POS" ] && [ "$(hyprctl cursorpos 2>/dev/null)" != "$START_POS" ]; then
      cancel_running
      exit 0
    fi
  done
done

if [ "$LOCK_AT_END" = "1" ]; then
  loginctl lock-session
fi
