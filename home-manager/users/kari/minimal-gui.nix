_:
let
  user = "kari";
in
{
  # This configuration extends the minimal-dev version
  imports = [ ./minimal-dev.nix ];

  # Required for home-manager GTK apps
  programs.dconf.enable = true;

  # Home-manager config
  home-manager.users."${user}" = {
    imports = [
      ./.config/foot.nix
      ./.config/firefox
    ];

    # Allow fonts trough home.packages
    fonts.fontconfig.enable = true;

    # Default apps by user
    home.sessionVariables = {
      BROWSER = "firefox";
      FONT = "JetBrains Mono";
      TERMINAL = "foot";
    };
  };
}
