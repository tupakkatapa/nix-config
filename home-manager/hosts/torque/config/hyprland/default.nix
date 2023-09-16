{config, ...}: let
  inherit (config.home.sessionVariables) TERMINAL BROWSER EDITOR FILEMANAGER;

  # Colors
  accent = "ffce8a";
  inactive = "444444";
  blue = "7d9bba";
  cyan = "8be9fd";
  green = "66cc99";
  orange = "ebcb8b";
  red = "fb958b";
  yellow = "ebcb8b";
in {
  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    LIBSEAT_BACKEND = "logind";
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
  };

  home.file = {
    # Notify
    ".config/hypr/notify-volume.sh".source = ./scripts/notify-volume.sh;
    ".config/hypr/notify-hyprprop.sh".source = ./scripts/notify-hyprprop.sh;
    ".config/hypr/notify-screenshot.sh".source = ./scripts/notify-screenshot.sh;
    # Assets
    ".config/hypr/audio-volume-high-panel.svg".source = ./assets/audio-volume-high-panel.svg;
    "Pictures/wallpaper.jpg".source = ./assets/wallpaper.jpg;
    # Wofi
    ".config/hypr/dm-pipewire-out-switcher.sh".source = ./scripts/dm-pipewire-out-switcher.sh;
    ".config/hypr/dm-radio.sh".source = ./scripts/dm-radio.sh;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
      ### Tupakkatapa ############################## -->
      #
      #       ~/.config/hypr/hyprland.conf
      #
      ##

      ### Variables ################################ -->
      $MOD = ALT

      ### Exec ##################################### -->
      exec-once = wl-clipboard-history -t
      exec-once = swayidle -w
      exec-once = dunst

      # Wallpaper
      exec-once = swaybg -i ~/Pictures/wallpaper.jpg --mode fill

      # RGB
      exec-once = openrgb --client --device 1 --mode direct --color "330099"

      ### My programs

      # background
      exec-once = solaar -w=hide

      # social (ws4)
      exec-once = discord
      exec-once = ferdium
      #exec-once = signal-desktop

      # audio (ws5)
      exec-once = plexamp
      #exec-once = qjackctl
      #exec-once = guitarix

      ### Monitors ################################# -->
      monitor = ,preferred,auto,1


      ### Brightness (gummy)
      bind = ,XF86MonBrightnessDown, exec, gummy -b -5
      bind = ,XF86MonBrightnessUp, exec, gummy -b +5


      ### Input #################################### -->
      input {
        follow_mouse = 1
        kb_layout    = fi
        kb_options   = caps:escape
        repeat_delay = 300
        repeat_rate  = 50
        sensitivity  = 0 # -1.0 - 1.0, 0 means no modification.
      }


      ### General ################################## -->
      general {
        border_size           = 2
        col.active_border     = rgb(${accent})
        col.inactive_border   = rgb(${inactive})
        gaps_in               = 5
        gaps_out              = 5
        layout                = master
        no_border_on_floating = false
      }


      ### Misc ##################################### -->
      misc {
        disable_hyprland_logo    = true
        disable_splash_rendering = true
        enable_swallow           = true
        mouse_move_enables_dpms  = true
        swallow_regex            = ^(wezterm)$
      }


      ### Decorations ############################## -->
      decoration {

        # Rounded corners
        rounding = 8
        multisample_edges = true

        # Opacity
        active_opacity   = 1.0
        inactive_opacity = 1.0

        # Blurls
        blurls = gtk-layer-shell
        blurls = lockscreen

        # Shadow
        col.shadow           = 0x66000000
        drop_shadow          = true
        shadow_ignore_window = true
        shadow_offset        = 0 0
        shadow_range         = 0
        shadow_render_power  = 2
      }


      ### Animations ############################### -->
      animations {
        enabled = true

        # Bezier Curve
        bezier = overshot,  0.05, 0.9, 0.1,   1.05
        bezier = smoothIn,  0.25, 1,   0.5,   1
        bezier = smoothOut, 0.36, 0,   0.66, -0.56

        # Animation
        animation = border,      1, 3, default
        animation = fade,        1, 3, smoothIn
        animation = fadeDim,     1, 3, smoothIn
        animation = windows,     1, 3, overshot, slide
        animation = windowsMove, 1, 3, default
        animation = windowsOut,  1, 3, smoothOut, slide
        animation = workspaces,  1, 3, default
      }


      ### Layouts ################################## -->
      dwindle {
        force_split       = 2 # always split to the right
        no_gaps_when_only = false
        pseudotile        = true
        preserve_split    = true
      }

      master {
        new_is_master = false
      }


      ### Window Rules ############################# -->

      # Sets the workspace on which a window should open
      windowrule = workspace 4, discord
      windowrule = workspace 4, org.telegram.desktop
      windowrule = workspace 4, Ferdium
      windowrule = workspace 4, Signal
      windowrule = workspace 4, whatsapp-for-linux
      windowrule = workspace 5, guitarix
      windowrule = workspace 5, Plexamp
      windowrule = workspace 5, qjackctl

      # Floats a window
      windowrule = float, Alacritty
      windowrule = float, yad
      windowrule = float, blueberry
      windowrule = float, blueman
      windowrule = float, confirm
      windowrule = float, confirmreset
      windowrule = float, dialog
      windowrule = float, download
      windowrule = float, error
      windowrule = float, feh
      windowrule = float, file_progress
      windowrule = float, file-roller
      windowrule = float, guitarix
      windowrule = float, LosslessCut
      windowrule = float, Lxappearance
      windowrule = float, moe.launcher.an-anime-game-launcher # Genshin Impact
      windowrule = float, mpv
      windowrule = float, notification
      windowrule = float, org.kde.polkit-kde-authentication-agent-1
      windowrule = float, org.raspberrypi.rpi-imager
      windowrule = float, pavucontrol
      windowrule = float, pavucontrol-qt
      windowrule = float, putty
      windowrule = float, qemu
      windowrule = float, QjackCtl
      windowrule = float, Rofi
      windowrule = float, solaar
      windowrule = float, splash
      windowrule = float, thunar
      windowrule = float, title:^(Media viewer)$
      windowrule = float, title:branchdialog
      windowrule = float, title:Confirm to replace files
      windowrule = float, title:File Operation Progress
      windowrule = float, title:Open File
      windowrule = float, title:wlogout
      windowrule = float, viewnior
      windowrule = float, Viewnior
      windowrule = float, Nautilus
      windowrule = float, imv
      windowrule = float, org.pwmt.zathura

      # Floats a window and resizes
      windowrule = float, title:RuneLite
      windowrule = size 800 500, title:RuneLite
      windowrule = float, title:QEMU
      windowrule = size 1280 828, title:QEMU
      windowrule = float, Plexamp
      windowrule = size 700 400, Plexamp
      windowrule = float, title:^(Volume Control)$
      windowrule = size 700 400, title:^(Volume Control)$
      windowrule = float, title:^(Picture-in-Picture)$
      windowrule = pin, title:^(Picture-in-Picture)$

      # Sets an idle inhibit rule for the window
      windowrule = idleinhibit focus, mpv
      windowrule = idleinhibit fullscreen, ${BROWSER}

      # Fullscreens a window
      windowrule = fullscreen, wlogout
      windowrule = fullscreen, title:wlogout

      # Forces an animation onto a window
      windowrule = animation none, Rofi

      # Additional opacity multiplier
      windowrule = opacity 0.9 override 0.9 override, ^(Alacritty)$
      windowrule = opacity 0.9 override 0.9 override, ^(Plexamp)$

      ### Key binds ################################ -->
      bind = $MOD SHIFT, R,      exec, hyprctl reload && notify-send "Hyprland reloaded"
      bind = $MOD SHIFT, W,      exec, pkill waybar; waybar & notify-send "Waybar reloaded"
      bind = $MOD SHIFT, Return, exec, wofi
      bind = $MOD, Return,       exec, [tile]${TERMINAL}
      bind = $MOD, Backspace,    exec, ${TERMINAL}

      # Programs
      bind = SUPER, C,            exec, codium ~/Workspace
      bind = SUPER, V,            exec, [tile]${TERMINAL} -e sh -c '${EDITOR} ~/Workspace'
      bind = SUPER, F,            exec, ${FILEMANAGER}
      bind = SUPER, B,            exec, ${BROWSER}

      # Screenshot
      bind = , Print, exec, sh ~/.config/hypr/notify-screenshot.sh

      ## Submaps
      bind = $MOD, p, submap, scripts
      submap = scripts

      # Pipewire switcher
      bind = , p, exec, sh ~/.config/hypr/dm-pipewire-out-switcher.sh
      bind = , p, submap, reset

      # Colorpicker
      bind = , c, exec, hyprpicker -a -n
      bind = , c, submap, reset

      # Window props
      bind = , w, exec, sh ~/.config/hypr/notify-hyprprop.sh
      bind = , w, submap, reset

      # Radio
      bind = , r, exec, sh ~/.config/hypr/dm-radio.sh
      bind = , r, submap, reset

      # Reset submaps
      bind = , escape, submap, reset
      submap = reset

      ## Fn keys

      # Volume
      bind = ,XF86AudioRaiseVolume, exec, pamixer -i 5 && exec sh ~/.config/hypr/notify-volume.sh
      bind = ,XF86AudioLowerVolume, exec, pamixer -d 5 && exec sh ~/.config/hypr/notify-volume.sh
      bind = ,XF86AudioMute,        exec, pamixer -t

      # Media
      bind = ,XF86AudioNext, exec, playerctl -p Plexamp next
      bind = ,XF86AudioPlay, exec, playerctl -p Plexamp play-pause
      bind = ,XF86AudioPrev, exec, playerctl -p Plexamp previous

      ### Window management ################ -->
      bind = $MOD SHIFT, F, togglefloating,
      bind = $MOD SHIFT, P, pin # Pin a window
      bind = $MOD, P,       pseudo, # dwindle
      bind = $MOD, Q,       killactive,
      bind = $MOD, Space,   fullscreen,

      ## Focus

      # Moves the focus in a direction
      bind = $MOD, H, movefocus, l
      bind = $MOD, L, movefocus, r
      bind = $MOD, K, movefocus, u
      bind = $MOD, J, movefocus, d

      bind = $MOD, right, movefocus, l
      bind = $MOD, left,  movefocus, r
      bind = $MOD, up,    movefocus, u
      bind = $MOD, down,  movefocus, d

      # Focuses the next window on a workspace
      bind = $MOD, comma, cyclenext, prev

      # Focuses the master window
      bind = $MOD, M, layoutmsg, focusmaster auto

      ## Move

      # Moves the active window in a direction
      bind = $MOD SHIFT, H, movewindow, l
      bind = $MOD SHIFT, J, movewindow, d
      bind = $MOD SHIFT, K, movewindow, u
      bind = $MOD SHIFT, L, movewindow, r

      bind = $MOD SHIFT, down,  movewindow, d
      bind = $MOD SHIFT, left,  movewindow, l
      bind = $MOD SHIFT, right, movewindow, r
      bind = $MOD SHIFT, up,    movewindow, u

      # Swaps the focused window with the next one
      bind = $MOD SHIFT, comma, swapnext, prev

      # Swaps the current window with master
      bind = $MOD SHIFT, M, layoutmsg, swapwithmaster auto

      ## Resize

      # Resizes the active window
      bind = $MOD CTRL, h, resizeactive, -50 0
      bind = $MOD CTRL, j, resizeactive, 0 50
      bind = $MOD CTRL, k, resizeactive, 0 -50
      bind = $MOD CTRL, l, resizeactive, 50 0

      bind = $MOD CTRL, left, resizeactive, -50 0
      bind = $MOD CTRL, down, resizeactive, 0 50
      bind = $MOD CTRL, up, resizeactive, 0 -50
      bind = $MOD CTRL, right, resizeactive, 50 0

      ### Grouped windows ######
      bind= $MOD, g, togglegroup
      bind= $MOD, tab, changegroupactive

      ### Workspaces ######
      bind = $MOD, x, togglespecialworkspace
      bind = $MODSHIFT, x, movetoworkspace, special

      # Change the workspace
      bind = $MOD, 1, workspace, 1
      bind = $MOD, 2, workspace, 2
      bind = $MOD, 3, workspace, 3
      bind = $MOD, 4, workspace, 4
      bind = $MOD, 5, workspace, 5
      bind = $MOD, 6, workspace, 6
      bind = $MOD, 7, workspace, 7
      bind = $MOD, 8, workspace, 8
      bind = $MOD, 9, workspace, 9

      # Move focused window to a workspace
      bind = $MOD SHIFT, 1, movetoworkspacesilent, 1
      bind = $MOD SHIFT, 2, movetoworkspacesilent, 2
      bind = $MOD SHIFT, 3, movetoworkspacesilent, 3
      bind = $MOD SHIFT, 4, movetoworkspacesilent, 4
      bind = $MOD SHIFT, 5, movetoworkspacesilent, 5
      bind = $MOD SHIFT, 6, movetoworkspacesilent, 6
      bind = $MOD SHIFT, 7, movetoworkspacesilent, 7
      bind = $MOD SHIFT, 8, movetoworkspacesilent, 8
      bind = $MOD SHIFT, 9, movetoworkspacesilent, 9

      # Move focused window to a workspace and switch to that workspace
      bind = $MOD CTRL, 1, movetoworkspace, 1
      bind = $MOD CTRL, 2, movetoworkspace, 2
      bind = $MOD CTRL, 3, movetoworkspace, 3
      bind = $MOD CTRL, 4, movetoworkspace, 4
      bind = $MOD CTRL, 5, movetoworkspace, 5

      bind = $MOD CTRL, 6, movetoworkspace, 6
      bind = $MOD CTRL, 7, movetoworkspace, 7
      bind = $MOD CTRL, 8, movetoworkspace, 8
      bind = $MOD CTRL, 9, movetoworkspace, 9


      ### Mouse binds ############################## -->
      bindm = $MOD, mouse:272,  movewindow
      bindm = $MOD, mouse:273,  resizewindow
      bind  = $MOD, mouse_down, workspace, e+1
      bind  = $MOD, mouse_up,   workspace, e-1
    '';
  };
}
