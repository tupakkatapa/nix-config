#!/usr/bin/env bash
# Script to select and open files or directories
# deps: wofi, xdg-open

set -euo pipefail

# Config
DMENU="wofi --dmenu -w 1 --insensitive"
ITEMS=(
  "/mnt/sftp/docs/tabs"
  #"/home/kari/Workspace/nix-config"
)

# Function to list files and directories
list_items() {
    for item in "${ITEMS[@]}"; do
        if [ -d "$item" ]; then
            # It's a directory, list all files inside
            find "$item" -type f
        elif [ -f "$item" ]; then
            # It's a file, list it
            echo "$item"
        fi
    done
}

main() {
    choice=$(printf '%s\n' "$(list_items)" | \
        sort | \
        ${DMENU} 'Select file or directory: ' "$@") || exit 1

    if [ -n "$choice" ]; then
        xdg-open "$choice" &> /dev/null
    else
        echo "Program terminated." && exit 0
    fi
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
