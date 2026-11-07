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

  couchMenu = pkgs.writeShellApplication {
    name = "couch-menu";
    runtimeInputs = [ pkgs.coreutils pkgs.util-linux pkgs.jq pkgs.evsieve config.wayland.windowManager.sway.package config.programs.fuzzel.package ];
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

  # Each pad's Xbox button is the home key, through a virtual keyboard. Udev
  # starts one instance per pad, as evsieve needs the device at startup, and
  # the instance ends when the pad disconnects
  systemd.user.services."couch-pad@" = {
    Unit.Description = "Xbox button of %i returns to the couch menu";
    Service.ExecStart = "${pkgs.evsieve}/bin/evsieve --input /dev/input/couch-pad-%i persist=exit --map btn:mode key:leftmeta --output";
  };

  # On-screen output volume for the volume keys; the TV's own volume is out of
  # reach over HDMI, and Plexamp ignores MPRIS volume
  services.swayosd.enable = true;

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
