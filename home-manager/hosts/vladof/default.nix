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
    for icon in firefox retroarch steam; do
      rsvg-convert -w 192 -h 192 ${pkgs.papirus-icon-theme}/share/icons/Papirus/64x64/apps/$icon.svg -o $out/$icon.png
    done
  '';

  # Shows the module build in a terminal; on failure it stays open until Enter
  enable = module: ''${TERMINAL} sh -c 'sudo -n runtime-modules enable ${module} || { read -r -p "Failed, press Enter"; exit 1; }' '';

  # Couch home screen: one app at a time, back to the menu when it closes
  couchMenu = pkgs.writeShellApplication {
    name = "couch-menu";
    text = ''
      while true; do
        choice=$(printf 'img:${icons}/%s.png:text:%s\n' firefox Firefox retroarch RetroArch steam Steam |
          wofi --dmenu) || continue
        case ''${choice##*:} in
        Firefox) firefox https://plex.coditon.com/web https://www.youtube.com/feed/subscriptions ;;
        RetroArch) ${enable "retroarch"} && retroarch ;;
        Steam) ${enable "steam"} && steam -bigpicture ;;
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
      # 1920x1080 lays out as 1371x771, readable from the couch
      output."*".scale = "1.4";
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

  # The couch menu: one compact column, no search
  programs.wofi = {
    enable = true;
    settings = {
      allow_images = true;
      image_size = 48;
      hide_search = true;
      hide_scroll = true;
      lines = 3;
      width = "20%";
      cache_file = "/dev/null";
    };
    style = ''
      * {
        font-family: "${FONT}";
        font-size: 20px;
      }
      #window {
        background-color: #${colors.base00};
        color: #${colors.base05};
        border: 1px solid #${colors.base02};
        border-radius: 12px;
      }
      #outer-box {
        padding: 12px;
      }
      #img {
        padding-right: 16px;
      }
      #entry {
        padding: 8px 12px;
        border-radius: 8px;
      }
      #entry:selected {
        background-color: #${colors.base02};
      }
      #text:selected {
        color: #${colors.base0A};
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
