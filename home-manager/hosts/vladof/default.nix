{ config
, lib
, pkgs
, customLib
, ...
}:
let
  inherit (config.home.sessionVariables) BROWSER FONT TERMINAL THEME;
  colors = customLib.colors.${THEME};

  icons = pkgs.runCommand "couch-menu-icons" { nativeBuildInputs = [ pkgs.librsvg ]; } ''
    mkdir $out
    for icon in plex youtube firefox retroarch steam; do
      rsvg-convert -w 192 -h 192 ${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/$icon.svg -o $out/$icon.png
    done
  '';

  # Couch home screen: one app at a time, back to the menu when it closes
  couchMenu = pkgs.writeShellApplication {
    name = "couch-menu";
    text = ''
      while true; do
        choice=$(printf 'img:${icons}/%s.png:text:%s\n' plex Plex youtube YouTube firefox Firefox retroarch RetroArch steam Steam |
          wofi --dmenu) || continue
        case ''${choice##*:} in
        Plex) firefox --kiosk https://plex.coditon.com/web ;;
        YouTube) firefox --kiosk https://www.youtube.com/feed/subscriptions ;;
        Firefox) firefox ;;
        RetroArch) sudo -n runtime-modules enable retroarch && retroarch ;;
        Steam) sudo -n runtime-modules enable steam && steam -bigpicture ;;
        esac || true
      done
    '';
  };
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
      # 1920x1080 lays out as 1280x720, readable from the couch
      output."*".scale = "1.5";
      startup = [{ command = lib.getExe couchMenu; }];
      input."type:keyboard" = {
        xkb_layout = "fi";
        xkb_numlock = "enabled";
      };
      keybindings = {
        "Mod4+b" = "exec ${BROWSER}";
        "Mod1+Return" = "exec ${TERMINAL}";
        "Mod1+q" = "kill";
        "Mod1+Tab" = "focus next";
        "Mod1+space" = "fullscreen toggle";
        # Home key: closing the app brings the menu back
        "--release Super_L" = "kill";
      };
      window.commands = [
        { criteria.app_id = ".*"; command = "fullscreen enable"; }
        { criteria.class = ".*"; command = "fullscreen enable"; }
      ];
    };
  };

  # The couch menu: large rows readable from the couch, one column, no search
  programs.wofi = {
    enable = true;
    settings = {
      allow_images = true;
      image_size = 96;
      hide_search = true;
      hide_scroll = true;
      lines = 5;
      width = "40%";
      cache_file = "/dev/null";
    };
    style = ''
      * {
        font-family: "${FONT}";
        font-size: 32px;
      }
      #window {
        background-color: #${colors.base00};
        color: #${colors.base05};
        border: 2px solid #${colors.base01};
      }
      #outer-box {
        padding: 24px;
      }
      #img {
        padding-right: 24px;
      }
      #entry {
        padding: 16px;
      }
      #entry:selected {
        background-color: #${colors.base0A};
      }
      #text:selected {
        color: #${colors.base00};
      }
    '';
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
