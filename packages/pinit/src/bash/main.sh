#!/usr/bin/env bash

set -o pipefail
trap 'exit 0' SIGINT

# Initial argument values
name=""

# Display usage information
display_usage() {
  cat <<USAGE
Usage: foobar [OPTIONS...] [ARGUMENT]

Description:
  Brief description of what the script does

Arguments:
  ARGUMENT
    Description of any required or optional positional arguments

Options:
  -n, --name VALUE
    Description of the name option

  -h, --help
    Show this help message

Examples:
  foobar -n name

USAGE
}

# Parse and validate command line arguments
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
    -n | --name)
      name="$2"
      shift 2
      ;;
    -h | --help)
      display_usage
      exit 0
      ;;
    *)
      echo "error: unknown option '$1'"
      echo "try '--help' for more information."
      display_usage
      exit 1
      ;;
    esac
  done
}

# Main function
main() {
  parse_arguments "$@"

  echo "Hello, $name!"
}

main "$@"
