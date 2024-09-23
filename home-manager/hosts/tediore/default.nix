{ pkgs
, lib
, ...
}: {
  # This file should be imported under 'home-manager.users.<username>'
  # See 'home-manager/users/kari/minimal.nix' for an example how to do this conditionally

  imports = [
    ../.config/rice02
  ];

  # Default apps
  home.sessionVariables = {
    FONT = lib.mkDefault "JetBrainsMono Nerd Font";
  };

  # Allow fonts trough home.packages
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    # Fonts
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })

    # WM Apps
    wl-clipboard
    mako
  ];

}
