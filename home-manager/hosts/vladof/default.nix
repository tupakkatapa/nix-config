{ config, ... }:
let
  inherit (config.home.sessionVariables) BROWSER TERMINAL;
  launch = module: "${TERMINAL} -e runtime-modules enable ${module}";
in
{
  # This file should be imported under 'home-manager.users.<username>'
  # See 'home-manager/users/kari/minimal.nix' for an example how to do this conditionally

  imports = [ ../.config/base01/rice01/nixvim.nix ];

  # Couch launcher on the TV: bare compositor, every window fullscreen
  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Mod1";
      bars = [ ];
      startup = [{ command = "${BROWSER} https://plex.coditon.com https://www.youtube.com/feed/subscriptions"; }];
      input."type:keyboard" = {
        xkb_layout = "fi";
        xkb_numlock = "enabled";
      };
      keybindings = {
        "Mod4+b" = "exec ${BROWSER}";
        "Mod4+r" = "exec ${launch "retroarch"}";
        "Mod4+s" = "exec ${launch "steam"}";
        "Mod1+Return" = "exec ${TERMINAL}";
        "Mod1+q" = "kill";
        "Mod1+Tab" = "focus next";
        "Mod1+space" = "fullscreen toggle";
      };
      window.commands = [
        { criteria.app_id = ".*"; command = "fullscreen enable"; }
        { criteria.class = ".*"; command = "fullscreen enable"; }
      ];
    };
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = false;
    setSessionVariables = true;
    download = "/mnt/wd-red/sftp/dnld";
    documents = "/mnt/wd-red/sftp/docs";
  };
}
