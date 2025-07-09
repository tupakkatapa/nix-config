# https://github.com/fdnt7/nix-config/blob/3d9866e701e6bb897a189e428add4b68922d1e6f/home-manager/programs/yazi/yazi.nix
# https://github.com/Anomalocaridid/dotfiles/blob/4e6c64d2a80f04de451d7807b99e2c345a197296/home-modules/yazi.nix
{ pkgs
, ...
}:
let
  plugs = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "3d1efb706924112daed986a4eef634e408bad65e";
    hash = "sha256-GgEg1A5sxaH7hR1CUOO9WV21kH8B2YUGAtOapcWLP7Y=";
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
        open = [
          {
            run = ''xdg-open "$@"'';
            desc = "Open";
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
