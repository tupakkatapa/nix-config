#!/usr/bin/env bash
# Debounced brightness control for waybar
# Scroll changes target instantly, ddcutil applies after idle timeout

TARGET_FILE="/tmp/brightness-target"
CONTRAST_FILE="/tmp/brightness-contrast"
PID_FILE="/tmp/brightness-apply.pid"
DEBOUNCE=1 # seconds

# Get current brightness from ddcutil (slow)
get_actual() {
  ddcutil getvcp 10 2>/dev/null | awk -F'current value = |, max' '{gsub(/ /,"",$2); print $2}'
}

# Get current target (or seed from actual on first call)
# Returns empty if ddcutil is unavailable (no DDC-CI, e.g. laptop)
get_target() {
  if [[ -f $TARGET_FILE ]]; then
    cat "$TARGET_FILE"
  else
    local actual
    actual=$(get_actual)
    [[ -z $actual ]] && return 1
    echo "$actual" | tee "$TARGET_FILE"
  fi
}

case "$1" in
up | down)
  current=$(get_target) || exit 0
  if [[ $1 == "up" ]]; then
    new=$((current + 1))
    ((new > 100)) && new=100
  else
    new=$((current - 1))
    ((new < 0)) && new=0
  fi
  echo "$new" >"$TARGET_FILE"

  # Kill pending apply
  if [[ -f $PID_FILE ]]; then
    kill "$(cat "$PID_FILE")" 2>/dev/null
  fi

  # Schedule debounced apply and sync contrast cache
  (
    sleep "$DEBOUNCE"
    ddcutil setvcp 10 "$(cat "$TARGET_FILE")" 2>/dev/null
    contrast=$(ddcutil getvcp 12 2>/dev/null | awk -F'current value = |, max' '{gsub(/ /,"",$2); print $2}')
    [[ -n $contrast ]] && echo "$contrast" >"$CONTRAST_FILE"
    rm -f "$PID_FILE"
    pkill -RTMIN+8 waybar
  ) &
  echo $! >"$PID_FILE"

  # Signal waybar to refresh immediately
  pkill -RTMIN+8 waybar
  ;;

show)
  # Fast path: only reads files, no ddcutil
  brightness=$(get_target) || exit 0
  contrast=$(cat "$CONTRAST_FILE" 2>/dev/null || echo "?")
  printf '{"text": "󰃟 %s%%", "tooltip": "Brightness: %s%%\\nContrast: %s%%", "percentage": %s}\n' \
    "$brightness" "$brightness" "$contrast" "$brightness"
  # Seed contrast cache in background on first run
  if [[ ! -f $CONTRAST_FILE ]]; then
    (ddcutil getvcp 12 2>/dev/null | awk -F'current value = |, max' '{gsub(/ /,"",$2); print $2}' >"$CONTRAST_FILE" && pkill -RTMIN+8 waybar) &
  fi
  ;;

sync)
  # Slow path: queries ddcutil, updates cache (called periodically)
  actual=$(get_actual)
  [[ -n $actual ]] && echo "$actual" >"$TARGET_FILE"
  contrast=$(ddcutil getvcp 12 2>/dev/null | awk -F'current value = |, max' '{gsub(/ /,"",$2); print $2}')
  [[ -n $contrast ]] && echo "$contrast" >"$CONTRAST_FILE"
  ;;
esac
