{ pkgs
, lib
, config
, ...
}:
let
  inherit (config.home.sessionVariables) TERMINAL BROWSER EDITOR FILEMANAGER THEME;
  colors = (import ../../../colors.nix).${THEME};
  mod = "ALT";

  notify = {
    brightness = "${pkgs.notify-brightness}/bin/notify-brightness";
    not-hyprprop = "${pkgs.notify-not-hyprprop}/bin/notify-not-hyprprop";
    pipewire-out-switcher = "${pkgs.notify-pipewire-out-switcher}/bin/notify-pipewire-out-switcher";
    screenshot = "${pkgs.notify-screenshot}/bin/notify-screenshot";
    volume = "${pkgs.notify-volume}/bin/notify-volume";
  };

  dm = {
    pipewire-out-switcher = "${pkgs.dm-pipewire-out-switcher}/bin/dm-pipewire-out-switcher";
    radio = "${pkgs.dm-radio}/bin/dm-radio-wrapper";
  };

  hyprpicker = "${pkgs.hyprpicker}/bin/hyprpicker";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  swaybg = "${pkgs.swaybg}/bin/swaybg";
in
{
  home.sessionVariables = {
    LIBSEAT_BACKEND = "logind";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
  };

  home.file = {
    "wallpaper".source = ./wallpaper.png;
    "hypr_binds.txt".text = lib.concatStringsSep "\n" config.wayland.windowManager.hyprland.settings.bind;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    systemd = {
      enable = true;
      # Same as default, but stop graphical-session too
      extraCommands = lib.mkBefore [
        "systemctl --user stop graphical-session.target"
        "systemctl --user start hyprland-session.target"
      ];
    };

    # Submaps are impossible to be defined in settings
    extraConfig =
      ''
        bind = ${mod}, S, submap, scripts
        submap = scripts
        bind = , c, exec, ${hyprpicker} -a -n
        bind = , c, submap, reset
        bind = , p, exec, ${dm.pipewire-out-switcher}
        bind = , p, submap, reset
        bind = , r, exec, ${dm.radio}
        bind = , r, submap, reset
        bind = , w, exec, ${notify.not-hyprprop}
        bind = , w, submap, reset
        bind = , escape, submap, reset
        submap = reset
      ''
      # Mouse binds
      + ''
        bind =  ${mod}, mouse_down, workspace, e+1
        bind =  ${mod}, mouse_up,   workspace, e-1
        bindm = ${mod}, mouse:272,  movewindow
        bindm = ${mod}, mouse:273,  resizewindow
      '';

    settings = {
      monitor = ",preferred,auto,1";

      input = {
        kb_layout = "fi";
        kb_options = "caps:escape";
        repeat_delay = 300;
        repeat_rate = 50;
      };

      general = {
        "col.active_border" = "rgb(${colors.base06})";
        "col.inactive_border" = "rgb(${colors.base02})";
        border_size = 2;
        gaps_out = 5;
      };

      decoration = {
        rounding = 7;
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

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        enable_swallow = true;
        mouse_move_enables_dpms = true;
        swallow_regex = "^(wezterm)$";
      };

      dwindle = {
        force_split = 2; # Always split to the right
        preserve_split = true;
        pseudotile = true;
        split_width_multiplier = "2.0";
      };

      # Startup
      exec-once = [
        "${swaybg} -i ~/wallpaper --mode fill"
        "dunst"
        "swayidle -w"
        "wl-clipboard-history -t"

        # Open programs on spesific workspaces
        "[workspace 4 silent] ${BROWSER} https://web.whatsapp.com https://app.element.io/ https://web.telegram.org/ https://www.instagram.com/ https://discord.com/channels/@me https://outlook.live.com/mail/0/"
        "[workspace 5 silent] plexamp"
      ];

      bind = [
        # Brightness
        ",XF86MonBrightnessUp,   exec, ${notify.brightness} set +5%"
        ",XF86MonBrightnessDown, exec, ${notify.brightness} set 5%-"

        # Volume
        ",XF86AudioRaiseVolume, exec, ${notify.volume} -i 5"
        ",XF86AudioLowerVolume, exec, ${notify.volume} -d 5"
        ",XF86AudioMute,        exec, ${notify.volume} -t"

        # Media
        ",XF86AudioNext, exec, ${playerctl} -p Plexamp next"
        ",XF86AudioPrev, exec, ${playerctl} -p Plexamp previous"
        ",XF86AudioPlay, exec, ${playerctl} -p Plexamp play-pause"

        # General
        "${mod} SHIFT, Return, exec, wofi"
        "${mod}, Backspace, exec, ${TERMINAL}"
        "${mod}, Return, exec, [tile]${TERMINAL}"

        # Programs
        "SUPER, B, exec, ${BROWSER}"
        "SUPER, G, exec, ${TERMINAL} -e $SHELL -c 'chatgpt -d'"
        "SUPER, F, exec, ${TERMINAL} -e $SHELL -c '${FILEMANAGER} ~'"
        "SUPER, V, exec, ${TERMINAL} -e $SHELL -c '${EDITOR} ~'"

        # Misc
        "${mod} SHIFT, R, exec, hyprctl reload && notify-send \"Hyprland reloaded\""
        "${mod} SHIFT, W, exec, pkill waybar; waybar & notify-send \"Waybar reloaded\""
        "${mod}, XF86AudioRaiseVolume, exec, ${notify.pipewire-out-switcher}"
        ", Print, exec, ${notify.screenshot} \"$HOME\""

        # Window management
        "${mod}, D,     pseudo"
        "${mod}, F,     togglefloating"
        "${mod}, P,     pin"
        "${mod}, Q,     killactive"
        "${mod}, Space, fullscreen"

        # Moves the focus in a direction
        "${mod}, H, movefocus, l"
        "${mod}, J, movefocus, d"
        "${mod}, K, movefocus, u"
        "${mod}, L, movefocus, r"

        # Focuses the next window on a workspace
        "${mod}, comma, cyclenext, prev"

        # Focuses the master window
        "${mod}, M, layoutmsg, focusmaster auto"

        # Moves the active window in a direction
        "${mod} SHIFT, H, movewindow, l"
        "${mod} SHIFT, J, movewindow, d"
        "${mod} SHIFT, K, movewindow, u"
        "${mod} SHIFT, L, movewindow, r"

        # Swaps the focused window with the next one
        "${mod} SHIFT, comma, swapnext, prev"

        # Swaps the current window with master
        "${mod} SHIFT, M, layoutmsg, swapwithmaster auto"

        # Resizes the active window
        "${mod} CTRL, h, resizeactive, -50   0"
        "${mod} CTRL, j, resizeactive,   0  50"
        "${mod} CTRL, k, resizeactive,   0 -50"
        "${mod} CTRL, l, resizeactive,  50   0"

        # Grouped windows
        "${mod}, g,   togglegroup"
        "${mod}, tab, changegroupactive"
        "${mod} SHIFT, g, moveoutofgroup, d"

        # workspaces
        "${mod}, x,       togglespecialworkspace"
        "${mod} SHIFT, x, movetoworkspace, special"

        # Change the workspace
        "${mod}, 1, workspace, 1"
        "${mod}, 2, workspace, 2"
        "${mod}, 3, workspace, 3"
        "${mod}, 4, workspace, 4"
        "${mod}, 5, workspace, 5"
        "${mod}, 6, workspace, 6"
        "${mod}, 7, workspace, 7"
        "${mod}, 8, workspace, 8"
        "${mod}, 9, workspace, 9"

        # Move focused window to a workspace
        "${mod} SHIFT, 1, movetoworkspacesilent, 1"
        "${mod} SHIFT, 2, movetoworkspacesilent, 2"
        "${mod} SHIFT, 3, movetoworkspacesilent, 3"
        "${mod} SHIFT, 4, movetoworkspacesilent, 4"
        "${mod} SHIFT, 5, movetoworkspacesilent, 5"
        "${mod} SHIFT, 6, movetoworkspacesilent, 6"
        "${mod} SHIFT, 7, movetoworkspacesilent, 7"
        "${mod} SHIFT, 8, movetoworkspacesilent, 8"
        "${mod} SHIFT, 9, movetoworkspacesilent, 9"

        # Move focused window to a workspace and switch to that workspace
        "${mod} CTRL, 1, movetoworkspace, 1"
        "${mod} CTRL, 2, movetoworkspace, 2"
        "${mod} CTRL, 3, movetoworkspace, 3"
        "${mod} CTRL, 4, movetoworkspace, 4"
        "${mod} CTRL, 5, movetoworkspace, 5"
        "${mod} CTRL, 6, movetoworkspace, 6"
        "${mod} CTRL, 7, movetoworkspace, 7"
        "${mod} CTRL, 8, movetoworkspace, 8"
        "${mod} CTRL, 9, movetoworkspace, 9"
      ];

      # Window behiavior
      windowrule = [
        # Sets the workspace on which a window should open
        "workspace 4 silent, discord"

        # Program specific (float, position and size etc.)
        "float, blueberry"
        "float, imv"
        "float, moe.launcher.an-anime-game-launcher"
        "float, mpv"
        "float, org.pwmt.zathura"
        "float, org.raspberrypi.rpi-imager"

        "center, title:Runelite"
        "float, title:RuneLite"
        "size 800 500, title:RuneLite"

        "center, title:QEMU"
        "float, title:QEMU"
        "size 1400 800, title:QEMU"

        "center, pavucontrol"
        "float, pavucontrol"
        "size 1400 800, pavucontrol"

        "center, title:^(Picture-in-Picture)$"
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"

        "center, title:^(Properties)$"
        "size 480 650, title:^(Properties)$"

        "center, foot"
        "float, foot"
        "size 1400 800, foot"

        "center, Plexamp"
        "float, Plexamp"
        "size 1400 800, Plexamp"

        # Sets an idle inhibit rule for the window
        "idleinhibit focus, mpv"
        "idleinhibit fullscreen, ${BROWSER}"

        # Additional opacity multiplier
        "opacity 0.95 override 0.95 override, ^(foot)$"
        "opacity 0.95 override 0.95 override, ^(Plexamp)$"
      ];
    };
  };
}
