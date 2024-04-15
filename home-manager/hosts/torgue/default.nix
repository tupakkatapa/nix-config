{ pkgs
, ...
}@args:
let
  helpers = import ../helpers.nix args;
in
{
  # This file should be imported under 'home-manager.users.<username>'
  # See 'home-manager/users/kari/minimal.nix' for an example how to do this conditionally

  imports = [
    ../.config/thunar.nix
    ../.config/rice01
  ];

  # Default apps
  home.sessionVariables = {
    FONT = "JetBrainsMono Nerd Font";
  };
  xdg.mime.enable = true;
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = helpers.createMimes {
    audio = [ "mpv.desktop" ];
    archive = [ "xarchiver.desktop" ];
    image = [ "imv-dir.desktop" ];
    pdf = [ "org.pwmt.zathura-pdf-mupdf.desktop" ];
    text = [ "org.xfce.mousepad.desktop" ];
    video = [ "mpv.desktop" ];
  };
  xdg.configFile."mimeapps.list".force = true;

  # Allow fonts trough home.packages
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    # Nautilus
    gnome.nautilus
    gnome.file-roller
    gnome.sushi

    # GUI tools
    xfce.mousepad
    xarchiver
    zathura
    imv

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
