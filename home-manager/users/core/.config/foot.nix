{ config
, ...
}:
let
  inherit (config.home.sessionVariables) FONT THEME;
in
{
  programs.foot = {
    enable = true;

    settings = {
      main = {
        term = "xterm-256color";
        font = "${FONT}:size=8";
        dpi-aware = "yes";
        pad = "20x20";
      };

      mouse = {
        hide-when-typing = "yes";
      };
    };
  };
}

