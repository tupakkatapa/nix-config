{ config
, customLib
, ...
}:
let
  inherit (config.home.sessionVariables) THEME;
  colors = customLib.colors.${THEME};
in
{
  programs.zathura.options = {
    statusbar-fg = "#${colors.base05}";
    statusbar-bg = "#${colors.base00}";
  };
}
