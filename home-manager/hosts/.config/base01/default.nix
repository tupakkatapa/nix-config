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

  home.sessionVariables = {
    FILEMANAGER = "nautilus";
  };

  gtk.enable = true;

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "gtk2";
  };

  services.mako = {
    enable = true;
    settings = {
      default-timeout = 5000;
      markup = true;
      icons = true;
      max-icon-size = 64;
      padding = "8,8";
      height = 1000;
      anchor = "top-right";
      sort = "+time";
      group-by = "app-name";
    };
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
