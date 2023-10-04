{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;
  hasPackage = pname: lib.any (p: p ? pname && p.pname == pname) config.home.packages;
  hasNeovim = config.programs.neovim.enable || config.programs.nixvim.enable;
  hasEza = hasPackage "eza";
in {
  programs.fish = {
    enable = true;
    shellAbbrs = rec {
      q = "exit";
      c = "clear";
      ka = "pkill";

      # Powerstate
      bios = "systemctl reboot --firmware-setup";
      lock = "swaylock -S --daemonize";
      logout = "hyprctl dispatch exit";
      rbt = "reboot";
      sdn = "shutdown -h now";
      sus = "systemctl suspend";
      win = "systemctl reboot --boot-loader-entry=auto-windows";

      # Changing 'ls' to 'eza'
      ls = mkIf hasEza "eza -al --color=always --group-directories-first";
      tree = mkIf hasEza "eza -T";

      # Rsync
      rcp = "rsync -IPaL";
      rmv = "rsync -IPaL --remove-source-files";

      # Adding flags
      df = "df -h";
      free = "free -h";
      grep = "grep --color=auto";
      jctl = "journalctl -p 3 -xb";

      # Confirm before overwriting something
      cp = "cp -i";
      mv = "mv -i";
      rm = "rm -i";

      # Nix
      nd = "nix develop --impure .#";
      nb = "nix build .#";
      nr = "nix run .#";
      nfc = "nix flake check --impure";
      buidl = "sudo nixos-rebuild switch --flake path:$HOME/Workspace/nix-config#$(hostname) --show-trace";
      buidl-darwin = "nix build path:$HOME/Workspace/nix-config#darwinConfigurations.$(hostname).system --show-trace && ./result/sw/bin/darwin-rebuild switch --flake path:$HOME/Workspace/nix-config#$(hostname) --show-trace";

      # YouTube-DL
      yt = "yt-dlp --embed-metadata --sponsorblock-remove all -i --format mp4";
      yta = yt + " -x --embed-thumbnail --audio-format mp3 -f 'ba'";
      yta-channel = yta + " -o '%(channel)s/%(title)s.%(ext)s'";
      yta-playlist = yta + " -o '%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s'";
      yta-chapters =
        yta
        + ''
          -o '%(title)s.%(ext)s' -o 'chapter:%(title)s/%(section_number)s - %(section_title)s.%(ext)s' --split-chapters --exec 'rm "%(title)s.%(ext)s"'
        '';

      # Misc
      vim = mkIf hasNeovim "nvim";
      code = "codium";
    };
    functions = {
      fish_greeting = "";
    };
    interactiveShellInit =
      # Print banner
      ''
        if test -e ~/.local/bin/print-quote
          ~/.local/bin/print-quote
        end
      ''
      +
      # Set pager
      ''
        set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"
      ''
      +
      # Use vim bindings and cursors
      ''
        fish_vi_key_bindings
        set fish_cursor_default     block      blink
        set fish_cursor_insert      line       blink
        set fish_cursor_replace_one underscore blink
        set fish_cursor_visual      block
      ''
      +
      # Use terminal colors
      ''
        set -U fish_color_autosuggestion      brblack
        set -U fish_color_cancel              -r
        set -U fish_color_command             brgreen
        set -U fish_color_comment             brmagenta
        set -U fish_color_cwd                 green
        set -U fish_color_cwd_root            red
        set -U fish_color_end                 brmagenta
        set -U fish_color_error               brred
        set -U fish_color_escape              brcyan
        set -U fish_color_history_current     --bold
        set -U fish_color_host                normal
        set -U fish_color_match               --background=brblue
        set -U fish_color_normal              normal
        set -U fish_color_operator            cyan
        set -U fish_color_param               brblue
        set -U fish_color_quote               yellow
        set -U fish_color_redirection         bryellow
        set -U fish_color_search_match        'bryellow' '--background=brblack'
        set -U fish_color_selection           'white' '--bold' '--background=brblack'
        set -U fish_color_status              red
        set -U fish_color_user                brgreen
        set -U fish_color_valid_path          --underline
        set -U fish_pager_color_completion    normal
        set -U fish_pager_color_description   yellow
        set -U fish_pager_color_prefix        'white' '--bold' '--underline'
        set -U fish_pager_color_progress      'brwhite' '--background=cyan'
      '';
    loginShellInit = ''
      if test (tty) = "/dev/tty1"
        exec Hyprland &> /dev/null
      end
    '';
  };
}
