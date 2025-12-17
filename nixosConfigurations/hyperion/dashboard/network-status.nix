{ pkgs, config, ... }:
let
  inherit (config.services.nixie.dhcp.wan) interface;

  hostsScript = pkgs.writeScript "hosts-api" ''
    #!${pkgs.bash}/bin/bash
    echo "Content-Type: application/json"
    echo ""
    ${pkgs.iproute2}/bin/ip -j neigh show
  '';

  wanScript = pkgs.writeScript "wan-api" ''
    #!${pkgs.bash}/bin/bash
    echo "Content-Type: application/json"
    echo ""
    ${pkgs.iproute2}/bin/ip -j -4 addr show ${interface}
  '';
in
{
  services.fcgiwrap.instances.api = {
    socket.type = "tcp";
    socket.address = "127.0.0.1:9001";
  };

  services.nginx.virtualHosts."${config.networking.domain}".locations = {
    "= /api/hosts.json" = {
      extraConfig = ''
        # Security: restrict API to localhost only
        allow 127.0.0.1;
        deny all;

        fastcgi_pass 127.0.0.1:9001;
        fastcgi_param SCRIPT_FILENAME ${hostsScript};
        include ${pkgs.nginx}/conf/fastcgi_params;
      '';
    };
    "= /api/wan.json" = {
      extraConfig = ''
        # Security: restrict API to localhost only
        allow 127.0.0.1;
        deny all;

        fastcgi_pass 127.0.0.1:9001;
        fastcgi_param SCRIPT_FILENAME ${wanScript};
        include ${pkgs.nginx}/conf/fastcgi_params;
      '';
    };
  };
}
