#!/usr/bin/env bash
# Couch home screen: one app on screen at a time, the others running hidden.
# Runtime-module apps build detached and one at a time, so closing a window
# never interrupts a build.
set -euo pipefail

: "${ICONS:?}" "${TERMINAL:?}"
jobs=$XDG_RUNTIME_DIR/couch-menu
mkdir -p "$jobs"

running() {
  local pid
  pid=$(cat "$jobs/$1.pid" 2>/dev/null) || return 1
  [[ "$(tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null)" == *"/couch-menu --build $1 " ]]
}

installed() { [ -x "/run/current-system/sw/bin/$1" ]; }

# -f: a rebuild interrupted earlier may have left the module recorded as enabled
build() {
  echo $$ >"$jobs/$1.pid"
  rm -f "$jobs/$1.failed"
  {
    flock -n 9 || {
      echo "Waiting for the previous build..."
      flock 9
    }
    sudo -n runtime-modules -f enable "$1" || touch "$jobs/$1.failed"
  } 9>"$jobs/lock" >"$jobs/$1.log" 2>&1
  rm -f "$jobs/$1.pid"
}

# Shows the build log until the build ends; succeeds only when a retry is wanted
follow() {
  tail -n +1 -F "$jobs/$1.log" 2>/dev/null &
  local tailpid=$!
  while running "$1"; do sleep 1; done
  sleep 1
  kill "$tailpid"
  if [ -e "$jobs/$1.failed" ]; then
    read -r -p $'\nBuild failed. Enter retries, Alt+Q closes. '
    return 0
  fi
  sleep 1
  return 1
}

queue() {
  setsid -f "$0" --build "$1" </dev/null >/dev/null 2>&1
  for _ in $(seq 20); do
    running "$1" && return
    sleep 0.1
  done
}

tree() { swaymsg -t get_tree; }

# The menu is a layer surface, so every window in the tree belongs to an app;
# the scratchpad lives under the "__i3" output and holds the hidden ones
visible() {
  [ "$(tree | jq '[.nodes[] | select(.name != "__i3") | recurse(.nodes[]?, .floating_nodes[]?) | select(.pid?)] | length')" -gt 0 ]
}

has_mark() {
  tree | jq -e --arg mark "$1" 'any(recurse(.nodes[]?, .floating_nodes[]?); (.marks? // []) | index($mark))' >/dev/null
}

# A launcher that exits early has handed off to a running instance, whose
# window still has to appear
start() {
  local mark=$1 before id pid ticks=0
  shift
  before=$(tree | jq -c '[recurse(.nodes[]?, .floating_nodes[]?) | select(.pid?) | .id]')
  # A scope still alive here has lost its window, like Steam left in the background
  systemctl --user stop "couch-$mark.scope" 2>/dev/null || true
  systemd-run --user --scope --quiet --unit="couch-$mark" -- "$@" &
  pid=$!
  until id=$(tree | jq -e --argjson before "$before" \
    'first(recurse(.nodes[]?, .floating_nodes[]?) | select(.pid? and (.id as $id | $before | index($id) | not)) | .id)'); do
    if kill -0 "$pid" 2>/dev/null; then
      [ "$ticks" -lt 240 ] || return 1
    else
      [ "$ticks" -lt 10 ] || return 1
    fi
    ticks=$((ticks + 1))
    sleep 0.5
  done
  swaymsg "[con_id=$id] mark --add $mark" >/dev/null
}

# Returns once nothing is on screen
show() {
  local mark=$1
  if has_mark "$mark"; then
    swaymsg "[con_mark=\"$mark\"] scratchpad show, floating disable, fullscreen enable" >/dev/null
  else
    start "$@" || return 0
  fi
  while visible; do sleep 0.5; done
}

# Terminals close; apps only hide and keep running
close() {
  if tree | jq -e 'any(..; .focused? == true and .app_id? == "foot")' >/dev/null; then
    swaymsg kill >/dev/null
  else
    swaymsg move scratchpad >/dev/null
  fi
}

launch() {
  local module=$1
  shift
  if running "$module" || { ! installed "$1" && [ -e "$jobs/$module.failed" ]; }; then
    ! "$TERMINAL" "$0" --follow "$module" || queue "$module"
  elif installed "$1"; then
    show "$module" "$@"
  else
    queue "$module"
  fi
}

icon() {
  if running "$1"; then
    echo "$ICONS/$2-busy.png"
  elif installed "$2"; then
    echo "$ICONS/$2-on.png"
  else
    echo "$ICONS/$2-off.png"
  fi
}

entry() { printf '%s\0icon\x1f%s\n' "$1" "$2"; }

case ${1:-} in
--build)
  build "$2"
  exit
  ;;
--follow)
  follow "$2"
  exit
  ;;
--close)
  close
  exit
  ;;
esac

# Apps outlive the session that started them, and a stale Firefox holds the
# profile the new one needs
systemctl --user stop 'couch-*.scope' 2>/dev/null || true

firefox=(firefox --kiosk https://plex.coditon.com/web https://www.youtube.com/feed/subscriptions)
! start firefox "${firefox[@]}" || swaymsg '[con_mark="firefox"] move scratchpad' >/dev/null

selected=Firefox
while true; do
  # Outlives a restarted session otherwise, and would draw on the next one
  swaymsg -t get_version >/dev/null 2>&1 || exit 0

  choice=$({
    entry Firefox "$ICONS/firefox.png"
    entry RetroArch "$(icon retroarch retroarch)"
    entry Steam "$(icon rt.steam steam)"
    entry Plexamp "$(icon plexamp plexamp)"
  } | fuzzel --dmenu --select="$selected") || {
    sleep 0.5
    continue
  }
  selected=$choice
  case $choice in
  Firefox) show firefox "${firefox[@]}" ;;
  RetroArch) launch retroarch retroarch ;;
  Steam) launch rt.steam steam -bigpicture ;;
  Plexamp) launch plexamp plexamp ;;
  esac || true
done
