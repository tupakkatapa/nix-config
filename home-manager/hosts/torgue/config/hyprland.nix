{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (config.home.sessionVariables) TERMINAL BROWSER EDITOR FILEMANAGER;
  inherit (import ./colors.nix) background foreground accent inactive blue cyan green orange pink purple red yellow;
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
    quickfile = "${pkgs.dm-quickfile}/bin/dm-quickfile";
    radio = "${pkgs.dm-radio}/bin/dm-radio-wrapper";
  };

  hyprpicker = "${pkgs.hyprpicker}/bin/hyprpicker";
  pamixer = "${pkgs.pamixer}/bin/pamixer";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  swaybg = "${pkgs.swaybg}/bin/swaybg";
in {
  home.sessionVariables = {
    LIBSEAT_BACKEND = "logind";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
  };

  home.file."wallpaper".source = ./wallpaper.png;

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
        bind = , e, exec, ${pkgs.wofi-emoji}/bin/wofi-emoji
        bind = , e, submap, reset
        bind = , f, exec, ${dm.quickfile} "/mnt/sftp/docs/tabs" "$HOME/Documents" "$HOME/nix-config"
        bind = , f, submap, reset
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
      input = {
        follow_mouse = "1";
        kb_layout = "fi";
        kb_options = "caps:escape";
        repeat_delay = "300";
        repeat_rate = "50";
        sensitivity = "0"; # -1.0 - 1.0, 0 means no modification.
      };
      monitor = ",preferred,auto,1";

      general = {
        "col.active_border" = "rgb(${accent})";
        "col.inactive_border" = "rgb(${inactive})";
        border_size = "2";
        gaps_in = "5";
        gaps_out = "5";
        layout = "dwindle";
        no_border_on_floating = "false";
      };

      misc = {
        disable_hyprland_logo = "true";
        disable_splash_rendering = "true";
        enable_swallow = "true";
        mouse_move_enables_dpms = "true";
        swallow_regex = "^(wezterm)$";
      };

      decoration = {
        "col.shadow" = "0x66000000";
        active_opacity = "1.0";
        drop_shadow = "false";
        inactive_opacity = "1.0";
        rounding = "8";
        shadow_ignore_window = "true";
        shadow_offset = "0 0";
        shadow_range = "0";
        shadow_render_power = "2";
      };

      animations = {
        enabled = "true";
        bezier = [
          "overshot,  0.05, 0.9, 0.1,   1.05"
          "smoothIn,  0.25, 1,   0.5,   1"
          "smoothOut, 0.36, 0,   0.66, -0.56"
        ];
        animation = [
          "border,      1, 3, default"
          "fade,        1, 3, smoothIn"
          "fadeDim,     1, 3, smoothIn"
          "windows,     1, 3, overshot, slide"
          "windowsMove, 1, 3, default"
          "windowsOut,  1, 3, smoothOut, slide"
          "workspaces,  1, 3, default"
        ];
      };

      # Layouts
      dwindle = {
        force_split = "2"; # always split to the right
        no_gaps_when_only = "false";
        preserve_split = "true";
        pseudotile = "true";
        split_width_multiplier = "2.0";
      };
      master.new_is_master = "false";

      # Startup
      exec-once = [
        "${swaybg} -i ~/wallpaper --mode fill"
        "dunst"
        "swayidle -w"
        "wl-clipboard-history -t"

        "[workspace 4 silent] discord"
        "[workspace 4 silent] ferdium"
        "[workspace 5 silent] plexamp"
        "openrgb --startminimized"
        "solaar -w=hide"
      ];

      # Key bindings
      bind = [
        # Brightness
        ",XF86MonBrightnessUp,   exec, ${notify.brightness} -b +5"
        ",XF86MonBrightnessDown, exec, ${notify.brightness} -b -5"

        # Volume
        ",XF86AudioRaiseVolume, exec, ${notify.volume} -i 5"
        ",XF86AudioLowerVolume, exec, ${notify.volume} -d 5"
        ",XF86AudioMute,        exec, ${pamixer} -t"

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
        "SUPER, F, exec, ${FILEMANAGER}"
        "SUPER, V, exec, [tile]${TERMINAL} -e sh -c '${EDITOR} ~/Workspace'"
        "SUPER, C, exec, [tile]${TERMINAL} -e sh -c '${EDITOR} ~/nix-config'"

        # Misc
        "${mod} SHIFT, R, exec, hyprctl reload && notify-send \"Hyprland reloaded\""
        "${mod} SHIFT, W, exec, pkill waybar; waybar & notify-send \"Waybar reloaded\""
        "${mod}, XF86AudioRaiseVolume, exec, ${notify.pipewire-out-switcher}"
        ", Print, exec, ${notify.screenshot} \"$HOME/Pictures/Screenshots\""

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

        # Floats a window
        "float, LosslessCut"
        "float, Lxappearance"
        "float, Rofi"
        "float, Viewnior"
        "float, blueberry"
        "float, blueman"
        "float, confirm"
        "float, confirmreset"
        "float, dialog"
        "float, download"
        "float, error"
        "float, feh"
        "float, file-roller"
        "float, file_progress"
        "float, imv"
        "float, moe.launcher.an-anime-game-launcher" # Genshin Impact
        "float, mpv"
        "float, notification"
        "float, org.kde.polkit-kde-authentication-agent-1"
        "float, org.pwmt.zathura"
        "float, org.raspberrypi.rpi-imager"
        "float, putty"
        "float, solaar"
        "float, splash"
        "float, title:Confirm to replace files"
        "float, title:File Operation Progress"
        "float, title:Open File"
        "float, title:^(Media viewer)$"
        "float, title:branchdialog"
        "float, title:wlogout"
        "float, viewnior"
        "float, yad"

        # Pseudo
        "pseudo, QjackCtl"
        "pseudo, guitarix"

        # Program specific (float, position and size etc.)
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
        "size 480 648, title:^(Properties)$"

        "center, title:^(Close Virtual Machine)$"

        "center, org.gnome.Nautilus"
        "float, Nautilus"
        "size 1400 800, org.gnome.Nautilus"

        "center, Alacritty"
        "float, Alacritty"
        "size 1400 800, Alacritty"

        "center, Plexamp"
        "float, Plexamp"
        "size 1400 800, Plexamp"

        # Sets an idle inhibit rule for the window
        "idleinhibit focus, mpv"
        "idleinhibit fullscreen, ${BROWSER}"

        # Fullscreens a window
        "fullscreen, wlogout"
        "fullscreen, title:wlogout"

        # Fake fullscreens a window
        # "fakefullscreen, Ferdium"
        # "fakefullscreen, discord"
        # "fakefullscreen, firefox"

        # Forces an animation onto a window
        "animation none, Rofi"

        # Additional opacity multiplier
        "opacity 0.9 override 0.9 override, ^(Alacritty)$"
        "opacity 0.9 override 0.9 override, ^(Plexamp)$"
        "opacity 0.9 override 0.9 override, ^(org.gnome.Nautilus)$"
      ];
    };
  };
}
