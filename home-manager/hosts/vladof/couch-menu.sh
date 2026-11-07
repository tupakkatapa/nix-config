#!/usr/bin/env bash
# Couch home screen: one app on screen at a time, the others running hidden.
# An app owns the windows of the processes in its systemd scope, so a stray
# window is never mistaken for it. Runtime-module apps build detached, so
# closing a window never interrupts a build, and picks close together share one
# rebuild.
set -euo pipefail

: "${ICONS:?}" "${TERMINAL:?}"
dir=$XDG_RUNTIME_DIR/couch-menu
mkdir -p "$dir"

# Runtime-module apps: menu entry, module and command, whose name the icons share
apps=(
  "RetroArch retroarch retroarch"
  "Steam rt.steam steam -bigpicture"
  "Plexamp plexamp plexamp"
)

running() {
  local pid
  pid=$(cat "$dir/$1.pid" 2>/dev/null) || return 1
  [[ "$(tr '\0' ' ' 2>/dev/null <"/proc/$pid/cmdline")" == *"/couch-menu --build $1 " ]]
}

installed() { [ -x "/run/current-system/sw/bin/$1" ]; }

# Builds queue up and take turns; a turn enables every module queued by then in
# one rebuild, so a module whose turn comes after its rebuild just ends. -f: a
# rebuild interrupted earlier may have left the module recorded as enabled
build() {
  local batch m
  echo $$ >"$dir/$1.pid"
  rm -f "$dir/$1.failed"
  {
    flock 8
    echo "$1" >>"$dir/pending"
  } 8>"$dir/pending.lock"
  {
    flock -n 9 || {
      echo "Waiting for the previous build..."
      flock 9
    }
    if grep -qxF -- "$1" "$dir/pending" 2>/dev/null; then
      # Picks made right after this one join the same rebuild
      sleep 10
      {
        flock 8
        mapfile -t batch < <(LC_ALL=C sort -u "$dir/pending")
        rm "$dir/pending"
      } 8>"$dir/pending.lock"
      : >"$dir/build.log"
      echo "Enabling ${batch[*]}..."
      sudo -n runtime-modules -f enable "${batch[@]}" || for m in "${batch[@]}"; do touch "$dir/$m.failed"; done
    fi
  } 9>"$dir/lock" >>"$dir/build.log" 2>&1
  rm -f "$dir/$1.pid"
}

# Shows the build log until the build ends; succeeds only when a retry is wanted
follow() {
  tail -n +1 -F "$dir/build.log" 2>/dev/null &
  local tailpid=$!
  while running "$1"; do sleep 1; done
  sleep 1
  kill "$tailpid"
  if [ -e "$dir/$1.failed" ]; then
    read -r -p $'\nBuild failed. Enter retries, Alt+Q closes. '
    return 0
  fi
  sleep 1
  return 1
}

# Shows why an app gave no window; succeeds only when a retry is wanted
log() {
  tail -n 40 "$dir/$1.log" 2>/dev/null || true
  systemctl --user status "couch-$1.scope" --no-pager 2>/dev/null | tail -n 5 || true
  read -r -p $'\n'"$2 gave no window. Enter retries, Alt+Q closes. "
}

queue() {
  setsid -f "$0" --build "$1" </dev/null >/dev/null 2>&1
  for _ in $(seq 20); do
    running "$1" && return
    sleep 0.1
  done
}

tree() { swaymsg -t get_tree; }

# "id pid visible" per window; the menu is a layer surface, so every window in
# the tree belongs to an app or a terminal, and the hidden ones sit in the
# scratchpad
windows() {
  tree | jq -r '.. | objects | select(.pid != null) | "\(.id) \(.pid) \(.visible)"'
}

# The app's windows, the one on screen first
windows_of() {
  local id pid vis
  while read -r id pid vis; do
    grep -qF -- "/couch-$1.scope" "/proc/$pid/cgroup" 2>/dev/null && echo "$id $pid $vis"
  done < <(windows) | sort -k3 -r
}

# Succeeds while something is on screen, or while the TV is off, as its windows
# leave the tree until it is back. A sway that is gone ends the menu; a hiccup
# counts as "on screen" so the menu never pops over an app
visible() {
  local n
  n=$(tree | jq '[.. | objects | select(.pid != null and .visible == true)] | length') || {
    swaymsg -t get_version >/dev/null 2>&1 || exit 0
    return 0
  }
  [ "$n" -gt 0 ] || ! swaymsg -t get_outputs | jq -e 'any(.[]; .active)' >/dev/null
}

# Starts the app in its own scope and waits for its first window; fails when
# the launcher dies without one or nothing shows up in two minutes
start() {
  local app=$1 name=$2 pid ticks=0
  shift 2
  # A scope still alive here has lost its window, like Steam left in the background
  systemctl --user stop "couch-$app.scope" 2>/dev/null || true
  echo "Starting $name..." >"$dir/status"
  systemd-run --user --scope --quiet --unit="couch-$app" -p TimeoutStopSec=5 -- "$@" >"$dir/$app.log" 2>&1 &
  pid=$!
  while [ -z "$(windows_of "$app")" ]; do
    if kill -0 "$pid" 2>/dev/null; then
      [ "$ticks" -lt 240 ] || break
    else
      [ "$ticks" -lt 10 ] || break
    fi
    ticks=$((ticks + 1))
    sleep 0.5
  done
  rm -f "$dir/status"
  [ -n "$(windows_of "$app")" ]
}

# Puts the app on screen, starting it when it has no window. A visible window
# only gets focus: "scratchpad show" would toggle it away
raise() {
  local app=$1 name=$2 id='' vis=''
  shift 2
  read -r id _ vis < <(windows_of "$app") || true
  if [ -z "$id" ]; then
    start "$app" "$name" "$@"
  elif [ "$vis" = true ]; then
    swaymsg "[con_id=$id] focus, fullscreen enable" >/dev/null
  else
    swaymsg "[con_id=$id] scratchpad show, floating disable, fullscreen enable" >/dev/null
  fi
}

# Returns once nothing is on screen; a failed start shows its log and retries
show() {
  while ! raise "$@"; do
    "$TERMINAL" "$0" --log "$1" "$2" || return 0
  done
  while visible; do sleep 0.5; done
}

# Apps and the terminal only hide and keep running; anything else closes
close() {
  local id='' pid=''
  read -r id pid < <(tree | jq -r '.. | objects | select(.pid != null and .focused == true) | "\(.id) \(.pid)"') || true
  [ -n "$id" ] || return 0
  if grep -qE '/couch-[^/]+\.scope$' "/proc/$pid/cgroup" 2>/dev/null; then
    swaymsg "[con_id=$id] move scratchpad" >/dev/null
  else
    swaymsg "[con_id=$id] kill" >/dev/null
  fi
}

launch() {
  local module=$1 name=$2
  shift 2
  if running "$module" || { ! installed "$1" && [ -e "$dir/$module.failed" ]; }; then
    ! "$TERMINAL" "$0" --follow "$module" || queue "$module"
  elif installed "$1"; then
    show "$module" "$name" "$@"
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

entries() {
  local app name module cmd
  entry Firefox "$ICONS/firefox.png"
  for app in "${apps[@]}"; do
    read -r name module cmd <<<"$app"
    entry "$name" "$(icon "$module" "${cmd%% *}")"
  done
}

# What builds, else what failed to; nothing when neither
builds() {
  local app name module cmd busy=() failed=()
  for app in "${apps[@]}"; do
    read -r name module cmd <<<"$app"
    if running "$module"; then
      busy+=("$name")
    elif [ -e "$dir/$module.failed" ] && ! installed "${cmd%% *}"; then
      failed+=("$name")
    fi
  done
  if [ "${#busy[@]}" -gt 0 ]; then
    echo "Building $(join "${busy[@]}")…"
  elif [ "${#failed[@]}" -gt 0 ]; then
    echo "$(join "${failed[@]}") failed to build"
  fi
}

join() {
  local list
  list=$(printf ', %s' "$@")
  echo "${list:2}"
}

# Sets $choice. The pad drives the menu while it is open, and the menu closes
# by itself as soon as something is on screen, or reopens when its icons go
# stale, like after a build or a rebuild of the host
menu() {
  local fuzzel dog pad shown
  evsieve --input /dev/input/couch-pad-* grab \
    --map abs:hat0y:-1 key:up:1 --map abs:hat0y:1 key:down:1 --map abs:hat0y:0 key:up:0 key:down:0 \
    --map btn:dpad_up key:up --map btn:dpad_down key:down --map btn:south key:enter \
    --output >/dev/null 2>&1 &
  pad=$!
  shown=$(entries | cksum)
  entries | fuzzel --dmenu --select="$selected" >"$dir/choice" &
  fuzzel=$!
  (while sleep 1; do { visible || [ "$(entries | cksum)" != "$shown" ]; } && kill "$fuzzel" 2>/dev/null; done) &
  dog=$!
  wait "$fuzzel" && choice=$(<"$dir/choice") || choice=
  kill "$dog" "$pad" 2>/dev/null || true
  [ -n "$choice" ]
}

# The bar's status line; the bar shows only while nothing is on screen
bar() {
  local up uptime build
  while true; do
    if [ -e "$dir/status" ]; then
      cat "$dir/status"
    else
      up=$(cut -d. -f1 /proc/uptime)
      if [ "$up" -ge 86400 ]; then
        uptime="$((up / 86400))d $((up % 86400 / 3600))h"
      else
        uptime="$((up / 3600))h $((up % 3600 / 60))m"
      fi
      build=$(builds)
      echo "${build:+$build  ·  }$(uname -n)  ·  up $uptime  ·  $(date +'%d.%m.%Y  %H:%M')"
    fi
    sleep 2
  done
}

case ${1:-} in
--build)
  build "$2"
  exit
  ;;
--follow)
  follow "$2"
  exit
  ;;
--log)
  log "$2" "$3"
  exit
  ;;
--close)
  close
  exit
  ;;
--terminal)
  raise terminal Terminal "$TERMINAL"
  exit
  ;;
--status)
  bar
  exit
  ;;
esac

trap 'rm -f "$dir/status"; jobs -p | xargs -r kill 2>/dev/null' EXIT

# Apps outlive the session that started them, and a stale Firefox holds the
# profile the new one needs
systemctl --user stop 'couch-*.scope' 2>/dev/null || true

firefox=(firefox --kiosk https://plex.coditon.com/web https://www.youtube.com/feed/subscriptions)
if start firefox Firefox "${firefox[@]}"; then
  read -r id _ < <(windows_of firefox)
  swaymsg "[con_id=$id] move scratchpad" >/dev/null
fi

selected=Firefox
while true; do
  # Outlives a restarted session otherwise, and would draw on the next one
  swaymsg -t get_version >/dev/null 2>&1 || exit 0
  while visible; do sleep 0.5; done

  menu || {
    sleep 0.5
    continue
  }
  selected=$choice
  if [ "$choice" = Firefox ]; then
    show firefox Firefox "${firefox[@]}" || true
  else
    for app in "${apps[@]}"; do
      read -r name module cmd <<<"$app"
      [ "$name" = "$choice" ] || continue
      read -ra command <<<"$cmd"
      launch "$module" "$name" "${command[@]}" || true
    done
  fi
done
