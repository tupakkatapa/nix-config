{ pkgs
, lib
, ...
}:
{
  # This file should be imported under 'home-manager.users.<username>'
  # See 'home-manager/users/kari/minimal.nix' for an example how to do this conditionally

  imports = [
    ../.config/rice01
  ];

  # Default apps by host
  home.sessionVariables = {
    FONT = lib.mkDefault "JetBrainsMono Nerd Font";
    THEME = lib.mkDefault "gruvbox-dark-medium";
  };

  # Allow fonts trough home.packages
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    # Fonts
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    font-awesome # for waybar

    # WM Apps
    swaybg
    wl-clipboard
    pavucontrol
    pulseaudio
  ];
}
