# Hyperion - Router Migration Plan

> **⚠️ DISCLAIMER:** This documentation was generated with assistance from an LLM (Large Language Model).
> Please review and verify all technical details before implementation.

Migration from pfSense to NixOS router on StarLabs Byte.

## Host Naming

**Hyperion** - Borderlands manufacturer theme (precision/high-tech)

**Alternatives:** Dahl (military-grade reliability), Atlas (corporate/professional)

## Architecture

### Current
```
Internet → pfSense → LAN (192.168.1.0/24)
                      └─ Vladof (DHCP, PXE, WireGuard, Services)
```

### New
```
Internet → Hyperion (Router)
             ├─ WAN (DHCP from ISP)
             ├─ DHCP/PXE Server (Nixie)
             ├─ DNS Server (CoreDNS or Unbound)
             ├─ WireGuard VPN
             ├─ Firewall/NAT (nftables)
             └─ LAN (NEW_SUBNET.0/24)
                  ├─ Vladof (Services only)
                  ├─ Torgue (Desktop, PXE boot)
                  ├─ Maliwan (Laptop)
                  └─ Other devices
```

## Boot Strategy

| Host     | Boot Method | Notes                           |
|----------|-------------|---------------------------------|
| Hyperion | rEFInd      | **Required** - Serves PXE       |
| Maliwan  | rEFInd      | **Required** - Portable         |
| Vladof   | PXE/Netboot | From hyperion (NEW)             |
| Torgue   | PXE/Netboot | From hyperion                   |
| Bandit   | PXE/Netboot | From hyperion                   |
| Kaakkuri | PXE/Netboot | External (ponkila/homestaking)  |

**Netboot images:** torgue, bandit, vladof, kaakkuri-ephemeral-alpha
**Persistence:** `/var/www/netboot` (several GB)

## Network Redesign

### Subnet Options
- **Recommended:** 10.42.0.0/24 (LAN), keep 172.16.16.0/24 (WireGuard)
- **Alternative:** 172.16.0.0/24 or 192.168.42.0/24

### IP Mapping
| Device   | Current (192.168.1.x) | New (e.g., 10.42.0.x) |
|----------|------------------------|------------------------|
| Hyperion | N/A (new)              | .1 (router/gateway)    |
| Torgue   | .7                     | .7                     |
| Vladof   | .8                     | .8                     |
| Kaakkuri | .25                    | .25                    |
| Static Range | .1-.29            | .1-.29                 |
| DHCP Pool| .30-.59 (old limit)    | .30-.254               |

**Example with 10.42.0.0/24 (flat network):**
- Hyperion: 10.42.0.1 (gateway)
- Torgue: 10.42.0.7
- Vladof: 10.42.0.8
- Static: 10.42.0.1-29 (reserved for static assignments)
- DHCP: 10.42.0.30-254 (225 IPs available)

**Note:** If using VLANs, subnets change to 10.42.X.0/24 (see VLAN Scheme in Hardware Setup)

**Files to update:** `vladof/{nixie,wireguard,containers}.nix`, WireGuard clients

## Services Migration

### From Vladof → Hyperion

**1. Nixie (DHCP + PXE)**
- Source: `nixosConfigurations/vladof/nixie.nix`
- Interface: Update to Byte's Ethernet interface
- Static DHCP: torgue (.7), kaakkuri (.25), vladof (.8 - NEW)
- Add vladof to netboot images
- Persistent: `/var/www/netboot`
- **Note:** Nixie natively supports multiple subnets via `dhcp.subnets` array - VLAN DHCP is built-in

**2. WireGuard VPN**
- Source: `nixosConfigurations/vladof/wireguard.nix`
- Port: 51820/udp
- Network: 172.16.16.0/24
- Peers: OnePlus 9 (.2), Kari (.3)
- Update AllowedIPs for new LAN subnet
- Persistent: WireGuard keys (age-encrypted)

### Staying on Vladof

**Application Services:**
- 9 containers: Plex, Vaultwarden, Kavita, Transmission, SearX, Radicale, Ollama, Blog, Index
- Caddy reverse proxy (ACME/Let's Encrypt)
- SFTP server
- Kiosk/VNC

## Required Services on Hyperion

### Core Router Functions

**1. DNS Server**

**Option A: CoreDNS** (Recommended for metrics/modern stack)
- Built-in Prometheus metrics (integrates with monitoring)
- Simple Corefile configuration
- Local zones: `*.coditon.com` → vladof, `eth.coditon.com` → kaakkuri
- Upstream forwarding: 9.9.9.9 (Quad9 - privacy-focused)
- NixOS: `services.coredns`
- Optional: Steven Black hosts list via `hosts` plugin

**Option B: Unbound** (Recommended for maximum privacy)
- **Recursive resolver** - queries root servers directly (no upstream DNS)
- Maximum privacy (only you + authoritative nameservers see queries)
- Excellent DNSSEC validation (built-in)
- Lower memory footprint (~10-30 MB vs CoreDNS ~20-50 MB)
- Local zones: `local-data` directives for *.coditon.com
- NixOS: `services.unbound`
- Trade-off: Slower initial queries, more network traffic
- Optional: Can forward to Quad9 instead of recursive mode

**Choose CoreDNS if:** You want Prometheus metrics, modern config, lighter setup
**Choose Unbound if:** Privacy is priority, you want true recursive resolution

Both support DHCP option 6 and local zone overrides.

**2. WAN - systemd-networkd**
- DHCP client (or PPPoE if needed)
- Default route via ISP gateway
- NixOS: `networking.interfaces.<wan>.useDHCP = true;`

**3. Firewall/NAT - nftables**
- Masquerade: LAN → WAN
- Allow: WireGuard (51820/udp on hyperion), established/related
- Block: Unsolicited WAN → LAN
- Allow LAN: DNS (53), DHCP (67), NTP (123), SSH (22), HTTP (80 for PXE)
- **Port forwarding (from pfSense):**
  - To vladof: 80, 443, 32400, 54783 (TCP)
  - To kaakkuri: 9001, 30303 (TCP/UDP), 51821 (UDP)
- **Note:** WireGuard (51820) runs on hyperion directly (no port forward needed)
- **VLANs:** If using VLANs, add inter-VLAN routing rules (see VLAN section)
- NixOS: `networking.nftables.enable = true;`

**4. NTP - chrony**
- Serve time to LAN (critical for PXE boot)
- Upstream: pool.ntp.org
- DHCP option 42
- NixOS: `services.chrony`

**5. Security - fail2ban**
- Progressive bans (5 attempts → 24h → 48h → 96h)
- Whitelist LAN subnets
- Monitor: sshd
- NixOS: `services.fail2ban.enable = true;`

**6. Monitoring - Prometheus + vnStat**
- node_exporter (port 9100) for Grafana on vladof
- vnStat for bandwidth tracking
- DNS metrics: CoreDNS has built-in Prometheus; Unbound needs separate exporter
- NixOS: `services.prometheus.exporters.node`, `programs.vnstat`

**7. IPv4 Forwarding**
- `boot.kernel.sysctl."net.ipv4.ip_forward" = 1;`

**8. Boot - rEFInd**
- Local boot required (serves netboot to others)
- Persistence via stateSaver + FIDO2 HMAC

## Optional Enhancements

**Note:** These are optional features. Start with basics, add later as needed.

- **DNS-based Ad/Malware Blocking** (pfBlockerNG equivalent)
  - Steven Black unified hosts list (ads, malware, tracking)
  - Implementation options:
    - CoreDNS with `hosts` plugin + systemd timer for updates
    - `blocky` - Lightweight DNS proxy with blocking
    - AdGuard Home - Full-featured with Web UI (heavier)
  - Auto-update blocklists daily/weekly
- **VLANs** - Network segmentation (Management, Trusted, Servers, IoT, Guest)
- **QoS** - Traffic shaping with tc/FQ_CODEL
- **DynDNS** - ddclient for Cloudflare
- **IPv6** - radvd, prefix delegation
- **IDS/IPS** - Suricata (resource intensive)
- **GeoIP blocking** - nftables + GeoIP database
- **mDNS repeater** - For multi-VLAN setups
- **SNMP** - Monitoring integration
- **Wake-on-LAN** - Remote wake proxy

## Hardware Setup

**StarLabs Byte:**
- 2 Ethernet ports: Port 1 (WAN), Port 2 (LAN trunk)
- Identify interface names after first boot (enp1s0, enp2s0, etc.)
- Test throughput: 1 Gbps line-rate forwarding

**Network Switch:**

**Option A: VLAN-capable switch** (TL-SG608E or similar)
- Port 1: Trunk to hyperion (all VLANs tagged)
- Ports 2-8: Access ports for different VLANs
- Enables network segmentation (Trusted/Servers/IoT/Guest)
- **Configuration:** Manual via web UI (802.1Q VLAN support)
- **Note:** TL-SG608E has no API/CLI - switch config cannot be declarative

**Option B: Dumb switch**
- Single flat network (10.42.0.0/24)
- No VLAN isolation
- Simpler setup, less security

**VLAN Scheme** (if using managed switch):
- VLAN 10: Trusted (10.42.10.0/24) - Workstations
- VLAN 20: Servers (10.42.20.0/24) - Vladof, Kaakkuri
- VLAN 30: IoT (10.42.30.0/24) - Smart devices (internet-only)
- VLAN 40: Guest (10.42.40.0/24) - Guest WiFi (internet-only)

**Nixie Multi-Subnet Configuration** (VLAN DHCP example):
```nix
services.nixie.dhcp.subnets = [
  {
    name = "trusted";
    address = "10.42.10.1";
    interfaces = ["enp2s0.10"];  # VLAN 10 tagged interface
    poolStart = "10.42.10.30";
    poolEnd = "10.42.10.254";
    defaultMenu = "torgue";
  }
  {
    name = "servers";
    address = "10.42.20.1";
    interfaces = ["enp2s0.20"];  # VLAN 20 tagged interface
    poolStart = "10.42.20.30";
    poolEnd = "10.42.20.254";
    clients = [
      { mac = "xx:xx:xx:xx:xx:xx"; address = "10.42.20.8"; menu = "vladof"; }
    ];
  }
];
```

**Storage:**
- DHCP leases: ~1 MB
- DNS cache: ~10-100 MB
- Netboot images: several GB
- Logs: rotate regularly

## Migration Checklist

### Pre-Migration
- [ ] Choose subnet (recommend: 10.42.0.0/24)
- [ ] Identify Byte's WAN/LAN interfaces
- [ ] Backup pfSense config

### Phase 1: Build Hyperion
- [ ] Create `nixosConfigurations/hyperion/`
- [ ] Configure rEFInd bootloader
- [ ] Migrate Nixie, add vladof to netboot images
- [ ] Migrate WireGuard
- [ ] Configure DNS (CoreDNS or Unbound)
- [ ] Configure nftables (NAT + firewall)
- [ ] Configure chrony (NTP)
- [ ] Configure fail2ban
- [ ] Configure monitoring (node_exporter, vnStat)
- [ ] Optional: Configure VLANs (if using managed switch) - systemd-networkd + Nixie subnets
- [ ] Update all IPs to new subnet

### Phase 2: Update Vladof
- [ ] Remove Nixie and WireGuard configs
- [ ] Update gateway/DNS to hyperion
- [ ] Convert to netboot (rEFInd optional fallback)

### Phase 3: Update Other Hosts
- [ ] Update torgue, maliwan, bandit: subnet, gateway, DNS

### Phase 4: External Updates
- [ ] Update WireGuard clients (AllowedIPs, endpoint)
- [ ] Update DNS records (if WAN IP changes)

### Phase 5: Testing
- [ ] DHCP, PXE boot, DNS resolution
- [ ] LAN → Internet, WireGuard → LAN
- [ ] Vladof services access
- [ ] Firewall rules, throughput test

### Phase 6: Cutover
- [ ] Deploy hyperion, connect WAN/LAN
- [ ] Verify DHCP/DNS/Internet
- [ ] Power off pfSense
- [ ] Deploy updated vladof/hosts

### Phase 7: Post-Migration
- [ ] Monitor logs/metrics
- [ ] Update documentation
- [ ] Decommission pfSense

## File Structure

```
nixosConfigurations/hyperion/
├── default.nix              # Main config
├── networking.nix           # WAN/LAN interfaces (+ VLANs if used)
├── firewall.nix             # nftables NAT/rules
├── nixie.nix                # DHCP + PXE
├── wireguard.nix            # VPN
├── dns.nix                  # DNS (CoreDNS or Unbound)
├── ntp.nix                  # chrony
├── monitoring.nix           # Prometheus, vnStat
├── persistence.nix          # State persistence
└── secrets/
    └── rekeyed/             # Age-encrypted secrets
```

**Note:** VLANs can be configured in networking.nix or separate vlans.nix if preferred.

## References

- Vladof configs: `nixosConfigurations/vladof/{nixie,wireguard,containers}.nix`
- Nixie module: `inputs.nixie` (PXE + Kea DHCP, supports multiple subnets natively)
- StateSaver module: `.config/state-saver.nix`
- Current pfSense: Port forwards and DNS overrides (screenshots)
