#!/usr/bin/env bash
# Script to select and open files or directories with specific find options

DMENU="wofi --dmenu -w 1 --insensitive"
USE_VIM=0

# Display usage information
display_usage() {
  cat <<USAGE
Usage: $0 [OPTIONS..] <paths> [--type f|d] [--depth N] [--iname pattern]

Description:
  Select and open files or directories with specific find options.

Options:
  --vim
    Open files in Vim/Neovim if available, otherwise use xdg-open.

  -t, --type [f|d]
    Type of files to find (f for files, d for directories).

  -d, --depth N
    Descend at most N directory levels below the command line arguments.

  --iname, -i
    Search for files or directories with case-insensitive name matching the pattern.

  -h, --help
    Display this help message and exit.
USAGE
}

# Parse and validate command line arguments
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --vim)
      USE_VIM=1
      shift
      ;;
    -t|--type)
      FIND_FLAGS+=("-type" "$2")
      shift 2
      ;;
    -d|--depth)
      FIND_FLAGS+=("-maxdepth" "$2")
      shift 2
      ;;
    -i|--iname)
      FIND_FLAGS+=("-iname" "$2")
      shift 2
      ;;
    -h|--help)
      display_usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1"
      display_usage
      exit 1
      ;;
    *)
      ITEMS+=("$1")
      shift
      ;;
    esac
  done
}

FIND_FLAGS=()
ITEMS=()
parse_arguments "$@"

# Check if there are any items to process
if [ ${#ITEMS[@]} -eq 0 ]; then
    echo "No valid file paths provided."
    exit 1
fi

check_exists() {
    [ -e "$1" ] && return 0 || return 1
}

list_items() {
    for item in "${ITEMS[@]}"; do
        if check_exists "$item"; then
            find "$item" "${FIND_FLAGS[@]}"
        else
            echo "File or directory does not exist: $item" >&2
        fi
    done
}

open_with_vim() {
    if command -v nvim &> /dev/null; then
        alacritty -e nvim "$1"
    elif command -v vim &> /dev/null; then
        alacritty -e vim "$1"
    else
        xdg-open "$1"
    fi
}

main() {
    choice=$(printf '%s\n' "$(list_items)" | \
        sort | \
        ${DMENU} 'Select file or directory: ') || exit 1

    if [ -n "$choice" ]; then
        if [ $USE_VIM -eq 1 ]; then
            open_with_vim "$choice"
        else
            xdg-open "$choice"
        fi
    else
        echo "Program terminated." && exit 0
    fi
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"

