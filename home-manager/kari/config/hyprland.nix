{ config }:
let
  inherit (config.environment.sessionVariables) TERMINAL BROWSER EDITOR;
in
''
  ### Tupakkatapa ############################## -->
  #
  #       ~/.config/hypr/hyprland.conf
  #
  ##

  ### Exec ##################################### -->
  # exec-once = /usr/lib/polkit-kde-authentication-agent-1
  # exec-once = ~/.config/hypr/desktop-portals.sh
  # exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
  # exec-once = echo fi > /tmp/kb_layout
  # exec-once = greenclip daemon
  # exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
  # exec-once = waybar
  # exec-once = wl-clipboard-history -t
  # exec-once = wlsunset -S 9:00 -s 9:00 -t 4500

  # # Wallpaper
  # #exec-once = ~/.config/hypr/scripts/set_wallpaper.sh ~/Pictures/Wallpapers/random/
  # exec-once = swaybg -m "fill" -i $(cat ~/.cache/wall) 

  # ### My programs
  # exec-once = openrgb --startminimized -d 1 -m marquee -c 3e0694 # flickering "ultraviolet"
  # exec-once = solaar -w=hide

  # # social (ws4)
  # #exec-once = whatsapp-for-linux
  # #exec-once = telegram-desktop
  # exec-once = discord
  # exec-once = ferdium
  # #exec-once = signal-desktop

  # # audio (ws5)
  # exec-once = ~/Applications/Plexamp*
  # #exec-once = qjackctl
  # #exec-once = guitarix


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
    col.active_border     = 0xffffce8a
    col.inactive_border   = 0xff444444
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

    # Blur
    blur                   = true
    blur_new_optimizations = true
    blur_passes            = 3
    blur_size              = 3
  
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
  windowrule = float, ${TERMINAL}
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
  windowrule = float, qjackctl
  windowrule = float, Rofi
  windowrule = float, solaar
  windowrule = float, splash
  windowrule = float, thunar
  windowrule = float, title:^(Media viewer)$
  windowrule = float, title:^(Volume Control)$
  windowrule = float, title:branchdialog
  windowrule = float, title:Confirm to replace files
  windowrule = float, title:File Operation Progress
  windowrule = float, title:Open File
  windowrule = float, title:wlogout
  windowrule = float, viewnior
  windowrule = float, Viewnior

  # Plexamp
  windowrule = float,        Plexamp # Float
  windowrule = move 79% 6%,  Plexamp # Move
  windowrule = size 668 376, Plexamp # Resize

  # Moves a floating window
  windowrule = move 2% 5%, guitarix
  windowrule = move 5% 50%, qjackctl

  # Resizes a floating window
  windowrule = size 600 400, title:^(Volume Control)$

  # Picture-in-Picture
  windowrule = float,       title:^(Picture-in-Picture)$  # Float
  windowrule = move 79% 6%, title:^(Picture-in-Picture)$  # Move
  windowrule = pin,         title:^(Picture-in-Picture)$  # Pin

  # Sets an idle inhibit rule for the window
  windowrule = idleinhibit focus, mpv
  windowrule = idleinhibit fullscreen, ${BROWSER}

  # Fullscreens a window
  windowrule = fullscreen, wlogout
  windowrule = fullscreen, title:wlogout

  # Forces an animation onto a window
  windowrule = animation none, Rofi

  # Additional opacity multiplier
  windowrule = opacity 0.9 override 0.9 override, ^(${TERMINAL})$
  windowrule = opacity 0.9 override 0.9 override, ^(Plexamp)$

  ### Key binds ################################ -->
  bind = SUPER SHIFT, R,      exec, hyprctl reload && notify-send "Hyprland reloaded" 
  bind = SUPER SHIFT, W,      exec, killall waybar; waybar & notify-send "Waybar reloaded"
  bind = SUPER SHIFT, Return, exec, sh ~/.config/hypr/scripts/dm-fullmenu
  bind = SUPER, Return,       exec, [tile]${TERMINAL}
  bind = SUPER, Backspace,    exec, ${TERMINAL}
  bind = SUPER, C,            exec, codium
  bind = SUPER, F,            exec, thunar
  bind = SUPER, B,            exec, ${BROWSER}
  bind = SUPER, V,            exec, ${TERMINAL} -e ${EDITOR} -c 'Telescope find_files find_command=rg,--hidden,--files'

  # Screenshot
  #bind = , Print, exec, grim $(xdg-user-dir PICTURES)/$(date +'%s.png') && exec ~/.config/hypr/scripts/screenshot_notify
  bind = , Print, exec, grim  -g "$(slurp)" ~/Pictures/Screenshots/$(date +"Screenshot_%Y-%m-%d_%H-%M-%S.png") && exec ~/.config/hypr/scripts/screenshot_notify 

  # Submaps
  bind = SUPER, p, submap, p
  submap = p
  
    # Pipewire switcher
    bind = ,p, exec, ~/.config/hypr/scripts/dm-pipewire-out-switcher
    bind = ,p, submap, reset

    # Colorpicker
    bind = ,c, exec, hyprpicker -a -n
    bind = ,c, submap, reset

    # Window props
    bind = ,w, exec, ~/.config/hypr/scripts/hyprprop_notify
    bind = ,w, submap, reset

    # Emoji menu
    bind = ,e, exec, rofi -mode emoji -show emoji -theme ~/.config/rofi/emoji.rasi 
    bind = ,e, submap, reset

    # Lighting fast memes
    bind = ,m, exec, [float]Thunar /mnt/sftp/media/b/
    bind = ,m, submap, reset

    # Set background
    bind = ,b, exec, ~/.config/hypr/scripts/dm-setbg
    bind = ,b, submap, reset

    # Radio
    bind = ,r, exec, ~/.config/hypr/scripts/dm-radio
    bind = ,r, submap, reset


  # Reset submaps
  bind = ,escape, submap, reset
  submap = reset

  ## Fn keys

  # Volume 
  bind = ,XF86AudioRaiseVolume, exec, pamixer -i 5 && exec ~/.config/hypr/scripts/volume_notify
  bind = ,XF86AudioLowerVolume, exec, pamixer -d 5 && exec ~/.config/hypr/scripts/volume_notify
  bind = ,XF86AudioMute,        exec, pamixer -t 

  # Media
  bind = ,XF86AudioNext, exec, playerctl -p Plexamp next
  bind = ,XF86AudioPlay, exec, playerctl -p Plexamp play-pause
  bind = ,XF86AudioPrev, exec, playerctl -p Plexamp previous 

  ### Window management ################ -->
  bind = SUPER SHIFT, F, togglefloating,
  bind = SUPER SHIFT, P, pin # Pin a window
  bind = SUPER, P,       pseudo, # dwindle
  bind = SUPER, Q,       killactive,
  bind = SUPER, Space,   fullscreen,

  ## Focus

  # Moves the focus in a direction
  bind = SUPER, H, movefocus, l
  bind = SUPER, L, movefocus, r
  bind = SUPER, K, movefocus, u
  bind = SUPER, J, movefocus, d

  bind = SUPER, right, movefocus, l
  bind = SUPER, left,  movefocus, r
  bind = SUPER, up,    movefocus, u
  bind = SUPER, down,  movefocus, d

  # Focuses the next window on a workspace
  bind = SUPER, comma, cyclenext, prev

  # Focuses the master window
  bind = SUPER, M, layoutmsg, focusmaster auto

  ## Move

  # Moves the active window in a direction
  bind = SUPER SHIFT, H, movewindow, l
  bind = SUPER SHIFT, J, movewindow, d
  bind = SUPER SHIFT, K, movewindow, u
  bind = SUPER SHIFT, L, movewindow, r

  bind = SUPER SHIFT, down,  movewindow, d
  bind = SUPER SHIFT, left,  movewindow, l
  bind = SUPER SHIFT, right, movewindow, r
  bind = SUPER SHIFT, up,    movewindow, u

  # Swaps the focused window with the next one
  bind = SUPER SHIFT, comma, swapnext, prev

  # Swaps the current window with master 
  bind = SUPER SHIFT, M, layoutmsg, swapwithmaster auto

  ## Resize

  # Resizes the active window
  bind = SUPER CTRL, h, resizeactive, -50 0
  bind = SUPER CTRL, j, resizeactive, 0 50
  bind = SUPER CTRL, k, resizeactive, 0 -50
  bind = SUPER CTRL, l, resizeactive, 50 0

  bind = SUPER CTRL, left, resizeactive, -50 0
  bind = SUPER CTRL, down, resizeactive, 0 50
  bind = SUPER CTRL, up, resizeactive, 0 -50
  bind = SUPER CTRL, right, resizeactive, 50 0

  ### Grouped windows ######
  bind= SUPER, g, togglegroup
  bind= SUPER, tab, changegroupactive

  ### Workspaces ######
  bind = SUPER, x, togglespecialworkspace
  bind = SUPERSHIFT, x, movetoworkspace, special

  # Change the workspace
  bind = SUPER, 1, workspace, 1
  bind = SUPER, 2, workspace, 2
  bind = SUPER, 3, workspace, 3
  bind = SUPER, 4, workspace, 4
  bind = SUPER, 5, workspace, 5
  bind = SUPER, 6, workspace, 6
  bind = SUPER, 7, workspace, 7
  bind = SUPER, 8, workspace, 8
  bind = SUPER, 9, workspace, 9

  # Move focused window to a workspace
  bind = SUPER SHIFT, 1, movetoworkspacesilent, 1
  bind = SUPER SHIFT, 2, movetoworkspacesilent, 2
  bind = SUPER SHIFT, 3, movetoworkspacesilent, 3
  bind = SUPER SHIFT, 4, movetoworkspacesilent, 4
  bind = SUPER SHIFT, 5, movetoworkspacesilent, 5
  bind = SUPER SHIFT, 6, movetoworkspacesilent, 6
  bind = SUPER SHIFT, 7, movetoworkspacesilent, 7
  bind = SUPER SHIFT, 8, movetoworkspacesilent, 8
  bind = SUPER SHIFT, 9, movetoworkspacesilent, 9

  # Move focused window to a workspace and switch to that workspace
  bind = SUPER CTRL, 1, movetoworkspace, 1
  bind = SUPER CTRL, 2, movetoworkspace, 2
  bind = SUPER CTRL, 3, movetoworkspace, 3
  bind = SUPER CTRL, 4, movetoworkspace, 4
  bind = SUPER CTRL, 5, movetoworkspace, 5

  bind = SUPER CTRL, 6, movetoworkspace, 6
  bind = SUPER CTRL, 7, movetoworkspace, 7
  bind = SUPER CTRL, 8, movetoworkspace, 8
  bind = SUPER CTRL, 9, movetoworkspace, 9


  ### Mouse binds ############################## -->
  bindm = SUPER, mouse:272,  movewindow
  bindm = SUPER, mouse:273,  resizewindow
  bind  = SUPER, mouse_down, workspace, e+1
  bind  = SUPER, mouse_up,   workspace, e-1
''
