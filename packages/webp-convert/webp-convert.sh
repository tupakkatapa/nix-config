#!/usr/bin/env bash
set -uo pipefail

verbose=false

display_usage() {
  cat <<USAGE
Usage: webp-convert [OPTIONS] PATH...

Description:
  Convert WebP images to JPEG or PNG and remove the original.
  Lossy without alpha becomes JPEG (quality 92), everything else PNG.
  Animated and empty files are skipped; an existing target is never
  overwritten (photo-1.jpg). A directory converts its *.webp files.
  Prints each written file to stdout.

Options:
  -v, --verbose    Show skipped files
  -h, --help       Show this help
USAGE
}

# Output function with optional verbose-only mode and timestamps
# Usage:
#   say "message"          - always shown (with timestamp if verbose enabled)
#   say verbose "message"  - only shown when verbose flag is set
say() {
  local message
  local verbose_only=false

  if [[ $1 == "verbose" ]]; then
    verbose_only=true
    shift
  fi

  message="$*"

  if [[ $verbose_only == true ]] && [[ $verbose == false ]]; then
    return
  fi

  if [[ $verbose == true ]]; then
    echo "[$(date '+%H:%M:%S')] $message" >&2
  else
    echo "$message" >&2
  fi
}

die() {
  say "$@"
  exit 1
}

# First free name: photo.jpg, photo-1.jpg, photo-2.jpg, ...
target() {
  local base="$1" ext="$2" out="$1.$2" n=1
  while [[ -e $out ]]; do
    out="$base-$n.$ext"
    n=$((n + 1))
  done
  echo "$out"
}

convert_file() {
  local file="$1" info out

  # Firefox holds the final name with an empty file while downloading
  if [[ ! -s $file ]]; then
    say verbose "skipped empty: $file"
    return 0
  fi
  if ! info=$(webpinfo "$file" 2>/dev/null); then
    say "not a WebP image: $file"
    return 1
  fi
  if grep -q "Animation: 1" <<<"$info"; then
    say verbose "skipped animated: $file"
    return 0
  fi

  if grep -q "Format: Lossy" <<<"$info" && ! grep -q "Alpha: 1" <<<"$info"; then
    out=$(target "${file%.*}" jpg)
    if ! dwebp -quiet -ppm "$file" -o - | cjpeg -quality 92 >"$out"; then
      rm -f "$out"
      say "failed: $file"
      return 1
    fi
  else
    out=$(target "${file%.*}" png)
    if ! dwebp -quiet "$file" -o "$out"; then
      rm -f "$out"
      say "failed: $file"
      return 1
    fi
  fi

  rm "$file"
  echo "$out"
}

paths=()
while [[ $# -gt 0 ]]; do
  case "$1" in
  -v | --verbose)
    verbose=true
    shift
    ;;
  -h | --help)
    display_usage
    exit 0
    ;;
  --)
    shift
    paths+=("$@")
    break
    ;;
  -*) die "unknown flag: $1" ;;
  *)
    paths+=("$1")
    shift
    ;;
  esac
done

[[ ${#paths[@]} -gt 0 ]] || {
  display_usage >&2
  exit 1
}

shopt -s nullglob nocaseglob
status=0
for path in "${paths[@]}"; do
  if [[ -d $path ]]; then
    for file in "$path"/*.webp; do
      convert_file "$file" || status=1
    done
  else
    convert_file "$path" || status=1
  fi
done
exit "$status"
