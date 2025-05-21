{ lib
, config
, hostName
, ...
}:
let
  inherit (lib) mkIf;
  hasPackage = pname:
    lib.any (p: p ? pname && p.pname == pname) config.home.packages;
  hasNeovim = config.programs.neovim.enable || config.programs.nixvim.enable;
  hasYazi = config.programs.yazi.enable;
  hasEza = hasPackage "eza";
  hasTmux = hostName == "vladof";
in
{
  programs.tmux = {
    enable = hasTmux;
    keyMode = "vi";
    prefix = "C-Space";
    extraConfig = ''
      set -s escape-time 0
      set -g status off
      set -g mouse on
      bind-key v split-window -h -c "#{pane_current_path}"
      bind-key g split-window -v -c "#{pane_current_path}"
    '';
  };
  programs.fish = {
    enable = true;
    shellAbbrs = rec {
      q = "exit";
      c = "clear";
      ka = "pkill";

      # Powerstate
      bios = "systemctl reboot --firmware-setup";
      lock = "swaylock --daemonize";
      logout = "hyprctl dispatch exit";
      rbt = "systemctl reboot";
      reboot = "systemctl reboot";
      sdn = "systemctl poweroff";
      sus = "systemctl suspend";

      # Changing 'ls' to 'eza'
      ls = mkIf hasEza "eza -agl --color=always --group-directories-first";
      tree = mkIf hasEza "eza --git-ignore -T";

      # Changing 'fm' to 'yazi'
      fm = mkIf hasYazi "yazi";

      # Rsync
      rcp = "rsync --exclude='/.git' --filter='dir-merge,-n /.gitignore' -PaL";
      rmv = rcp + " --remove-source-files";

      # Adding flags
      df = "df -h";
      du = "du -h";
      mv = "mv -i";
      cp = "cp -ia";
      free = "free -h";
      grep = "grep --color=auto";

      # Utils
      lsd = "du -Lhc --max-depth=0 ./* | sort -h";
      rpg = "shuf -i 1024-65535 -n 1";
      wlc = "wl-copy --type text/plain";
      jctl = "journalctl -p 3 -xb";

      # Nix
      nfc = "nix flake check --impure --accept-flake-config";
      buidl = "sudo nixos-rebuild test --flake path:$HOME/nix-config#$(hostname) --accept-flake-config";
      gc = "nix-collect-garbage -d";
      ns = "nix-shell -p";

      # YouTube-DL
      yt = ", yt-dlp --embed-metadata --sponsorblock-remove all -i --format mp4";
      yt-pl-urls = yt + "--flat-playlist --print '%(url)s' --no-warnings";
      yta = yt + " -x --embed-thumbnail --audio-format mp3 -f 'ba'";
      yta-ch = yta + " -o '%(channel)s/%(title)s.%(ext)s'";
      yta-pl = yta + " -o '%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s'";
      yta-cp = yta + " -o '%(title)s.%(ext)s' -o 'chapter:%(title)s/%(section_number)s - %(section_title)s.%(ext)s' --split-chapters --exec 'rm %(title)s.%(ext)s'";

      # Misc
      vim = mkIf hasNeovim "nvim";
      amimullvad = "curl https://am.i.mullvad.net/connected";
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

        ${lib.optionalString hasTmux ''
        # Autostart tmux when not in an SSH session
        if not set -q SSH_CONNECTION; and not set -q TMUX
          exec tmux
        end
        ''}

        # Function to handle missing commands with comma
        # function fish_command_not_found --on-event fish_command_not_found
        #   , $argv[1..-1]
        # end
      '';
    loginShellInit = ''
      if test (tty) = "/dev/tty1"
        if command -q Hyprland
          exec Hyprland &> /dev/null
        end
      end
    '';
  };
}
