{ config
, customLib
, ...
}:
let
  inherit (config.home.sessionVariables) FONT THEME;
  colors = customLib.colors.${THEME};
  rice = import ./config.nix { inherit customLib config; };
in
{
  services.mako.settings = {
    background-color = "#${colors.base00}";
    border-color = "#${colors.base06}";
    border-radius = rice.rounding;
    border-size = rice.border.size;
    font = "${FONT} 8";
    text-color = "#${colors.base05}";
    progress-color = "#${colors.base08}";
  };
}

