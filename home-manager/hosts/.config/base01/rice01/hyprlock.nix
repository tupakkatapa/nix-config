{ config
, customLib
, ...
}:
let
  inherit (config.home.sessionVariables) FONT THEME;
  colors = customLib.colors.${THEME};
in
{
  programs.hyprlock.settings = {
    general.hide_cursor = true;
    background = {
      path = "screenshot";
      blur_passes = 4;
      brightness = 0.8;
    };
    input-field = {
      size = "300, 50";
      placeholder_text = "";
      fail_text = "";
      outline_thickness = 0;
      inner_color = "rgba(00000000)";
      check_color = "rgba(00000000)";
      fail_color = "rgba(00000000)";
      font_color = "rgb(${colors.base05})";
      font_family = FONT;
      position = "0, -20%";
    };
    label = {
      text = "$TIME";
      color = "rgb(${colors.base05})";
      font_family = FONT;
      font_size = 89;
      position = "0, 0";
    };
  };
}
