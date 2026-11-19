{
  programs.herdr = {
    enable = true;
    settings = {
      onboarding = false;
      theme.name = "gruvbox";
      # Nix pins the version; `herdr update` cannot replace a store binary
      update.version_check = false;
      # Tabs: h/l or Ctrl+Tab cycle, 1-9 pick. Panes: the arrows, and j/k for down/up.
      # Workspaces: n/p, or w for the list
      keys = {
        previous_tab = [ "ctrl+shift+tab" "prefix+h" ];
        next_tab = [ "ctrl+tab" "prefix+l" ];
        previous_workspace = "prefix+p";
        next_workspace = "prefix+n";
        focus_pane_left = "prefix+left";
        focus_pane_down = [ "prefix+j" "prefix+down" ];
        focus_pane_up = [ "prefix+k" "prefix+up" ];
        focus_pane_right = "prefix+right";
      };
    };
  };
}
