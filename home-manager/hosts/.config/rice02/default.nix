{ config, pkgs, ... }:
let
  inherit (config.home.sessionVariables) TERMINAL BROWSER FONT;
  mod = "Mod1"; # Left Alt / Command key
in
{
  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "${mod}";

      # Default apps
      terminal = "${TERMINAL}";

      # Startup applications
      startup = [
        { command = "steam"; }
      ];

      # Bind keys
      keybindings = {
        "${mod}+b" = "${BROWSER}";
        "${mod}+Return" = "${TERMINAL}";
        "${mod}+Shift+Return" = "${pkgs.rofi}/bin/rofi -show drun";
      };

      # Font
      fonts = {
        names = [ "${FONT}" ];
        size = 9.0;
      };
    };
  };
}

