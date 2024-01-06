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
      win = "sudo grub-reboot 2 && reboot";

      # Changing 'ls' to 'eza'
      ls = mkIf hasEza "eza -agl --color=always --group-directories-first";
      lsd = "sudo du -Lhc --max-depth=0 *";
      tree = mkIf hasEza "eza -T";

      # Rsync
      rcp = "rsync -IPaL";
      rmv = "rsync -IPaL --remove-source-files";

      # Adding flags
      df = "df -h";
      du = "du -h";
      free = "free -h";
      grep = "grep --color=auto";
      jctl = "journalctl -p 3 -xb";

      # Nix
      ngd = "nix fmt && git add . && direnv reload";
      nfc = "nix flake check --impure";
      buidl = "rm -f ~/.config/mimeapps.list && sudo nixos-rebuild switch --flake path:$HOME/Workspace/nix-config#$(hostname) --show-trace";
      gc = "nix-collect-garbage -d";

      # YouTube-DL
      yt = "yt-dlp --embed-metadata --sponsorblock-remove all -i --format mp4";
      yta = yt + " -x --embed-thumbnail --audio-format mp3 -f 'ba'";
      yta-channel = yta + " -o '%(channel)s/%(title)s.%(ext)s'";
      yta-playlist = yta + " -o '%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s'";
      yta-chapters = yta + " -o '%(title)s.%(ext)s' -o 'chapter:%(title)s/%(section_number)s - %(section_title)s.%(ext)s' --split-chapters --exec 'rm %(title)s.%(ext)s'";

      # Misc
      vim = mkIf hasNeovim "nvim";
    };
    functions = {
      fish_greeting = "";
    };
    interactiveShellInit =
      # Print banner
      ''
        if test -z "$VIMRUNTIME"
            if type print-quote &>/dev/null
                print-quote -m 152 -p "  " -s "\n"
            end
        end
      ''
      +
      # Use vim bindings and cursors
      ''
        fish_vi_key_bindings
        set fish_cursor_default     block      blink
        set fish_cursor_insert      line       blink
        set fish_cursor_replace_one underscore blink
        set fish_cursor_visual      block
      '';
    loginShellInit = ''
      if command -q Hyprland
        exec Hyprland &> /dev/null
      end
    '';
  };
}
