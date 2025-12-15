{ pkgs, config, ... }:
let
  inherit (config.services.nixie.dhcp.wan) interface;
in
{
  systemd.services.network-status = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.iproute2}/bin/ip -j neigh show";
      StandardOutput = "truncate:/run/network-status.json";
    };
  };

  systemd.services.wan-ip = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.iproute2}/bin/ip -j -4 addr show ${interface}";
      StandardOutput = "truncate:/run/wan-ip.json";
    };
  };

  systemd.timers.network-status = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnBootSec = "10s"; OnUnitActiveSec = "30s"; };
  };

  systemd.timers.wan-ip = {
    wantedBy = [ "timers.target" ];
    timerConfig = { OnBootSec = "10s"; OnUnitActiveSec = "60s"; };
  };

  services.nginx.virtualHosts."${config.networking.domain}".locations = {
    "= /api/hosts.json".alias = "/run/network-status.json";
    "= /api/wan.json".alias = "/run/wan-ip.json";
  };
}
