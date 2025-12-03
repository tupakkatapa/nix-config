#!/usr/bin/env bash
set -euo pipefail

# dep-hunter - Find large dependencies in NixOS closures
# Usage: dep-hunter [options] <hostname>
#
# Example: dep-hunter torgue

VERSION="0.1.0"
THRESHOLD_MB=100
VERBOSE=0
HOSTNAME=""
# Packages to skip (output artifacts or essential components, not optimizable)
BLACKLIST=("squashfs.img" "initrd" "kexec-tree" "kexec-boot" "linux-")

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <hostname>

Find large dependencies in NixOS closures.

ARGUMENTS:
    <hostname>              NixOS hostname to analyze (e.g., torgue, vladof)

OPTIONS:
    -t, --threshold MB      Size threshold in MiB (default: 100)
    -v, --verbose           Verbose output (show full dependency chains)
    -h, --help              Show this help message

EXAMPLES:
    # Analyze with default threshold (100 MiB)
    $(basename "$0") torgue

    # Custom threshold (200 MiB)
    $(basename "$0") -t 200 torgue

    # Verbose mode (show full chains)
    $(basename "$0") -v vladof

EOF
  exit 0
}

log() {
  if [ "$VERBOSE" -eq 1 ]; then
    echo "[$(date +'%H:%M:%S')] $*" >&2
  else
    echo "$*" >&2
  fi
}

verbose() {
  if [ "$VERBOSE" -eq 1 ]; then
    log "$@"
  fi
}

# Parse size string (e.g., "322.0 MiB") to MiB value
parse_size() {
  local size_str="$1"
  local value unit

  value=$(echo "$size_str" | grep -oE '[0-9]+\.[0-9]+|[0-9]+')
  unit=$(echo "$size_str" | grep -oE 'KiB|MiB|GiB')

  case "$unit" in
  KiB)
    awk "BEGIN {print $value / 1024}"
    ;;
  MiB)
    echo "$value"
    ;;
  GiB)
    awk "BEGIN {print $value * 1024}"
    ;;
  *)
    echo "0"
    ;;
  esac
}

# Extract package name from store path
get_package_name() {
  local path="$1"
  basename "$path" | sed 's/^[^-]*-//'
}

# Find package size in path-info
get_package_size() {
  local package_path="$1"
  local path_info="$2"

  grep -F "$package_path" "$path_info" | awk '{print $2, $3}' || echo "0 MiB"
}

# Format size for display (show KiB if < 1 MiB)
format_size() {
  local size_mb="$1"
  if awk "BEGIN {exit !($size_mb < 1)}"; then
    local size_kib=$(awk "BEGIN {printf \"%.1f\", $size_mb * 1024}")
    echo "${size_kib} KiB"
  else
    echo "${size_mb} MiB"
  fi
}

# Analyze package using mathematical properties
# Returns: suggestion or empty if not suspicious
analyze_package() {
  local pkg_size_mb="$1"
  local full_chain_str="$2"
  local root_size_mb="$3"

  # Skip if root is tiny config file (< 0.1 MiB = 100 KiB)
  if awk "BEGIN {exit !($root_size_mb < 0.1)}"; then
    return
  fi

  # Calculate chain length from full chain (before simplification)
  local chain_length
  if [ -n "$full_chain_str" ]; then
    chain_length=$(echo "$full_chain_str" | grep -o '→' | wc -l)
    chain_length=$((chain_length + 1))
  else
    chain_length=1
  fi

  # Calculate size ratio (how many times larger than root)
  local ratio=1
  if awk "BEGIN {exit !($root_size_mb > 0)}"; then
    ratio=$(awk "BEGIN {printf \"%.1f\", $pkg_size_mb / $root_size_mb}")
  fi

  # Format root size for display
  local root_size_display=$(format_size "$root_size_mb")

  # Mark based on mathematical properties
  # Only flag: Small root pulling in large dependency (ratio > 5x, chain > 2)
  if [ "$chain_length" -gt 2 ] && awk "BEGIN {exit !($ratio > 5)}"; then
    echo "Small root (${root_size_display}) pulls large dep (${ratio}x) - consider override or alternative"
  fi
}

# Build dependency chain by following referrers
# Outputs: line 1 = root path, line 2 = chain string
build_dependency_chain() {
  local pkg_path="$1"
  local max_depth="${2:-5}"
  local depth=0
  local current="$pkg_path"
  local chain=()

  while [ $depth -lt $max_depth ]; do
    local referrers
    referrers=$(nix-store --query --referrers "$current" 2>/dev/null | grep -v "^$current$" || echo "")

    if [ -z "$referrers" ]; then
      break
    fi

    # Get first referrer
    local parent
    parent=$(echo "$referrers" | head -1)

    # Extract package name
    local parent_name
    parent_name=$(get_package_name "$parent")

    chain+=("$parent_name")
    current="$parent"
    depth=$((depth + 1))
  done

  # Output root path on first line
  echo "$current"

  # Print chain in reverse (root first) on second line
  if [ ${#chain[@]} -gt 0 ]; then
    printf '%s' "${chain[-1]}"
    for ((i = ${#chain[@]} - 2; i >= 0; i--)); do
      printf ' → %s' "${chain[i]}"
    done
    echo ""
  else
    echo ""
  fi
}

# Main function
main() {
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
    -t | --threshold)
      THRESHOLD_MB="$2"
      shift 2
      ;;
    -v | --verbose)
      VERBOSE=1
      shift
      ;;
    -h | --help)
      usage
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      ;;
    *)
      HOSTNAME="$1"
      shift
      ;;
    esac
  done

  if [ -z "$HOSTNAME" ]; then
    echo "Error: Missing hostname" >&2
    usage
  fi

  # Construct flake attribute path
  local flake_attr=".#nixosConfigurations.${HOSTNAME}.config.system.build.toplevel"

  log "dep-hunter v$VERSION"
  log "Host: ${HOSTNAME}"
  log "Threshold: ${THRESHOLD_MB} MiB"
  log ""

  # Generate path-info in /tmp
  local PATH_INFO_FILE="/tmp/path-info-$(date +%s).txt"
  log "Generating path-info..."
  nix path-info --impure -rsSh "$flake_attr" >"$PATH_INFO_FILE"
  log "Generated: $PATH_INFO_FILE"

  log ""
  log "Analyzing large packages..."
  log ""

  # Find packages over threshold
  local large_packages=()
  while IFS= read -r line; do
    local pkg_path size_str
    pkg_path=$(echo "$line" | awk '{print $1}')
    size_str=$(echo "$line" | awk '{print $2, $3}') # Get both number and unit

    local size_mb
    size_mb=$(parse_size "$size_str")

    if awk "BEGIN {exit !($size_mb >= $THRESHOLD_MB)}"; then
      large_packages+=("$pkg_path:$size_str")
    fi
  done <"$PATH_INFO_FILE"

  # Filter out blacklisted packages and build analysis data
  local -a filtered_packages=()
  for pkg_info in "${large_packages[@]}"; do
    IFS=':' read -r pkg_path size_str <<<"$pkg_info"
    local pkg_name
    pkg_name=$(get_package_name "$pkg_path")

    # Skip blacklisted packages
    local skip=0
    for blacklisted in "${BLACKLIST[@]}"; do
      if [[ $pkg_name == *"$blacklisted"* ]]; then
        verbose "Skipping blacklisted: $pkg_name ($size_str)"
        skip=1
        break
      fi
    done
    [ "$skip" -eq 1 ] && continue

    filtered_packages+=("$pkg_info")
  done

  log "Found ${#filtered_packages[@]} packages over ${THRESHOLD_MB} MiB (after filtering)"
  log ""

  # Build output entries with size prefix for sorting
  local -a output_entries=()
  for pkg_info in "${filtered_packages[@]}"; do
    IFS=':' read -r pkg_path size_str <<<"$pkg_info"
    local pkg_name
    pkg_name=$(get_package_name "$pkg_path")
    local size_mb
    size_mb=$(parse_size "$size_str")

    verbose "Analyzing: $pkg_name ($size_str)"

    # Build full dependency chain
    local chain_output root_path chain_str root_name
    chain_output=$(build_dependency_chain "$pkg_path")
    root_path=$(echo "$chain_output" | head -1)
    chain_str=$(echo "$chain_output" | tail -1)

    # Get root package size for analysis
    local root_size_mb=0
    local root_size_str suggestion
    if [ -n "$chain_str" ] && [ "$root_path" != "$pkg_path" ]; then
      root_name=$(get_package_name "$root_path")
      root_size_str=$(get_package_size "$root_path" "$PATH_INFO_FILE")
      root_size_mb=$(parse_size "$root_size_str")

      # Analyze package (using full chain for length calculation)
      suggestion=$(analyze_package "$size_mb" "$chain_str" "$root_size_mb")

      # Build chain string based on verbose mode
      local chain_display
      if [ "$VERBOSE" -eq 1 ]; then
        chain_display="$chain_str"
      else
        chain_display="$root_name → ... → $pkg_name"
      fi

      # Build sortable entry with analysis
      output_entries+=("$(printf "%010.1f\t%s\t%s\t%s\t%s" "$size_mb" "$size_str" "$pkg_name" "$chain_display" "$suggestion")")
    else
      output_entries+=("$(printf "%010.1f\t%s\t%s\t\t" "$size_mb" "$size_str" "$pkg_name")")
    fi
  done

  # Sort by size (descending) and display
  echo "LARGE PACKAGES FOUND (sorted by size):"
  echo ""
  local display_count=0
  while IFS=$'\t' read -r _ size_str pkg_name chain_info suggestion; do
    echo "   ${size_str} - ${pkg_name}"
    if [ -n "$chain_info" ]; then
      echo "      Chain: $chain_info"
    else
      echo "      (root-level package)"
    fi
    if [ -n "$suggestion" ]; then
      echo "      Note: $suggestion"
    fi
    echo ""
    display_count=$((display_count + 1))
  done < <(printf '%s\n' "${output_entries[@]}" | sort -rn)

  log "Summary:"
  log "  Total large packages displayed: $display_count"
  log ""
  log "Next steps:"
  log "  1. Review packages above and identify optimization candidates"
  log "  2. Check package definitions: https://search.nixos.org/packages"
  log "  3. Consider overriding to exclude heavy dependencies"
  log "  4. Move to runtime-modules if not needed in initrd"
}

main "$@"
