{ config
, ...
}:
let
  inherit (config.home.sessionVariables) THEME;
  colors = (import ../../colors.nix).${THEME};
in
{
  programs.zathura.options = {
    statusbar-fg = "#${colors.base05}";
    statusbar-bg = "#${colors.base00}";
  };
}
