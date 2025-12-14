OUTPUT_DIR="/var/lib/network-status"
OUTPUT_FILE="$OUTPUT_DIR/hosts.json"
LEASE_FILE="/var/lib/kea/dhcp4.leases"

mkdir -p "$OUTPUT_DIR"

# Get current ARP table (recently seen = online)
declare -A arp_online
while read -r ip dev iface lladdr mac state; do
  if [[ $mac =~ ^([0-9a-f]{2}:){5}[0-9a-f]{2}$ ]]; then
    arp_online["$ip"]=1
  fi
done < <(ip neigh show)

# Parse Kea leases file (CSV format)
# Format: address,hwaddr,client_id,valid_lifetime,expire,subnet_id,fqdn_fwd,fqdn_rev,hostname,state,user_context,pool_id
declare -A leases
now=$(date +%s)
if [[ -f $LEASE_FILE ]]; then
  while IFS=, read -r address hwaddr client_id valid_lifetime expire subnet_id fqdn_fwd fqdn_rev hostname state user_context pool_id; do
    # Skip header and empty lines
    [[ $address == "address" || -z $address ]] && continue
    # State 0 = default (active), 1 = declined, 2 = expired
    [[ $state != "0" ]] && continue
    # Check if lease is not expired
    [[ $expire -lt $now ]] && continue
    # Store lease info (later entries override earlier for same MAC)
    leases["$hwaddr"]="$address|$hostname|$expire|$subnet_id"
  done <"$LEASE_FILE"
fi

# Build JSON output
echo '{"hosts":[' >"$OUTPUT_FILE.tmp"
first=true

for mac in "${!leases[@]}"; do
  IFS='|' read -r ip hostname expire subnet_id <<<"${leases[$mac]}"

  # Determine online status from ARP
  if [[ -n ${arp_online[$ip]:-} ]]; then
    online="true"
  else
    online="false"
  fi

  # Determine bridge from subnet_id (generated from nixie config)
  bridge="@subnetBridges@"

  # Clean hostname (remove quotes if present)
  hostname="${hostname//\"/}"
  [[ -z $hostname ]] && hostname=""

  if [[ $first == "true" ]]; then
    first=false
  else
    echo "," >>"$OUTPUT_FILE.tmp"
  fi

  cat >>"$OUTPUT_FILE.tmp" <<ENTRY
  {"ip":"$ip","mac":"$mac","hostname":"$hostname","online":$online,"bridge":"$bridge","expire":$expire}
ENTRY
done

echo ']}' >>"$OUTPUT_FILE.tmp"
mv "$OUTPUT_FILE.tmp" "$OUTPUT_FILE"
