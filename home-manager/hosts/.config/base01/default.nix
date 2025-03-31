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

  programs.waybar = {
    enable = true;
    # systemd = {
    #   enable = true;
    #   target = "hyprland-session.target";
    # };
    package = pkgs.waybar.overrideAttrs (oa: {
      mesonFlags = (oa.mesonFlags or [ ]) ++ [ "-Dexperimental=true" ];
    });
  };

  programs.wofi = {
    enable = true;
  };
}
