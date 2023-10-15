# https://github.com/hmajid2301/dotfiles/tree/main/home-manager/editors/nvim
# https://github.com/jhvst/nix-config/blob/main/nixosModules/neovim/default.nix
{
  lib,
  pkgs,
  ...
}: {
  home.sessionVariables = {
    EDITOR = lib.mkDefault "nvim";
    MANPAGER = lib.mkDefault "nvim +Man!";
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
        # Easier buffer switching
        {
          mode = "n";
          key = "<leader>h";
          action = "<C-w>h";
        }
        {
          mode = "n";
          key = "<leader>j";
          action = "<C-w>j";
        }
        {
          mode = "n";
          key = "<leader>k";
          action = "<C-w>k";
        }
        {
          mode = "n";
          key = "<leader>l";
          action = "<C-w>l";
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

      barbar = {
        enable = true;
        animation = true;
        clickable = true;
        semanticLetters = true;
        sidebarFiletypes = {
          "neo-tree" = {
            event = "BufWipeout";
          };
        };
        keymaps = {
          silent = true;
          close = "<leader>q";
          goTo1 = "<leader>1";
          goTo2 = "<leader>2";
          goTo3 = "<leader>3";
          goTo4 = "<leader>4";
          goTo5 = "<leader>5";
          goTo6 = "<leader>6";
          goTo7 = "<leader>7";
          goTo8 = "<leader>8";
          goTo9 = "<leader>9";
          next = "<leader>.";
          previous = "<leader>,";
        };
      };

      neo-tree = {
        enable = true;
        addBlankLineAtTop = true;
        enableDiagnostics = true;
        enableGitStatus = true;
        closeIfLastWindow = true;
        window = {
          width = 35;
          autoExpandWidth = true;
        };
      };

      indent-blankline = {
        enable = true;
        showCurrentContext = true;
        showCurrentContextStart = true;
      };

      lsp = {
        enable = true;
        servers = {
          bashls.enable = true;
          nixd.enable = true;
        };
      };

      null-ls = {
        enable = true;
        sources = {
          code_actions.shellcheck.enable = true;

          diagnostics = {
            deadnix.enable = true;
            gitlint.enable = true;
            shellcheck.enable = true;
            #statix.enable = true;
          };

          formatting = {
            alejandra.enable = true;
            cbfmt.enable = true;
            prettier.enable = true;
            shfmt.enable = true;
            rustfmt.enable = true;
          };
        };
      };

      telescope = {
        enable = true;
        extensions.fzf-native.enable = true;
      };

      treesitter = {
        enable = true;
        indent = true;
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
