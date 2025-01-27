# https://github.com/fdnt7/nix-config/blob/3d9866e701e6bb897a189e428add4b68922d1e6f/home-manager/programs/yazi/yazi.nix
# https://github.com/Anomalocaridid/dotfiles/blob/4e6c64d2a80f04de451d7807b99e2c345a197296/home-modules/yazi.nix
{ pkgs
, config
, ...
}:
let
  inherit (config.home.sessionVariables) THEME;
  colors = (import ../../../colors.nix).${THEME};

  plugs = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "8ed253716c60f3279518ce34c74ca053530039d8";
    hash = "sha256-xY2yVCLLcXRyFfnmyP6h5Fw+4kwOZhEOCWVZrRwXnTA=";
  };
in
{
  home.packages = with pkgs; [
    exiftool
  ];

  programs.zathura = {
    enable = true;
    options = {
      adjust-open = "width";
      smooth-scroll = true;
      statusbar-fg = "#${colors.base05}";
      statusbar-bg = "#${colors.base00}";
    };
  };

  programs.yazi = {
    enable = true;
    enableFishIntegration = true;

    plugins = {
      chmod = "${plugs}/chmod.yazi";
      diff = "${plugs}/diff.yazi";
      full-border = "${plugs}/full-border.yazi";
      hide-preview = "${plugs}/hide-preview.yazi";
      jump-to-char = "${plugs}/jump-to-char.yazi";
      max-preview = "${plugs}/max-preview.yazi";
      smart-filter = "${plugs}/smart-filter.yazi";
      smart-enter = "${plugs}/smart-enter.yazi";
    };

    settings = {
      manager = {
        sort_by = "natural";
        show_hidden = false;
        show_symlink = true;
        sort_dir_first = true;
      };

      preview = {
        image_filter = "lanczos3";
        image_quality = 80;
        max_width = 600;
        max_height = 900;
        ueberzug_scale = 1;
        ueberzug_offset = [ 0 0 0 0 ];
      };

      opener = {
        play = [
          {
            run = "mpv \"$@\"";
            desc = "Play with mpv";
            orphan = true;
          }
        ];
        image = [
          {
            run = "imv-dir \"$@\"";
            desc = "Open with imv";
            orphan = true;
          }
        ];
        pdf = [
          {
            run = "Zathura \"$@\"";
            desc = "Open with Zathura";
            orphan = true;
          }
        ];
        folder = [
          {
            run = "nvim \"$@\"";
            desc = "Edit with NeoVim";
            block = true;
          }
        ];
        text = [
          {
            run = "nvim \"$@\"";
            desc = "Edit with NeoVim";
            block = true;
          }
        ];
        fallback = [
          {
            run = "xdg-open \"$@\"";
            desc = "XDG Open";
            orphan = true;
          }
          {
            run = "nvim \"$@\"";
            desc = "Edit with NeoVim";
            block = true;
          }
        ];
      };
    };

    keymap = {
      manager.prepend_keymap = [
        {
          on = [ "<C-s>" ];
          run = ''shell "$SHELL" --block --confirm'';
          desc = "Open shell here";
        }
        {
          on = [ "y" ];
          run = [ ''shell 'for path in "$@"; do echo "file://$path"; done | wl-copy -t text/uri-list' --confirm'' "yank" ];
        }
        # Plugins
        {
          on = [ "l" ];
          run = "plugin smart-enter";
          desc = "Enter the child directory; or open file.";
        }
        {
          on = [ "c" "m" ];
          run = "plugin chmod";
          desc = "Chmod on selected files";
        }
        {
          on = "T";
          run = "plugin max-preview";
          desc = "Maximize or restore preview";
        }
        {
          on = "Y";
          run = "plugin hide-preview";
          desc = "Hide or show preview";
        }
        {
          on = "F";
          run = "plugin smart-filter";
          desc = "Smart filter";
        }
        {
          on = "f";
          run = "plugin jump-to-char";
          desc = "Jump to char";
        }
        {
          on = "<C-d>";
          run = "plugin diff";
          desc = "Diff the selected with the hovered file";
        }
      ];
    };
  };
}
