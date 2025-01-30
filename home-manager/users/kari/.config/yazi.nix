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
      jump-to-char = "${plugs}/jump-to-char.yazi";
      smart-enter = "${plugs}/smart-enter.yazi";
    };

    settings = {
      manager = {
        sort_by = "natural";
        show_hidden = false;
        show_symlink = true;
        sort_dir_first = true;
      };
      opener = {
        image = [
          {
            run = "imv-dir \"$@\"";
            desc = "Open with imv";
            orphan = true;
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
          on = "<C-h>";
          run = "toggle hidden";
          desc = "Toggle hidden files";
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
