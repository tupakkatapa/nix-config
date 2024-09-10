{ pkgs, lib, ... }: {
  systemd.user.services.rgb =
    let
      setColor = color: "${lib.getExe pkgs.openrgb} --client -c ${lib.removePrefix "#"color} -m static";
    in
    {
      Unit.Description = "Set RGB colors to match scheme. Requires openrgb.";
      Service = {
        Type = "oneshot";
        ExecStart = setColor "#330099";
        ExecStop = setColor "#000000";
        Restart = "on-failure";
        RemainAfterExit = true;
      };
      Install.WantedBy = [ "default.target" ];
    };
}


