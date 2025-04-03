# https://github.com/hyper-dot/Arch-Hyprland
{ pkgs
, customLib
, ...
}:
let
  user = "kari";
in
{
  # This configuration extends the minimal-passwd and minimal-gui versions
  imports = [ ./minimal-passwd.nix ./minimal-gui.nix ];

  # Home-manager config
  home-manager.users."${user}" = {
    # Default apps
    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications = customLib.xdg.createMimes {
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

      discord
      # libreoffice-qt6-fresh
      # chromium
      # rpi-imager
      # appimage-run

      # Networking
      wireguard-go
      wireguard-tools
    ];
  };
}
