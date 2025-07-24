# https://github.com/fdnt7/nix-config/blob/3d9866e701e6bb897a189e428add4b68922d1e6f/home-manager/programs/yazi/yazi.nix
# https://github.com/Anomalocaridid/dotfiles/blob/4e6c64d2a80f04de451d7807b99e2c345a197296/home-modules/yazi.nix
{ pkgs
, ...
}:
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

    plugins = with pkgs.yaziPlugins; {
      inherit chmod diff full-border jump-to-char smart-enter;
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
