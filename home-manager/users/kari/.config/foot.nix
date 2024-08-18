{ config
, ...
}:
let
  inherit (config.home.sessionVariables) FONT;
in
{
  programs.foot = {
    enable = true;

    settings = {
      main = {
        term = "xterm-256color";
        font = "${FONT}:size=8:weight=bold";
        dpi-aware = "yes";
        pad = "20x20";
      };

      mouse = {
        hide-when-typing = "yes";
      };

      # Color settings
      colors = {
        background = "282828"; # Background color
        foreground = "ebdbb2"; # Foreground (text) color

        # Regular colors
        regular0 = "282828"; # Surface 1 (Black)
        regular1 = "cc241d"; # Red
        regular2 = "98971a"; # Green
        regular3 = "d79921"; # Yellow
        regular4 = "458588"; # Blue
        regular5 = "b16286"; # Maroon (Magenta)
        regular6 = "689d6a"; # Teal (Cyan)
        regular7 = "a89984"; # Subtext 1 (White)

        # Bright colors
        bright0 = "928374"; # Surface 2 (Bright Black)
        bright1 = "fb4934"; # Red
        bright2 = "b8bb26"; # Green
        bright3 = "fabd2f"; # Yellow
        bright4 = "83a598"; # Blue
        bright5 = "d3869b"; # Maroon (Bright Magenta)
        bright6 = "8ec07c"; # Teal (Bright Cyan)
        bright7 = "ebdbb2"; # Subtext 0 (Bright White)
      };
    };
  };
}
