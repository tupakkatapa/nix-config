_: {
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    prefix = "C-Space";
    extraConfig = ''
      set -s escape-time 0

      set -g mouse on
      bind-key v split-window -h -c "#{pane_current_path}"
      bind-key g split-window -v -c "#{pane_current_path}"

      # Minimal status bar
      set -g status on
      set -g status-left ""
      set -g status-right "[TMUX]"
      set -g status-style "bg=default,fg=yellow"
      set -g status-right-length 20
    '';
  };
}
