{ pkgs
, lib
, config
, customLib
, ...
}:
let
  inherit (config.home.sessionVariables) BROWSER THEME;
  colors = customLib.colors.${THEME};
  rice = import ./config.nix { inherit customLib config; };
  swaybg = "${pkgs.swaybg}/bin/swaybg";
  liquidctl = "${pkgs.liquidctl}/bin/liquidctl";
in
{
  home.file = {
    "wallpaper".source = ./wallpaper.png;
    "hypr_binds.txt".text = lib.concatStringsSep "\n" config.wayland.windowManager.hyprland.settings.bind;
  };

  wayland.windowManager.hyprland.settings = {
    general = {
      "col.active_border" = "rgb(${rice.border.active})";
      "col.inactive_border" = "rgb(${rice.border.inactive})";
      border_size = rice.border.size;
      gaps_in = rice.spacing / 2;
      gaps_out = rice.spacing;
    };

    decoration = {
      inherit (rice) rounding;
      shadow.enabled = false;
      blur.enabled = false;
    };

    animations = {
      enabled = true;
      bezier = [
        "easein,0.1,0,0.5,0"
        "easeout,0.5,1,0.9,1"
        "easeinout,0.45,0,0.55,1"
      ];
      animation =
        let
          duration = "1";
        in
        [
          "fadeIn,1,${duration},easeout"
          "fadeLayersIn,1,${duration},easeout"
          "layersIn,1,${duration},easeout"
          "windowsIn,1,${duration},easeout"

          "fadeLayersOut,1,${duration},easein"
          "fadeOut,1,${duration},easein"
          "layersOut,1,${duration},easein"
          "windowsOut,1,${duration},easein"

          "border,1,${duration},easeout"
          "fadeDim,1,${duration},easeinout"
          "fadeShadow,1,${duration},easeinout"
          "fadeSwitch,1,${duration},easeinout"
          "windowsMove,1,${duration},easeout"
          "workspaces,1,${duration},easeout"
        ];
    };

    group = {
      "col.border_active" = "rgb(${colors.base06})";
      "col.border_inactive" = "rgb(${colors.base02})";
      groupbar.font_size = 11;
    };

    # Startup
    exec-once = [
      "${swaybg} -i ~/wallpaper --mode fill"
      "${liquidctl} set led1 color fixed 850255"
      "${liquidctl} set led2 color fixed 330066"

      # Open programs on spesific workspaces
      "[workspace 4 silent] ${BROWSER} https://web.whatsapp.com https://web.telegram.org/ https://discord.com/channels/@me https://outlook.live.com/mail/0/"
      "[workspace 5 silent] ${pkgs.google-chrome}/bin/google-chrome-stable https://app.slack.com/client https://mail.google.com/mail https://calendar.google.com/calendar https://drive.google.com/drive/home"
    ];

    # Window behiavior
    windowrule = [
      # Sets the workspace on which a window should open
      "workspace 4 silent, class:discord"
    ];
  };
}
