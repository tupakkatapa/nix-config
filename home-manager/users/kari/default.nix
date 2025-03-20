# https://github.com/hyper-dot/Arch-Hyprland
{ pkgs
, ...
}@args:
let
  user = "kari";
  helpers = import ../../helpers.nix args;
in
{
  # This configuration extends the minimal-passwd and minimal-gui versions
  imports = [ ./minimal-passwd.nix ./minimal-gui.nix ];

  # Home-manager config
  home-manager.users."${user}" = {
    # Default apps
    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications = helpers.createMimes {
      text = [ "writer.desktop" ];
      spreadsheet = [ "calc.desktop" ];
      presentation = [ "impress.desktop" ];
    };
    xdg.configFile."mimeapps.list".force = true;

    # Default apps by user
    home.sessionVariables = {
      # FILEMANAGER = lib.mkForce "nautilus";
    };

    home.packages = with pkgs; [
      monitor-adjust
      levari

      # sublime-merge
      discord
      # libreoffice-qt6-fresh
      # chromium
      # nautilus
      # rpi-imager

      # Networking
      wireguard-go
      wireguard-tools
    ];
  };
}
