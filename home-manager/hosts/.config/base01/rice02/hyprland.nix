{ pkgs
, lib
, config
, customLib
, ...
}:
let
  inherit (config.home.sessionVariables) BROWSER THEME;
  colors = customLib.colors.${THEME};
  swaybg = "${pkgs.swaybg}/bin/swaybg";
in
{
  home.file = {
    "wallpaper".source = ./wallpaper.png;
    "hypr_binds.txt".text = lib.concatStringsSep "\n" config.wayland.windowManager.hyprland.settings.bind;
  };

  wayland.windowManager.hyprland.settings = {
    general = {
      "col.active_border" = "rgb(${colors.base06})";
      "col.inactive_border" = "rgb(${colors.base02})";
      border_size = 2;
      gaps_out = 5;
    };

    decoration = {
      rounding = 0;
      active_opacity = 1;
      inactive_opacity = 1;
      shadow.enabled = false;
      blur.enabled = false;
    };

    animations = {
      enabled = false;
    };

    group = {
      "col.border_active" = "rgb(${colors.base06})";
      "col.border_inactive" = "rgb(${colors.base02})";
      groupbar.font_size = 11;
    };

    # Startup
    exec-once = [
      "${swaybg} -i ~/wallpaper --mode fill"

      # Open programs on spesific workspaces
      "[workspace 4 silent] ${BROWSER} https://web.whatsapp.com https://app.element.io/ https://web.telegram.org/ https://www.instagram.com/ https://discord.com/channels/@me https://outlook.live.com/mail/0/"
    ];

    # Window behiavior
    windowrule = [
      # Sets the workspace on which a window should open
      "workspace 4 silent, class:discord"
    ];
  };
}
