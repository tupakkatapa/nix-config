{ customLib, config, ... }:
let
  inherit (config.home.sessionVariables) THEME;
  colors = customLib.colors.${THEME};
in
{
  rounding = 12;
  spacing = 10;
  border = {
    size = 2;
    active = colors.base06;
    inactive = colors.base02;
  };
}
