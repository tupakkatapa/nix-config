{ config
, ...
}:
let
  inherit (config.home.sessionVariables) FONT THEME;
  colors = (import ../../colors.nix).${THEME};
in
{
  services.mako = {
    backgroundColor = "#${colors.base00}";
    borderColor = "#${colors.base06}";
    borderRadius = 10;
    borderSize = 2;
    font = "${FONT} 10";
    textColor = "#${colors.base05}";
    progressColor = "#${colors.base08}";
    extraConfig = ''
      [urgency=low]
      background-color=#${colors.base00}
      text-color=#${colors.base05}

      [urgency=normal]
      background-color=#${colors.base00}
      text-color=#${colors.base05}

      [urgency=critical]
      background-color=#${colors.base00}
      text-color=#${colors.base08}
    '';
  };
}

