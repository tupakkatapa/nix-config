# https://github.com/jhvst/nix-config/blob/main/nixosModules/neovim/default.nix
{
  lib,
  pkgs,
  ...
}: {
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

    options = {
      laststatus = 0;
      ruler = false;
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
        # Git status
        {
          mode = "n";
          key = "<leader>g";
          action = "<cmd>Neotree float git_status <CR>";
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
      rainbow-delimiters.enable = true;
      fugitive.enable = true;

      # Tabline plugin
      bufferline = {
        enable = true;
        offsets = [
          {
            filetype = "neo-tree";
            text = " Neovim ";
            text_align = "center";
          }
        ];
      };

      # File browser
      neo-tree = {
        enable = true;
        addBlankLineAtTop = true;
        enableDiagnostics = true;
        enableGitStatus = true;
        closeIfLastWindow = true;
        window = {
          width = 35;
          #autoExpandWidth = true;
          mappings = {
            "l".command = "open";
            "h".command = "close_node";
          };
        };
        filesystem.filteredItems.visible = true;
      };

      # Status line
      lualine = {
        enable = true;
        theme = "gruvbox-material";
        iconsEnabled = false;
        disabledFiletypes.statusline = ["neo-tree"];
        sections = {
          lualine_a = [""];
          lualine_b = [""];
          lualine_c = [
            "location"
            {
              name = "filename";
              extraConfig.path = 1;
            }
            "filetype"
          ];
          lualine_x = ["diagonostics"];
          lualine_y = ["branch"];
          lualine_z = ["mode"];
        };
        componentSeparators = {
          left = "";
          right = "";
        };
        sectionSeparators = {
          left = "";
          right = "";
        };
      };

      # Indentation guides
      indent-blankline = {
        enable = true;
        showCurrentContext = true;
        showCurrentContextStart = true;
      };

      # Language server protocols
      lsp = {
        enable = true;
        servers = {
          bashls.enable = true;
          nixd.enable = true;
        };
      };
      lsp-format.enable = true;

      # Highlighting
      treesitter = {
        enable = true;
        indent = true;
        nixvimInjections = true;
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
          markdown # dep of noice
          markdown_inline # dep of noice
          nix
          query # implicit
          regex
          toml
          vim
          vimdoc
          xml
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
        insert_final_newline = true;
        max_line_width = 78;
        indent_style = "space";
        indent_size = 2;
      };
    };
  };
}
