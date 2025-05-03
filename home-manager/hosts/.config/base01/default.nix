{ pkgs, ... }:
{
  imports = [
    ./hyprland.nix
  ];

  home.packages = with pkgs; [
    wl-clipboard
    libnotify
    nautilus
  ];

  gtk.enable = true;

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "gtk2";
  };

  services.mako = {
    enable = true;
    defaultTimeout = 5000;
    markup = true;
    icons = true;
    maxIconSize = 64;
    padding = "8,8";
    height = 1000;
    anchor = "top-right";
    sort = "+time";
    groupBy = "app-name";
  };

  programs.waybar.enable = true;
  programs.wofi.enable = true;

  # Automount removable media
  services.udiskie = {
    enable = true;
    settings = {
      # Workaround for https://github.com/nix-community/home-manager/issues/632
      program_options = {
        file_manager = "${pkgs.nautilus}/bin/nautilus";
      };
    };
  };
}
