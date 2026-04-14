#!/usr/bin/env bash
set -euo pipefail

# dep-hunter - Find large dependencies in NixOS closures
# Usage: dep-hunter [options] <hostname>
#        dep-hunter --current

VERSION="0.2.0"
THRESHOLD_MB=100
VERBOSE=0
HOSTNAME=""
USE_CURRENT=0
PATH_INFO_FILE=""
# Packages to skip (output artifacts, not optimizable)
BLACKLIST=("squashfs.img" "initrd" "kexec-tree" "kexec-boot" "linux-")

cleanup() {
  [ -n "$PATH_INFO_FILE" ] && rm -f "$PATH_INFO_FILE"
}
trap cleanup EXIT

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <hostname>
       $(basename "$0") --current

Find large dependencies in NixOS closures, grouped by root cause.

ARGUMENTS:
    <hostname>              NixOS hostname to analyze (e.g., torgue, vladof)

OPTIONS:
    -c, --current           Analyze /run/current-system (skip flake eval)
    -t, --threshold MB      Size threshold in MiB (default: 100)
    -v, --verbose           Show full dependency chains
    -h, --help              Show this help message

EXAMPLES:
    $(basename "$0") torgue
    $(basename "$0") --current
    $(basename "$0") -t 200 torgue
    $(basename "$0") -v torgue

EOF
  exit 0
}

log() {
  echo "$*" >&2
}

verbose() {
  if [ "$VERBOSE" -eq 1 ]; then
    echo "$*" >&2
  fi
}

# Parse size string (e.g., "322.0 MiB") to MiB float
parse_size() {
  local size_str="$1"
  local value unit
  value=$(echo "$size_str" | grep -oE '[0-9]+\.[0-9]+|[0-9]+')
  unit=$(echo "$size_str" | grep -oE 'KiB|MiB|GiB')
  case "$unit" in
  KiB) awk "BEGIN {printf \"%.1f\", $value / 1024}" ;;
  MiB) echo "$value" ;;
  GiB) awk "BEGIN {printf \"%.1f\", $value * 1024}" ;;
  *) echo "0" ;;
  esac
}

# Extract package name from store path, stripping the hash prefix
get_package_name() {
  local path="$1"
  basename "$path" | sed 's/^[^-]*-//'
}

# Get a display name for a package - adds hash prefix for generic names
get_display_name() {
  local path="$1"
  local name
  name=$(get_package_name "$path")

  # Generic names that need hash prefix for identification
  local generic_names="source|env|deps|lib|dev|out|man|doc|info|data|bin|etc|tmp"
  if [ "${#name}" -le 10 ] && echo "$name" | grep -qE "^($generic_names)$"; then
    local hash
    hash=$(basename "$path" | cut -c1-8)
    echo "${hash}-${name}"
  else
    echo "$name"
  fi
}

# Extract the meaningful root from a nix why-depends chain.
# Skips infrastructure paths (nixos-system-*, etc, system-path, home-manager-*-generation)
# and returns the first "real" package a user would remove from their config.
extract_meaningful_root() {
  local chain="$1"
  local root=""
  local found_anchor=0

  while IFS= read -r node; do
    [ -z "$node" ] && continue

    # Skip the toplevel nixos-system-* entry
    if [[ $node == nixos-system-* ]]; then
      continue
    fi

    # These are infrastructure nodes - the next real package after them is the root
    if [[ $node == "etc" ]] ||
      [[ $node == etc-* ]] ||
      [[ $node == system-path ]] ||
      [[ $node == system-units ]] ||
      [[ $node == home-manager-files ]] ||
      [[ $node == home-manager-path ]] ||
      [[ $node == home-manager-generation ]] ||
      [[ $node == *-home-manager-generation ]] ||
      [[ $node == *-home-manager-files ]] ||
      [[ $node == *-home-manager-path ]] ||
      [[ $node == unit-script-* ]] ||
      [[ $node == unit-* ]] ||
      [[ $node == *.conf ]] ||
      [[ $node == *.d ]] ||
      [[ $node == graphics-drivers ]]; then
      found_anchor=1
      continue
    fi

    # First real package after an anchor (or if no anchor was seen, the first non-toplevel)
    if [ "$found_anchor" -eq 1 ] || [ -z "$root" ]; then
      root="$node"
      break
    fi
  done <<<"$chain"

  echo "$root"
}

# Run nix why-depends and parse the chain into package names (one per line)
get_why_depends_chain() {
  local toplevel="$1"
  local pkg_path="$2"

  local raw_output
  raw_output=$(nix why-depends "$toplevel" "$pkg_path" 2>/dev/null) || return 1

  # Strip ANSI codes, tree drawing chars, and extract store paths
  echo "$raw_output" |
    sed 's/\x1b\[[0-9;]*m//g' |
    sed 's/[│├└─╴╶ ]//g' |
    grep -oE '/nix/store/[a-z0-9]+-[^ ]+' |
    while IFS= read -r path; do
      get_package_name "$path"
    done
}

# Get a simplified chain string for display
get_chain_display() {
  local toplevel="$1"
  local pkg_path="$2"
  local pkg_name="$3"

  local chain_names
  chain_names=$(get_why_depends_chain "$toplevel" "$pkg_path")
  [ -z "$chain_names" ] && return

  # Build array of unique meaningful names
  local -a names=()
  local prev=""
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    # Skip nixos-system-* toplevel
    [[ $name == nixos-system-* ]] && continue
    # Skip consecutive duplicates
    [ "$name" = "$prev" ] && continue
    # Skip infrastructure
    [[ $name == "etc" ]] && continue
    [[ $name == etc-* ]] && continue
    [[ $name == system-units ]] && continue
    [[ $name == unit-script-* ]] && continue
    [[ $name == unit-* ]] && continue
    [[ $name == home-manager-generation ]] && continue
    [[ $name == *-home-manager-generation ]] && continue
    [[ $name == *.conf ]] && continue
    [[ $name == *.d ]] && continue
    [[ $name == graphics-drivers ]] && continue
    names+=("$name")
    prev="$name"
  done <<<"$chain_names"

  # Print as arrow chain
  if [ "${#names[@]}" -gt 0 ]; then
    local result="${names[0]}"
    for ((i = 1; i < ${#names[@]}; i++)); do
      result+=" -> ${names[$i]}"
    done
    echo "$result"
  fi
}

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
    -c | --current)
      USE_CURRENT=1
      shift
      ;;
    -h | --help) usage ;;
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

  if [ "$USE_CURRENT" -eq 0 ] && [ -z "$HOSTNAME" ]; then
    echo "Error: Missing hostname (or use --current)" >&2
    usage
  fi

  # Determine the toplevel store path
  local toplevel=""
  local display_host=""

  if [ "$USE_CURRENT" -eq 1 ]; then
    toplevel=$(readlink -f /run/current-system)
    display_host=$(hostname)
  else
    display_host="$HOSTNAME"
    local flake_attr=".#nixosConfigurations.${HOSTNAME}.config.system.build.toplevel"

    verbose "Evaluating flake attribute..."
    if ! toplevel=$(nix path-info --impure "$flake_attr" 2>&1); then
      echo "Error: System closure not in store. Run first:" >&2
      echo "  nix build --impure --no-link .#nixosConfigurations.${HOSTNAME}.config.system.build.toplevel" >&2
      exit 1
    fi
    # nix path-info returns the store path
    toplevel=$(echo "$toplevel" | tail -1)
  fi

  verbose "Toplevel: $toplevel"

  # Generate path-info
  PATH_INFO_FILE="/tmp/dep-hunter-$$.txt"

  verbose "Generating path-info..."
  if ! nix path-info -rsSh "$toplevel" >"$PATH_INFO_FILE" 2>/dev/null; then
    echo "Error: Failed to query path info for $toplevel" >&2
    if [ "$USE_CURRENT" -eq 0 ]; then
      echo "The closure may not be in the store. Run first:" >&2
      echo "  nix build --impure --no-link .#nixosConfigurations.${HOSTNAME}.config.system.build.toplevel" >&2
    fi
    exit 1
  fi

  # Calculate total closure size and package count
  local total_bytes=0
  local pkg_count=0
  while IFS= read -r line; do
    local size_str
    size_str=$(echo "$line" | awk '{print $2, $3}')
    local size_mb
    size_mb=$(parse_size "$size_str")
    total_bytes=$(awk "BEGIN {printf \"%.1f\", $total_bytes + $size_mb}")
    pkg_count=$((pkg_count + 1))
  done <"$PATH_INFO_FILE"

  local total_gib
  total_gib=$(awk "BEGIN {printf \"%.2f\", $total_bytes / 1024}")

  # Header
  echo "dep-hunter v${VERSION} -- ${display_host}"
  echo "Closure: ${total_gib} GiB (${pkg_count} packages)"
  echo "Threshold: ${THRESHOLD_MB} MiB"
  echo ""

  # Collect large packages: path, size_mb, display_name
  # Use associative arrays for dedup by name
  declare -A seen_names       # name -> best_path (largest)
  declare -A seen_sizes       # name -> best_size_mb
  declare -A seen_counts      # name -> count
  declare -A seen_total_sizes # name -> total_size_mb across all instances
  declare -A path_to_display  # path -> display_name

  while IFS= read -r line; do
    local pkg_path size_str
    pkg_path=$(echo "$line" | awk '{print $1}')
    size_str=$(echo "$line" | awk '{print $2, $3}')

    local size_mb
    size_mb=$(parse_size "$size_str")

    # Check threshold
    if ! awk "BEGIN {exit !($size_mb >= $THRESHOLD_MB)}"; then
      continue
    fi

    local pkg_name
    pkg_name=$(get_package_name "$pkg_path")

    # Check blacklist
    local skip=0
    for bl in "${BLACKLIST[@]}"; do
      if [[ $pkg_name == *"$bl"* ]]; then
        skip=1
        break
      fi
    done
    [ "$skip" -eq 1 ] && continue

    local display_name
    display_name=$(get_display_name "$pkg_path")
    path_to_display["$pkg_path"]="$display_name"

    # Dedup by package name
    if [ -z "${seen_names[$pkg_name]+x}" ]; then
      seen_names["$pkg_name"]="$pkg_path"
      seen_sizes["$pkg_name"]="$size_mb"
      seen_counts["$pkg_name"]=1
      seen_total_sizes["$pkg_name"]="$size_mb"
    else
      seen_counts["$pkg_name"]=$((${seen_counts[$pkg_name]} + 1))
      seen_total_sizes["$pkg_name"]=$(awk "BEGIN {printf \"%.1f\", ${seen_total_sizes[$pkg_name]} + $size_mb}")
      # Keep the largest instance
      if awk "BEGIN {exit !($size_mb > ${seen_sizes[$pkg_name]})}"; then
        seen_names["$pkg_name"]="$pkg_path"
        seen_sizes["$pkg_name"]="$size_mb"
      fi
    fi
  done <"$PATH_INFO_FILE"

  # Now run why-depends for each unique large package and group by root
  declare -A root_groups # root_name -> newline-separated "size_mb|display_name|count|total_size" entries
  declare -A root_totals # root_name -> total MiB
  declare -A root_chains # root_name -> chain display string (from first/largest member)
  local -a ungrouped=()  # entries that couldn't be grouped

  local total_large=${#seen_names[@]}
  local progress=0

  for pkg_name in "${!seen_names[@]}"; do
    progress=$((progress + 1))
    local pkg_path="${seen_names[$pkg_name]}"
    local size_mb="${seen_sizes[$pkg_name]}"
    local count="${seen_counts[$pkg_name]}"
    local total_size="${seen_total_sizes[$pkg_name]}"
    local display_name="${path_to_display[$pkg_path]}"

    verbose "[$progress/$total_large] Analyzing: $display_name"

    # Get why-depends chain
    local chain_names
    chain_names=$(get_why_depends_chain "$toplevel" "$pkg_path" 2>/dev/null) || chain_names=""

    if [ -z "$chain_names" ]; then
      ungrouped+=("$(printf "%s|%s|%s|%s" "$size_mb" "$display_name" "$count" "$total_size")")
      continue
    fi

    # Extract meaningful root
    local root
    root=$(extract_meaningful_root "$chain_names")

    if [ -z "$root" ] || [ "$root" = "$pkg_name" ]; then
      ungrouped+=("$(printf "%s|%s|%s|%s" "$size_mb" "$display_name" "$count" "$total_size")")
      continue
    fi

    # Add to root group
    if [ -z "${root_totals[$root]+x}" ]; then
      root_totals["$root"]=0
      root_groups["$root"]=""
      # Get chain display for this root group
      local chain_display
      chain_display=$(get_chain_display "$toplevel" "$pkg_path" "$display_name")
      root_chains["$root"]="${chain_display:-}"
    fi

    root_groups["$root"]+="${size_mb}|${display_name}|${count}|${total_size}
"
    root_totals["$root"]=$(awk "BEGIN {printf \"%.1f\", ${root_totals[$root]} + $size_mb}")
  done

  # Sort root groups by total size (descending)
  local -a sorted_roots=()
  for root in "${!root_totals[@]}"; do
    sorted_roots+=("$(printf "%010.1f|%s" "${root_totals[$root]}" "$root")")
  done
  mapfile -t sorted_roots < <(printf '%s\n' "${sorted_roots[@]}" | sort -rn)

  # Display grouped output
  echo "GROUPED BY ROOT CAUSE (sorted by group total):"
  echo ""

  for entry in "${sorted_roots[@]}"; do
    local root_total root_name
    root_total=$(echo "$entry" | cut -d'|' -f1 | sed 's/^0*//')
    root_name=$(echo "$entry" | cut -d'|' -f2)

    # Format total
    local total_display
    total_display=$(printf "%'.1f MiB" "$root_total")

    # Print group header
    printf "  %-50s %10s\n" "$root_name" "$total_display"

    # Sort and print members
    echo "${root_groups[$root_name]}" | sort -t'|' -k1 -rn | while IFS='|' read -r m_size m_name m_count m_total; do
      [ -z "$m_size" ] && continue
      local size_display
      size_display=$(printf "%'10.1f MiB" "$m_size")

      local suffix=""
      if [ "$m_count" -gt 1 ]; then
        suffix="  (x${m_count}, $(printf "%'.1f" "$m_total") MiB total)"
      fi

      printf "    %s  %s%s\n" "$size_display" "$m_name" "$suffix"
    done

    # Show chain if available
    if [ -n "${root_chains[$root_name]:-}" ]; then
      echo "    Chain: ${root_chains[$root_name]}"
    fi
    echo ""
  done

  # Display ungrouped packages
  if [ ${#ungrouped[@]} -gt 0 ]; then
    echo "UNGROUPED (root-level or shared):"
    echo ""

    # Sort by size descending
    printf '%s\n' "${ungrouped[@]}" | sort -t'|' -k1 -rn | while IFS='|' read -r u_size u_name u_count u_total; do
      [ -z "$u_size" ] && continue
      local size_display
      size_display=$(printf "%'10.1f MiB" "$u_size")

      local suffix=""
      if [ "$u_count" -gt 1 ]; then
        suffix="  (x${u_count}, $(printf "%'.1f" "$u_total") MiB total)"
      fi

      printf "   %s  %s%s\n" "$size_display" "$u_name" "$suffix"
    done
    echo ""
  fi
}

main "$@"
