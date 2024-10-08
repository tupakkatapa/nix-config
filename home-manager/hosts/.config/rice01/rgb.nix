{ pkgs, lib, ... }: {
  systemd.user.services.rgb =
    let
      setColor = color: builtins.concatStringsSep " " [
        "${lib.getExe pkgs.openrgb} --client"
        "-d 'Corsair Lightning Node' -z 0 -s 18 -c ${lib.removePrefix "#"color} -m direct"
        "-d 'Corsair Lightning Node' -z 1 -s 30 -c ${lib.removePrefix "#"color} -m direct"
      ];
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


