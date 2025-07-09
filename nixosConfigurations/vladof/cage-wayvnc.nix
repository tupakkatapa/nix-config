{ pkgs, ... }:
let
  user = "kari";
in
{
  # WayVNC server for a remote display
  systemd.services.wayvnc =
    let
      cfg = pkgs.writeText "wayvnc-config" ''
        use_relative_paths=true
        address=0.0.0.0
      '';
    in
    {
      description = "WayVNC Server";
      wantedBy = [ "graphical-session.target" ];
      unitConfig = {
        After = "cage-tty1.service";
        Requires = "cage-tty1.service";
        PartOf = "cage-tty1.service";
      };
      environment = {
        WAYLAND_DISPLAY = "wayland-0";
        XDG_RUNTIME_DIR = "/run/user/1000";
      };
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.wayvnc}/bin/wayvnc --config ${cfg} --render-cursor --max-fps=60";
        Restart = "always";
        RestartSec = "10";
        User = user;
        Group = user;
      };
    };

  # Open firewall
  networking.firewall.allowedTCPPorts = [ 5900 ];
}

