# https://github.com/jhvst/nix-config/blob/main/nixosModules/neovim/default.nix
{ pkgs
, config
, lib
, ...
}:
let
  inherit (config.home.sessionVariables) THEME;
  colors = (import ../../../colors.nix).${THEME};
in
{
  home.sessionVariables = {
    EDITOR = lib.mkDefault "nvim";
    MANPAGER = lib.mkDefault "nvim +Man!";
  };

  programs.nixvim = {
    enable = true;

    clipboard = {
      register = "unnamedplus";
      providers.wl-copy.enable = true;
    };

    globals = { mapleader = " "; };

    opts = {
      cursorline = true;
      swapfile = false;
      relativenumber = true;
      laststatus = 0;
      ruler = false;
    };

    colorschemes.base16 = {
      enable = true;
      colorscheme = lib.mapAttrs (_name: color: "#${color}") colors;
    };

    # NOTE: Default mode is normal-visual-op
    keymaps = [
      # Map :W to :w
      {
        mode = "c";
        key = ":W";
        action = "<cmd>w<cr>";
      }
      # Do not yank when pasting or deleting
      {
        key = "p";
        action = "P";
      }
      {
        key = "x";
        action = ''"_x'';
      }
      # Ctrl+s
      {
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
    ];

    plugins = {
      nix.enable = true;
      gitsigns.enable = true;
      todo-comments.enable = true;
      comment.enable = true;
      rainbow-delimiters.enable = true;
      fugitive.enable = true;
      # hardtime.enable = true;

      # Tabline plugin
      bufferline = {
        enable = true;
        settings.options = {
          offsets = [
            {
              filetype = "neo-tree";
              text = " Neovim ";
              text_align = "center";
            }
          ];
        };
      };

      # File browser
      neo-tree = {
        enable = true;
        addBlankLineAtTop = true;
        enableDiagnostics = true;
        enableGitStatus = true;
        closeIfLastWindow = true;
        eventHandlers = {
          neo_tree_buffer_enter = ''
            function()
              vim.opt_local.number = true;
              vim.opt_local.relativenumber = true;
            end
          '';
        };
        window = {
          autoExpandWidth = true;
          mappings = {
            "l".command = "open";
            "h".command = "close_node";
          };
        };
        filesystem = {
          useLibuvFileWatcher = true;
          filteredItems = {
            visible = false;
            alwaysShow = [
              ".gitignore"
              ".envrc"
              ".config"
              ".wine"
              ".sops.yaml"
            ];
          };
          followCurrentFile.enabled = true;
        };
      };

      # Status line
      lualine = {
        enable = true;
        settings = {

          sections = {
            lualine_a = [ "" ];
            lualine_b = [ "" ];
            # lualine_c = [
            #  "location"
            #  {
            #    name = "filename";
            #    extraConfig.path = 1;
            #  }
            #  "filetype"
            # ];
            lualine_x = [ "diagonostics" ];
            lualine_y = [ "branch" ];
            lualine_z = [ "mode" ];
          };
          options = {

            theme = "gruvbox-material";
            icons_enabled = false;
            disabled_filetypes.statusline = [ "neo-tree" ];
            component_separators = {
              left = "";
              right = "";
            };
            section_separators = {
              left = "";
              right = "";
            };
          };
        };
      };

      # Indentation guides
      indent-blankline = {
        enable = true;
        settings.scope = {
          enabled = true;
          show_start = true;
        };
      };

      # Language server protocols
      lsp = {
        enable = true;
        servers = {
          bashls.enable = true;
          nixd.enable = true;
          rust-analyzer = {
            enable = true;
            installRustc = true;
            installCargo = true;
          };
        };
      };
      lsp-format.enable = true;

      # A completion
      cmp = {
        enable = true;
        settings = {
          mapping = {
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
          };
          snippet.expand = "luasnip";
          sources = [
            { name = "buffer"; }
            { name = "luasnip"; }
            { name = "nvim_lsp"; }
            { name = "path"; }
            { name = "tmux"; }
          ];
        };
      };

      # Highlighting
      treesitter = {
        enable = true;
        settings.indent.enable = true;
        folding = false;
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
