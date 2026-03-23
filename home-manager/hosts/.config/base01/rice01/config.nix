{ customLib, config, ... }:
let
  inherit (config.home.sessionVariables) THEME;
  colors = customLib.colors.${THEME};
in
{
  rounding = 13;
  spacing = 5;
  border = {
    size = 1;
    active = colors.base06;
    inactive = colors.base02;
  };
}
