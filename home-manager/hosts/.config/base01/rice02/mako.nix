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
    background-color = "#${colors.base00}";
    border-color = "#${colors.base06}";
    border-radius = 0;
    border-size = 2;
    font = "${FONT} 10";
    text-color = "#${colors.base05}";
    progress-color = "#${colors.base08}";
  };
}

