# https://github.com/hmajid2301/dotfiles/tree/main/home-manager/editors/nvim
# https://github.com/jhvst/nix-config/blob/main/nixosModules/neovim/default.nix
{
  lib,
  pkgs,
  ...
}: {
  home.sessionVariables = {
    EDITOR = lib.mkDefault "nvim";
  };

  programs.nixvim = let
    disableKeys = keysList:
      map (keyName: {
        key = "<${keyName}>";
        action = "<Nop>";
      })
      keysList;
  in {
    enable = true;

    clipboard = {
      register = "unnamedplus";
      providers.wl-copy.enable = true;
    };

    globals = {
      mapleader = " ";
    };

    colorschemes.gruvbox = {
      enable = true;
      contrastDark = "medium";
    };

    keymaps =
      [
        {
          # Default mode is normal-visual-op
          key = "<C-s>";
          action = "<cmd>w<cr><esc>";
        }
        {
          mode = "n";
          key = "<leader>ff";
          action = "<cmd> Telescope find_files follow=true no_ignore=true hidden=true <CR>";
        }
      ]
      ++ (disableKeys ["Up" "Down" "Left" "Right"]);

    options = {
      cursorline = true;
      swapfile = false;
      relativenumber = true;
    };

    plugins = {
      nix.enable = true;
      gitsigns.enable = true;
      todo-comments.enable = true;
      comment-nvim.enable = true;

      indent-blankline = {
        enable = true;
        #showCurrentContext = true;
        #showCurrentContextStart = true;
      };

      lsp = {
        enable = true;
        servers = {
          bashls.enable = true;
          nixd.enable = true;
          yamlls.enable = true;
        };
      };

      telescope = {
        enable = true;
        extensions.fzf-native.enable = true;
      };

      treesitter = {
        enable = true;
        nixvimInjections = true;
        indent = true;
        grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          bash
          c # c is implicit dependency, not specifying it will lead to healtcheck errors
          diff
          fish
          git_config
          git_rebase
          gitattributes
          gitcommit
          gitignore
          json
          lua
          luadoc
          make
          markdown
          nix
          query # implicit
          regex
          toml
          vim
          vimdoc
          yaml
        ];
      };
    };
  };

  editorconfig = {
    enable = true;
    settings = {
      "*" = {
        charset = "utf-8";
        end_of_line = "lf";
        trim_trailing_whitespace = true;
        insert_final_newline = false;
        max_line_width = 78;
        indent_style = "space";
        indent_size = 2;
      };
    };
  };
}
