{ pkgs, lib, config, ... }:
let
  inherit (config.services.nixie.wan) interface;

  mkScript = name: cmd: pkgs.writeScript "${name}-api" ''
    #!${pkgs.bash}/bin/bash
    echo "Content-Type: application/json"
    echo ""
    ${cmd}
  '';

  endpoints = {
    hosts = mkScript "hosts" "${pkgs.iproute2}/bin/ip -j neigh show";
    wan = mkScript "wan" "${pkgs.iproute2}/bin/ip -j -4 addr show ${interface}";
    wg = mkScript "wg" "${pkgs.wireguard-tools}/bin/wg show all dump | ${pkgs.jc}/bin/jc --wg-show";

    # System metrics: uptime, load, memory, conntrack
    system = mkScript "system" ''
      UPTIME=$(${pkgs.gawk}/bin/awk '{printf "%.0f", $1}' /proc/uptime)
      read L1 L5 L15 REST < /proc/loadavg
      MEM_TOTAL=$(${pkgs.gawk}/bin/awk '/MemTotal/ {print $2}' /proc/meminfo)
      MEM_AVAIL=$(${pkgs.gawk}/bin/awk '/MemAvailable/ {print $2}' /proc/meminfo)
      CPU_COUNT=$(${pkgs.coreutils}/bin/nproc)
      CONNS=0
      CONNS_MAX=0
      [ -r /proc/sys/net/netfilter/nf_conntrack_count ] && read CONNS < /proc/sys/net/netfilter/nf_conntrack_count
      [ -r /proc/sys/net/netfilter/nf_conntrack_max ] && read CONNS_MAX < /proc/sys/net/netfilter/nf_conntrack_max
      printf '{"uptime":%s,"load":[%s,%s,%s],"cpu_count":%s,"mem_total":%s,"mem_available":%s,"connections":%s,"connections_max":%s}\n' \
        "$UPTIME" "$L1" "$L5" "$L15" "$CPU_COUNT" "$MEM_TOTAL" "$MEM_AVAIL" "$CONNS" "$CONNS_MAX"
    '';

    # WAN interface traffic via vnstat (scoped to WAN interface only)
    traffic = mkScript "traffic" "${pkgs.vnstat}/bin/vnstat --json -i ${interface} 2>/dev/null || echo '{}'";
  };

  mkLocation = script: {
    extraConfig = ''
      allow 127.0.0.1;
      allow 172.16.16.0/24;
      allow 10.42.0.0/24;
      deny all;
      fastcgi_pass 127.0.0.1:9001;
      fastcgi_param SCRIPT_FILENAME ${script};
      include ${pkgs.nginx}/conf/fastcgi_params;
    '';
  };
in
{
  services.fcgiwrap.instances.api = {
    socket.type = "tcp";
    socket.address = "127.0.0.1:9001";
  };

  # vnstat database access for traffic stats
  users.users.fcgiwrap = {
    isSystemUser = true;
    group = "fcgiwrap";
    extraGroups = [ "vnstatd" ];
  };
  users.groups.fcgiwrap = { };

  services.nginx.virtualHosts."${config.networking.domain}".locations =
    lib.mapAttrs' (name: script: lib.nameValuePair "= /api/${name}.json" (mkLocation script)) endpoints;
}
