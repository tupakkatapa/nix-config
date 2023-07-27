{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;
  inherit config;
  hasPackage = pname: lib.any (p: p ? pname && p.pname == pname) config.home.packages;
  hasNeovim = config.programs.neovim.enable;
  hasExa = hasPackage "exa";
in {
  programs.fish = {
    enable = true;
    shellAbbrs = rec {
      q = "exit";
      c = "clear";
      ka = "killall";

      # Powerstate
      sdn = "shutdown -h now";
      rbt = "reboot";
      sus = "systemctl suspend";
      bios = "systemctl reboot --firmware-setup";

      # Changing 'ls' to 'exa'
      ls = mkIf hasExa "exa -al --color=always --group-directories-first";
      tree = mkIf hasExa "exa -T";

      # Rsync
      rcp = "rsync -PaL";
      rmv = "rsync -PaL --remove-source-files";

      # Adding flags
      df = "df -h";
      free = "free -h";
      grep = "grep --color=auto";
      jctl = "journalctl -p 3 -xb";

      # Confirm before overwriting something
      cp = "cp -i";
      mv = "mv -i";
      rm = "rm -i";

      # Misc
      vim = mkIf hasNeovim "nvim";
      rebuidl = "sudo nixos-rebuild switch --flake path:$HOME/Workspace/nix-config#$(hostname) --show-trace";
    };
    functions = {
      fish_greeting = "";
    };
    interactiveShellInit =
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
    #loginShellInit = ''
    #  set -x PATH '${lib.concatStringsSep ":" [
    #    "/home/kari/.nix-profile/bin"
    #    "/run/wrappers/bin"
    #    "/etc/profiles/per-user/kari/bin"
    #    "/run/current-system/sw/bin"
    #    "/nix/var/nix/profiles/default/bin"
    #    "/opt/homebrew/bin"
    #    "/usr/bin"
    #    "/sbin"
    #    "/bin"
    #  ]}'
    #'';
  };
}
