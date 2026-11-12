{
  programs.herdr = {
    enable = true;
    settings = {
      onboarding = false;
      theme.name = "gruvbox";
      # Nix pins the version; `herdr update` cannot replace a store binary
      update.version_check = false;
      # h/l tabs, j/k workspaces; pane focus moves to the arrows
      keys = {
        previous_workspace = "prefix+k";
        next_workspace = "prefix+j";
        previous_tab = [ "prefix+p" "prefix+h" ];
        next_tab = [ "prefix+n" "prefix+l" ];
        focus_pane_left = "prefix+left";
        focus_pane_down = "prefix+down";
        focus_pane_up = "prefix+up";
        focus_pane_right = "prefix+right";
      };
    };
  };
}
