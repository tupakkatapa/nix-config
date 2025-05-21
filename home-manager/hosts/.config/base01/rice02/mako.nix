{ config
, customLib
, ...
}:
let
  inherit (config.home.sessionVariables) FONT THEME;
  colors = customLib.colors.${THEME};
in
{
  services.mako.settings = {
    backgroundColor = "#${colors.base00}";
    borderColor = "#${colors.base06}";
    borderRadius = 0;
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

