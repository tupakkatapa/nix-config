#!/usr/bin/env bash

# Initial argument values
config="$HOME/.config/fish/config.fish"

# Display usage information
display_usage() {
  cat <<USAGE
Usage: fissh [OPTIONS..] [USER@]HOST[:PORT]

Description:
  Bring your fish and keys with you

Options:
  -c, --config PATH
    Path to local fish config (default: '$config').

USAGE
}

# Parse and validate command line arguments
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
    -c | --config)
      config="$2"
      shift 2
      ;;
    -h | --help)
      display_usage
      exit 0
      ;;
    *)
      destination="$1"
      shift
      ;;
    esac
  done

  # Check if the fish config exists
  if [ ! -f "$config" ]; then
      echo "Error: file not found -- '$config'"
      exit 1
  fi
}

parse_arguments "$@"

# Check arguments
if [ "$#" -lt 1 ]; then
    echo "Usage: fissh [OPTIONS..] [USER@]HOST[:PORT]"
    echo "Try '--help' for more information."
    exit 1
fi

# Extract local abbreviations
abbrevations=$(fish -c 'abbr --show')

# Connect to the remote server
ssh -At "$destination" "fish --init-command '$abbrevations'"

