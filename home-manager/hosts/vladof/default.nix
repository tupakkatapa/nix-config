{ config
, lib
, pkgs
, customLib
, ...
}:
let
  inherit (config.home.sessionVariables) FONT TERMINAL THEME;
  colors = customLib.colors.${THEME};
  swayosd = "${config.services.swayosd.package}/bin/swayosd-client";
  playerctl = "${pkgs.playerctl}/bin/playerctl";

  # Runtime-module apps get installed (green), building (yellow) and missing (red) variants
  icons = pkgs.runCommand "couch-menu-icons" { nativeBuildInputs = [ pkgs.librsvg pkgs.imagemagick ]; } ''
    mkdir $out
    for icon in firefox retroarch steam plexamp; do
      rsvg-convert -w 192 -h 192 ${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/$icon.svg -o $out/$icon.png
    done
    for icon in retroarch steam plexamp; do
      dot() { magick $out/$icon.png -fill "#$1" -stroke "#${colors.base00}" -strokewidth 8 -draw "circle 158,158 158,182" "$2"; }
      dot ${colors.base0B} $out/$icon-on.png
      dot ${colors.base0A} $out/$icon-busy.png
      dot ${colors.base08} $out/$icon-off.png
    done
  '';

  couchPad = pkgs.writers.writePython3 "couch-pad"
    { libraries = [ pkgs.python3Packages.evdev pkgs.python3Packages.i3ipc ]; }
    (builtins.readFile ./couch-pad.py);

  # GtkLayerShell comes through GObject introspection, which the Python
  # wrapper leaves out
  couchOsk = pkgs.writers.writePython3 "couch-osk"
    {
      libraries = [ pkgs.python3Packages.pygobject3 ];
      makeWrapperArgs = [ "--prefix" "GI_TYPELIB_PATH" ":" (lib.makeSearchPathOutput "out" "lib/girepository-1.0" [ pkgs.gtk3 pkgs.gtk-layer-shell pkgs.pango pkgs.gdk-pixbuf pkgs.harfbuzz pkgs.at-spi2-core pkgs.glib pkgs.gobject-introspection ]) ];
    }
    (builtins.readFile ./couch-osk.py);
  # Styled like the menu
  oskStyle = pkgs.writeText "couch-osk.css" ''
    window { background: transparent; }
    .panel { background: #${colors.base00}; border: 1px solid #${colors.base01}; border-radius: 13px; padding: 8px 8px 4px; }
    .key { font: 16pt "${FONT}"; color: #${colors.base05}; background: #${colors.base01}; border-radius: 8px; margin: 3px; padding: 10px 14px; }
    .key.shift { color: #${colors.base0A}; }
    .key.selected { color: #${colors.base00}; background: #${colors.base0A}; }
    .hint { font: 9pt "${FONT}"; color: #${colors.base03}; margin-top: 6px; }
  '';

  couchMenu = pkgs.writeShellApplication {
    name = "couch-menu";
    runtimeInputs = [ pkgs.coreutils pkgs.util-linux pkgs.jq config.wayland.windowManager.sway.package config.programs.fuzzel.package ];
    runtimeEnv = {
      ICONS = icons;
      inherit TERMINAL;
    };
    text = builtins.readFile ./couch-menu.sh;
  };
in
{
  # This file should be imported under 'home-manager.users.<username>'
  # See 'home-manager/users/kari/minimal.nix' for an example how to do this conditionally

  imports = [
    ../.config/base01/rice01/cursor.nix
    ../.config/base01/rice01/nixvim.nix
  ];

  home.pointerCursor.size = 32;

  # Couch launcher on the TV: bare compositor, every window fullscreen
  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Mod1";
      # Full-screen apps cover it, so it only shows with the menu
      bars = [{
        position = "bottom";
        workspaceButtons = false;
        trayOutput = "none";
        fonts = {
          names = [ FONT ];
          size = 9.0;
        };
        statusCommand = "${lib.getExe couchMenu} --status";
        extraConfig = "gaps 0 24 12 24";
        colors = {
          background = "#1d2021";
          statusline = "#${colors.base01}";
          separator = "#1d2021";
        };
      }];
      # A window that loses fullscreen to another (only one per workspace)
      # still fills the screen as the only tile
      window = {
        border = 0;
        titlebar = false;
      };
      floating = {
        border = 0;
        titlebar = false;
      };
      output."*" = {
        # 1920x1080 lays out as 1371x771, readable from the couch
        scale = "1.4";
        bg = "#1d2021 solid_color";
      };
      startup = [{ command = lib.getExe couchMenu; }];
      seat."*".xcursor_theme = "\"${config.home.pointerCursor.name}\" ${toString config.home.pointerCursor.size}";
      input."type:keyboard" = {
        xkb_layout = "fi";
        xkb_numlock = "enabled";
      };
      # The pad's stick has its own speed curve
      input."3084:1:Couch_pad".accel_profile = "flat";
      keybindings = {
        "Mod1+Return" = "exec ${lib.getExe couchMenu} --terminal";
        "Mod1+q" = "exec ${lib.getExe couchMenu} --close";
        "Mod1+Shift+q" = "kill";
        # Home key: back to the menu, which shows once no app is visible
        "--release Super_L" = "exec ${lib.getExe couchMenu} --close";
        "XF86HomePage" = "exec ${lib.getExe couchMenu} --close";
        "XF86AudioRaiseVolume" = "exec ${swayosd} --output-volume raise";
        "XF86AudioLowerVolume" = "exec ${swayosd} --output-volume lower";
        "XF86AudioMute" = "exec ${swayosd} --output-volume mute-toggle";
        "XF86AudioPlay" = "exec ${playerctl} play-pause";
        "XF86AudioNext" = "exec ${playerctl} next";
        "XF86AudioPrev" = "exec ${playerctl} previous";
      };
      window.commands = [
        { criteria.app_id = ".*"; command = "fullscreen enable"; }
        { criteria.class = ".*"; command = "fullscreen enable"; }
      ];
    };
  };

  # One instance per pad, started by udev as the pad connects, ending as it
  # disconnects
  systemd.user.services."couch-pad@" = {
    Unit.Description = "Couch controls of the pad %i";
    Service = {
      ExecStart = "${couchPad} /dev/input/couch-pad-%i ${couchOsk} ${oskStyle}";
      Restart = "on-failure";
    };
  };

  # Udev starts couch-pad@ only as a pad connects, not for one already there
  # when the user manager starts
  systemd.user.services.couch-pads = {
    Unit.Description = "Couch controls of the pads connected before login";
    Install.WantedBy = [ "default.target" ];
    Service = {
      Type = "oneshot";
      ExecStart = toString (pkgs.writeShellScript "couch-pads" ''
        shopt -s nullglob
        for pad in /dev/input/couch-pad-*; do
          ${pkgs.systemd}/bin/systemctl --user start --no-block "couch-pad@''${pad#/dev/input/couch-pad-}.service"
        done
      '');
    };
  };

  # On-screen output volume for the volume keys; the TV's own volume is out of
  # reach over HDMI, and Plexamp ignores MPRIS volume
  services.swayosd.enable = true;

  # The pad's B is Backspace: a page back, unless typing
  programs.firefox.profiles.personal.settings."browser.backspace_action" = 0;

  # The TV's physical DPI is low; size by the output scale instead
  programs.foot.settings.main = {
    dpi-aware = lib.mkForce "no";
    font = "monospace:size=14";
  };

  # The couch menu: one compact column, no search
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "${FONT}:size=16";
        # The TV's physical DPI is low; size by the output scale instead
        dpi-aware = "no";
        hide-prompt = "yes";
        lines = 4;
        width = 18;
        line-height = 56;
        horizontal-pad = 13;
        vertical-pad = 13;
        inner-pad = 0;
      };
      colors = {
        background = "${colors.base00}ff";
        text = "${colors.base05}ff";
        selection = "${colors.base0A}ff";
        selection-text = "${colors.base00}ff";
        match = "${colors.base0A}ff";
        selection-match = "${colors.base00}ff";
        border = "${colors.base01}ff";
      };
      border = {
        width = 1;
        radius = 13;
        selection-radius = 13;
      };
    };
  };

  # Frecency-based dir jumping
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    options = [ "--cmd cd" ];
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = false;
    setSessionVariables = true;
    download = "/mnt/wd-red/sftp/dnld";
    documents = "/mnt/wd-red/sftp/docs";
  };
}
