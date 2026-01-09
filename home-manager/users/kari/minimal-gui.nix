{ pkgs
, ...
}:
let
  user = "kari";
in
{
  # This configuration extends the minimal version
  imports = [ ./minimal.nix ];

  # Required for home-manager GTK apps
  programs.dconf.enable = true;

  # Required for swaylock via home-manager
  security.pam.services.swaylock = { };

  # Home-manager config
  home-manager.users."${user}" = {
    imports = [
      ./.config/claude-bridge.nix
      ./.config/foot.nix
      ./.config/firefox
      ./.config/mpv.nix
      ./.config/imv.nix
    ];

    # Allow fonts trough home.packages
    fonts.fontconfig.enable = true;

    # Default apps by user
    home.sessionVariables = {
      BROWSER = "firefox";
      FONT = "JetBrainsMono Nerd Font";
      TERMINAL = "foot";
      THEME = "gruvbox-dark-medium";
    };

    home.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
    ];
  };
}
