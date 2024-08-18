# https://github.com/fdnt7/nix-config/blob/3d9866e701e6bb897a189e428add4b68922d1e6f/home-manager/programs/yazi/yazi.nix
# https://github.com/Anomalocaridid/dotfiles/blob/4e6c64d2a80f04de451d7807b99e2c345a197296/home-modules/yazi.nix
{ pkgs
, lib
, ...
}@args:
let
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
  #
  gruvbox_theme = pkgs.fetchFromGitHub {
    owner = "poperigby";
    repo = "gruvbox-dark-yazi";
    rev = "3337133a913d48765094eed937af728bedc65beb";
    hash = "sha256-TRRyuTg4JBE+u987C+42C36cXEV6rb8+pw7qTA56jhM=";
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
    zathura
    xarchiver

    glow
    miller
    hexyl
    exiftool
    ouch

    # for alacritty
    # ueberzugpp
  ];

  home.sessionVariables = {
    FILEMANAGER = lib.mkDefault "yazi";
  };

  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    theme = fromTOML (builtins.readFile "${gruvbox_theme}/theme.toml");

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

  };
}
