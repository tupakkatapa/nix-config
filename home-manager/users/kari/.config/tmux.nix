{ config
, customLib
, ...
}:
let
  inherit (config.home.sessionVariables) THEME;
  colors = customLib.colors.${THEME};
in
{
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    prefix = "C-Space";
    extraConfig = ''
      set -s escape-time 0

      set -g mouse on
      bind-key v split-window -h -c "#{pane_current_path}"
      bind-key g split-window -v -c "#{pane_current_path}"

      # prefix+r renames session (prefix+$ also works); prefix+b sets a free-form label
      bind-key r command-prompt -p "session:" "rename-session '%%'"
      set -g @label ""
      bind-key b command-prompt -p "label:" "set @label '%%'"

      set -g status on
      # Faded: everything in base03 (muted grey from the active theme); C-Space lights up only on prefix.
      # left: session · label (if set) · fish-style cwd (pane shell dir, not Claude's)
      set -g status-left '#[fg=#${colors.base04},bold]#{session_name}#[default]#{?@label,#[fg=#${colors.base04}] #{@label}#[default],}  #[fg=#${colors.base03}]#(echo "#{pane_current_path}" | sed -E "s|^$HOME|~|;:a;s@/([^/])[^/]+/@/\1/@;ta")#[default] '
      # right: prefix reminder, inverts while pending
      set -g status-right '#{?client_prefix,#[reverse] C-Space #[noreverse],#[fg=#${colors.base03}]C-Space }'
      # window list only when there's more than one window (panes, not windows, is the norm)
      set -g window-status-format "#{?#{==:#{session_windows},1},,#I:#W#F}"
      set -g window-status-current-format "#{?#{==:#{session_windows},1},,#I:#W#F}"
      set -g status-style "bg=default,fg=#${colors.base03}"
      set -g message-style "bg=#${colors.base0B},fg=#${colors.base00},bold"
      set -g status-left-length 80
      set -g status-right-length 20
    '';
  };
}
