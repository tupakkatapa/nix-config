{ pkgs, lib, config, hostName, customLib, ... }:
let
  inherit (config.home.sessionVariables) TERMINAL BROWSER EDITOR FILEMANAGER;
  mod = "ALT";

  # Use the imported global customLib
  hyprLib = customLib.hyprland;

  # Define monitor configurations for different hosts
  monitorSpecs =
    if (hostName == "torgue") then [
      {
        name = "DP-4";
        mode = "3440x1440@60";
        position = 0;
        workspaces = "1-9";
        primary = true;
      }
      {
        name = "HDMI-A-1";
        mode = "3840x2160@60";
        position = 1;
        workspaces = "10";
        primary = false;
      }
    ] else [
      {
        name = "";
        mode = "preferred";
        position = null;
        workspaces = "1-9";
        primary = true;
      }
    ];

  # Use the library functions to generate configurations
  monitorConfig = hyprLib.generateMonitors monitorSpecs;
  workspaceConfig = hyprLib.generateWorkspaces monitorSpecs;

  # Generate workspace bindings (standard 1-9,0 mapping)
  workspaceBindings = hyprLib.generateWorkspaceBindings {
    inherit mod;
    moveSilent = "SHIFT";
    move = "CTRL";
  };

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
in
{
  # hyprland.nix
  home.sessionVariables = {
    LIBSEAT_BACKEND = "logind";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
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
      monitor = monitorConfig;
      workspace = workspaceConfig;

      input = {
        kb_layout = "fi";
        kb_options = "caps:escape";
        numlock_by_default = true;
        repeat_delay = 300;
        repeat_rate = 50;
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
        "dunst"
        "swayidle -w"
        "wl-clipboard-history -t"
      ];

      bind = [
        # Brightness
        ",XF86MonBrightnessUp,   exec, ${notify.brightness} set +5%"
        ",XF86MonBrightnessDown, exec, ${notify.brightness} set 5%-"

        # Volume
        ",XF86AudioRaiseVolume, exec, ${notify.volume} -i 5"
        ",XF86AudioLowerVolume, exec, ${notify.volume} -d 5"
        ",XF86AudioMute,        exec, ${notify.volume} -t"

        # General
        "${mod} SHIFT, Return, exec, wofi"
        "${mod}, Backspace, exec, ${TERMINAL}"
        "${mod}, Return, exec, [tile]${TERMINAL}"

        # Programs
        "SUPER, B, exec, ${BROWSER}"
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
      ]
      # Add all workspace bindings generated by our function
      ++ workspaceBindings;

      # Window behavior
      windowrule = [
        # Program specific (float, position and size etc.)
        "float, blueberry"
        "float, imv"
        "float, qjackctl"
        "float, moe.launcher.an-anime-game-launcher"
        "float, mpv"
        "float, org.raspberrypi.rpi-imager"

        "center, org.pwmt.zathura"
        "float, org.pwmt.zathura"
        "size 800 1150, org.pwmt.zathura"

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

        # Sets an idle inhibit rule for the window
        "idleinhibit focus, mpv"
        "idleinhibit fullscreen, ${BROWSER}"

        # Additional opacity multiplier
        "opacity 0.95 override 0.95 override, ^(foot)$"
      ];
    };
  };
}
