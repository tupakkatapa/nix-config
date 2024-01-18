#!/usr/bin/env bash
# Script to select and open files or directories

DMENU="wofi --dmenu -w 1 --insensitive"

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <paths>"
    exit 1
fi

ITEMS=("$@")

check_exists() {
    [ -e "$1" ] && return 0 || return 1
}

list_items() {
    for item in "${ITEMS[@]}"; do
        if check_exists "$item"; then
            if [ -d "$item" ]; then
                find "$item" -type f
            elif [ -f "$item" ]; then
                echo "$item"
            else
                echo "Invalid file or directory: $item" >&2
            fi
        else
            echo "File or directory does not exist: $item" >&2
        fi
    done
}

main() {
    choice=$(printf '%s\n' "$(list_items)" | \
        sort | \
        ${DMENU} 'Select file or directory: ' "$@") || exit 1

    if [ -n "$choice" ]; then
        # Check if the file is a text file
        if file -b --mime-type "$choice" | grep -qE '^text/'; then
            alacritty -e nvim "$choice" &> /dev/null
        else
            xdg-open "$choice" &> /dev/null
        fi
    else
        echo "Program terminated." && exit 0
    fi
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"


