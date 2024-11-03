#!/usr/bin/env bash
# wofi - flat list bookmarks, custom search shortcuts, and installed programs

profile_dir_name="personal"
places_file="/home/$USER/.mozilla/firefox/${profile_dir_name}/places.sqlite"
places_backup="/home/$USER/.mozilla/firefox/${profile_dir_name}/places.wofi.sqlite"
search_shortcuts_file="@SHORTCUTS_FILE_PATH@"
sqlite_path="$(command -v sqlite3)"
sqlite_params="-separator ^"

# Create backup if required
[[ -f "$places_file" && "$places_file" -nt "$places_backup" ]] && cp "$places_file" "$places_backup"

# Function definitions
fetch_bookmarks() {
  query="SELECT b.title, p.url FROM moz_bookmarks AS b LEFT JOIN moz_places AS p ON b.fk=p.id WHERE b.type=1 AND p.hidden=0 AND b.title IS NOT NULL"
  $sqlite_path $sqlite_params "$places_backup" "$query" | \
  sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' | \
  awk -F'^' '{print ($1 == "" ? $2 : $1) " [" $2 "]"}'
}

fetch_desktop_entries() {
  IFS=':' read -ra desktop_dirs <<< "$XDG_DATA_DIRS"
  desktop_dirs+=("$XDG_DATA_HOME/applications")

  for dir in "${desktop_dirs[@]}"; do
    app_dir="${dir}/applications"
    if [ -d "$app_dir" ]; then
      find "$app_dir" -name "*.desktop" -print0 | while IFS= read -r -d '' file; do
        app_name=$(grep -m 1 "^Name=" "$file" | cut -d= -f2)
        exec_cmd=$(grep -m 1 "^Exec=" "$file" | sed 's/^Exec=//; s/ *%[fFuUdDnNickvm]//g')
        [ -n "$app_name" ] && [ -n "$exec_cmd" ] && printf "%s [run:%s]\n" "$app_name" "$exec_cmd"
      done
    fi
  done
}

fetch_shortcuts() {
  jq -r '.shortcuts[] | "\(.shortcut): \(.description) [shortcut]"' "$search_shortcuts_file" 2>/dev/null
}

# Run fetching functions in parallel
bookmarks_output=$(fetch_bookmarks &)
desktop_entries_output=$(fetch_desktop_entries &)
shortcuts_output=$(fetch_shortcuts &)
wait

# Combine and display entries
selection=$( (echo "$bookmarks_output"; echo "$desktop_entries_output"; echo "$shortcuts_output") | sort -u | wofi --dmenu --prompt "Select a bookmark, app, or enter search shortcut")

# Handle selection
if [[ "$selection" =~ ^([a-z]+):\ (.+) ]]; then
  search_engine="${BASH_REMATCH[1]}"
  query="${BASH_REMATCH[2]}"
  url_template=$(jq -r ".shortcuts[] | select(.shortcut == \"$search_engine\") | .url" "$search_shortcuts_file")
  firefox "${url_template//%s/$query}" &
elif [ -n "$selection" ]; then
  entry=$(echo "$selection" | awk -F'[][]' '{print $2}')
  if [[ "$entry" =~ ^run:(.+)$ ]]; then
    eval "${BASH_REMATCH[1]}" &
  else
    firefox "$entry" &
  fi
fi
