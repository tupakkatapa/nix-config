{ pkgs, lib, config, ... }:
let
  inherit (config.services.nixie.dhcp.wan) interface;

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

  services.nginx.virtualHosts."${config.networking.domain}".locations =
    lib.mapAttrs' (name: script: lib.nameValuePair "= /api/${name}.json" (mkLocation script)) endpoints;
}
