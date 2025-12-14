{ pkgs, config, lib, ... }:
let
  inherit (config.services) nixie;

  # Build subnet_id -> bridge name mapping from nixie config
  # Kea assigns IDs sequentially starting from 1 for subnets with serve=true
  servedSubnets = lib.filter (s: s.serve or false) nixie.dhcp.subnets;
  subnetBridgesArray = lib.concatStringsSep " " (lib.imap1
    (i: subnet: "[${toString i}]=\"br-${subnet.name}\"")
    servedSubnets);

  networkStatusScript = pkgs.writeShellApplication {
    name = "network-status";
    runtimeInputs = [ pkgs.iproute2 ];
    text = builtins.replaceStrings
      [ "@subnetBridges@" ]
      [ ''$\{_subnet_bridges[$subnet_id]:-unknown}'' ]
      ''
        declare -A _subnet_bridges=(${subnetBridgesArray})
        ${builtins.readFile ./network-status.sh}
      '';
  };
in
{
  # Systemd service to update network status
  systemd.services.network-status = {
    description = "Update network host status";
    after = [ "kea-dhcp4-server.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${networkStatusScript}/bin/network-status";
    };
  };

  # Timer to run every 30 seconds
  systemd.timers.network-status = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "30s";
      Unit = "network-status.service";
    };
  };
}
