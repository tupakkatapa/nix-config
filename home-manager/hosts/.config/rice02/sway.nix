{ lib, pkgs, config, ... }:
let
  inherit (config.home.sessionVariables) TERMINAL BROWSER;
  mod = "Mod1";
  super = "Mod4";
in
{
  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = mod;

      # Default apps
      terminal = "${TERMINAL}";

      # Startup applications
      startup = [
        { command = "steam"; }
        { command = "discord"; }
      ];
      assigns = {
        "1" = [{ class = "^steam"; }];
        "2" = [{ class = "^discord"; }];
      };

      # Bind keys
      keybindings = lib.mkDefault {
        # General
        "${mod}+Return" = "exec ${TERMINAL}";
        "${mod}+Shift+Return" = "exec ${pkgs.wofi}/bin/wofi --show run";

        # Programs
        "${super}+b" = "exec ${BROWSER}";

        # Window management
        "${mod}+f" = "floating toggle";
        "${mod}+q" = "kill";
        "${mod}+Space" = "fullscreen";

        # Moves the focus in a direction
        "${mod}+h" = "focus left";
        "${mod}+j" = "focus down";
        "${mod}+k" = "focus up";
        "${mod}+l" = "focus right";

        # Moves the active window in a direction
        "${mod}+Shift+h" = "move left";
        "${mod}+Shift+j" = "move down";
        "${mod}+Shift+k" = "move up";
        "${mod}+Shift+l" = "move right";

        # Change the workspace
        "${mod}+1" = "workspace 1";
        "${mod}+2" = "workspace 2";
        "${mod}+3" = "workspace 3";
        "${mod}+4" = "workspace 4";
        "${mod}+5" = "workspace 5";
        "${mod}+6" = "workspace 6";
        "${mod}+7" = "workspace 7";
        "${mod}+8" = "workspace 8";
        "${mod}+9" = "workspace 9";

        # Move focused window to a workspace
        "${mod}+Shift+1" = "move container to workspace 1";
        "${mod}+Shift+2" = "move container to workspace 2";
        "${mod}+Shift+3" = "move container to workspace 3";
        "${mod}+Shift+4" = "move container to workspace 4";
        "${mod}+Shift+5" = "move container to workspace 5";
        "${mod}+Shift+6" = "move container to workspace 6";
        "${mod}+Shift+7" = "move container to workspace 7";
        "${mod}+Shift+8" = "move container to workspace 8";
        "${mod}+Shift+9" = "move container to workspace 9";

        # Move focused window to a workspace and switch to that workspace
        "${mod}+Ctrl+1" = "move container to workspace 1; workspace 1";
        "${mod}+Ctrl+2" = "move container to workspace 2; workspace 2";
        "${mod}+Ctrl+3" = "move container to workspace 3; workspace 3";
        "${mod}+Ctrl+4" = "move container to workspace 4; workspace 4";
        "${mod}+Ctrl+5" = "move container to workspace 5; workspace 5";
        "${mod}+Ctrl+6" = "move container to workspace 6; workspace 6";
        "${mod}+Ctrl+7" = "move container to workspace 7; workspace 7";
        "${mod}+Ctrl+8" = "move container to workspace 8; workspace 8";
        "${mod}+Ctrl+9" = "move container to workspace 9; workspace 9";
      };

      # Settings
      focus.followMouse = true;
      window = {
        border = 2;
      };
      gaps = {
        inner = 5;
        outer = 5;
      };
      input = {
        "*" = {
          xkb_layout = "fi";
        };
      };
    };
  };
}
