{ customLib, config, ... }:
let
  inherit (config.home.sessionVariables) THEME;
  colors = customLib.colors.${THEME};
in
{
  rounding = 12;
  spacing = 8;
  border = {
    size = 1;
    active = colors.base06;
    inactive = colors.base02;
  };
}
