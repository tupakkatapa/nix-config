# https://github.com/fdnt7/nix-config/blob/3d9866e701e6bb897a189e428add4b68922d1e6f/home-manager/programs/yazi/yazi.nix
# https://github.com/Anomalocaridid/dotfiles/blob/4e6c64d2a80f04de451d7807b99e2c345a197296/home-modules/yazi.nix
{ pkgs
, config
, lib
, ...
}@args:
let
  inherit (config.home.sessionVariables) THEME;
  colors = (import ../../../colors.nix).${THEME};
  helpers = import ../../../helpers.nix args;

  plugs = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "3783ea0";
    hash = "sha256-otOGaTg4DQaTnpezkAVbTq509US/efN0elosUZbzxeU=";
  };

  glow_plug = pkgs.fetchFromGitHub {
    owner = "Reledia";
    repo = "glow.yazi";
    rev = "536185a4e60ac0adc11d238881e78678fdf084ff";
    hash = "sha256-NcMbYjek99XgWFlebU+8jv338Vk1hm5+oW5gwH+3ZbI=";
  };

  miller_plug = pkgs.fetchFromGitHub {
    owner = "Reledia";
    repo = "miller.yazi";
    rev = "75f00026a0425009edb6fedcfbe893f3d2ddedf4";
    hash = "sha256-u8xadj6/s16xXUAWGezYBqnygKaFMnRUsqtjMDr6DZA=";
  };

  hexyl_plug = pkgs.fetchFromGitHub {
    owner = "Reledia";
    repo = "hexyl.yazi";
    rev = "64daf93a67d75eff871befe52d9013687171ffad";
    hash = "sha256-B2L3/Q1g0NOO6XEMIMGBC/wItbNgBVpbaMMhiXOYcrI=";
  };

  exifaudio = pkgs.fetchFromGitHub {
    owner = "Sonico98";
    repo = "exifaudio.yazi";
    rev = "94329ead8b3a6d3faa2d4975930a3d0378980c7a";
    hash = "sha256-jz6fVtcLHw9lsxFWECbuxE7tEBttE08Fl4oJSTifaEc=";
  };

  ouch_plug = pkgs.fetchFromGitHub {
    owner = "ndtoan96";
    repo = "ouch.yazi";
    rev = "694d149be5f96eaa0af68d677c17d11d2017c976";
    hash = "sha256-J3vR9q4xHjJt56nlfd+c8FrmMVvLO78GiwSNcLkM4OU=";
  };

  mime_plug = pkgs.fetchFromGitHub {
    owner = "ndtoan96";
    repo = "mime.yazi";
    rev = "0ba4bb22e452c287daaf67fe87e218dc12205dba";
    hash = "sha256-K+JXBfJPPl/scLeMCq4+OiyGjYKM7bJgdZf8q8O+2zk=";
  };

  # Dynamically create open rules for archive types
  archiveOpenRules = map
    (mimeType: {
      mime = mimeType;
      use = "archive";
    })
    helpers.mimes.archive;

  # Dynamically create previewers for archive types
  archivePreviewers = map
    (mimeType: {
      mime = mimeType;
      run = "ouch";
    })
    helpers.mimes.archive;
in
{
  home.packages = with pkgs; [
    fd
    ffmpegthumbnailer
    file
    fzf
    jq
    poppler
    ripgrep
    unar
    xarchiver

    glow
    miller
    hexyl
    exiftool
    ouch
  ];

  home = {
    sessionVariables = {
      FILEMANAGER = lib.mkDefault "yazi";
    };
    # https://yazi-rs.github.io/docs/tips/#smart-enter
    file.".config/yazi/plugins/smart-enter.yazi/init.lua".text = ''
      return {
        entry = function()
          local h = cx.active.current.hovered
          ya.manager_emit(h and h.cha.is_dir and "enter" or "open", { hovered = true })
        end,
      }
    '';
  };

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

      glow = glow_plug;
      miller = miller_plug;
      hexyl = hexyl_plug;
      inherit exifaudio;
      ouch = ouch_plug;
      mime = mime_plug;
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

      tasks = {
        micro_workers = 5;
        macro_workers = 10;
      };

      open.rules = lib.concatLists [
        [
          { mime = "inode/directory"; use = "folder"; }
          { mime = "application/pdf"; use = "pdf"; }
          { mime = "audio/*"; use = "play"; }
          { mime = "image/*"; use = "image"; }
          { mime = "text/*"; use = "text"; }
          { mime = "video/*"; use = "play"; }
        ]
        archiveOpenRules
      ];

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
            run = "zathura \"$@\"";
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
          {
            run = "imv \"$@\"";
            desc = "Open with imv";
            orphan = true;
          }
          {
            run = "mpv \"$@\"";
            desc = "Play with mpv";
            orphan = true;
          }
        ];
        text = [
          {
            run = "nvim \"$@\"";
            desc = "Edit with NeoVim";
            block = true;
          }
        ];
        archive = [
          {
            run = "xarchiver \"$1\"";
            desc = "Open with Xarchiver";
          }
          {
            run = "unar \"$1\"";
            desc = "Extract here";
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

      plugin = {
        prepend_previewers = lib.concatLists [
          [
            {
              name = "*.md";
              run = "glow";
            }
            {
              mime = "text/csv";
              run = "miller";
            }
            {
              mime = "audio/*";
              run = "exifaudio";
            }
          ]
          archivePreviewers
        ];
        append_previewers = [
          {
            name = "*";
            run = "hexyl";
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
          run = "plugin --sync smart-enter";
          desc = "Enter the child directory; or open file.";
        }
        {
          on = [ "c" "m" ];
          run = "plugin chmod";
          desc = "Chmod on selected files";
        }
        {
          on = "T";
          run = "plugin --sync max-preview";
          desc = "Maximize or restore preview";
        }
        {
          on = "Y";
          run = "plugin --sync hide-preview";
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

    theme = with colors;
      {
        manager = {
          cwd = { fg = "#${base0D}"; };

          hovered = { fg = "#${base00}"; bg = "#${base0D}"; };
          preview_hovered = { underline = true; };

          find_keyword = { fg = "#${base0B}"; italic = true; };
          find_position = { fg = "#${base09}"; bg = "reset"; italic = true; };

          marker_selected = { fg = "#${base0B}"; bg = "#${base0B}"; };
          marker_copied = { fg = "#${base0B}"; bg = "#${base0B}"; };
          marker_cut = { fg = "#${base08}"; bg = "#${base08}"; };

          tab_active = { fg = "#${base00}"; bg = "#${base02}"; };
          tab_inactive = { fg = "#${base04}"; bg = "#${base01}"; };
          tab_width = 1;

          border_symbol = "│";
          border_style = { fg = "#${base03}"; };
        };

        status = {
          separator_open = "";
          separator_close = "";
          separator_style = { fg = "#${base01}"; bg = "#${base01}"; };

          mode_normal = { fg = "#${base00}"; bg = "#${base04}"; bold = true; };
          mode_select = { fg = "#${base00}"; bg = "#${base0B}"; bold = true; };
          mode_unset = { fg = "#${base00}"; bg = "#${base0E}"; bold = true; };

          progress_label = { fg = "#${base06}"; bold = true; };
          progress_normal = { fg = "#${base02}"; bg = "#${base01}"; };
          progress_error = { fg = "#${base08}"; bg = "#${base01}"; };

          permissions_t = { fg = "#${base02}"; };
          permissions_r = { fg = "#${base0B}"; };
          permissions_w = { fg = "#${base08}"; };
          permissions_x = { fg = "#${base0B}"; };
          permissions_s = { fg = "#${base03}"; };
        };

        input = {
          border = { fg = "#${base04}"; };
          title = { };
          value = { };
          selected = { reversed = true; };
        };

        select = {
          border = { fg = "#${base02}"; };
          active = { fg = "#${base09}"; };
          inactive = { };
        };

        tasks = {
          border = { fg = "#${base02}"; };
          title = { };
          hovered = { underline = true; };
        };

        which = {
          mask = { bg = "#${base01}"; };
          cand = { fg = "#${base0D}"; };
          rest = { fg = "#${base03}"; };
          desc = { fg = "#${base09}"; };
          separator = "  ";
          separator_style = { fg = "#${base02}"; };
        };

        help = {
          on = { fg = "#${base09}"; };
          exec = { fg = "#${base0D}"; };
          desc = { fg = "#${base03}"; };
          hovered = { bg = "#${base02}"; bold = true; };
          footer = { fg = "#${base01}"; bg = "#${base04}"; };
        };

        filetype = {
          rules = [
            { mime = "image/*"; fg = "#${base0D}"; }
            { mime = "video/*"; fg = "#${base0B}"; }
            { mime = "audio/*"; fg = "#${base0B}"; }
            { mime = "application/zip"; fg = "#${base09}"; }
            { mime = "application/gzip"; fg = "#${base09}"; }
            { mime = "application/x-tar"; fg = "#${base09}"; }
            { mime = "application/x-bzip"; fg = "#${base09}"; }
            { mime = "application/x-bzip2"; fg = "#${base09}"; }
            { mime = "application/x-7z-compressed"; fg = "#${base09}"; }
            { mime = "application/x-rar"; fg = "#${base09}"; }
            { name = "*"; fg = "#${base04}"; }
            { name = "*/"; fg = "#${base0D}"; }
          ];
        };
      };
  };
}
