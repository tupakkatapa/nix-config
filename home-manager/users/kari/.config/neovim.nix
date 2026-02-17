# https://github.com/jhvst/nix-config/blob/main/nixosModules/neovim/default.nix
{ pkgs
, ...
}:
{
  programs.nixvim = {
    enable = true;

    # Telescope deps
    extraPackages = with pkgs; [ fd ripgrep ];

    clipboard = {
      register = "unnamedplus";
      providers.wl-copy.enable = true;
    };

    globals = { mapleader = " "; };

    opts = {
      cursorline = true;
      swapfile = false;
      number = true;
      relativenumber = true;
      laststatus = 0;
      ruler = false;
      scrolloff = 10;
    };

    # NOTE: Default mode is normal-visual-op
    keymaps = [
      # Do not yank when pasting or deleting
      {
        key = "p";
        action = "P";
      }
      {
        key = "d";
        action = "\"_d";
      }
      {
        key = "dd";
        action = "\"_dd";
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
      # BufferLine navigation
      {
        key = "<Tab>";
        action = ":BufferLineCycleNext<CR>";
      }
      {
        key = "<S-Tab>";
        action = ":BufferLineCyclePrev<CR>";
      }
      {
        key = "Q";
        action = ":Bdelete<CR>";
      }
      # Plugins
      {
        mode = "n";
        key = "<leader>p";
        action.__raw = ''
          function()
            local ft = vim.bo.filetype
            if ft == "markdown" then
              vim.cmd("Markview toggle")
            elseif ft == "csv" then
              vim.cmd("CsvViewToggle")
            end
          end
        '';
      }
      {
        mode = "n";
        key = "<leader>g";
        action = "<cmd>LazyGitCurrentFile <CR>";
      }
      {
        mode = "n";
        key = "<leader>e";
        action = ":Neotree toggle<CR>";
      }
    ];

    plugins = {
      nix.enable = true;
      comment.enable = true;
      hardtime = {
        enable = true;
        settings = {
          max_count = 0;
          disabled_filetypes.__raw = ''{ ["neo%-tree.*"] = false }'';
        };
      };
      bufdelete.enable = true;
      markview = {
        enable = true;
        settings.preview.enable = false;
      };
      csvview = {
        enable = true;
        settings.view.display_mode = "border";
      };

      # Git
      lazygit = {
        enable = true;
        settings = {
          floating_window_winblend = 0;
          floating_window_scaling_factor = 0.9;
        };
      };
      gitsigns.enable = true;

      # Fuzzy finder
      telescope = {
        enable = true;
        extensions.fzf-native.enable = true;
        keymaps = {
          "<leader>ff" = "find_files";
          "<leader>fg" = "live_grep";
        };
        settings.pickers.find_files.hidden = true;
      };

      # UI
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
        settings = {
          add_blank_line_at_top = true;
          enable_diagnostics = true;
          enable_git_status = true;
          close_if_last_window = true;
          event_handlers = [
            {
              event = "neo_tree_buffer_enter";
              handler.__raw = ''
                function()
                  vim.opt_local.number = true
                  vim.opt_local.relativenumber = true
                end
              '';
            }
          ];
          window = {
            auto_expand_width = false;
            mappings = {
              "l".command = "open";
              "h".command = "close_node";
              "Y" = {
                __raw = ''
                  function(state)
                    local node = state.tree:get_node()
                    local filepath = node:get_id()
                    local filename = node.name

                    local i = vim.fn.inputlist({
                      'Copy to clipboard:',
                      '1. Absolute: ' .. filepath,
                      '2. Filename: ' .. filename,
                    })

                    local result = ({ filepath, filename })[i]
                    if result then
                      vim.fn.setreg('+', result)
                      vim.notify('Copied: ' .. result)
                    end
                  end
                '';
              };
            };
          };
          filesystem = {
            find_by_full_path_words = true;
            use_libuv_file_watcher = true;
            filtered_items = {
              visible = false;
              hide_gitignored = true;
              hide_dotfiles = false;
              never_show_by_pattern = [ ".git" ".direnv" ".devenv" ];
            };
            follow_current_file = {
              enabled = true;
            };
          };
        };
      };

      lualine = {
        enable = true;
        settings = {
          sections = {
            lualine_a = [ "" ];
            lualine_b = [ "" ];
            lualine_c = [ "" ];
            lualine_x = [ "location" ];
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

      # LSP
      lsp = {
        enable = true;
        servers = {
          bashls.enable = true;
          nixd.enable = true;
        };
      };
      lsp-format.enable = true;
      lsp-lines.enable = true;

      # Completion
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
      luasnip.enable = true;

      # Highlighting
      rainbow-delimiters.enable = true;
      todo-comments.enable = true;
      web-devicons.enable = true;
      indent-blankline = {
        enable = true;
        settings.scope = {
          enabled = true;
          show_start = true;
        };
      };
      treesitter = {
        enable = true;
        settings.indent.enable = true;
        folding = false;
        nixvimInjections = true;
        grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          bash
          c # c is implicit dependency, not specifying it will lead to healtcheck errors
          csv
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
          markdown # dep of markview
          markdown_inline # dep of markview
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
